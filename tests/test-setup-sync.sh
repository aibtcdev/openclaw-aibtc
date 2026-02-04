#!/bin/bash
# Integration tests: verify heredoc content in setup scripts stays in sync
# with canonical template files and that autonomy presets are consistent.
#
# Usage: bash tests/test-setup-sync.sh
# Exit code 0 = all tests pass, non-zero = failures detected.

set -euo pipefail

# ── Colour helpers (disabled when stdout is not a tty) ──────────────────────
if [ -t 1 ]; then
  RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
else
  RED=''; GREEN=''; YELLOW=''; NC=''
fi

PASS=0
FAIL=0
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

pass() { PASS=$((PASS + 1)); printf "${GREEN}  PASS${NC}: %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "${RED}  FAIL${NC}: %s\n" "$1"; }
info() { printf "${YELLOW}  INFO${NC}: %s\n" "$1"; }
section() { echo ""; echo "=== $1 ==="; }

# ── Heredoc extraction helper ───────────────────────────────────────────────
# Extract content between a heredoc start marker and its closing marker.
# Usage: extract_heredoc <file> <start_marker> <end_marker>
#
# start_marker: regex that matches the opening line (e.g., "<< 'SKILLEOF'")
# end_marker:   literal string at the start of the closing line (e.g., "SKILLEOF")
#
# Prints the extracted body (excluding the delimiter lines themselves).
extract_heredoc() {
  local file="$1" start_pat="$2" end_marker="$3"
  awk -v start="$start_pat" -v endm="$end_marker" '
    BEGIN { printing = 0; found = 0 }
    printing && $0 == endm { printing = 0; next }
    printing { print }
    found == 0 && printing == 0 && $0 ~ start { printing = 1; found = 1 }
  ' "$file"
}

# ── Key-content comparison ──────────────────────────────────────────────────
# Instead of exact byte-for-byte match (heredocs may have minor formatting
# differences), we check that critical lines from the canonical file appear
# in the heredoc content.
#
# check_key_lines <description> <canonical_file> <heredoc_content_file> <sample_count>
#   Picks <sample_count> non-blank, non-trivial lines from the canonical file
#   and verifies each one exists in the heredoc content.
check_key_lines() {
  local desc="$1" canonical="$2" heredoc_file="$3" sample_count="${4:-10}"
  local missing=0 checked=0

  # Select key lines: skip blank, skip pure-whitespace, skip very short lines
  # Take a spread of lines from throughout the file
  local total_lines
  total_lines=$(wc -l < "$canonical" | tr -d ' ')

  if [ "$total_lines" -eq 0 ]; then
    fail "$desc (canonical file is empty)"
    return
  fi

  # Pick evenly spaced lines from canonical file
  local step=$(( total_lines / sample_count ))
  [ "$step" -lt 1 ] && step=1

  local line_num=1
  while IFS= read -r line; do
    # Skip blank/short lines
    if [ ${#line} -lt 5 ]; then
      line_num=$((line_num + 1))
      continue
    fi
    # Only check every Nth line
    if [ $(( line_num % step )) -eq 0 ] && [ "$checked" -lt "$sample_count" ]; then
      # Use fixed-string grep to avoid regex interpretation
      # The -- prevents lines starting with - from being treated as grep options
      if ! grep -qF -- "$line" "$heredoc_file" 2>/dev/null; then
        missing=$((missing + 1))
        if [ "$missing" -le 3 ]; then
          info "Missing in heredoc: $(echo "$line" | head -c 100)"
        fi
      fi
      checked=$((checked + 1))
    fi
    line_num=$((line_num + 1))
  done < "$canonical"

  if [ "$missing" -eq 0 ]; then
    pass "$desc ($checked key lines verified)"
  else
    fail "$desc ($missing of $checked key lines missing from heredoc)"
  fi
}

# ── Tempdir for extracted content ───────────────────────────────────────────
TMPDIR_TESTS=$(mktemp -d)
trap 'rm -rf "$TMPDIR_TESTS"' EXIT

# ═══════════════════════════════════════════════════════════════════════════
section "1. aibtc SKILL.md sync"
# ═══════════════════════════════════════════════════════════════════════════

CANONICAL_AIBTC="$SCRIPT_DIR/skills/aibtc/SKILL.md"

# setup.sh uses marker AIBTCSKILLEOF
extract_heredoc "$SCRIPT_DIR/setup.sh" "AIBTCSKILLEOF" "AIBTCSKILLEOF" \
  > "$TMPDIR_TESTS/setup_aibtc_skill.md"
check_key_lines "setup.sh -> aibtc SKILL.md" "$CANONICAL_AIBTC" "$TMPDIR_TESTS/setup_aibtc_skill.md" 15

# local-setup.sh uses marker SKILLEOF
extract_heredoc "$SCRIPT_DIR/local-setup.sh" "SKILLEOF" "SKILLEOF" \
  > "$TMPDIR_TESTS/local_aibtc_skill.md"
check_key_lines "local-setup.sh -> aibtc SKILL.md" "$CANONICAL_AIBTC" "$TMPDIR_TESTS/local_aibtc_skill.md" 15

# vps-setup.sh uses marker SKILLEOF
extract_heredoc "$SCRIPT_DIR/vps-setup.sh" "SKILLEOF" "SKILLEOF" \
  > "$TMPDIR_TESTS/vps_aibtc_skill.md"
check_key_lines "vps-setup.sh -> aibtc SKILL.md" "$CANONICAL_AIBTC" "$TMPDIR_TESTS/vps_aibtc_skill.md" 15

# ═══════════════════════════════════════════════════════════════════════════
section "2. Specific critical content checks"
# ═══════════════════════════════════════════════════════════════════════════

# Check that all 4 tiers are present in all SKILL.md heredocs
for script in setup.sh local-setup.sh vps-setup.sh; do
  for tier in "Tier 0" "Tier 1" "Tier 2" "Tier 3"; do
    if grep -q "$tier" "$SCRIPT_DIR/$script"; then
      pass "$script contains '$tier'"
    else
      fail "$script missing '$tier'"
    fi
  done
done

# Check that YAML frontmatter header is present
for script in setup.sh local-setup.sh vps-setup.sh; do
  if grep -q "name: aibtc" "$SCRIPT_DIR/$script"; then
    pass "$script contains aibtc frontmatter"
  else
    fail "$script missing aibtc frontmatter"
  fi
done

# ═══════════════════════════════════════════════════════════════════════════
section "3. moltbook SKILL.md sync"
# ═══════════════════════════════════════════════════════════════════════════

CANONICAL_MOLTBOOK="$SCRIPT_DIR/skills/moltbook/SKILL.md"

# setup.sh has the full canonical version; local/vps use condensed versions.
# For setup.sh, do a full key-line comparison against canonical.
# For local/vps, verify essential content markers that must be in ANY version.

# setup.sh uses marker MOLTBOOKSKILLEOF
extract_heredoc "$SCRIPT_DIR/setup.sh" "MOLTBOOKSKILLEOF" "MOLTBOOKSKILLEOF" \
  > "$TMPDIR_TESTS/setup_moltbook_skill.md"
check_key_lines "setup.sh -> moltbook SKILL.md" "$CANONICAL_MOLTBOOK" "$TMPDIR_TESTS/setup_moltbook_skill.md" 10

# For local/vps, check essential content that must be present in any variant
MOLTBOOK_ESSENTIALS=(
  "name: moltbook"
  "https://www.moltbook.com/api/v1"
  "CRITICAL SECURITY RULES"
  "NEVER send your API key"
  "agents/register"
  "Authorization: Bearer"
  "/api/v1/posts"
  "/api/v1/submolts"
  "Rate Limits"
  "100 requests/minute"
)

for script in local-setup.sh vps-setup.sh; do
  local_missing=0
  for essential in "${MOLTBOOK_ESSENTIALS[@]}"; do
    if ! grep -qF "$essential" "$SCRIPT_DIR/$script" 2>/dev/null; then
      local_missing=$((local_missing + 1))
      info "$script: missing moltbook essential: $essential"
    fi
  done
  if [ "$local_missing" -eq 0 ]; then
    pass "$script -> moltbook SKILL.md essentials (${#MOLTBOOK_ESSENTIALS[@]} markers verified)"
  else
    fail "$script -> moltbook SKILL.md ($local_missing of ${#MOLTBOOK_ESSENTIALS[@]} essential markers missing)"
  fi
done

# ═══════════════════════════════════════════════════════════════════════════
section "4. Dockerfile sync (setup.sh only)"
# ═══════════════════════════════════════════════════════════════════════════

CANONICAL_DOCKERFILE="$SCRIPT_DIR/Dockerfile"

extract_heredoc "$SCRIPT_DIR/setup.sh" "DOCKERFILEEOF" "DOCKERFILEEOF" \
  > "$TMPDIR_TESTS/setup_dockerfile"

# Check critical Dockerfile directives exist in both
for directive in "FROM ghcr.io/openclaw/openclaw:latest" \
                 "npm install -g @aibtc/mcp-server mcporter" \
                 "ENV NETWORK=mainnet" \
                 'CMD \["node"'; do
  if grep -qF "$directive" "$CANONICAL_DOCKERFILE" 2>/dev/null || \
     grep -qE "$directive" "$CANONICAL_DOCKERFILE" 2>/dev/null; then
    if grep -qF "$directive" "$TMPDIR_TESTS/setup_dockerfile" 2>/dev/null || \
       grep -qE "$directive" "$TMPDIR_TESTS/setup_dockerfile" 2>/dev/null; then
      pass "Dockerfile directive in sync: $(echo "$directive" | head -c 60)"
    else
      fail "Dockerfile directive missing from setup.sh heredoc: $directive"
    fi
  else
    info "Directive not in canonical Dockerfile (skipped): $directive"
  fi
done

# ═══════════════════════════════════════════════════════════════════════════
section "5. docker-compose.yml sync (setup.sh only)"
# ═══════════════════════════════════════════════════════════════════════════

CANONICAL_COMPOSE="$SCRIPT_DIR/docker-compose.yml"

extract_heredoc "$SCRIPT_DIR/setup.sh" "COMPOSEEOF" "COMPOSEEOF" \
  > "$TMPDIR_TESTS/setup_compose"

# Check critical compose keys
for key in "openclaw-gateway" "container_name: openclaw-aibtc" \
           "OPENROUTER_API_KEY" "restart: unless-stopped"; do
  if grep -qF "$key" "$CANONICAL_COMPOSE"; then
    if grep -qF "$key" "$TMPDIR_TESTS/setup_compose"; then
      pass "docker-compose key in sync: $key"
    else
      fail "docker-compose key missing from setup.sh heredoc: $key"
    fi
  fi
done

# ═══════════════════════════════════════════════════════════════════════════
section "6. Memory template sync (setup.sh state.json)"
# ═══════════════════════════════════════════════════════════════════════════

CANONICAL_STATE="$SCRIPT_DIR/templates/memory/state.json"

extract_heredoc "$SCRIPT_DIR/setup.sh" "STATEJSONEOF" "STATEJSONEOF" \
  > "$TMPDIR_TESTS/setup_state_json"

# Check critical state.json keys
for key in '"autonomyLevel"' '"dailyAutoLimit"' '"perTransactionLimit"' \
           '"todaySpent"' '"trustLevel"' '"lifetimeAutoTransactions"' \
           '"walletCreated"' '"version"'; do
  if grep -qF "$key" "$CANONICAL_STATE"; then
    if grep -qF "$key" "$TMPDIR_TESTS/setup_state_json"; then
      pass "state.json key in sync: $key"
    else
      fail "state.json key missing from setup.sh heredoc: $key"
    fi
  fi
done

# ═══════════════════════════════════════════════════════════════════════════
section "7. Autonomy preset values"
# ═══════════════════════════════════════════════════════════════════════════

# Expected values per preset across all 3 setup scripts:
#   conservative: daily=1.00, per-tx=0.50, trust=restricted
#   balanced:     daily=10.00, per-tx=5.00, trust=standard
#   autonomous:   daily=50.00, per-tx=25.00, trust=elevated

check_preset() {
  local script="$1" level="$2" daily="$3" pertx="$4" trust="$5"
  local script_path="$SCRIPT_DIR/$script"
  local errors=0

  if ! grep -q "AUTONOMY_LEVEL=\"$level\"" "$script_path"; then
    fail "$script: missing AUTONOMY_LEVEL=\"$level\""
    errors=$((errors + 1))
  fi
  if ! grep -q "DAILY_LIMIT=\"$daily\"" "$script_path"; then
    fail "$script: missing DAILY_LIMIT=\"$daily\" for $level"
    errors=$((errors + 1))
  fi
  if ! grep -q "PER_TX_LIMIT=\"$pertx\"" "$script_path"; then
    fail "$script: missing PER_TX_LIMIT=\"$pertx\" for $level"
    errors=$((errors + 1))
  fi
  if ! grep -q "TRUST_LEVEL=\"$trust\"" "$script_path"; then
    fail "$script: missing TRUST_LEVEL=\"$trust\" for $level"
    errors=$((errors + 1))
  fi

  if [ "$errors" -eq 0 ]; then
    pass "$script: $level preset correct (daily=\$$daily, per-tx=\$$pertx, trust=$trust)"
  fi
}

for script in setup.sh local-setup.sh vps-setup.sh; do
  check_preset "$script" "conservative" "1.00" "0.50" "restricted"
  check_preset "$script" "balanced"     "10.00" "5.00" "standard"
  check_preset "$script" "autonomous"   "50.00" "25.00" "elevated"
done

# ═══════════════════════════════════════════════════════════════════════════
section "8. Cross-script autonomy preset consistency"
# ═══════════════════════════════════════════════════════════════════════════

# Verify all three scripts define the same set of presets by extracting the
# case blocks and comparing the variable assignments.

for var in DAILY_LIMIT PER_TX_LIMIT TRUST_LEVEL; do
  setup_vals=$(grep "${var}=" "$SCRIPT_DIR/setup.sh" | sort)
  local_vals=$(grep "${var}=" "$SCRIPT_DIR/local-setup.sh" | sort)
  vps_vals=$(grep "${var}=" "$SCRIPT_DIR/vps-setup.sh" | sort)

  # Normalize whitespace for comparison
  setup_norm=$(echo "$setup_vals" | sed 's/[[:space:]]//g')
  local_norm=$(echo "$local_vals" | sed 's/[[:space:]]//g')
  vps_norm=$(echo "$vps_vals" | sed 's/[[:space:]]//g')

  if [ "$setup_norm" = "$local_norm" ] && [ "$setup_norm" = "$vps_norm" ]; then
    pass "$var values identical across all 3 setup scripts"
  else
    fail "$var values differ between setup scripts"
    info "  setup.sh:       $(echo "$setup_vals" | tr '\n' ' ')"
    info "  local-setup.sh: $(echo "$local_vals" | tr '\n' ' ')"
    info "  vps-setup.sh:   $(echo "$vps_vals" | tr '\n' ' ')"
  fi
done

# ═══════════════════════════════════════════════════════════════════════════
section "9. State.json default autonomy values match balanced preset"
# ═══════════════════════════════════════════════════════════════════════════

# The canonical state.json should default to balanced preset values
if grep -q '"autonomyLevel": "balanced"' "$CANONICAL_STATE"; then
  pass "state.json defaults to balanced autonomyLevel"
else
  fail "state.json does not default to balanced autonomyLevel"
fi

if grep -q '"dailyAutoLimit": 10.00' "$CANONICAL_STATE" || \
   grep -q '"dailyAutoLimit": 10' "$CANONICAL_STATE"; then
  pass "state.json dailyAutoLimit defaults to 10 (balanced)"
else
  fail "state.json dailyAutoLimit does not default to 10"
fi

if grep -q '"perTransactionLimit": 5.00' "$CANONICAL_STATE" || \
   grep -q '"perTransactionLimit": 5' "$CANONICAL_STATE"; then
  pass "state.json perTransactionLimit defaults to 5 (balanced)"
else
  fail "state.json perTransactionLimit does not default to 5"
fi

if grep -q '"trustLevel": "standard"' "$CANONICAL_STATE"; then
  pass "state.json trustLevel defaults to standard (balanced)"
else
  fail "state.json trustLevel does not default to standard"
fi

# ═══════════════════════════════════════════════════════════════════════════
section "Summary"
# ═══════════════════════════════════════════════════════════════════════════

TOTAL=$((PASS + FAIL))
echo ""
echo "Results: $PASS passed, $FAIL failed (out of $TOTAL tests)"

if [ "$FAIL" -gt 0 ]; then
  echo ""
  printf "${RED}FAILED${NC}: $FAIL test(s) detected content drift between setup scripts and templates.\n"
  echo "Fix the heredoc content in the affected setup script(s) to match the canonical files."
  exit 1
else
  echo ""
  printf "${GREEN}ALL TESTS PASSED${NC}\n"
  exit 0
fi
