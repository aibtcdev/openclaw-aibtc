import asyncio
import io
import json
from collections.abc import AsyncGenerator

import paramiko

from setup_script import generate_setup_commands


def test_ssh_connection(
    host: str,
    user: str,
    auth_method: str,
    password: str = "",
    key: str = "",
) -> dict:
    """Test SSH connection to VPS. Returns success/error dict."""
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    try:
        connect_kwargs = {"hostname": host, "port": 22, "username": user, "timeout": 10}
        if auth_method == "key" and key:
            pkey = paramiko.RSAKey.from_private_key(io.StringIO(key))
            connect_kwargs["pkey"] = pkey
        else:
            connect_kwargs["password"] = password

        client.connect(**connect_kwargs)
        _, stdout, _ = client.exec_command("echo ok && uname -a")
        info = stdout.read().decode().strip()
        client.close()
        return {"success": True, "info": info}
    except Exception as e:
        return {"success": False, "error": str(e)}
    finally:
        client.close()


def _exec_command(client: paramiko.SSHClient, command: str, timeout: int = 300) -> dict:
    """Execute a command over SSH. Returns stdout, stderr, exit code."""
    _, stdout, stderr = client.exec_command(command, timeout=timeout)
    exit_code = stdout.channel.recv_exit_status()
    return {
        "stdout": stdout.read().decode(),
        "stderr": stderr.read().decode(),
        "code": exit_code,
    }


async def run_deploy(vps: dict, config: dict) -> AsyncGenerator[dict, None]:
    """
    Deploy agent to VPS via SSH.
    Yields SSE event dicts with step/message fields.
    """
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

    try:
        # Step 1: Connect
        yield {
            "step": "connecting",
            "message": f"Connecting to {vps['user']}@{vps['host']}...",
        }

        connect_kwargs = {
            "hostname": vps["host"],
            "port": 22,
            "username": vps["user"],
            "timeout": 15,
        }
        if vps.get("authMethod") == "key" and vps.get("key"):
            pkey = paramiko.RSAKey.from_private_key(io.StringIO(vps["key"]))
            connect_kwargs["pkey"] = pkey
        else:
            connect_kwargs["password"] = vps.get("password", "")

        await asyncio.to_thread(client.connect, **connect_kwargs)
        yield {"step": "connecting", "message": "SSH connection established"}

        # Step 2: Install Docker
        yield {"step": "docker", "message": "Checking for Docker..."}
        result = await asyncio.to_thread(
            _exec_command, client, "docker --version 2>/dev/null || echo 'NOT_FOUND'"
        )

        if "NOT_FOUND" in result["stdout"]:
            yield {
                "step": "docker",
                "message": "Installing Docker (this may take a minute)...",
            }

            for cmd in [
                "apt-get update -qq && apt-get install -y -qq curl ca-certificates",
                "curl -fsSL https://get.docker.com | sh",
                "systemctl enable docker && systemctl start docker",
            ]:
                yield {"step": "docker", "message": f"Running: {cmd[:60]}..."}
                r = await asyncio.to_thread(_exec_command, client, cmd, 180)
                if r["code"] != 0:
                    yield {"step": "error", "message": f"Failed: {r['stderr'][:200]}"}
                    return
        else:
            yield {
                "step": "docker",
                "message": f"Docker already installed: {result['stdout'].strip()}",
            }

        # Verify docker compose
        r = await asyncio.to_thread(_exec_command, client, "docker compose version")
        if r["code"] != 0:
            yield {"step": "docker", "message": "Installing docker-compose-plugin..."}
            await asyncio.to_thread(
                _exec_command, client, "apt-get install -y -qq docker-compose-plugin"
            )

        yield {"step": "docker", "message": "Docker is ready"}

        # Step 3: Write configuration
        yield {"step": "config", "message": "Creating project directory..."}
        await asyncio.to_thread(
            _exec_command,
            client,
            "mkdir -p /opt/openclaw-aibtc/data/{config,workspace/skills/aibtc,workspace/skills/moltbook,workspace/memory}",
        )

        commands = generate_setup_commands(config)
        # Skip indices 0 (apt), 1 (systemctl), 2 (mkdir) — already done above
        file_commands = commands[3:-3]  # Skip docker install and build/start/verify

        for cmd in file_commands:
            # Extract filename for display
            if "cat >" in cmd:
                fname = (
                    cmd.split("cat >")[1]
                    .split("<<")[0]
                    .strip()
                    .replace("/opt/openclaw-aibtc/", "")
                )
            elif ".wallet_password" in cmd or ".pending_wallet_password" in cmd:
                fname = "wallet password"
            elif "chown" in cmd:
                fname = "permissions"
            else:
                fname = "config"
            yield {"step": "config", "message": f"Writing {fname}..."}
            r = await asyncio.to_thread(_exec_command, client, cmd)
            if r["code"] != 0:
                yield {
                    "step": "error",
                    "message": f"Failed writing {fname}: {r['stderr'][:200]}",
                }
                return

        yield {"step": "config", "message": "Configuration complete"}

        # Step 4: Build image
        yield {
            "step": "building",
            "message": "Building agent Docker image (this may take a few minutes)...",
        }
        r = await asyncio.to_thread(
            _exec_command,
            client,
            "cd /opt/openclaw-aibtc && docker compose build --no-cache",
            600,
        )
        if r["code"] != 0:
            yield {"step": "error", "message": f"Build failed: {r['stderr'][:300]}"}
            return
        yield {"step": "building", "message": "Image built successfully"}

        # Step 5: Start container
        yield {"step": "starting", "message": "Starting agent container..."}
        r = await asyncio.to_thread(
            _exec_command, client, "cd /opt/openclaw-aibtc && docker compose up -d"
        )
        if r["code"] != 0:
            yield {"step": "error", "message": f"Start failed: {r['stderr'][:300]}"}
            return
        yield {"step": "starting", "message": "Container started, waiting for init..."}
        await asyncio.sleep(3)

        # Restart to ensure config is fully loaded (first boot race condition)
        yield {"step": "starting", "message": "Restarting to finalize config..."}
        r = await asyncio.to_thread(
            _exec_command, client, "cd /opt/openclaw-aibtc && docker compose restart"
        )
        if r["code"] != 0:
            yield {"step": "error", "message": f"Restart failed: {r['stderr'][:300]}"}
            return
        yield {"step": "starting", "message": "Container restarted"}

        # Step 6: Verify
        yield {"step": "verifying", "message": "Waiting for container to initialize..."}
        await asyncio.sleep(5)

        r = await asyncio.to_thread(
            _exec_command,
            client,
            "cd /opt/openclaw-aibtc && docker compose ps --format '{{.Name}} {{.Status}}'",
        )
        status = r["stdout"].strip()
        yield {"step": "verifying", "message": f"Container status: {status}"}

        if "up" in status.lower():
            # Resolve bot username via Telegram API
            bot_username = ""
            tg_token = config.get("telegram_token", "")
            if tg_token:
                yield {"step": "verifying", "message": "Resolving Telegram bot info..."}
                r = await asyncio.to_thread(
                    _exec_command,
                    client,
                    f"curl -s https://api.telegram.org/bot{tg_token}/getMe",
                    15,
                )
                try:
                    me = json.loads(r["stdout"])
                    if me.get("ok"):
                        bot_username = me["result"].get("username", "")
                except Exception:
                    pass

            yield {
                "step": "complete",
                "message": "Agent deployed successfully!",
                "gatewayUrl": f"http://{vps['host']}:18789",
                "botUsername": bot_username,
            }
        else:
            logs = await asyncio.to_thread(
                _exec_command,
                client,
                "cd /opt/openclaw-aibtc && docker compose logs --tail=20",
            )
            yield {
                "step": "error",
                "message": f"Container not healthy. Logs:\n{logs['stdout'][:500]}",
            }

    except Exception as e:
        yield {"step": "error", "message": str(e)}
    finally:
        client.close()
