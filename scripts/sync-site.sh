#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cp "$ROOT_DIR/install.sh" "$ROOT_DIR/docs/install.sh"
chmod +x "$ROOT_DIR/docs/install.sh"
