#!/bin/bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "DMG creation requires macOS and hdiutil." >&2
  exit 1
fi

RELEASE_DIR="$PROJECT_ROOT/build/macos/Build/Products/Release"
APP_PATH="${1:-}"
if [[ -z "$APP_PATH" ]]; then
  shopt -s nullglob
  apps=("$RELEASE_DIR"/*.app)
  if [[ ${#apps[@]} -ne 1 ]]; then
    echo "Expected one release .app. Run flutter build macos --release first," >&2
    echo "or pass the app path: bash tools/create_dmg.sh /path/to/YourApp.app" >&2
    exit 1
  fi
  APP_PATH="${apps[0]}"
fi

if [[ ! -d "$APP_PATH/Contents" || "$APP_PATH" != *.app ]]; then
  echo "App bundle not found: $APP_PATH" >&2
  exit 1
fi

APP_NAME="$(basename "$APP_PATH" .app)"
DMG_PATH="$PROJECT_ROOT/$APP_NAME.dmg"
STAGING_DIR="$(mktemp -d "${TMPDIR:-/tmp}/animation-book-dmg.XXXXXX")"
trap 'rm -rf "$STAGING_DIR"' EXIT

ditto "$APP_PATH" "$STAGING_DIR/$APP_NAME.app"
ln -s /Applications "$STAGING_DIR/Applications"
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$STAGING_DIR" \
  -ov -format UDZO \
  "$DMG_PATH"
hdiutil verify "$DMG_PATH"
printf 'Created %s\n' "$DMG_PATH"
