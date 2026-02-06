import asyncio
import json

import httpx
from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse, JSONResponse, StreamingResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates

from deploy import run_deploy, test_ssh_connection


app = FastAPI()
app.mount("/static", StaticFiles(directory="static"), name="static")
templates = Jinja2Templates(directory="templates")

# Models known to work well as agents with tool calling
RECOMMENDED_IDS = {
    "anthropic/claude-sonnet-4",
    "anthropic/claude-opus-4",
    "anthropic/claude-haiku-4",
    "google/gemini-2.5-flash",
    "google/gemini-2.5-pro",
    "deepseek/deepseek-chat-v3-0324",
    "openai/gpt-4o",
}


@app.get("/", response_class=HTMLResponse)
async def wizard(request: Request):
    return templates.TemplateResponse("wizard.html", {"request": request})


@app.post("/api/test-connection")
async def api_test_connection(request: Request):
    body = await request.json()
    result = await asyncio.to_thread(
        test_ssh_connection,
        host=body["host"],
        user=body["user"],
        auth_method=body["authMethod"],
        password=body.get("password", ""),
        key=body.get("key", ""),
    )
    return result


@app.post("/api/models")
async def api_models(request: Request):
    body = await request.json()
    api_key = body.get("apiKey", "")
    if not api_key:
        return JSONResponse({"error": "API key required"}, status_code=400)

    try:
        async with httpx.AsyncClient(timeout=15) as client:
            resp = await client.get(
                "https://openrouter.ai/api/v1/models",
                params={"supported_parameters": "tools"},
                headers={"Authorization": f"Bearer {api_key}"},
            )
            resp.raise_for_status()
            data = resp.json()
    except Exception as e:
        return JSONResponse({"error": str(e)}, status_code=502)

    models = []
    for m in data.get("data", []):
        model_id = m.get("id", "")
        pricing = m.get("pricing", {})
        prompt_cost = pricing.get("prompt", "0")
        completion_cost = pricing.get("completion", "0")
        models.append({
            "id": model_id,
            "name": m.get("name", model_id),
            "context": m.get("context_length", 0),
            "promptCost": prompt_cost,
            "completionCost": completion_cost,
            "recommended": model_id in RECOMMENDED_IDS,
        })

    # Sort: recommended first, then by name
    models.sort(key=lambda x: (not x["recommended"], x["name"]))
    return {"models": models}


@app.post("/api/deploy")
async def api_deploy(request: Request):
    body = await request.json()

    async def event_stream():
        async for event in run_deploy(body["vps"], body["config"]):
            yield f"data: {json.dumps(event)}\n\n"
        yield "data: [DONE]\n\n"

    return StreamingResponse(
        event_stream(),
        media_type="text/event-stream",
        headers={"Cache-Control": "no-cache", "Connection": "keep-alive"},
    )
