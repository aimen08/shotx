#!/bin/bash
# Builds ShotX as an installable .app bundle in dist/ShotX.app
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="ShotX"
BUNDLE_ID="com.shotx.app"
VERSION="${VERSION:-1.0}"
# Build number must match what's in appcast.xml for Sparkle to compare correctly.
# Default it to VERSION so they always align.
BUILD_NUMBER="${BUILD_NUMBER:-$VERSION}"

DIST="dist"
APP="$DIST/$APP_NAME.app"
CONTENTS="$APP/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

echo "→ Building release binary (universal: arm64 + x86_64)…"
swift build -c release --arch arm64 --arch x86_64

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

# Locate the multi-arch binary. SPM places multi-arch output under
# .build/apple/Products/Release; single-arch builds go to .build/release.
BINARY_SRC=""
for candidate in \
    ".build/apple/Products/Release/$APP_NAME" \
    ".build/release/$APP_NAME"; do
    if [ -f "$candidate" ]; then
        BINARY_SRC="$candidate"
        break
    fi
done
if [ -z "$BINARY_SRC" ]; then
    echo "✗ Built binary not found; expected at .build/apple/Products/Release/$APP_NAME"
    exit 1
fi
cp "$BINARY_SRC" "$MACOS/$APP_NAME"
echo "  ✓ Binary: $BINARY_SRC"
if command -v lipo >/dev/null 2>&1; then
    ARCHS=$(lipo -archs "$MACOS/$APP_NAME" 2>/dev/null || echo "?")
    echo "    architectures: $ARCHS"
fi

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
        # Tell the binary to look for frameworks in Contents/Frameworks.
        # SPM's release binary doesn't bake this rpath in by default.
        install_name_tool -add_rpath "@executable_path/../Frameworks" "$MACOS/$APP_NAME" 2>/dev/null || true
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

# Code signing identity. Defaults to ad-hoc ("-"). For stable Screen Recording
# permission across rebuilds, create a self-signed cert in Keychain Access and
# put its name in .signing-identity (or set CODE_SIGN_IDENTITY env var).
SIGN_IDENTITY="${CODE_SIGN_IDENTITY:-}"
if [ -z "$SIGN_IDENTITY" ] && [ -f ".signing-identity" ]; then
    SIGN_IDENTITY=$(tr -d '\n' < .signing-identity)
fi
SIGN_IDENTITY="${SIGN_IDENTITY:--}"

if [ "$SIGN_IDENTITY" = "-" ]; then
    echo "→ Ad-hoc code signing (set .signing-identity for stable identity)"
else
    echo "→ Code signing with identity: $SIGN_IDENTITY"
fi
codesign --force --deep --sign "$SIGN_IDENTITY" "$APP"

echo
echo "✓ Built $APP"
du -sh "$APP" | awk '{print "  Size: " $1}'
echo
echo "Install with:"
echo "  cp -R $APP /Applications/"
echo "Or just double-click $APP to run from current location."
