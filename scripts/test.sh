#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
SERVICE_ID="@openbao"

SERVICE_ID_ACTUAL=$(python3 - <<'PY'
import json, pathlib
print(json.loads(pathlib.Path('service.json').read_text())['id'])
PY
)
if [ "$SERVICE_ID_ACTUAL" != "$SERVICE_ID" ]; then
  echo "service.json id mismatch: expected $SERVICE_ID, got $SERVICE_ID_ACTUAL" >&2
  exit 1
fi

CONTRACT_ID=$(python3 - <<'PY'
import json, pathlib
print(json.loads(pathlib.Path('verify/service-harness.json').read_text())['serviceId'])
PY
)
if [ "$CONTRACT_ID" != "$SERVICE_ID" ]; then
  echo "service-harness.json serviceId mismatch: expected $SERVICE_ID, got $CONTRACT_ID" >&2
  exit 1
fi

OS_NAME=$(uname -s)
case "$OS_NAME" in
  Linux*) PLATFORM="linux" ;;
  Darwin*) PLATFORM="darwin" ;;
  *) echo "Unsupported OS for test.sh: $OS_NAME" >&2; exit 1 ;;
esac

BINARY="$ROOT/dist/openbao-$PLATFORM/runtime/bao"
if [ ! -x "$BINARY" ]; then
  echo "OpenBao runtime not found at $BINARY; run scripts/package.sh first" >&2
  exit 1
fi

VERSION=$("$BINARY" version 2>&1)
if [[ "$VERSION" != *"OpenBao v"* ]]; then
  echo "OpenBao runtime version check failed: $VERSION" >&2
  exit 1
fi

echo "Service tests passed ($OS_NAME: $SERVICE_ID, $VERSION)"
