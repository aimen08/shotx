#!/bin/bash
# Remove all build artifacts and generated files.
set -euo pipefail

cd "$(dirname "$0")/.."

echo "→ Removing Swift build cache"
rm -rf .build

echo "→ Removing app + DMG outputs"
rm -rf dist

echo "→ Removing generated iconset (icns is kept; iconset is intermediate)"
rm -rf Resources/AppIcon.iconset

echo "→ Removing macOS metadata"
find . -name '.DS_Store' -type f -delete 2>/dev/null || true

echo "→ Removing SwiftPM caches"
rm -rf .swiftpm Package.resolved

echo
echo "✓ Project cleaned."
echo "  Rebuild with:"
echo "    swift build              # dev binary"
echo "    ./Scripts/launch.sh      # build + run .app"
echo "    ./Scripts/release.sh     # full ship pipeline"
