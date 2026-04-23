#!/bin/bash
# Builds ShotX as an installable .app bundle in dist/ShotX.app
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="ShotX"
BUNDLE_ID="com.shotx.app"
VERSION="${VERSION:-1.0}"
BUILD_NUMBER="${BUILD_NUMBER:-1}"

DIST="dist"
APP="$DIST/$APP_NAME.app"
CONTENTS="$APP/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

echo "→ Building release binary…"
swift build -c release

# Sparkle public key (used for verifying update signatures)
SU_PUBLIC_KEY=""
if [ -f ".sparkle-public-key" ]; then
    SU_PUBLIC_KEY=$(cat .sparkle-public-key)
fi
SU_FEED_URL="https://raw.githubusercontent.com/aimen08/shotx/main/appcast.xml"

if [ ! -f "Resources/AppIcon.icns" ]; then
    echo "→ Generating app icon…"
    ./Scripts/make-icon.swift
fi

echo "→ Assembling app bundle at $APP"
rm -rf "$APP"
mkdir -p "$MACOS" "$RESOURCES"
cp ".build/release/$APP_NAME" "$MACOS/$APP_NAME"
cp "Resources/AppIcon.icns" "$RESOURCES/AppIcon.icns"

# Embed Sparkle.framework — without this, the app launches but Sparkle won't function.
# Sparkle ships as an xcframework artifact via SPM; pick the one matching the host arch.
ARCH=$(uname -m)
SPARKLE_SLICE=""
case "$ARCH" in
    arm64) SPARKLE_SLICE="macos-arm64_x86_64" ;;
    x86_64) SPARKLE_SLICE="macos-arm64_x86_64" ;;
esac
SPARKLE_FRAMEWORK_CANDIDATES=(
    ".build/artifacts/sparkle/Sparkle/Sparkle.xcframework/$SPARKLE_SLICE/Sparkle.framework"
    ".build/artifacts/Sparkle/Sparkle/Sparkle.xcframework/$SPARKLE_SLICE/Sparkle.framework"
    ".build/release/Sparkle.framework"
    ".build/arm64-apple-macosx/release/Sparkle.framework"
)
for src in "${SPARKLE_FRAMEWORK_CANDIDATES[@]}"; do
    if [ -d "$src" ]; then
        FRAMEWORKS="$CONTENTS/Frameworks"
        mkdir -p "$FRAMEWORKS"
        cp -R "$src" "$FRAMEWORKS/"
        echo "  ✓ Embedded Sparkle.framework from $src"
        break
    fi
done

cat > "$CONTENTS/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>$BUILD_NUMBER</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSScreenCaptureUsageDescription</key>
    <string>ShotX needs to capture your screen to take screenshots and recordings.</string>
    <key>NSAppleEventsUsageDescription</key>
    <string>ShotX uses Apple Events to control Finder for the desktop-icons toggle.</string>
    <key>SUFeedURL</key>
    <string>$SU_FEED_URL</string>
    <key>SUPublicEDKey</key>
    <string>$SU_PUBLIC_KEY</string>
    <key>SUEnableAutomaticChecks</key>
    <true/>
    <key>SUScheduledCheckInterval</key>
    <integer>86400</integer>
</dict>
</plist>
EOF

# Ad-hoc sign so Gatekeeper allows the app to launch locally
echo "→ Ad-hoc code signing"
codesign --force --deep --sign - "$APP"

echo
echo "✓ Built $APP"
du -sh "$APP" | awk '{print "  Size: " $1}'
echo
echo "Install with:"
echo "  cp -R $APP /Applications/"
echo "Or just double-click $APP to run from current location."
