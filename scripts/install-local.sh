#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="MagicRight"
APP_SOURCE="$ROOT_DIR/.build/dist/$APP_NAME.app"
APP_DEST="$HOME/Applications/$APP_NAME.app"
EXTENSION_ID="local.elidev.MagicRight.FinderSync"

"$ROOT_DIR/scripts/build-app.sh"

mkdir -p "$HOME/Applications"
rm -rf "$APP_DEST"
ditto "$APP_SOURCE" "$APP_DEST"

LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister"
"$LSREGISTER" -f "$APP_DEST" || true

pluginkit -a "$APP_DEST/Contents/PlugIns/MagicRightFinderSync.appex" || true
pluginkit -e use -i "$EXTENSION_ID" || true

open "$APP_DEST"

echo
echo "Installed: $APP_DEST"
echo "Extension: $EXTENSION_ID"
echo "If this is the first install, enable it in System Settings -> Privacy & Security -> Extensions -> Finder Extensions."
