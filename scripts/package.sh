#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIST="$ROOT/dist"
CACHE="$DIST/.cache"

# Pinned upstream OpenBao release. Keep in sync with service.json "version".
OPENBAO_VERSION="2.7.1"
OPENBAO_REPO="openbao/openbao"

OS_NAME=$(uname -s)
case "$OS_NAME" in
  Linux*) PLATFORM="linux" ;;
  Darwin*) PLATFORM="darwin" ;;
  *) echo "Unsupported OS for package.sh: $OS_NAME" >&2; exit 1 ;;
esac

MACHINE=$(uname -m)
case "$MACHINE" in
  x86_64|amd64) ARCH="amd64" ;;
  arm64|aarch64) ARCH="arm64" ;;
  *) echo "Unsupported architecture for package.sh: $MACHINE" >&2; exit 1 ;;
esac

STAGING="$DIST/openbao-$PLATFORM"
TAR_PATH="$DIST/openbao-$PLATFORM.tar.gz"
ASSET="openbao_${OPENBAO_VERSION}_${PLATFORM}_${ARCH}.tar.gz"
ASSET_URL="https://github.com/$OPENBAO_REPO/releases/download/v$OPENBAO_VERSION/$ASSET"

mkdir -p "$DIST" "$CACHE" "$STAGING/runtime" "$STAGING/config"

if [ ! -f "$CACHE/$ASSET" ]; then
  echo "Downloading $ASSET_URL"
  curl -fsSL "$ASSET_URL" -o "$CACHE/$ASSET"
fi

tar -xzf "$CACHE/$ASSET" -C "$STAGING/runtime"
cp "$ROOT/config/example.env" "$STAGING/config/example.env"
chmod +x "$STAGING/runtime/bao" 2>/dev/null || true

rm -f "$TAR_PATH"
tar -czf "$TAR_PATH" -C "$STAGING" .
echo "Created $TAR_PATH"
