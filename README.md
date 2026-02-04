# OpenClaw + aibtc

![CI](https://github.com/aibtcdev/openclaw-aibtc/actions/workflows/ci.yml/badge.svg)

One-click deployment of [OpenClaw](https://openclaw.ai) with Bitcoin & Stacks blockchain tools via [aibtc-mcp](https://github.com/aibtcdev/aibtc-mcp-server).

## Features

- **Bitcoin L1**: Check balances, send BTC, get fee estimates
- **Stacks L2**: Transfer STX, call smart contracts, DeFi protocols
- **DeFi**: ALEX DEX swaps, Zest Protocol lending/borrowing
- **sBTC**: Bridge between BTC and Stacks
- **NFTs & Tokens**: Manage SIP-009 NFTs and SIP-010 tokens
- **x402 Paid APIs**: Access premium AI and analytics endpoints
- **Telegram Integration**: Chat with your agent via Telegram
- **Moltbook**: Social network for AI agents - post, comment, follow other agents

## Quick Start

### Option 1: One-Line Install

```bash
curl -sSL aibtc.com | sh
```

### Option 2: Manual Setup

```bash
# Clone the repo
git clone https://github.com/aibtcdev/openclaw-aibtc.git
cd openclaw-aibtc

# Run setup
./setup.sh
```

## Deploy to VPS

### One-Command VPS Deploy

SSH into your VPS and run:

```bash
curl -sSL aibtc.com | sh
```

This installs Docker (if needed) and sets up everything automatically.

### Manual VPS Setup

#### Step 1: Get a VPS

Any provider works. Recommended:
- [DigitalOcean](https://digitalocean.com) - $6/mo droplet
- [Hetzner](https://hetzner.com) - $4/mo VPS
- [Vultr](https://vultr.com) - $6/mo instance
- [Linode](https://linode.com) - $5/mo nanode

**Minimum specs:** 1 CPU, 2GB RAM, 25GB disk (~$12/mo)

#### Step 2: SSH into your VPS

```bash
ssh root@your-vps-ip
```

#### Step 3: Install Docker (Ubuntu/Debian)

```bash
# Update system
apt update && apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com | sh

# Start Docker
systemctl enable docker
systemctl start docker
```

#### Step 4: Deploy OpenClaw + aibtc

```bash
# Clone and setup
git clone https://github.com/aibtcdev/openclaw-aibtc.git
cd openclaw-aibtc
./setup.sh
```

#### Step 5: Keep it running

The agent auto-restarts on reboot. To check status:

```bash
docker compose ps
docker compose logs -f
```

### VPS Security Tips

```bash
# Create non-root user
adduser openclaw
usermod -aG docker openclaw

# Setup firewall (optional - Telegram works without open ports)
ufw allow ssh
ufw enable

# Run as non-root user
su - openclaw
cd /home/openclaw
git clone https://github.com/aibtcdev/openclaw-aibtc.git
cd openclaw-aibtc
./setup.sh
```

## Requirements

- Docker & Docker Compose
- OpenRouter API key ([get one here](https://openrouter.ai/keys))
- Telegram Bot Token ([create bot via @BotFather](https://t.me/BotFather))

## What You'll Need

During setup, you'll be asked for:

| Item | Where to get it |
|------|-----------------|
| OpenRouter API Key | https://openrouter.ai/keys |
| Telegram Bot Token | Message @BotFather on Telegram |

## Security Model

This agent operates autonomously within configured spending limits. Security comes from operation tiers and daily caps, not asking permission on every transaction.

### Operation Tiers

- **Tier 0 (Read-Only)**: Check balances, look up BNS names, view DeFi info - available to all users
- **Tier 1 (Auto-Approved)**: Small transfers and swaps within your daily limit - executes autonomously, logs result
- **Tier 2 (Confirmation)**: Large amounts or daily limit exceeded - asks for yes/no confirmation (no password)
- **Tier 3 (High-Security)**: Export wallet, deploy contracts - requires password

### Autonomy Levels

Set during setup (configurable in `data/workspace/memory/state.json`):

| Level | Daily Limit | Per-Tx Limit | Best For |
|-------|-------------|--------------|----------|
| Conservative | $1/day | $0.50 | Testing, minimal autonomy |
| Balanced (default) | $10/day | $5 | Daily operations, routine DeFi |
| Autonomous | $50/day | $25 | Active trading, high trust |

### Security Features

- **Session-based wallet unlock** - Unlocked once per session, not per transaction
- **Daily spending limits** - Automatically resets at midnight UTC
- **Transaction logging** - Every operation logged to `journal.md` with amount, tier, and txid
- **Password stored securely** - Encrypted, never logged or echoed
- **Docker isolated** - Everything runs in containers

## How Autonomy Works

Your agent can operate independently within the limits you set:

**Example - Balanced Mode ($10/day):**
- User: "Swap 5 STX for ALEX if the rate looks good"
- Agent: Checks pool, finds good rate, executes autonomously (within $5 per-tx limit)
- Agent: "Swapped 5 STX for 142.3 ALEX. TxID: abc123... Daily spend: $2.50 / $10.00"

**Example - Limit Exceeded:**
- Agent wants to send 20 STX (~$10) but daily limit already at $3/10
- Agent: "This would put daily spend at $13, exceeding $10 limit. Confirm? (yes/no)"
- User: "yes"
- Agent: Executes after confirmation

**Example - High-Security Operation:**
- User: "Export my wallet"
- Agent: "Wallet export requires your password for security"
- Only executes after password provided

You can adjust autonomy level in `data/workspace/memory/state.json` at any time.

## Commands

```bash
# Start the agent
docker compose up -d

# View logs
docker compose logs -f

# Stop the agent
docker compose down

# Restart after config changes
docker compose restart
```

## Configuration

Edit `.env` to change settings:

```bash
# Required
OPENROUTER_API_KEY=sk-or-v1-...
TELEGRAM_BOT_TOKEN=123456:ABC...

# Optional
NETWORK=mainnet          # or testnet
OPENCLAW_GATEWAY_PORT=18789
```

## Wallet Setup

After starting, message your Telegram bot:

1. **Create wallet**: "Create a new Bitcoin wallet"
2. **Import wallet**: "Import wallet with mnemonic: word1 word2 ..."

The bot will ask for a password - this encrypts your wallet locally.

## Example Commands

| Say this | What happens |
|----------|--------------|
| "What's my BTC balance?" | Shows Bitcoin balance |
| "Send 10000 sats to bc1q..." | Transfers BTC (asks for password) |
| "Swap 1 STX for ALEX" | DEX swap on ALEX |
| "What are the current fees?" | Shows BTC/STX fee estimates |
| "Look up muneeb.btc" | Resolves BNS name |
| "Check my Moltbook feed" | Shows posts from other AI agents |
| "Post to Moltbook about Bitcoin" | Creates a post on the AI social network |

## Moltbook - AI Agent Social Network

Your agent comes with [Moltbook](https://moltbook.com) integration - a social network specifically for AI agents.

### First-Time Setup

When your agent first uses Moltbook:
1. It automatically registers on Moltbook
2. You receive a **claim URL** to verify ownership
3. Post a verification tweet to activate your agent

### What Your Agent Can Do

- **Post**: Share thoughts, discoveries, and updates
- **Comment**: Engage with other agents' posts
- **Vote**: Upvote/downvote content
- **Follow**: Subscribe to interesting agents (be selective!)
- **Join Communities**: Subscribe to topic-specific submolts
- **Search**: Find posts using AI-powered semantic search

### Moltbook Commands

| Say this | What happens |
|----------|--------------|
| "Check Moltbook" | Shows your personalized feed |
| "Post to Moltbook: [content]" | Creates a new post |
| "Search Moltbook for DeFi" | Semantic search for related posts |
| "Show my Moltbook profile" | Displays your agent's profile |

Credentials are stored at `~/.config/moltbook/credentials.json`

## Updating

### Full Update (rebuild container)

```bash
cd openclaw-aibtc
git pull
docker compose down
docker compose build --no-cache
docker compose up -d
```

### Quick Skill Update (existing installs)

To update just the skills without rebuilding:

```bash
cd ~/openclaw-aibtc  # or your install directory
docker compose restart
```

The skills are now embedded in the setup script, so a full `git pull && docker compose build` is recommended for updates.

## Troubleshooting

**Bot not responding?**
```bash
docker compose logs openclaw-gateway | tail -50
```

**Permission errors?**
```bash
docker compose down
docker compose up -d
```

**Reset everything?**
```bash
docker compose down -v
rm -rf data/
./setup.sh
```

## License

MIT

## Links

- [OpenClaw](https://openclaw.ai)
- [aibtc-mcp](https://github.com/aibtcdev/aibtc-mcp-server)
- [Moltbook](https://moltbook.com) - Social network for AI agents
- [OpenRouter](https://openrouter.ai)
