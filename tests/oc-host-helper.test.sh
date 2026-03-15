#!/usr/bin/env bash
set -euo pipefail

# Test: openclaw-host.sh provides correct defaults
# Verifies shared helper has correct prod container name

HELPER="ops/lib/openclaw-host.sh"

echo "Testing: $HELPER has correct VPS defaults"

# Fail if helper doesn't exist
if [ ! -f "$HELPER" ]; then
  echo "FAIL: $HELPER does not exist"
  exit 1
fi

echo "PASS: $HELPER exists"

# Source the helper to check values
source "$HELPER"

# Verify default values match actual Hostinger state
if [ "$HOST" != "187.77.7.226" ]; then
  echo "FAIL: HOST default is '$HOST', expected '187.77.7.226'"
  exit 1
fi
echo "PASS: HOST = 187.77.7.226"

if [ "$USER_NAME" != "root" ]; then
  echo "FAIL: USER_NAME default is '$USER_NAME', expected 'root'"
  exit 1
fi
echo "PASS: USER_NAME = root"

# This is the critical one - must match actual prod container
if [ "$PROD_CONTAINER" != "openclaw-ylld-openclaw-1" ]; then
  echo "FAIL: PROD_CONTAINER default is '$PROD_CONTAINER', expected 'openclaw-ylld-openclaw-1'"
  exit 1
fi
echo "PASS: PROD_CONTAINER = openclaw-ylld-openclaw-1"

if [ "$STAGE_CONTAINER" != "openclaw-stage-1" ]; then
  echo "FAIL: STAGE_CONTAINER default is '$STAGE_CONTAINER', expected 'openclaw-stage-1'"
  exit 1
fi
echo "PASS: STAGE_CONTAINER = openclaw-stage-1"

if [ "$PROD_STATE_DIR" != "/docker/openclaw-ylld/data" ]; then
  echo "FAIL: PROD_STATE_DIR default is '$PROD_STATE_DIR', expected '/docker/openclaw-ylld/data'"
  exit 1
fi
echo "PASS: PROD_STATE_DIR = /docker/openclaw-ylld/data"

# Verify ssh_host function exists
if ! declare -f ssh_host > /dev/null; then
  echo "FAIL: ssh_host function not defined"
  exit 1
fi
echo "PASS: ssh_host function defined"

echo ""
echo "All host helper tests passed!"
