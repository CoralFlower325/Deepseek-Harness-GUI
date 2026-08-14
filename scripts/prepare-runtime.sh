#!/bin/zsh
set -euo pipefail

PROJECT_DIR="${0:A:h:h}"
RESOURCES_DIR="$PROJECT_DIR/Resources"
ENGINE_DIR="$RESOURCES_DIR/engine"
SEED_DIR="$RESOURCES_DIR/seed-runtime"
SYSTEM_NODE="$(command -v node)"
SYSTEM_NPM="$(command -v npm)"
NPM_VERSION="$($SYSTEM_NPM --version)"
DSH_VERSION="${1:-$($SYSTEM_NPM view @deepseek-ai/dsh dist-tags.latest)}"

mkdir -p "$ENGINE_DIR/bin" "$SEED_DIR"
cp "$SYSTEM_NODE" "$ENGINE_DIR/bin/node"
chmod +x "$ENGINE_DIR/bin/node"

"$SYSTEM_NPM" install \
  --prefix "$ENGINE_DIR" \
  "npm@$NPM_VERSION" \
  --omit=dev \
  --no-audit \
  --no-fund

"$ENGINE_DIR/bin/node" \
  "$ENGINE_DIR/node_modules/npm/bin/npm-cli.js" install \
  --prefix "$SEED_DIR" \
  "@deepseek-ai/dsh@$DSH_VERSION" \
  --omit=dev \
  --no-audit \
  --no-fund \
  --dangerously-allow-all-scripts

echo "Prepared Node $("$ENGINE_DIR/bin/node" --version), npm $NPM_VERSION, dsh $DSH_VERSION"
