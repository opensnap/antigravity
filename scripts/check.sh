#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

bash -n install.sh
bash -n docs/install.sh
bash -n scripts/sync-site.sh

if ! cmp -s install.sh docs/install.sh; then
  echo "docs/install.sh is out of sync. Run: bash scripts/sync-site.sh" >&2
  exit 1
fi

bash install.sh --status >/dev/null

echo "All checks passed."
