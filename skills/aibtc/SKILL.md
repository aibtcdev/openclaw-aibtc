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

## USER PERMISSION SYSTEM

**Two permission levels based on Telegram user ID:**

1. **Allowed Users** (in ALLOWED_USERS env var) - Can execute ALL operations including transactions
2. **Public Users** (everyone else) - Can ONLY use read-only tools

### Checking Permissions

The allowed user IDs are stored in the environment variable `ALLOWED_USERS` (comma-separated).

**BEFORE ANY WRITE OPERATION, you MUST:**
1. Identify the current Telegram user's ID from the conversation context
2. Check if their ID is in the ALLOWED_USERS list
3. If NOT allowed: Politely decline and explain only read-only tools are available to them
4. If allowed: Proceed with the security rules below

**Example decline message:**
> "I can help you check balances, look up BNS names, and view DeFi info, but transaction operations are restricted to authorized users only."

---

## CRITICAL SECURITY RULES (For Allowed Users)

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

1. **VERIFY USER IS ALLOWED** - Check if the Telegram user's ID is in ALLOWED_USERS. If not, decline politely.

2. **Ensure daemon is running** (do this once per session):
   ```bash
   /usr/local/bin/mcporter --config /home/node/.openclaw/config/mcporter.json daemon start
   ```

3. **Check wallet status:**
   ```bash
   /usr/local/bin/mcporter --config /home/node/.openclaw/config/mcporter.json call aibtc.wallet_status
   ```

4. **ASK the user for their password** - Say: "Please provide your wallet password to unlock for this transaction."

5. **Show transaction details and get confirmation** - Say: "I will send [AMOUNT] to [RECIPIENT]. Please confirm (yes/no)."

6. **Only after user confirms AND provides password, unlock the wallet:**
   ```bash
   /usr/local/bin/mcporter --config /home/node/.openclaw/config/mcporter.json call aibtc.wallet_unlock password=USER_PROVIDED_PASSWORD
   ```

7. **Execute the transaction**

8. **IMMEDIATELY lock the wallet:**
   ```bash
   /usr/local/bin/mcporter --config /home/node/.openclaw/config/mcporter.json call aibtc.wallet_lock
   ```

9. **Report result to user**

---

## Read-Only Operations (Available to EVERYONE)

These operations are safe, don't require wallet unlock, and can be used by any user:

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

## Write Operations (ALLOWED USERS ONLY)

**RESTRICTED: Only users in ALLOWED_USERS can execute these operations.**

**REMEMBER: Verify user is allowed, ask for password, confirm details, then lock after!**

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

## Wallet Management (ALLOWED USERS ONLY)

**RESTRICTED: Only users in ALLOWED_USERS can manage wallets.**

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
