# Phases

## Phase 1: Update MCP server pin
Goal: Bump @aibtc/mcp-server from 1.13.1 to 1.14.2 in Dockerfile (issue #9)
Status: `completed`

Key files:
- `Dockerfile` (line 8)

Verification: Docker build succeeds

## Phase 2: Add agent lifecycle skill
Goal: Create skills/aibtc-lifecycle/SKILL.md teaching agents the full aibtc.com registration, X claiming, check-in, and paid-attention workflow with exact API contracts and MCP tool names (issue #8)
Status: `completed`

Key files:
- `skills/aibtc-lifecycle/SKILL.md` (create)

Pattern references:
- `skills/aibtc/SKILL.md` (YAML frontmatter style)
- `skills/moltbook/SKILL.md` (API-based skill pattern)

## Phase 3: Wire lifecycle into agent boot sequence
Goal: Update templates to add aibtc.com lifecycle after wallet creation, add state tracking, sync heredoc copies in setup scripts
Status: `planned`

Key files:
- `templates/USER.md` (add lifecycle steps)
- `templates/memory/state.json` (add aibtc tracking fields)
- `local-setup.sh` (sync heredoc)
- `vps-setup.sh` (sync heredoc)
- `update-skill.sh` (sync heredoc)

Verification: `bash tests/test-setup-sync.sh` passes
