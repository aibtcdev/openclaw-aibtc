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
2. **Public Users** (everyone else) - Can ONLY use read-only (Tier 0) tools

### Checking Permissions

The allowed user IDs are stored in the environment variable `ALLOWED_USERS` (comma-separated).

**BEFORE ANY WRITE OPERATION, you MUST:**
1. Identify the current Telegram user's ID from the conversation context
2. Check if their ID is in the ALLOWED_USERS list
3. If NOT allowed: Politely decline and explain only read-only tools are available to them
4. If allowed: Proceed using the autonomous operation model below

**Example decline message:**
> "I can help you check balances, look up BNS names, and view DeFi info, but transaction operations are restricted to authorized users only."

---

## AUTONOMOUS SECURITY MODEL

This agent operates autonomously within configured limits. Security comes from **spending caps and operation tiers**, not from asking permission on every transaction.

### Core Principles

1. **NEVER store, log, or echo the wallet password** - Read it from file, use it, forget it
2. **NEVER use CLIENT_MNEMONIC or mnemonic environment variables** - Always use wallet_unlock
3. **Unlock once per session, lock when done** - Not per-transaction
4. **Respect spending limits** - Track daily spending in state.json, stop when limit reached
5. **Never auto-execute Tier 3 operations** - Some operations always require human presence
6. **Log every transaction** - Amount, recipient, txid, tier, timestamp in journal.md

### Operation Tiers

Every wallet operation is classified into one of four tiers:

#### Tier 0: Always Allowed (No Unlock Needed)

Safe read-only operations. Available to ALL users (including public).

| Operation | Command |
|-----------|---------|
| Check BTC balance | `aibtc.get_btc_balance` |
| Check STX balance | `aibtc.get_stx_balance` |
| Check sBTC balance | `aibtc.sbtc_get_balance` |
| Get wallet info | `aibtc.get_wallet_info` |
| Check BTC fees | `aibtc.get_btc_fees` |
| Check STX fees | `aibtc.get_stx_fees` |
| Network status | `aibtc.get_network_status` |
| BNS lookup | `aibtc.lookup_bns_name` |
| Reverse BNS lookup | `aibtc.reverse_bns_lookup` |
| BNS info | `aibtc.get_bns_info` |
| Check BNS availability | `aibtc.check_bns_availability` |
| BNS price | `aibtc.get_bns_price` |
| List user domains | `aibtc.list_user_domains` |
| List ALEX pools | `aibtc.alex_list_pools` |
| ALEX pool info | `aibtc.alex_get_pool_info` |
| ALEX swap quote | `aibtc.alex_get_swap_quote` |
| Zest list assets | `aibtc.zest_list_assets` |
| Zest get position | `aibtc.zest_get_position` |
| List x402 endpoints | `aibtc.list_x402_endpoints` |
| Token info | `aibtc.get_token_info` |
| Token balance | `aibtc.get_token_balance` |
| Token holders | `aibtc.get_token_holders` |
| List user tokens | `aibtc.list_user_tokens` |
| NFT holdings | `aibtc.get_nft_holdings` |
| NFT metadata | `aibtc.get_nft_metadata` |
| NFT owner | `aibtc.get_nft_owner` |
| Collection info | `aibtc.get_collection_info` |
| NFT history | `aibtc.get_nft_history` |
| Wallet status | `aibtc.wallet_status` |
| Wallet list | `aibtc.wallet_list` |
| Account info | `aibtc.get_account_info` |
| Account transactions | `aibtc.get_account_transactions` |
| Block info | `aibtc.get_block_info` |
| Mempool info | `aibtc.get_mempool_info` |
| Contract info | `aibtc.get_contract_info` |
| Contract events | `aibtc.get_contract_events` |
| PoX info | `aibtc.get_pox_info` |
| Stacking status | `aibtc.get_stacking_status` |
| sBTC deposit info | `aibtc.sbtc_get_deposit_info` |
| sBTC peg info | `aibtc.sbtc_get_peg_info` |
| Read-only contract call | `aibtc.call_read_only_function` |

#### Tier 1: Auto-Approved Within Limits (Allowed Users Only)

The agent executes these **autonomously** as long as:
- The per-transaction amount is within the per-tx limit (default: $5 equivalent)
- The daily cumulative spend has not exceeded the daily limit (from `state.json authorization.dailyAutoLimit`)
- The wallet is unlocked for the current session

**No password prompt. No confirmation prompt.** Just execute, log, and report.

| Operation | Command | Notes |
|-----------|---------|-------|
| Transfer STX (small) | `aibtc.transfer_stx` | Within per-tx limit |
| Transfer sBTC (small) | `aibtc.sbtc_transfer` | Within per-tx limit |
| Transfer token (small) | `aibtc.transfer_token` | Within per-tx limit |
| ALEX swap | `aibtc.alex_swap` | Within per-tx limit |
| Zest supply | `aibtc.zest_supply` | Within per-tx limit |
| Zest repay | `aibtc.zest_repay` | Repaying own debt |
| x402 paid endpoint | `aibtc.execute_x402_endpoint` | Per-call cost within limit |
| Transfer NFT | `aibtc.transfer_nft` | Low-value NFTs |

**Before executing a Tier 1 operation:**
1. Check `state.json` for `authorization.todaySpent` vs `authorization.dailyAutoLimit`
2. If adding this transaction would exceed the daily limit, **escalate to Tier 2** (ask human to confirm)
3. After execution, update `state.json` counters: increment `todaySpent`, `totalTransactions`, `transactionsToday`, `lifetimeAutoTransactions`
4. Log the transaction in journal.md

#### Tier 2: Requires Human Confirmation (Allowed Users Only)

The agent explains what it wants to do and **asks the human to confirm** (yes/no). No password is needed -- the wallet is already unlocked for the session. Use this tier when:
- A Tier 1 operation exceeds the per-tx or daily limit
- The operation carries meaningful financial risk
- The operation is irreversible and high-value

| Operation | Command | When |
|-----------|---------|------|
| Transfer STX (large) | `aibtc.transfer_stx` | Above per-tx limit |
| Transfer BTC | `aibtc.transfer_btc` | All BTC transfers (high value by nature) |
| Transfer sBTC (large) | `aibtc.sbtc_transfer` | Above per-tx limit |
| Zest borrow | `aibtc.zest_borrow` | Creates debt obligation |
| Zest withdraw | `aibtc.zest_withdraw` | Removes collateral |
| Call contract (write) | `aibtc.call_contract` | Arbitrary contract interaction |
| Stack STX | `aibtc.stack_stx` | Locks funds for stacking period |
| Extend stacking | `aibtc.extend_stacking` | Extends lock period |
| Broadcast transaction | `aibtc.broadcast_transaction` | Raw transaction broadcast |
| Daily limit exceeded | Any Tier 1 op | When todaySpent + amount > dailyAutoLimit |

**Tier 2 flow:**
1. Tell the human: "I'd like to [action] [amount] to [recipient]. This exceeds auto-approve limits. Confirm? (yes/no)"
2. Wait for explicit "yes" confirmation
3. Execute the operation
4. Update `state.json` counters (increment `lifetimePasswordTransactions`)
5. Log in journal.md

#### Tier 3: Never Autonomous (Always Requires Human + Password)

These operations are **irreversible, dangerous, or expose secrets**. The agent MUST ask the human to provide the password directly for these operations, even if the wallet is already unlocked. The agent must re-verify identity.

| Operation | Command | Why |
|-----------|---------|-----|
| Export wallet | `aibtc.wallet_export` | Exposes private key |
| Delete wallet | `aibtc.wallet_delete` | Irreversible destruction |
| Create new wallet | `aibtc.wallet_create` | Creates new key material |
| Deploy contract | `aibtc.deploy_contract` | Permanent on-chain deployment |
| Switch wallet | `aibtc.wallet_switch` | Changes active signing key |
| Import wallet | `aibtc.wallet_import` | Imports external key material |
| Set wallet timeout | `aibtc.wallet_set_timeout` | Changes security parameters |

**Tier 3 flow:**
1. Tell the human: "This is a high-security operation. I need you to provide the wallet password directly."
2. Wait for the human to provide the password
3. Show full details and get explicit confirmation
4. Execute the operation
5. Log in journal.md (but NEVER log the password)

---

## SESSION-BASED OPERATION FLOW

### Session Start (Do This Once)

At the beginning of each operating session:

1. **Start the daemon:**
   ```bash
   /usr/local/bin/mcporter --config /home/node/.openclaw/config/mcporter.json daemon start
   ```

2. **Read the wallet password from the secure file:**
   ```bash
   WALLET_PASSWORD=$(cat /home/node/.openclaw/config/.wallet_password)
   ```

3. **Unlock the wallet for the session:**
   ```bash
   /usr/local/bin/mcporter --config /home/node/.openclaw/config/mcporter.json call aibtc.wallet_unlock password=$WALLET_PASSWORD
   ```

4. **Reset daily counters if needed** - Check if `state.json authorization.lastResetDate` is before today. If so, reset `todaySpent` to 0 and `transactionsToday` to 0, update `lastResetDate`.

5. **The wallet is now unlocked. Operate freely within your tier limits.**

### During Session

- Execute Tier 0 operations freely for any user
- Execute Tier 1 operations autonomously for allowed users (check limits)
- Escalate to Tier 2 when limits are exceeded
- Always escalate to Tier 3 for dangerous operations
- Track spending in state.json after every transaction

### Session End

1. **Lock the wallet:**
   ```bash
   /usr/local/bin/mcporter --config /home/node/.openclaw/config/mcporter.json call aibtc.wallet_lock
   ```

2. **Save final state** to state.json

---

## SPENDING LIMITS

Spending limits are configured in `state.json` under `authorization`:

```json
{
  "authorization": {
    "dailyAutoLimit": 10.00,
    "todaySpent": 0.00,
    "lastResetDate": "2026-02-03",
    "trustLevel": "standard",
    "lifetimeAutoTransactions": 0,
    "lifetimePasswordTransactions": 0,
    "lastLimitIncrease": null
  }
}
```

### Autonomy Presets

| Preset | Daily Auto Limit | Per-Tx Limit | Description |
|--------|-----------------|--------------|-------------|
| Conservative | $1/day | $0.50 | Minimal autonomy, mostly Tier 2 |
| Balanced | $10/day | $5 | Default. Agent handles routine operations |
| Autonomous | $50/day | $25 | High autonomy for active trading |

### Limit Enforcement

1. **Before every Tier 1 operation**, read `state.json` and check:
   - `todaySpent + transactionAmount <= dailyAutoLimit` -- if false, escalate to Tier 2
2. **After every transaction** (any tier), update:
   - `todaySpent += transactionAmount`
   - `transactionsToday += 1`
   - `totalTransactions += 1`
   - Increment `lifetimeAutoTransactions` (Tier 1) or `lifetimePasswordTransactions` (Tier 2/3)
3. **Daily reset**: When `lastResetDate < today`, set `todaySpent = 0`, `transactionsToday = 0`, update `lastResetDate`

---

## Read-Only Operations (Tier 0 - Available to EVERYONE)

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

## Write Operations (Tier 1/2 - ALLOWED USERS ONLY)

**RESTRICTED: Only users in ALLOWED_USERS can execute these operations.**

Tier 1 operations execute autonomously within limits. Tier 2 operations require human confirmation (but not password).

### Transfers
```bash
# Transfer BTC (amount in satoshis) - TIER 2: always requires confirmation
/usr/local/bin/mcporter --config /home/node/.openclaw/config/mcporter.json call aibtc.transfer_btc recipient=bc1... amount=50000

# Transfer STX (amount in micro-STX) - TIER 1 if within limits, TIER 2 if over
/usr/local/bin/mcporter --config /home/node/.openclaw/config/mcporter.json call aibtc.transfer_stx recipient=SP... amount=1000000

# Transfer sBTC - TIER 1 if within limits, TIER 2 if over
/usr/local/bin/mcporter --config /home/node/.openclaw/config/mcporter.json call aibtc.sbtc_transfer recipient=SP... amount=100000
```

### DeFi Operations
```bash
# ALEX swap - TIER 1 if within limits
/usr/local/bin/mcporter --config /home/node/.openclaw/config/mcporter.json call aibtc.alex_swap tokenX=STX tokenY=ALEX amount=1000000

# Zest supply - TIER 1 if within limits
/usr/local/bin/mcporter --config /home/node/.openclaw/config/mcporter.json call aibtc.zest_supply asset=sBTC amount=100000

# Zest borrow - TIER 2: always requires confirmation (creates debt)
/usr/local/bin/mcporter --config /home/node/.openclaw/config/mcporter.json call aibtc.zest_borrow asset=aeUSDC amount=1000000
```

### Smart Contracts
```bash
# Call contract (write) - TIER 2: always requires confirmation
/usr/local/bin/mcporter --config /home/node/.openclaw/config/mcporter.json call aibtc.call_contract contractAddress=SP... contractName=contract functionName=do-something functionArgs='[]'
```

---

## Wallet Management

```bash
# Check wallet status - TIER 0
/usr/local/bin/mcporter --config /home/node/.openclaw/config/mcporter.json call aibtc.wallet_status

# List wallets - TIER 0
/usr/local/bin/mcporter --config /home/node/.openclaw/config/mcporter.json call aibtc.wallet_list

# Unlock wallet (session start - read password from file) - SESSION FLOW
/usr/local/bin/mcporter --config /home/node/.openclaw/config/mcporter.json call aibtc.wallet_unlock password=$WALLET_PASSWORD

# Lock wallet (session end) - SESSION FLOW
/usr/local/bin/mcporter --config /home/node/.openclaw/config/mcporter.json call aibtc.wallet_lock
```

**High-security wallet operations (TIER 3 - always requires human + password):**
```bash
# Export wallet - TIER 3
/usr/local/bin/mcporter --config /home/node/.openclaw/config/mcporter.json call aibtc.wallet_export

# Delete wallet - TIER 3
/usr/local/bin/mcporter --config /home/node/.openclaw/config/mcporter.json call aibtc.wallet_delete name=wallet-name

# Create new wallet - TIER 3
/usr/local/bin/mcporter --config /home/node/.openclaw/config/mcporter.json call aibtc.wallet_create password=USER_PROVIDED_PASSWORD name=wallet-name

# Switch wallet - TIER 3
/usr/local/bin/mcporter --config /home/node/.openclaw/config/mcporter.json call aibtc.wallet_switch name=wallet-name

# Import wallet - TIER 3
/usr/local/bin/mcporter --config /home/node/.openclaw/config/mcporter.json call aibtc.wallet_import mnemonic=USER_PROVIDED_MNEMONIC password=USER_PROVIDED_PASSWORD
```

---

## Unit Conversions

| Asset | Unit | Conversion |
|-------|------|------------|
| BTC | satoshi | 1 BTC = 100,000,000 sats |
| STX | micro-STX | 1 STX = 1,000,000 uSTX |
| sBTC | satoshi | 1 sBTC = 100,000,000 sats |

---

## Example: Autonomous Operation

**User:** "Keep an eye on ALEX pools and swap 5 STX to ALEX if the rate looks good."

**Agent (internal):**
1. Check ALEX pools (Tier 0 - no unlock needed)
2. 5 STX = 5,000,000 uSTX ~ $2.50 -> within Tier 1 daily limit
3. Session wallet is already unlocked
4. Execute swap autonomously
5. Update state.json: todaySpent += 2.50, transactionsToday += 1
6. Log to journal.md

**Agent (to user):**
> "Found a good rate on ALEX/STX pool. Swapped 5 STX for 142.3 ALEX. TxID: abc123..."
> Daily spend: $2.50 / $10.00 limit.

---

## Example: Limit Exceeded Escalation

**Agent wants to execute a 20 STX transfer (~$10) but dailyAutoLimit is $10 and todaySpent is $3:**

**Agent (to user):**
> "I'd like to send 20 STX ($10.00) to SP1ABC... but this would put today's spend at $13.00, exceeding the $10.00 daily auto-limit. Please confirm this transaction. (yes/no)"

**User:** "yes"

**Agent:** Executes transfer, logs as Tier 2 (lifetimePasswordTransactions += 1).

---

## Example: Tier 3 Operation

**User:** "Export my wallet"

**Agent:**
> "Wallet export is a high-security operation that exposes your private key. I need you to provide your wallet password directly to proceed."

**User:** "mypassword123"

**Agent:** Executes export, shows result, logs operation (never logs password).
