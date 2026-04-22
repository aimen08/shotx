#!/bin/bash
# Builds a drag-to-Applications DMG installer at dist/ShotX-<version>.dmg
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="ShotX"
VERSION="1.0"
APP_PATH="dist/$APP_NAME.app"
DMG_PATH="dist/$APP_NAME-$VERSION.dmg"
STAGING="dist/dmg-staging"
VOLUME_NAME="$APP_NAME $VERSION"
RW_DMG="dist/$APP_NAME-rw.dmg"

# Build app if missing or older than sources
if [ ! -d "$APP_PATH" ] || [ "$(find Sources -newer "$APP_PATH" -type f | head -1)" ]; then
    echo "→ Building app first…"
    ./Scripts/build-app.sh
fi

echo "→ Staging contents in $STAGING"
rm -rf "$STAGING"
mkdir -p "$STAGING"
cp -R "$APP_PATH" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

# Clean up old artifacts
rm -f "$DMG_PATH" "$RW_DMG"

# Compute size with 30% headroom
SIZE_KB=$(du -sk "$STAGING" | awk '{print $1}')
SIZE_MB=$(( (SIZE_KB / 1024) + 20 ))

echo "→ Creating writable DMG (${SIZE_MB}M)"
hdiutil create \
    -srcfolder "$STAGING" \
    -volname "$VOLUME_NAME" \
    -fs HFS+ \
    -fsargs "-c c=64,a=16,e=16" \
    -format UDRW \
    -size "${SIZE_MB}m" \
    "$RW_DMG" >/dev/null

echo "→ Mounting for layout"
DEVICE=$(hdiutil attach -readwrite -noverify -noautoopen "$RW_DMG" | grep '^/dev/' | head -n1 | awk '{print $1}')
MOUNT="/Volumes/$VOLUME_NAME"
sleep 2

# Lay out icons via AppleScript (best-effort; ignore failures)
osascript <<EOF || echo "  (AppleScript layout skipped)"
tell application "Finder"
    tell disk "$VOLUME_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {200, 120, 760, 460}
        set theViewOptions to the icon view options of container window
        set arrangement of theViewOptions to not arranged
        set icon size of theViewOptions to 96
        set position of item "$APP_NAME.app" of container window to {150, 170}
        set position of item "Applications" of container window to {410, 170}
        update without registering applications
        delay 1
        close
    end tell
end tell
EOF

sync
sleep 1
hdiutil detach "$DEVICE" >/dev/null

echo "→ Converting to compressed read-only DMG"
hdiutil convert "$RW_DMG" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -o "$DMG_PATH" >/dev/null

rm -f "$RW_DMG"
rm -rf "$STAGING"

# Ad-hoc sign the DMG so quarantine knows it's been touched
codesign --force --sign - "$DMG_PATH" 2>/dev/null || true

echo
echo "✓ Built $DMG_PATH"
du -sh "$DMG_PATH" | awk '{print "  Size: " $1}'
echo
echo "Distribute by sending the .dmg. To install:"
echo "  1. Double-click the DMG"
echo "  2. Drag ShotX.app onto Applications"
echo "  3. Right-click → Open the first time (Gatekeeper warning since ad-hoc signed)"
