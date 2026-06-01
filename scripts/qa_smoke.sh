#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

(
  cd "$ROOT_DIR/relay"
  npm test
  npm run check
  npm run check:billing
)

(
  cd "$ROOT_DIR/native"
  swift test
  ./scripts/build_app.sh
  ./scripts/build_test_pair.sh
)

echo "QA smoke checks completed."
