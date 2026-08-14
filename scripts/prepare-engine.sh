#!/bin/zsh
set -euo pipefail

PROJECT_DIR="${0:A:h:h}"
ENGINE_DIR="$PROJECT_DIR/Resources/engine"
SYSTEM_NODE="$(command -v node)"
SYSTEM_NPM="$(command -v npm)"
NPM_VERSION="$($SYSTEM_NPM --version)"

mkdir -p "$ENGINE_DIR/bin"
cp "$SYSTEM_NODE" "$ENGINE_DIR/bin/node"
chmod +x "$ENGINE_DIR/bin/node"

"$SYSTEM_NPM" install \
  --prefix "$ENGINE_DIR" \
  "npm@$NPM_VERSION" \
  --omit=dev \
  --no-audit \
  --no-fund

echo "Prepared Node $("$ENGINE_DIR/bin/node" --version) and npm $NPM_VERSION"
