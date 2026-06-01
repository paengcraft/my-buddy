#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

APP_NAME="My Buddy A" \
BUNDLE_IDENTIFIER="com.mybuddy.desktop.a" \
DMG_PATH="$ROOT_DIR/build/My Buddy A_0.1.0_aarch64.dmg" \
"$ROOT_DIR/scripts/build_app.sh"

APP_NAME="My Buddy B" \
BUNDLE_IDENTIFIER="com.mybuddy.desktop.b" \
DMG_PATH="$ROOT_DIR/build/My Buddy B_0.1.0_aarch64.dmg" \
"$ROOT_DIR/scripts/build_app.sh"

echo "$ROOT_DIR/build/My Buddy A.app"
echo "$ROOT_DIR/build/My Buddy B.app"
echo "$ROOT_DIR/build/My Buddy A_0.1.0_aarch64.dmg"
echo "$ROOT_DIR/build/My Buddy B_0.1.0_aarch64.dmg"
