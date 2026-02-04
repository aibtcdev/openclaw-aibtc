# Phases

## Phase 1: Remove setup.sh from test suite
Goal: Remove all `setup.sh` references from `tests/test-setup-sync.sh`. Delete setup.sh-only test sections (Dockerfile, docker-compose, state.json). Update loops to only iterate over `local-setup.sh` and `vps-setup.sh`. Restructure autonomy preset comparison to compare local vs vps only.
Status: `completed`

## Phase 2: Delete setup.sh and update CI
Goal: Delete `setup.sh`. Remove it from `.github/workflows/ci.yml` shellcheck command and `CONTRIBUTING.md` shellcheck command.
Status: `completed`

## Phase 3: Update README install instructions
Goal: Replace all 4 `./setup.sh` references in `README.md` with `./local-setup.sh` (local/Docker Desktop) or `./vps-setup.sh` (VPS/cloud) depending on context.
Status: `completed`
