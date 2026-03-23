#!/usr/bin/env bash
set -euo pipefail

# Test: oc-stage-up.sh brings staging up on isolated loopback port

# Colors for output
readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly NC='\033[0m'

pass() { printf "${GREEN}PASS${NC}: %s\n" "$1"; }
fail() { printf "${RED}FAIL${NC}: %s\n" "$1"; exit 1; }

# Source shared helper if it exists
HELPER="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/ops/lib/openclaw-host.sh"
if [[ -f "$HELPER" ]]; then
  source "$HELPER"
fi

# Test 1: Script exists and is executable
test_script_exists() {
  local script
  script="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/ops/oc-stage-up.sh"
  [[ -x "$script" ]] || fail "oc-stage-up.sh not found or not executable"
  pass "oc-stage-up.sh exists"
}

# Test 2: docker-compose.stage.yml exists
test_compose_exists() {
  local compose
  compose="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/docker-compose.stage.yml"
  [[ -f "$compose" ]] || fail "docker-compose.stage.yml not found"
  pass "docker-compose.stage.yml exists"
}

# Test 3: Compose uses distinct container name
test_container_name() {
  local compose
  compose="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/docker-compose.stage.yml"
  grep -q "container_name:.*openclaw-stage" "$compose" || \
    fail "Compose missing distinct container name"
  pass "Compose uses distinct container name"
}

# Test 4: Compose binds different host loopback port
test_loopback_port() {
  local compose
  compose="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/docker-compose.stage.yml"
  grep -q "127.0.0.1:18790:18789" "$compose" || \
    fail "Compose not binding 127.0.0.1:18790:18789"
  pass "Compose binds isolated loopback port 18790"
}

# Test 5: Compose uses staging state directory
test_staging_state_dir() {
  local compose
  compose="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/docker-compose.stage.yml"
  grep -q "OPENCLAW_STAGE_STATE_DIR" "$compose" || \
    fail "Compose not using staging state directory variable"
  pass "Compose uses staging state directory"
}

# Test 6: Script syntax is valid
test_script_syntax() {
  local script
  script="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/ops/oc-stage-up.sh"
  bash -n "$script" 2>/dev/null || fail "Script has syntax errors"
  pass "Script syntax is valid"
}

# Test 7: Script sources shared helper
test_sources_helper() {
  local script
  script="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/ops/oc-stage-up.sh"
  grep -q "source.*lib/openclaw-host.sh" "$script" || \
    fail "Script doesn't source shared helper"
  pass "Script sources shared helper"
}

# Test 8: Script does not stop prod
test_does_not_stop_prod() {
  local script
  script="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/ops/oc-stage-up.sh"
  # Should not contain docker stop/rm for prod container
  ! grep -q "docker.*stop.*$PROD_CONTAINER" "$script" || \
    fail "Script should not stop prod container"
  ! grep -q "docker.*rm.*$PROD_CONTAINER" "$script" || \
    fail "Script should not remove prod container"
  pass "Script does not stop prod"
}

# Test 9: Script uses staging container variable
test_uses_stage_container() {
  local script
  script="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/ops/oc-stage-up.sh"
  grep -q "STAGE_CONTAINER" "$script" || \
    fail "Script doesn't use STAGE_CONTAINER variable"
  pass "Script uses staging container variable"
}

# Run all tests
main() {
  echo "Testing oc-stage-up.sh..."
  test_script_exists
  test_compose_exists
  test_container_name
  test_loopback_port
  test_staging_state_dir
  test_script_syntax
  test_sources_helper
  test_does_not_stop_prod
  test_uses_stage_container
  echo "All tests passed!"
}

main "$@"
