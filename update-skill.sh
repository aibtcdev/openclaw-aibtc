#!/bin/sh
# Update aibtc skill to use daemon mode for wallet persistence
# Run this on your VPS: curl -sSL https://sh.biwas.xyz/update-skill.sh | sh

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Find install directory
if [ -d "/opt/openclaw-aibtc" ]; then
    INSTALL_DIR="/opt/openclaw-aibtc"
elif [ -d "$HOME/openclaw-aibtc" ]; then
    INSTALL_DIR="$HOME/openclaw-aibtc"
else
    echo "Error: Cannot find openclaw-aibtc installation"
    exit 1
fi

SKILL_FILE="$INSTALL_DIR/data/workspace/skills/aibtc/SKILL.md"

printf "${BLUE}Updating aibtc skill at $SKILL_FILE...${NC}\n"

# Backup existing skill
if [ -f "$SKILL_FILE" ]; then
    cp "$SKILL_FILE" "$SKILL_FILE.backup"
fi

# Write updated skill
cat > "$SKILL_FILE" << 'SKILLEOF'
---
name: aibtc
description: Bitcoin L1 and Stacks L2 blockchain toolkit. Use for BTC/STX balances, transfers, DeFi (ALEX, Zest), sBTC, tokens, NFTs, BNS names, and x402 paid APIs.
homepage: https://github.com/aibtcdev/aibtc-mcp-server
user-invocable: true
metadata: {"openclaw":{"emoji":"₿","requires":{"bins":["mcporter","aibtc-mcp-server"]}}}
---

# aibtc - Bitcoin & Stacks Blockchain Tools

Use the commands EXACTLY as shown below. **Do not omit the `--config` flag** - wallet state won't persist without it.

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

# Network status
/usr/local/bin/mcporter --config /home/node/.openclaw/config/mcporter.json call aibtc.get_network_status

# BNS lookups
/usr/local/bin/mcporter --config /home/node/.openclaw/config/mcporter.json call aibtc.lookup_bns_name name=example.btc

# DeFi info (read-only)
/usr/local/bin/mcporter --config /home/node/.openclaw/config/mcporter.json call aibtc.alex_list_pools
/usr/local/bin/mcporter --config /home/node/.openclaw/config/mcporter.json call aibtc.zest_list_assets
```

---

## Write Operations (REQUIRE Password + Confirmation)

**REMEMBER: Start daemon, ask for password, confirm details, then lock after!**

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
1. Starts daemon (if not running)
2. "I'll help you send 0.001 BTC (100,000 satoshis) to bc1qxyz..."
3. "Please provide your wallet password to authorize this transaction."

**User:** "mypassword123"

**Agent:**
4. "Confirming: Send 100,000 satoshis to bc1qxyz... Do you approve? (yes/no)"

**User:** "yes"

**Agent:**
5. *Unlocks wallet, executes transfer, locks wallet*
6. "Transaction submitted! TxID: abc123... Your wallet has been locked for security."
SKILLEOF

# Update mcporter config with keep-alive
MCPORTER_CONFIG="$INSTALL_DIR/data/config/mcporter.json"
printf "${BLUE}Updating mcporter config at $MCPORTER_CONFIG...${NC}\n"

cat > "$MCPORTER_CONFIG" << 'EOF'
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

# Fix permissions
chown 1000:1000 "$SKILL_FILE" 2>/dev/null || true
chown 1000:1000 "$MCPORTER_CONFIG" 2>/dev/null || true

printf "${GREEN}✓ Skill updated!${NC}\n"
printf "${GREEN}✓ mcporter config updated with keep-alive!${NC}\n"
printf "${BLUE}Restarting container...${NC}\n"

cd "$INSTALL_DIR"
docker compose restart

printf "${GREEN}✓ Done! The agent now uses daemon mode for wallet persistence.${NC}\n"
printf "${BLUE}Note: The daemon will auto-start on first mcporter call.${NC}\n"
