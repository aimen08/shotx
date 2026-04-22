#!/bin/bash
# Build (if stale) and launch the ShotX.app bundle from dist/.
# Kills any existing instance first so changes are picked up.
set -euo pipefail

cd "$(dirname "$0")/.."

APP_PATH="dist/ShotX.app"

# Build if the app is missing or any source is newer than it
if [ ! -d "$APP_PATH" ] || [ "$(find Sources -newer "$APP_PATH" -type f 2>/dev/null | head -1)" ]; then
    echo "→ Building app…"
    ./Scripts/build-app.sh
fi

# Quit any running ShotX
if pgrep -x ShotX >/dev/null 2>&1; then
    echo "→ Quitting existing instance…"
    pkill -x ShotX || true
    # Wait briefly for clean shutdown
    for i in 1 2 3 4 5; do
        pgrep -x ShotX >/dev/null 2>&1 || break
        sleep 0.2
    done
fi

echo "→ Launching $APP_PATH"
open "$APP_PATH"
