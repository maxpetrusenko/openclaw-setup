#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_DIR="${OPENCLAW_SOURCE_DIR:-$ROOT_DIR/oss/openclaw}"
HOST="${OPENCLAW_VPS_HOST:-187.77.7.226}"
USER_NAME="${OPENCLAW_VPS_USER:-root}"
KEY_PATH="${OPENCLAW_VPS_KEY:-$HOME/.ssh/hostinger_agent}"
CONTAINER_NAME="${OPENCLAW_CONTAINER:-openclaw-ylld-openclaw-1}"
REMOTE_TMP_DIR="${OPENCLAW_REMOTE_TMP_DIR:-/tmp/openclaw-local-deploy}"
DRY_RUN=0
SKIP_BUILD=0
RESTART_CONTAINER=1

usage() {
  cat <<'EOF'
Usage: ./ops/openclaw-deploy-local.sh [--dry-run] [--skip-build] [--no-restart]

Packages the local oss/openclaw checkout, uploads the tarball to the VPS host,
installs it into the OpenClaw container as a global package, then optionally
restarts the container.

Environment:
  OPENCLAW_SOURCE_DIR    Local source checkout to package
  OPENCLAW_VPS_HOST      VPS host
  OPENCLAW_VPS_USER      SSH user
  OPENCLAW_VPS_KEY       SSH key path
  OPENCLAW_CONTAINER     Docker container name
  OPENCLAW_REMOTE_TMP_DIR Host tmp dir used during deploy
EOF
}

while (($# > 0)); do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --skip-build)
      SKIP_BUILD=1
      shift
      ;;
    --no-restart)
      RESTART_CONTAINER=0
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

need_cmd node
need_cmd npm
need_cmd ssh
need_cmd scp

if [[ ! -f "$SOURCE_DIR/package.json" ]]; then
  echo "Missing package.json in source dir: $SOURCE_DIR" >&2
  exit 1
fi

package_name="$(
  node -e 'const fs=require("node:fs"); const pkg=JSON.parse(fs.readFileSync(process.argv[1],"utf8")); process.stdout.write(String(pkg.name || ""));' \
    "$SOURCE_DIR/package.json"
)"
package_version="$(
  node -e 'const fs=require("node:fs"); const pkg=JSON.parse(fs.readFileSync(process.argv[1],"utf8")); process.stdout.write(String(pkg.version || ""));' \
    "$SOURCE_DIR/package.json"
)"

if [[ "$package_name" != "openclaw" ]]; then
  echo "Expected package name openclaw, got: ${package_name:-<empty>}" >&2
  exit 1
fi

ssh_base=(
  ssh
  -i "$KEY_PATH"
  -o StrictHostKeyChecking=accept-new
  "${USER_NAME}@${HOST}"
)

scp_base=(
  scp
  -i "$KEY_PATH"
  -o StrictHostKeyChecking=accept-new
)

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

echo "source: $SOURCE_DIR"
echo "package: ${package_name}@${package_version}"
echo "target: ${USER_NAME}@${HOST} container=${CONTAINER_NAME}"

if [[ "$SKIP_BUILD" != "1" ]]; then
  need_cmd pnpm
  echo "building local checkout"
  (
    cd "$SOURCE_DIR"
    pnpm build
  )
fi

echo "packing local tarball"
(
  cd "$SOURCE_DIR"
  npm pack --ignore-scripts --pack-destination "$tmp_dir" --silent >/dev/null
)
package_path="$(find "$tmp_dir" -maxdepth 1 -type f -name '*.tgz' -print)"
if [[ ! -f "$package_path" ]]; then
  echo "Packed tarball missing: $package_path" >&2
  exit 1
fi
package_file="$(basename "$package_path")"
remote_package_path="${REMOTE_TMP_DIR}/${package_file}"

echo "tarball: $package_path"

if [[ "$DRY_RUN" == "1" ]]; then
  cat <<EOF
dry-run:
  mkdir -p $REMOTE_TMP_DIR
  scp $package_path ${USER_NAME}@${HOST}:$remote_package_path
  docker cp $remote_package_path ${CONTAINER_NAME}:$remote_package_path
  docker exec ${CONTAINER_NAME} sh -lc 'npm install -g --prefix /usr/local "$remote_package_path" --no-fund --no-audit --loglevel=error'
EOF
  exit 0
fi

echo "uploading tarball to host"
"${ssh_base[@]}" "mkdir -p '$REMOTE_TMP_DIR'"
"${scp_base[@]}" "$package_path" "${USER_NAME}@${HOST}:$remote_package_path"

echo "installing tarball in container"
"${ssh_base[@]}" "sudo docker exec '${CONTAINER_NAME}' sh -lc 'mkdir -p \"$REMOTE_TMP_DIR\"'"
"${ssh_base[@]}" "sudo docker cp '$remote_package_path' '${CONTAINER_NAME}:$remote_package_path'"
"${ssh_base[@]}" "sudo docker exec '${CONTAINER_NAME}' sh -lc '
set -euo pipefail
current_version=\$(openclaw --version 2>/dev/null || true)
echo before=\${current_version:-unknown}
npm install -g --prefix /usr/local \"$remote_package_path\" --no-fund --no-audit --loglevel=error
new_version=\$(openclaw --version 2>/dev/null || true)
echo after=\${new_version:-unknown}
rm -f \"$remote_package_path\"
'"
"${ssh_base[@]}" "rm -f '$remote_package_path'"

if [[ "$RESTART_CONTAINER" == "1" ]]; then
  echo "restarting container"
  "${ssh_base[@]}" "sudo docker restart '$CONTAINER_NAME' >/dev/null"
fi

echo "verifying install"
"${ssh_base[@]}" "sudo docker exec '$CONTAINER_NAME' sh -lc '
set -euo pipefail
openclaw --version
openclaw status --json
'"

echo "deploy complete"
