# Phase 3: Update README install instructions

## Goal
Replace all 4 `./setup.sh` references in `README.md` with `./local-setup.sh` or `./vps-setup.sh` depending on context.

## References Found

| Line | Section | Context | Replacement |
|------|---------|---------|-------------|
| 34 | Quick Start > Option 2: Manual Setup | Local/Docker Desktop | `./local-setup.sh` |
| 87 | Deploy to VPS > Manual VPS Setup > Step 4 | VPS/cloud | `./vps-setup.sh` |
| 115 | VPS Security Tips | VPS/cloud | `./vps-setup.sh` |
| 306 | Troubleshooting > Reset everything | Generic (could be either) | Show both scripts |

## Tasks

### Task 1: Replace Quick Start manual setup reference
- Line 34: `./setup.sh` -> `./local-setup.sh`
- This is the "Manual Setup" path under Quick Start, targeting local/Docker Desktop users
- Commit: `docs(readme): replace setup.sh with local-setup.sh in quick start`

### Task 2: Replace VPS deploy references
- Line 87: `./setup.sh` -> `./vps-setup.sh` (Manual VPS Setup > Step 4)
- Line 115: `./setup.sh` -> `./vps-setup.sh` (VPS Security Tips)
- Both are clearly VPS context
- Commit: `docs(readme): replace setup.sh with vps-setup.sh in VPS sections`

### Task 3: Replace troubleshooting reference
- Line 306: `./setup.sh` -> show both `./local-setup.sh` and `./vps-setup.sh`
- The "Reset everything" section is generic, user could be on either platform
- Commit: `docs(readme): replace setup.sh with both scripts in troubleshooting`

## Verification
- `grep -c 'setup\.sh' README.md` should return 0 (excluding local-setup.sh and vps-setup.sh)
- README reads naturally with the new references
