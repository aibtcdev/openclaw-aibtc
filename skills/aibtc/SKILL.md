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

1. **Check wallet status first:**
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
