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
echo "║   Bitcoin & Stacks AI Agent (VPS)                         ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
printf "${NC}\n"

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    printf "${RED}Cannot detect OS. Please install Docker manually.${NC}\n"
    exit 1
fi

printf "${BLUE}Detected OS: ${OS}${NC}\n"

# Check if running as root or with sudo
if [ "$(id -u)" -ne 0 ]; then
    SUDO="sudo"
else
    SUDO=""
fi

# Install Docker if not present
if ! command -v docker >/dev/null 2>&1; then
    printf "${YELLOW}Docker not found. Installing...${NC}\n"

    case $OS in
        ubuntu|debian)
            $SUDO apt-get update
            $SUDO apt-get install -y ca-certificates curl gnupg
            $SUDO install -m 0755 -d /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/$OS/gpg | $SUDO gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            $SUDO chmod a+r /etc/apt/keyrings/docker.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$OS $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | $SUDO tee /etc/apt/sources.list.d/docker.list > /dev/null
            $SUDO apt-get update
            $SUDO apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        centos|rhel|fedora)
            $SUDO dnf -y install dnf-plugins-core
            $SUDO dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            $SUDO dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        *)
            printf "${YELLOW}Attempting generic Docker install...${NC}\n"
            curl -fsSL https://get.docker.com | $SUDO sh
            ;;
    esac

    $SUDO systemctl start docker
    $SUDO systemctl enable docker

    if [ "$(id -u)" -ne 0 ]; then
        $SUDO usermod -aG docker $USER
        printf "${YELLOW}Added $USER to docker group.${NC}\n"
    fi

    printf "${GREEN}✓ Docker installed${NC}\n"
else
    printf "${GREEN}✓ Docker is installed${NC}\n"
fi

# Check Docker is running
if ! $SUDO docker info >/dev/null 2>&1; then
    $SUDO systemctl start docker
fi

if ! $SUDO docker compose version >/dev/null 2>&1; then
    printf "${RED}Error: Docker Compose not available.${NC}\n"
    exit 1
fi

printf "${GREEN}✓ Docker Compose available${NC}\n"
echo ""

# Install directory
if [ "$(id -u)" -eq 0 ]; then
    INSTALL_DIR="/opt/openclaw-aibtc"
else
    INSTALL_DIR="$HOME/openclaw-aibtc"
fi

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
            $SUDO docker compose up -d
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
$SUDO mkdir -p "$INSTALL_DIR/data/config"
$SUDO mkdir -p "$INSTALL_DIR/data/workspace/skills/aibtc"
$SUDO mkdir -p "$INSTALL_DIR/data/workspace/memory"

# Clean up if openclaw.json is a directory
if [ -d "$INSTALL_DIR/data/openclaw.json" ]; then
    $SUDO rm -rf "$INSTALL_DIR/data/openclaw.json"
fi

# Fix permissions for Docker container (runs as node user, UID 1000)
$SUDO chown -R 1000:1000 "$INSTALL_DIR/data"

cd "$INSTALL_DIR"

# Create .env
$SUDO tee .env > /dev/null << EOF
OPENROUTER_API_KEY=${OPENROUTER_KEY}
TELEGRAM_BOT_TOKEN=${TELEGRAM_TOKEN}
NETWORK=${NETWORK}
OPENCLAW_GATEWAY_TOKEN=${GATEWAY_TOKEN}
EOF

# Create Dockerfile
$SUDO tee Dockerfile > /dev/null << 'EOF'
FROM ghcr.io/openclaw/openclaw:latest
USER root
RUN npm install -g @aibtc/mcp-server mcporter
ENV NETWORK=mainnet
USER node
CMD ["node", "dist/index.js", "gateway", "--bind", "lan", "--port", "18789"]
EOF

# Create docker-compose.yml
$SUDO tee docker-compose.yml > /dev/null << 'EOF'
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

# Create mcporter config with keep-alive for wallet persistence
$SUDO tee data/config/mcporter.json > /dev/null << 'EOF'
{
  "mcpServers": {
    "aibtc": {
      "command": "aibtc-mcp-server",
      "lifecycle": "keep-alive",
      "env": {}
    }
  }
}
EOF

# Create OpenClaw config
$SUDO tee data/openclaw.json > /dev/null << EOF
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
$SUDO tee data/workspace/skills/aibtc/SKILL.md > /dev/null << 'SKILLEOF'
---
name: aibtc
description: Bitcoin L1 and Stacks L2 blockchain toolkit. Use for BTC/STX balances, transfers, DeFi (ALEX, Zest), sBTC, tokens, NFTs, BNS names, and x402 paid APIs.
homepage: https://github.com/aibtcdev/aibtc-mcp-server
user-invocable: true
metadata: {"openclaw":{"emoji":"₿","requires":{"bins":["mcporter","aibtc-mcp-server"]}}}
---

# aibtc - Bitcoin & Stacks Blockchain Tools

Use `/usr/local/bin/mcporter` to call aibtc MCP tools. Execute commands with the `exec` tool. Always use the full path.

## IMPORTANT: Daemon Mode for Wallet Persistence

**The mcporter daemon MUST be running for wallet_unlock to persist between calls.**

Before any transaction, ensure the daemon is started:
```bash
/usr/local/bin/mcporter --config /home/node/.openclaw/config/mcporter.json daemon start
```

Check daemon status:
```bash
/usr/local/bin/mcporter --config /home/node/.openclaw/config/mcporter.json daemon status
```

**NEVER use CLIENT_MNEMONIC or environment variable mnemonics.** Always use wallet_unlock with the daemon.

---

## CRITICAL SECURITY RULES

**YOU MUST FOLLOW THESE RULES - NO EXCEPTIONS:**

1. **NEVER store, remember, or log passwords** - Do not save passwords anywhere
2. **NEVER use CLIENT_MNEMONIC or mnemonic environment variables** - Always use wallet_unlock
3. **ALWAYS ask the user for their password** before running `wallet_unlock` - Never assume or reuse passwords
4. **ONLY use the user's existing wallet** - Do not create new wallets unless the user explicitly asks
5. **LOCK wallet immediately after transactions** - Always run `wallet_lock` after any transaction completes
6. **CONFIRM before any transaction** - Always show the user what you're about to do and get confirmation before transfers
7. **Never auto-approve transactions** - Every transfer requires explicit user approval with amount and recipient shown

## Transaction Flow (MUST FOLLOW)

For ANY transaction (transfer, swap, supply, borrow, etc.):

1. **Ensure daemon is running** (do this once per session):
   ```bash
   /usr/local/bin/mcporter --config /home/node/.openclaw/config/mcporter.json daemon start
   ```

2. **Check wallet status:**
   ```bash
   /usr/local/bin/mcporter --config /home/node/.openclaw/config/mcporter.json call aibtc.wallet_status
   ```

3. **ASK the user for their password** - Say: "Please provide your wallet password to unlock for this transaction."

4. **Show transaction details and get confirmation** - Say: "I will send [AMOUNT] to [RECIPIENT]. Please confirm (yes/no)."

5. **Only after user confirms AND provides password, unlock the wallet:**
   ```bash
   /usr/local/bin/mcporter --config /home/node/.openclaw/config/mcporter.json call aibtc.wallet_unlock password=USER_PROVIDED_PASSWORD
   ```

6. **Execute the transaction**

7. **IMMEDIATELY lock the wallet:**
   ```bash
   /usr/local/bin/mcporter --config /home/node/.openclaw/config/mcporter.json call aibtc.wallet_lock
   ```

8. **Report result to user**

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
$SUDO tee data/workspace/USER.md > /dev/null << 'EOF'
# User Profile

This is your personal OpenClaw agent with Bitcoin & Stacks blockchain capabilities.

## Your Preferences
- Always ask for wallet password before transactions
- Confirm transaction details before executing
- Lock wallet immediately after transactions
EOF

# Build and start
printf "${BLUE}Building Docker image (this may take 1-2 minutes)...${NC}\n"
$SUDO docker compose build

printf "${BLUE}Starting agent...${NC}\n"
$SUDO docker compose up -d

sleep 5

if $SUDO docker compose ps | grep -q "Up\|running"; then
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
    echo "  sudo docker compose logs -f     # View logs"
    echo "  sudo docker compose restart     # Restart"
    echo "  sudo docker compose down        # Stop"
    echo ""
else
    printf "${RED}Error: Failed to start. Check: sudo docker compose logs${NC}\n"
    exit 1
fi
