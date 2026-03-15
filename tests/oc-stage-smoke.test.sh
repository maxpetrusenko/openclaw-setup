#!/usr/bin/env bash
set -euo pipefail

# Test: oc-stage-smoke.sh verifies staging health, status, extensions, plugins, logs

readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly NC='\033[0m'

pass() { printf "${GREEN}PASS${NC}: %s\n" "$1"; }
fail() { printf "${RED}FAIL${NC}: %s\n" "$1"; exit 1; }

# Test 1: Script exists and is executable
test_script_exists() {
  local script
  script="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/ops/oc-stage-smoke.sh"
  [[ -x "$script" ]] || fail "oc-stage-smoke.sh not found or not executable"
  pass "oc-stage-smoke.sh exists"
}

# Test 2: Script syntax is valid
test_script_syntax() {
  local script
  script="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/ops/oc-stage-smoke.sh"
  bash -n "$script" 2>/dev/null || fail "Script has syntax errors"
  pass "Script syntax is valid"
}

# Test 3: Script checks openclaw health
test_checks_health() {
  local script
  script="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/ops/oc-stage-smoke.sh"
  grep -q "openclaw health" "$script" || \
    fail "Script doesn't check openclaw health"
  pass "Script checks openclaw health"
}

# Test 4: Script checks openclaw status
test_checks_status() {
  local script
  script="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/ops/oc-stage-smoke.sh"
  grep -q "openclaw status" "$script" || \
    fail "Script doesn't check openclaw status"
  pass "Script checks openclaw status"
}

# Test 5: Script lists extensions
test_lists_extensions() {
  local script
  script="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/ops/oc-stage-smoke.sh"
  grep -q "extensions" "$script" || \
    fail "Script doesn't list extensions"
  pass "Script lists extensions"
}

# Test 6: Script checks plugin config
test_checks_plugins() {
  local script
  script="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/ops/oc-stage-smoke.sh"
  grep -q "openclaw.json" "$script" || \
    fail "Script doesn't check plugin config"
  pass "Script checks plugin config"
}

# Test 7: Script shows recent logs
test_shows_logs() {
  local script
  script="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/ops/oc-stage-smoke.sh"
  grep -q "docker logs" "$script" || \
    fail "Script doesn't show logs"
  pass "Script shows recent logs"
}

# Test 8: Script sources shared helper
test_sources_helper() {
  local script
  script="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/ops/oc-stage-smoke.sh"
  grep -q "source.*lib/openclaw-host.sh" "$script" || \
    fail "Script doesn't source shared helper"
  pass "Script sources shared helper"
}

# Test 9: Script uses staging container
test_uses_stage_container() {
  local script
  script="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/ops/oc-stage-smoke.sh"
  grep -q "STAGE_CONTAINER" "$script" || \
    fail "Script doesn't use STAGE_CONTAINER"
  pass "Script uses staging container"
}

# Test 10: Script has prompt smoke hook
test_prompt_smoke_hook() {
  local script
  script="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/ops/oc-stage-smoke.sh"
  grep -q "PROMPT_SMOKE\|OPENCLAW_STAGE_PROMPT_SMOKE" "$script" || \
    fail "Script missing prompt smoke hook"
  pass "Script has prompt smoke hook"
}

main() {
  echo "Testing oc-stage-smoke.sh..."
  test_script_exists
  test_script_syntax
  test_checks_health
  test_checks_status
  test_lists_extensions
  test_checks_plugins
  test_shows_logs
  test_sources_helper
  test_uses_stage_container
  test_prompt_smoke_hook
  echo "All tests passed!"
}

main "$@"
