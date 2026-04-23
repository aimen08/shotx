#!/bin/bash
# Build → commit → push → publish a GitHub release with the DMG attached.
#
# Usage:
#   ./Scripts/release.sh                       # auto-bump patch, default message
#   ./Scripts/release.sh 1.5                   # specific version
#   ./Scripts/release.sh 1.5 "Fix capture bug" # version + commit/release message
#
# Auto-bump rules: reads the latest published GitHub release tag and bumps
# the last segment (1.0 → 1.1, 1.0.3 → 1.0.4). If none, starts at 1.0.

set -euo pipefail

cd "$(dirname "$0")/.."

# --- Pre-flight
if ! command -v gh >/dev/null 2>&1; then
    echo "✗ gh CLI not installed. brew install gh"
    exit 1
fi
if ! gh auth status >/dev/null 2>&1; then
    echo "✗ gh not authenticated. Run: gh auth login"
    exit 1
fi

BRANCH=$(git branch --show-current)
if [ -z "$BRANCH" ]; then
    echo "✗ Detached HEAD. Check out a branch first."
    exit 1
fi

# --- Determine version
INPUT_VERSION="${1:-}"
if [ -z "$INPUT_VERSION" ]; then
    LATEST=$(gh release list --limit 1 --json tagName --jq '.[0].tagName // ""' 2>/dev/null || true)
    LATEST="${LATEST#v}"
    if [[ "$LATEST" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
        VERSION="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}.$((${BASH_REMATCH[3]} + 1))"
    elif [[ "$LATEST" =~ ^([0-9]+)\.([0-9]+)$ ]]; then
        VERSION="${BASH_REMATCH[1]}.$((${BASH_REMATCH[2]} + 1))"
    else
        VERSION="1.0"
    fi
    if [ -n "$LATEST" ]; then
        echo "→ Auto-bumping to v$VERSION (previous: v$LATEST)"
    else
        echo "→ Starting at v$VERSION (no previous releases)"
    fi
else
    VERSION="$INPUT_VERSION"
fi

TAG="v$VERSION"
DMG_PATH="dist/ShotX-$VERSION.dmg"
COMMIT_MSG="${2:-Release $TAG}"

# --- Verify tag is fresh
if gh release view "$TAG" >/dev/null 2>&1; then
    echo "✗ Release $TAG already exists on GitHub."
    exit 1
fi
if git rev-parse "$TAG" >/dev/null 2>&1; then
    echo "✗ Local tag $TAG already exists. Delete it with: git tag -d $TAG"
    exit 1
fi

# --- Build
echo "→ Building app + DMG (v$VERSION)…"
export VERSION
./Scripts/build-app.sh
./Scripts/make-dmg.sh

if [ ! -f "$DMG_PATH" ]; then
    echo "✗ Expected DMG not found: $DMG_PATH"
    exit 1
fi

# --- Sparkle: sign the DMG and update appcast.xml
if [ -f ".sparkle-tools/bin/sign_update" ] && [ -f ".sparkle-public-key" ]; then
    echo "→ Signing DMG with Sparkle"
    SIGN_OUTPUT=$(.sparkle-tools/bin/sign_update "$DMG_PATH")
    SIGNATURE=$(echo "$SIGN_OUTPUT" | sed -n 's/.*sparkle:edSignature="\([^"]*\)".*/\1/p')
    if [ -z "$SIGNATURE" ]; then
        echo "✗ sign_update returned no signature"
        exit 1
    fi
    DMG_LENGTH=$(stat -f %z "$DMG_PATH")
    DMG_URL="https://github.com/aimen08/shotx/releases/download/${TAG}/ShotX-${VERSION}.dmg"
    echo "→ Updating appcast.xml"
    Scripts/update-appcast.swift "$VERSION" "$DMG_URL" "$SIGNATURE" "$DMG_LENGTH"
else
    echo "→ Skipping Sparkle signing (run Scripts/sparkle-setup.sh to enable)"
fi

# --- Commit (only if there are changes)
if [ -n "$(git status --porcelain)" ]; then
    echo "→ Committing changes…"
    git add -u
    # Pick up new files in commonly-tracked locations (skips dist/ via .gitignore).
    for path in Sources Scripts Resources/AppIcon.icns README.md .gitignore Package.swift Package.resolved appcast.xml .sparkle-public-key; do
        if [ -e "$path" ]; then
            git add "$path"
        fi
    done

    git commit -m "$(cat <<EOF
$COMMIT_MSG

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
else
    echo "→ No source changes to commit; tagging current HEAD."
fi

# --- Push
echo "→ Pushing ${BRANCH}…"
git push origin "$BRANCH"

# --- Publish release (this also creates the tag at the current HEAD)
echo "→ Creating GitHub release ${TAG}…"
gh release create "$TAG" "$DMG_PATH" \
    --title "ShotX $TAG" \
    --notes "$(cat <<EOF
$COMMIT_MSG

## Requirements

macOS 13.0 or later
EOF
)"

URL=$(gh release view "$TAG" --json url --jq .url)
echo
echo "✓ Released $TAG"
echo "  $URL"
