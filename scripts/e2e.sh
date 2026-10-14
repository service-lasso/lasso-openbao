#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

OS_NAME=$(uname -s)
case "$OS_NAME" in
  Linux*) PLATFORM="linux" ;;
  Darwin*) PLATFORM="darwin" ;;
  *) echo "Unsupported OS for e2e.sh: $OS_NAME" >&2; exit 1 ;;
esac

RUNTIME_DIR="$ROOT/dist/openbao-$PLATFORM/runtime"
BINARY="$RUNTIME_DIR/bao"
if [ ! -x "$BINARY" ]; then
  echo "OpenBao runtime not found at $BINARY; run scripts/package.sh first" >&2
  exit 1
fi

PORT="${OPENBAO_E2E_PORT:-18200}"

# Materialize the server config from the canonical service.json config.files block.
python3 - "$ROOT/service.json" "$RUNTIME_DIR/openbao.hcl" "$PORT" <<'PY'
import json, pathlib, sys
service = json.loads(pathlib.Path(sys.argv[1]).read_text())
content = service['config']['files'][0]['content'].replace('${SERVICE_PORT}', sys.argv[3])
pathlib.Path(sys.argv[2]).write_text(content)
PY
mkdir -p "$RUNTIME_DIR/data"

STDOUT="$ROOT/dist/e2e-openbao.out"
STDERR="$ROOT/dist/e2e-openbao.err"
( cd "$RUNTIME_DIR" && "$BINARY" server -config="$RUNTIME_DIR/openbao.hcl" >"$STDOUT" 2>"$STDERR" ) &
PID=$!
cleanup() { kill "$PID" 2>/dev/null || true; wait "$PID" 2>/dev/null || true; }
trap cleanup EXIT

STATUS=""
for _ in $(seq 1 60); do
  sleep 0.5
  if ! kill -0 "$PID" 2>/dev/null; then
    echo "OpenBao server exited before becoming reachable" >&2
    tail -n 20 "$STDERR" >&2 || true
    exit 1
  fi
  CODE=$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:$PORT/v1/sys/health" || true)
  if [ -n "$CODE" ] && [ "$CODE" != "000" ]; then
    STATUS="$CODE"
    break
  fi
done

if [ -z "$STATUS" ]; then
  tail -n 20 "$STDERR" >&2 || true
  echo "OpenBao API did not become reachable on port $PORT" >&2
  exit 1
fi

case "$STATUS" in
  200|429|501|503) ;;
  *) echo "Unexpected OpenBao health status: $STATUS" >&2; exit 1 ;;
esac

echo "OpenBao runtime e2e passed: packaged server started and served /v1/sys/health (status $STATUS) on port $PORT"
