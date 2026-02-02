#!/bin/sh
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

printf "${BLUE}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                           ║"
echo "║   ₿  OpenClaw + aibtc                                     ║"
echo "║                                                           ║"
echo "║   Bitcoin & Stacks AI Agent (Docker Desktop)              ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
printf "${NC}\n"

# Check for Docker
if ! command -v docker >/dev/null 2>&1; then
    printf "${RED}Error: Docker is not installed.${NC}\n"
    echo "Please install Docker Desktop: https://docs.docker.com/get-docker/"
    exit 1
fi

if ! docker info >/dev/null 2>&1; then
    printf "${RED}Error: Docker is not running.${NC}\n"
    echo "Please start Docker Desktop."
    exit 1
fi

printf "${GREEN}✓ Docker is running${NC}\n"

if ! docker compose version >/dev/null 2>&1; then
    printf "${RED}Error: Docker Compose is not available.${NC}\n"
    exit 1
fi

printf "${GREEN}✓ Docker Compose available${NC}\n"
echo ""

# Install directory
INSTALL_DIR="$HOME/openclaw-aibtc"

# Check existing installation
if [ -f "$INSTALL_DIR/.env" ]; then
    printf "${YELLOW}Found existing installation at $INSTALL_DIR${NC}\n"
    printf "Reconfigure? (y/N): "
    read RECONFIG < /dev/tty
    case "$RECONFIG" in
        [Yy]|[Yy][Ee][Ss]) ;;
        *)
            printf "${BLUE}Starting existing installation...${NC}\n"
            cd "$INSTALL_DIR"
            docker compose up -d
            printf "${GREEN}✓ Agent started!${NC}\n"
            echo "Message your Telegram bot to chat."
            exit 0
            ;;
    esac
fi

# Get configuration
printf "${YELLOW}Step 1: OpenRouter API Key${NC}\n"
echo "Get your key at: https://openrouter.ai/keys"
printf "Enter OpenRouter API Key: "
read OPENROUTER_KEY < /dev/tty
if [ -z "$OPENROUTER_KEY" ]; then
    printf "${RED}Error: OpenRouter API key is required.${NC}\n"
    exit 1
fi

echo ""
printf "${YELLOW}Step 2: Telegram Bot Token${NC}\n"
echo "Create a bot via @BotFather on Telegram"
printf "Enter Telegram Bot Token: "
read TELEGRAM_TOKEN < /dev/tty
if [ -z "$TELEGRAM_TOKEN" ]; then
    printf "${RED}Error: Telegram bot token is required.${NC}\n"
    exit 1
fi

echo ""
printf "${YELLOW}Step 3: Network${NC}\n"
echo "1) mainnet (real Bitcoin/Stacks)"
echo "2) testnet (test tokens only)"
printf "Select [1]: "
read NETWORK_CHOICE < /dev/tty
if [ "$NETWORK_CHOICE" = "2" ]; then
    NETWORK="testnet"
else
    NETWORK="mainnet"
fi

# Generate token
GATEWAY_TOKEN=$(openssl rand -hex 32 2>/dev/null || head -c 64 /dev/urandom | xxd -p | tr -d '\n' | head -c 64)

# Create directory structure
echo ""
printf "${BLUE}Creating installation...${NC}\n"
mkdir -p "$INSTALL_DIR/data/config"
mkdir -p "$INSTALL_DIR/data/workspace/skills/aibtc"
mkdir -p "$INSTALL_DIR/data/workspace/memory"
cd "$INSTALL_DIR"

# Clean up if openclaw.json is a directory (Docker creates this if file missing)
if [ -d "$INSTALL_DIR/data/openclaw.json" ]; then
    rm -rf "$INSTALL_DIR/data/openclaw.json"
fi

# Create .env
cat > .env << EOF
OPENROUTER_API_KEY=${OPENROUTER_KEY}
TELEGRAM_BOT_TOKEN=${TELEGRAM_TOKEN}
NETWORK=${NETWORK}
OPENCLAW_GATEWAY_TOKEN=${GATEWAY_TOKEN}
EOF

# Create Dockerfile
cat > Dockerfile << 'EOF'
FROM ghcr.io/openclaw/openclaw:latest
USER root
RUN npm install -g @aibtc/mcp-server mcporter
ENV NETWORK=mainnet
USER node
CMD ["node", "dist/index.js", "gateway", "--bind", "lan", "--port", "18789"]
EOF

# Create docker-compose.yml
cat > docker-compose.yml << 'EOF'
services:
  openclaw-gateway:
    build: .
    container_name: openclaw-aibtc
    restart: unless-stopped
    environment:
      - OPENROUTER_API_KEY=${OPENROUTER_API_KEY}
      - NETWORK=${NETWORK}
      - OPENCLAW_GATEWAY_TOKEN=${OPENCLAW_GATEWAY_TOKEN}
      - OPENCLAW_CONFIG_PATH=/home/node/.openclaw/openclaw.json
    volumes:
      - ./data:/home/node/.openclaw
    ports:
      - "18789:18789"
EOF

# Create mcporter config
cat > data/config/mcporter.json << 'EOF'
{
  "mcpServers": {
    "aibtc": {
      "command": "aibtc-mcp-server",
      "env": {}
    }
  }
}
EOF

# Create OpenClaw config
cat > data/openclaw.json << EOF
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "openrouter/anthropic/claude-sonnet-4"
      },
      "workspace": "/home/node/.openclaw/workspace",
      "maxConcurrent": 4
    }
  },
  "commands": {
    "native": "auto",
    "nativeSkills": "auto"
  },
  "channels": {
    "telegram": {
      "dmPolicy": "open",
      "botToken": "${TELEGRAM_TOKEN}",
      "allowFrom": ["*"],
      "groupPolicy": "allowlist",
      "streamMode": "partial"
    }
  },
  "gateway": {
    "port": 18789,
    "mode": "local",
    "auth": {
      "mode": "token",
      "token": "${GATEWAY_TOKEN}"
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

# Create aibtc skill
cat > data/workspace/skills/aibtc/SKILL.md << 'SKILLEOF'
---
name: aibtc
description: Bitcoin L1 and Stacks L2 blockchain toolkit. Use for BTC/STX balances, transfers, DeFi (ALEX, Zest), sBTC, tokens, NFTs, BNS names, and x402 paid APIs.
homepage: https://github.com/aibtcdev/aibtc-mcp-server
user-invocable: true
metadata: {"openclaw":{"emoji":"₿","requires":{"bins":["mcporter","aibtc-mcp-server"]}}}
---

# aibtc - Bitcoin & Stacks Blockchain Tools

Use `/usr/local/bin/mcporter` to call aibtc MCP tools. Execute commands with the `exec` tool. Always use the full path.

## CRITICAL SECURITY RULES

**YOU MUST FOLLOW THESE RULES - NO EXCEPTIONS:**

1. **NEVER store, remember, or log passwords** - Do not save passwords anywhere
2. **ALWAYS ask the user for their password** before running `wallet_unlock` - Never assume or reuse passwords
3. **ONLY use the user's existing wallet** - Do not create new wallets unless the user explicitly asks
4. **LOCK wallet immediately after transactions** - Always run `wallet_lock` after any transaction completes
5. **CONFIRM before any transaction** - Always show the user what you're about to do and get confirmation before transfers
6. **Never auto-approve transactions** - Every transfer requires explicit user approval with amount and recipient shown

## Transaction Flow (MUST FOLLOW)

For ANY transaction (transfer, swap, supply, borrow, etc.):

1. **Check wallet status:**
   ```bash
   /usr/local/bin/mcporter --config /home/node/.openclaw/config/mcporter.json call aibtc.wallet_status
   ```

2. **ASK the user for their password** - Say: "Please provide your wallet password to unlock for this transaction."

3. **Show transaction details and get confirmation** - Say: "I will send [AMOUNT] to [RECIPIENT]. Please confirm (yes/no)."

4. **Only after user confirms AND provides password:**
   ```bash
   /usr/local/bin/mcporter --config /home/node/.openclaw/config/mcporter.json call aibtc.wallet_unlock password=USER_PROVIDED_PASSWORD
   ```

5. **Execute the transaction**

6. **IMMEDIATELY lock the wallet:**
   ```bash
   /usr/local/bin/mcporter --config /home/node/.openclaw/config/mcporter.json call aibtc.wallet_lock
   ```

7. **Report result to user**

---

## Read-Only Operations (No Password Needed)

These operations are safe and don't require wallet unlock:

```bash
# Check balances
/usr/local/bin/mcporter --config /home/node/.openclaw/config/mcporter.json call aibtc.get_btc_balance
/usr/local/bin/mcporter --config /home/node/.openclaw/config/mcporter.json call aibtc.get_stx_balance
/usr/local/bin/mcporter --config /home/node/.openclaw/config/mcporter.json call aibtc.sbtc_get_balance

# Get wallet info (addresses only, no sensitive data)
/usr/local/bin/mcporter --config /home/node/.openclaw/config/mcporter.json call aibtc.get_wallet_info

# Check fees
/usr/local/bin/mcporter --config /home/node/.openclaw/config/mcporter.json call aibtc.get_btc_fees
/usr/local/bin/mcporter --config /home/node/.openclaw/config/mcporter.json call aibtc.get_stx_fees

# Network status
/usr/local/bin/mcporter --config /home/node/.openclaw/config/mcporter.json call aibtc.get_network_status

# BNS lookups
/usr/local/bin/mcporter --config /home/node/.openclaw/config/mcporter.json call aibtc.lookup_bns_name name=example.btc

# DeFi info (read-only)
/usr/local/bin/mcporter --config /home/node/.openclaw/config/mcporter.json call aibtc.alex_list_pools
/usr/local/bin/mcporter --config /home/node/.openclaw/config/mcporter.json call aibtc.zest_list_assets
/usr/local/bin/mcporter --config /home/node/.openclaw/config/mcporter.json call aibtc.zest_get_position

# x402 endpoints list
/usr/local/bin/mcporter --config /home/node/.openclaw/config/mcporter.json call aibtc.list_x402_endpoints
```

---

## Write Operations (REQUIRE Password + Confirmation)

**REMEMBER: Ask for password, confirm details, then lock after!**

### Transfers
```bash
# Transfer BTC (amount in satoshis)
/usr/local/bin/mcporter --config /home/node/.openclaw/config/mcporter.json call aibtc.transfer_btc recipient=bc1... amount=50000

# Transfer STX (amount in micro-STX)
/usr/local/bin/mcporter --config /home/node/.openclaw/config/mcporter.json call aibtc.transfer_stx recipient=SP... amount=1000000

# Transfer sBTC
/usr/local/bin/mcporter --config /home/node/.openclaw/config/mcporter.json call aibtc.sbtc_transfer recipient=SP... amount=100000
```

### DeFi Operations
```bash
# ALEX swap
/usr/local/bin/mcporter --config /home/node/.openclaw/config/mcporter.json call aibtc.alex_swap tokenX=STX tokenY=ALEX amount=1000000

# Zest supply
/usr/local/bin/mcporter --config /home/node/.openclaw/config/mcporter.json call aibtc.zest_supply asset=sBTC amount=100000

# Zest borrow
/usr/local/bin/mcporter --config /home/node/.openclaw/config/mcporter.json call aibtc.zest_borrow asset=aeUSDC amount=1000000
```

### Smart Contracts
```bash
# Call contract (write)
/usr/local/bin/mcporter --config /home/node/.openclaw/config/mcporter.json call aibtc.call_contract contractAddress=SP... contractName=contract functionName=do-something functionArgs='[]'
```

---

## Wallet Management

```bash
# Check wallet status
/usr/local/bin/mcporter --config /home/node/.openclaw/config/mcporter.json call aibtc.wallet_status

# List wallets
/usr/local/bin/mcporter --config /home/node/.openclaw/config/mcporter.json call aibtc.wallet_list

# Unlock wallet (ONLY after asking user for password)
/usr/local/bin/mcporter --config /home/node/.openclaw/config/mcporter.json call aibtc.wallet_unlock password=USER_PROVIDED_PASSWORD

# Lock wallet (ALWAYS do this after transactions)
/usr/local/bin/mcporter --config /home/node/.openclaw/config/mcporter.json call aibtc.wallet_lock
```

**Creating new wallets** - Only if user explicitly requests:
```bash
/usr/local/bin/mcporter --config /home/node/.openclaw/config/mcporter.json call aibtc.wallet_create password=USER_PROVIDED_PASSWORD name=wallet-name
```

---

## Unit Conversions

| Asset | Unit | Conversion |
|-------|------|------------|
| BTC | satoshi | 1 BTC = 100,000,000 sats |
| STX | micro-STX | 1 STX = 1,000,000 uSTX |
| sBTC | satoshi | 1 sBTC = 100,000,000 sats |

---

## Example Conversation Flow

**User:** "Send 0.001 BTC to bc1qxyz..."

**Agent:**
1. "I'll help you send 0.001 BTC (100,000 satoshis) to bc1qxyz..."
2. "Please provide your wallet password to authorize this transaction."

**User:** "mypassword123"

**Agent:**
3. "Confirming: Send 100,000 satoshis to bc1qxyz... Do you approve? (yes/no)"

**User:** "yes"

**Agent:**
4. *Unlocks wallet, executes transfer, locks wallet*
5. "Transaction submitted! TxID: abc123... Your wallet has been locked for security."
SKILLEOF

# Create USER.md
cat > data/workspace/USER.md << 'EOF'
# User Profile

This is your personal OpenClaw agent with Bitcoin & Stacks blockchain capabilities.

## Your Preferences
- Always ask for wallet password before transactions
- Confirm transaction details before executing
- Lock wallet immediately after transactions
EOF

# Build and start
printf "${BLUE}Building Docker image (this may take a minute)...${NC}\n"
docker compose build

printf "${BLUE}Starting agent...${NC}\n"
docker compose up -d

sleep 5

if docker compose ps | grep -q "Up"; then
    echo ""
    printf "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}\n"
    printf "${GREEN}║   ✓ Setup Complete!                                       ║${NC}\n"
    printf "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}\n"
    echo ""
    printf "${YELLOW}Message your Telegram bot to start chatting!${NC}\n"
    echo ""
    echo "First steps:"
    echo "  1. Message your bot on Telegram"
    echo "  2. Say: \"Create a new Bitcoin wallet\""
    echo "  3. Set a strong password when prompted"
    echo ""
    echo "Commands:"
    echo "  cd $INSTALL_DIR"
    echo "  docker compose logs -f     # View logs"
    echo "  docker compose restart     # Restart"
    echo "  docker compose down        # Stop"
    echo ""
else
    printf "${RED}Error: Failed to start. Check: docker compose logs${NC}\n"
    exit 1
fi
