#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                           ║"
echo "║   ₿  OpenClaw + aibtc Setup                               ║"
echo "║                                                           ║"
echo "║   Bitcoin & Stacks blockchain agent powered by OpenClaw   ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check for Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed.${NC}"
    echo "Please install Docker: https://docs.docker.com/get-docker/"
    exit 1
fi

if ! docker info &> /dev/null; then
    echo -e "${RED}Error: Docker is not running.${NC}"
    echo "Please start Docker Desktop or the Docker daemon."
    exit 1
fi

echo -e "${GREEN}✓ Docker is installed and running${NC}"

# Check for docker compose
if ! docker compose version &> /dev/null; then
    echo -e "${RED}Error: Docker Compose is not available.${NC}"
    echo "Please install Docker Compose: https://docs.docker.com/compose/install/"
    exit 1
fi

echo -e "${GREEN}✓ Docker Compose is available${NC}"
echo ""

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Create data directories
echo -e "${BLUE}Creating data directories...${NC}"
mkdir -p data/config
mkdir -p data/workspace/skills/aibtc
mkdir -p data/workspace/memory

# Check if .env exists
if [ -f ".env" ]; then
    echo -e "${YELLOW}Found existing .env file.${NC}"
    read -p "Do you want to reconfigure? (y/N): " RECONFIG
    if [[ ! "$RECONFIG" =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Using existing configuration.${NC}"
        SKIP_CONFIG=true
    fi
fi

if [ "$SKIP_CONFIG" != "true" ]; then
    # Get OpenRouter API Key
    echo ""
    echo -e "${YELLOW}Step 1: OpenRouter API Key${NC}"
    echo "Get your key at: https://openrouter.ai/keys"
    echo ""
    read -p "Enter your OpenRouter API Key: " OPENROUTER_KEY

    if [ -z "$OPENROUTER_KEY" ]; then
        echo -e "${RED}Error: OpenRouter API key is required.${NC}"
        exit 1
    fi

    # Get Telegram Bot Token
    echo ""
    echo -e "${YELLOW}Step 2: Telegram Bot Token${NC}"
    echo "Create a bot via @BotFather on Telegram"
    echo ""
    read -p "Enter your Telegram Bot Token: " TELEGRAM_TOKEN

    if [ -z "$TELEGRAM_TOKEN" ]; then
        echo -e "${RED}Error: Telegram bot token is required.${NC}"
        exit 1
    fi

    # Network selection
    echo ""
    echo -e "${YELLOW}Step 3: Network Selection${NC}"
    echo "1) mainnet (real Bitcoin/Stacks)"
    echo "2) testnet (test tokens only)"
    read -p "Select network [1]: " NETWORK_CHOICE

    if [ "$NETWORK_CHOICE" = "2" ]; then
        NETWORK="testnet"
    else
        NETWORK="mainnet"
    fi

    # Generate gateway token
    GATEWAY_TOKEN=$(openssl rand -hex 32 2>/dev/null || head -c 64 /dev/urandom | xxd -p | tr -d '\n' | head -c 64)

    # Create .env file
    echo -e "${BLUE}Creating configuration...${NC}"
    cat > .env << EOF
# OpenClaw + aibtc Configuration
# Generated on $(date)

# Required: Your OpenRouter API key
OPENROUTER_API_KEY=${OPENROUTER_KEY}

# Required: Your Telegram bot token
TELEGRAM_BOT_TOKEN=${TELEGRAM_TOKEN}

# Network: mainnet or testnet
NETWORK=${NETWORK}

# Gateway token (auto-generated, keep secret)
OPENCLAW_GATEWAY_TOKEN=${GATEWAY_TOKEN}

# Ports (change if conflicts)
OPENCLAW_GATEWAY_PORT=18789
OPENCLAW_BRIDGE_PORT=18790
EOF

    echo -e "${GREEN}✓ Configuration saved to .env${NC}"
fi

# Load env vars
source .env

# Create mcporter config
echo -e "${BLUE}Creating mcporter configuration...${NC}"
cat > data/config/mcporter.json << 'EOF'
{
  "mcpServers": {
    "aibtc": {
      "command": "aibtc-mcp-server",
      "env": {
        "NETWORK": "${NETWORK:-mainnet}"
      }
    }
  }
}
EOF

# Create OpenClaw config
echo -e "${BLUE}Creating OpenClaw configuration...${NC}"
cat > data/openclaw.json << EOF
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "openrouter/anthropic/claude-sonnet-4"
      },
      "workspace": "/home/node/.openclaw/workspace",
      "maxConcurrent": 4,
      "subagents": {
        "maxConcurrent": 8
      }
    }
  },
  "commands": {
    "native": "auto",
    "nativeSkills": "auto"
  },
  "channels": {
    "telegram": {
      "dmPolicy": "open",
      "botToken": "${TELEGRAM_BOT_TOKEN}",
      "allowFrom": ["*"],
      "groupPolicy": "allowlist",
      "streamMode": "partial"
    }
  },
  "gateway": {
    "port": 18789,
    "mode": "local",
    "bind": "0.0.0.0",
    "auth": {
      "mode": "token",
      "token": "${OPENCLAW_GATEWAY_TOKEN}"
    },
    "controlUi": {
      "dangerouslyDisableDeviceAuth": true
    }
  },
  "plugins": {
    "entries": {
      "telegram": {
        "enabled": true
      }
    }
  }
}
EOF

# Copy aibtc skill
echo -e "${BLUE}Installing aibtc skill...${NC}"
cp -r skills/aibtc data/workspace/skills/

# Create workspace files
cat > data/workspace/USER.md << 'EOF'
# User Profile

This is your personal OpenClaw agent with Bitcoin & Stacks blockchain capabilities.

## Your Preferences
- Always ask for wallet password before transactions
- Confirm transaction details before executing
- Lock wallet immediately after transactions
EOF

# Build and start
echo ""
echo -e "${BLUE}Building Docker image...${NC}"
docker compose build

echo ""
echo -e "${BLUE}Starting OpenClaw...${NC}"
docker compose up -d

# Wait for startup
echo -e "${BLUE}Waiting for services to start...${NC}"
sleep 10

# Check if running
if docker compose ps | grep -q "Up"; then
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                           ║${NC}"
    echo -e "${GREEN}║   ✓ Setup Complete!                                       ║${NC}"
    echo -e "${GREEN}║                                                           ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Your agent is now running!${NC}"
    echo ""
    echo "  📱 Telegram: Message your bot to start chatting"
    echo "  🌐 Web UI:   http://localhost:${OPENCLAW_GATEWAY_PORT}/?token=${OPENCLAW_GATEWAY_TOKEN}"
    echo ""
    echo -e "${BLUE}Quick commands:${NC}"
    echo "  docker compose logs -f    # View logs"
    echo "  docker compose restart    # Restart agent"
    echo "  docker compose down       # Stop agent"
    echo ""
    echo -e "${YELLOW}First steps:${NC}"
    echo "  1. Message your Telegram bot"
    echo "  2. Say: \"Create a new Bitcoin wallet\""
    echo "  3. Set a strong password when prompted"
    echo ""
else
    echo -e "${RED}Error: Services failed to start.${NC}"
    echo "Check logs with: docker compose logs"
    exit 1
fi
