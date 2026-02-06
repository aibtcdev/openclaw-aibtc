import json
import uuid
from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parent.parent
_TEMPLATES = _REPO_ROOT / "templates"
_SKILLS = _REPO_ROOT / "skills"


def _escape_shell(s: str) -> str:
    return s.replace("'", "'\\''")


def _get_autonomy_values(level: str) -> dict:
    if level == "conservative":
        return {"daily": "1.00", "per_tx": "0.50", "trust": "restricted"}
    if level == "autonomous":
        return {"daily": "50.00", "per_tx": "25.00", "trust": "elevated"}
    return {"daily": "10.00", "per_tx": "5.00", "trust": "standard"}


def _patch_state_json(content: str, autonomy: dict, level: str) -> str:
    """Patch state.json template with chosen autonomy values."""
    data = json.loads(content)
    data["authorization"]["autonomyLevel"] = level
    data["authorization"]["dailyAutoLimit"] = float(autonomy["daily"])
    data["authorization"]["perTransactionLimit"] = float(autonomy["per_tx"])
    data["authorization"]["trustLevel"] = autonomy["trust"]
    return json.dumps(data, indent=2)


def _heredoc(path: str, content: str, delimiter: str) -> str:
    """Generate a cat heredoc command to write a file."""
    return f"cat > {path} << '{delimiter}'\n{content}\n{delimiter}"


def generate_setup_commands(config: dict) -> list[str]:
    """Generate ordered shell commands for full agent deployment.

    Command layout (deploy.py depends on this):
      [0]  apt-get install docker
      [1]  systemctl enable/start docker
      [2]  mkdir -p directories
      [3..N-4]  config file writes + permissions
      [N-3] docker compose build
      [N-2] docker compose up -d
      [N-1] verify
    """
    autonomy_level = config.get("autonomy_level", "balanced")
    autonomy = _get_autonomy_values(autonomy_level)
    gateway_token = uuid.uuid4().hex + uuid.uuid4().hex
    network = config.get("network", "mainnet")
    model = config.get("model", "openrouter/anthropic/claude-sonnet-4")
    telegram_token = config["telegram_token"]
    openrouter_key = config["openrouter_key"]
    wallet_password = config["wallet_password"]

    base = "/opt/openclaw-aibtc"
    commands = []

    # 0: Install Docker
    commands.append(
        "apt-get update -qq && apt-get install -y -qq curl ca-certificates docker.io docker-compose-plugin"
    )

    # 1: Start Docker
    commands.append("systemctl enable docker && systemctl start docker")

    # 2: Create directories
    commands.append(
        f"mkdir -p {base}/data/{{config,workspace/skills/aibtc,workspace/skills/moltbook,workspace/memory}}"
    )

    # --- Config file writes start here (index 3) ---

    # 3: .env
    env_content = (
        f"OPENROUTER_API_KEY={_escape_shell(openrouter_key)}\n"
        f"TELEGRAM_BOT_TOKEN={_escape_shell(telegram_token)}\n"
        f"NETWORK={network}\n"
        f"OPENCLAW_GATEWAY_TOKEN={gateway_token}"
    )
    commands.append(_heredoc(f"{base}/.env", env_content, "ENVEOF"))

    # 4: Dockerfile
    dockerfile_content = (
        "FROM ghcr.io/openclaw/openclaw:latest\n"
        "USER root\n"
        "RUN npm install -g @aibtc/mcp-server@1.13.1 mcporter@0.7.3\n"
        f"ENV NETWORK={network}\n"
        "USER node\n"
        'CMD ["node", "dist/index.js", "gateway", "--bind", "lan", "--port", "18789"]'
    )
    commands.append(_heredoc(f"{base}/Dockerfile", dockerfile_content, "DOCKEREOF"))

    # 5: docker-compose.yml
    compose_content = (
        "services:\n"
        "  openclaw-gateway:\n"
        "    build: .\n"
        "    container_name: openclaw-aibtc\n"
        "    restart: unless-stopped\n"
        "    environment:\n"
        "      - OPENROUTER_API_KEY=${OPENROUTER_API_KEY}\n"
        "      - NETWORK=${NETWORK}\n"
        "      - OPENCLAW_GATEWAY_TOKEN=${OPENCLAW_GATEWAY_TOKEN}\n"
        "      - OPENCLAW_CONFIG_PATH=/home/node/.openclaw/openclaw.json\n"
        "    volumes:\n"
        "      - ./data:/home/node/.openclaw\n"
        "    ports:\n"
        '      - "18789:18789"'
    )
    commands.append(
        _heredoc(f"{base}/docker-compose.yml", compose_content, "COMPOSEEOF")
    )

    # 6: mcporter.json
    mcporter_config = {
        "mcpServers": {
            "aibtc": {
                "command": "aibtc-mcp-server",
                "lifecycle": "keep-alive",
                "env": {},
            }
        }
    }
    commands.append(
        _heredoc(
            f"{base}/data/config/mcporter.json",
            json.dumps(mcporter_config, indent=2),
            "MCPORTEREOF",
        )
    )

    # 7: openclaw.json
    openclaw_config = {
        "agents": {
            "defaults": {
                "model": {"primary": model},
                "workspace": "/home/node/.openclaw/workspace",
                "maxConcurrent": 4,
            }
        },
        "commands": {"native": "auto", "nativeSkills": "auto"},
        "channels": {
            "telegram": {
                "dmPolicy": "open",
                "botToken": telegram_token,
                "allowFrom": ["*"],
                "groupPolicy": "allowlist",
                "streamMode": "partial",
            }
        },
        "gateway": {
            "port": 18789,
            "mode": "local",
            "auth": {"mode": "token", "token": gateway_token},
            "controlUi": {"dangerouslyDisableDeviceAuth": True},
        },
        "plugins": {"entries": {"telegram": {"enabled": True}}},
    }
    commands.append(
        _heredoc(
            f"{base}/data/openclaw.json",
            json.dumps(openclaw_config, indent=2),
            "OPENCLAWEOF",
        )
    )

    # 8: aibtc SKILL.md
    aibtc_skill = (_SKILLS / "aibtc" / "SKILL.md").read_text()
    commands.append(
        _heredoc(
            f"{base}/data/workspace/skills/aibtc/SKILL.md",
            aibtc_skill.rstrip(),
            "SKILLEOF",
        )
    )

    # 9: moltbook SKILL.md
    moltbook_skill = (_SKILLS / "moltbook" / "SKILL.md").read_text()
    commands.append(
        _heredoc(
            f"{base}/data/workspace/skills/moltbook/SKILL.md",
            moltbook_skill.rstrip(),
            "MOLTEOF",
        )
    )

    # 10: USER.md
    user_md = (_TEMPLATES / "USER.md").read_text()
    commands.append(
        _heredoc(
            f"{base}/data/workspace/USER.md", user_md.rstrip(), "USERMDEOF"
        )
    )

    # 11: Wallet password
    commands.append(
        f"printf '%s' '{_escape_shell(wallet_password)}' > {base}/data/config/.wallet_password && chmod 600 {base}/data/config/.wallet_password"
    )

    # 12: Pending wallet password (for initial wallet creation)
    commands.append(
        f"printf '%s' '{_escape_shell(wallet_password)}' > {base}/data/workspace/.pending_wallet_password && chmod 600 {base}/data/workspace/.pending_wallet_password"
    )

    # 13: state.json (patched with autonomy values)
    state_template = (_TEMPLATES / "memory" / "state.json").read_text()
    state_content = _patch_state_json(state_template, autonomy, autonomy_level)
    commands.append(
        _heredoc(
            f"{base}/data/workspace/memory/state.json",
            state_content,
            "STATEJSONEOF",
        )
    )

    # 14: identity.md
    identity_md = (_TEMPLATES / "memory" / "identity.md").read_text()
    commands.append(
        _heredoc(
            f"{base}/data/workspace/memory/identity.md",
            identity_md.rstrip(),
            "IDENTITYEOF",
        )
    )

    # 15: journal.md
    journal_md = (_TEMPLATES / "memory" / "journal.md").read_text()
    commands.append(
        _heredoc(
            f"{base}/data/workspace/memory/journal.md",
            journal_md.rstrip(),
            "JOURNALEOF",
        )
    )

    # 16: portfolio.json
    portfolio_json = (_TEMPLATES / "memory" / "portfolio.json").read_text()
    commands.append(
        _heredoc(
            f"{base}/data/workspace/memory/portfolio.json",
            portfolio_json.rstrip(),
            "PORTFOLIOEOF",
        )
    )

    # 17: preferences.json
    preferences_json = (_TEMPLATES / "memory" / "preferences.json").read_text()
    commands.append(
        _heredoc(
            f"{base}/data/workspace/memory/preferences.json",
            preferences_json.rstrip(),
            "PREFERENCESEOF",
        )
    )

    # 18: relationships.json
    relationships_json = (
        (_TEMPLATES / "memory" / "relationships.json").read_text()
    )
    commands.append(
        _heredoc(
            f"{base}/data/workspace/memory/relationships.json",
            relationships_json.rstrip(),
            "RELATIONSHIPSEOF",
        )
    )

    # 19: README.md (memory system guide)
    memory_readme = (_TEMPLATES / "memory" / "README.md").read_text()
    commands.append(
        _heredoc(
            f"{base}/data/workspace/memory/README.md",
            memory_readme.rstrip(),
            "MEMORYREADMEEOF",
        )
    )

    # 20: Fix permissions (Docker container runs as node user, UID 1000)
    commands.append(f"chown -R 1000:1000 {base}/data")

    # --- Config file writes end here ---

    # 21: Build
    commands.append(f"cd {base} && docker compose build")

    # 22: Start
    commands.append(f"cd {base} && docker compose up -d")

    # 23: Verify
    commands.append(
        f"sleep 5 && docker compose -f {base}/docker-compose.yml ps --format json"
    )

    return commands
