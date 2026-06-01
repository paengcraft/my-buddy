#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ "${RESET_DEFAULTS:-0}" == "1" ]]; then
  defaults delete com.mybuddy.desktop.a 2>/dev/null || true
  defaults delete com.mybuddy.desktop.b 2>/dev/null || true
fi

"$ROOT_DIR/scripts/build_test_pair.sh"

open -n "$ROOT_DIR/build/My Buddy A.app"
open -n "$ROOT_DIR/build/My Buddy B.app"

echo "Opened My Buddy A and My Buddy B."
echo "Set RESET_DEFAULTS=1 to clear saved size, device, and relay settings before launch."
