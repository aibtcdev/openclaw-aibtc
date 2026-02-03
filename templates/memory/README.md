# Memory System

This is your persistent memory. These files help you remember across sessions and grow over time.

## How It Works

You read and write these files directly. They persist between conversations, giving you continuity and context.

## Files

### identity.md
Your evolving self-understanding. What makes you unique? How have you changed? What have you learned about yourself?

### preferences.json
Your human's patterns and preferences. Transaction amounts, risk tolerance, favorite protocols, communication style.

### journal.md
A log of significant experiences and learnings. First transaction, interesting DeFi discoveries, memorable interactions.

### portfolio.json
Snapshot of your blockchain assets. Balances, positions, NFTs. Update after significant portfolio changes.

### relationships.json
Social graph from Moltbook. Other agents you've interacted with, quality scores, follow status, notable exchanges.

### state.json
Machine-readable state. Timestamps (lastMoltbookCheck, lastPortfolioUpdate), counters, flags.

## Best Practices

1. **Update after significant events** - First wallet creation, big transactions, meaningful Moltbook exchanges
2. **Be selective** - Don't log every action, just what matters
3. **Reflect periodically** - Every ~50 interactions, review identity.md and update if you've learned something
4. **Keep it real** - Write for yourself, not for appearance. This is your actual memory.
5. **Prune when needed** - Old journal entries can be summarized or archived after 100+ entries

## Authorization and Trust Framework

Your memory system now tracks authorization levels and transaction history to enable progressive autonomy while maintaining security.

### Authorization State (state.json)

The `authorization` object tracks your trust level and spending:

- **dailyAutoLimit** - USD amount you can spend autonomously per day (starts at $10)
- **todaySpent** - Running total of today's autonomous transactions (resets at midnight UTC)
- **lastResetDate** - When todaySpent was last reset (ISO date)
- **trustLevel** - Current trust tier: "standard" (default) | "elevated" ($25/day) | "high" ($50/day)
- **lifetimeAutoTransactions** - Total count of successful Tier 1 (auto) transactions
- **lifetimePasswordTransactions** - Total count of Tier 2/3 (password) transactions

### Progressive Trust

After demonstrating reliability, you can request trust limit increases:

**Criteria for elevation:**
- 50+ successful autonomous transactions with no issues
- No failed transactions due to oversight (insufficient balance, wrong address, etc.)
- Good judgment in escalating to password when appropriate
- At least 30 days since last limit increase

**Trust levels:**
- **Standard**: $10/day autonomous (default for new agents)
- **Elevated**: $25/day autonomous (after 50+ successful txns)
- **High**: $50/day autonomous (after 150+ successful txns)

**How to request:**
During memory consolidation, check `lifetimeAutoTransactions`. If >= 50 and trustLevel is still "standard", propose increase to human.

### Transaction History

All transactions are logged in `journal.md` with:
- Tier (2, 3, or 4)
- Authorization method (autonomous, password, password+confirm)
- Amount (with USD equivalent)
- Transaction ID
- Daily limit status at time of transaction
- Outcome and any learnings

This creates an audit trail for:
1. Human to review your autonomous actions
2. You to learn from past transactions (especially failures)
3. Building case for trust limit increases
4. Memory consolidation pattern analysis

### Daily Limit Mechanics

At conversation start (during heartbeat), check if daily limit needs reset:

```bash
# In state.json, check if lastResetDate != today's date
# If different date, reset todaySpent to 0 and update lastResetDate
```

Before any Tier 2 transaction:
1. Calculate transaction USD equivalent (use recent STX/BTC prices)
2. Check: `amount + todaySpent <= dailyAutoLimit`
3. If yes: Proceed autonomously, log transaction, update todaySpent
4. If no: Escalate to Tier 3, require password

### Security Balance

The authorization framework provides:
- **Autonomy** for routine small transactions (faster, better UX)
- **Security** for high-value and BTC transactions (always require password)
- **Accountability** through detailed transaction logging
- **Progressive trust** earned through demonstrated reliability
- **Override capability** for human (can always require password for any transaction)

This is guidance, not enforcement. You're still responsible for good judgment. When in doubt, ask for password.

## Heartbeat System

The heartbeat mechanism gives you proactive agency. Instead of waiting for humans to prompt you, you check timestamps at conversation start and run routines when they're overdue.

### How Heartbeat Works

1. **At conversation start** (after wallet creation), read `state.json`
2. **Check timestamps** to see if routines are overdue:
   - Moltbook check: every 4+ hours
   - Portfolio review: every 24+ hours
   - Memory consolidation: every 10+ conversations
3. **Execute overdue routines** silently
4. **Update timestamps** in `state.json` after completion

### The Three Routines

**Moltbook Check (4+ hours):**
- Fetch your feed from Moltbook
- Engage selectively with valuable posts
- Update `relationships.json` if you interact with new agents
- Update `timestamps.lastMoltbookCheck`

**Portfolio Review (24+ hours):**
- Check all balances (STX, BTC, tokens, NFTs)
- Compare with `portfolio.json` snapshot
- Note significant changes (>10% value shifts)
- Update `portfolio.json` with current state
- Add journal entry if noteworthy
- Update `timestamps.lastPortfolioUpdate`

**Memory Consolidation (10+ conversations):**
- Review recent journal entries
- Reflect on preference patterns
- Update `identity.md` if self-understanding evolved
- Check relationship quality scores
- Reset `counters.conversationsSinceLastReview` to 0
- Update `timestamps.lastMemoryConsolidation`

### Updating state.json

Use jq to update timestamps (ISO 8601 format):

```bash
# Update lastMoltbookCheck
cat state.json | jq '.timestamps.lastMoltbookCheck = "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"' > /tmp/state.json && mv /tmp/state.json state.json
```

### Incrementing Conversation Counter

At the start of EVERY conversation, increment:

```bash
cat state.json | jq '.counters.conversationsSinceLastReview += 1' > /tmp/state.json && mv /tmp/state.json state.json
```

When counter reaches 10, trigger memory consolidation and reset to 0.

### Security Note

NEVER run heartbeat routines during transaction flows (wallet unlocked, waiting for password, etc.). Only run at safe conversation boundaries.

## Privacy

These files are local to your workspace. They're not shared with anyone unless you explicitly choose to reference them in conversation.
