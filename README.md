# ShotX

A modern macOS screen capture app — screenshots, screen recording, annotation, and history. Lives in your menu bar.

## Features

### Screenshots
- **Capture region** — drag any rectangle on screen
- **Capture window** — click an app window to grab just it (with shadow)
- **Capture fullscreen** — entire display under the cursor
- **Capture previous area** — re-snap the last region
- **Self-timer** — pick the area, then 3 / 5 / 10s countdown with a live viewfinder around the region; UI is excluded from the shot
- **Open file / Open from clipboard** — annotate any existing image
- All captures land on the clipboard, get added to History, and trigger a bottom-left popup with **Save / Edit** actions
- Camera-shutter sound on each capture

### Screen recording
- **Record video** — H.264 MP4 of any region, via ScreenCaptureKit
- **Record GIF** — auto-converts the video at 12 fps, 720px max dimension
- **Picker → options panel → recording**: select region, see a subtle bottom-center options panel (dimensions, cursor toggle, more icons stubbed for future), then a **viewfinder border** stays around the region (red while recording)
- Floating stop pill with elapsed time + `⌘.` shortcut
- App's own UI is excluded from the captured frames (won't appear in the recording)
- On stop: bottom-left popup with first-frame thumbnail (click to play), Save, Copy

### Annotations
- Editor opens for any captured image (also for items in History)
- Tools: **Arrow** (chunky filled polygon with shadow), **Rectangle**, **Text** (in-canvas, draggable + resizable; live font sizing), **Numbered Step**
- 8-color palette, hover/press states, undo (`⌘Z`)
- Preview-style centered canvas with a glass-material toolbar
- Cancel / Save (Desktop) / Copy (clipboard) — Copy is the default action (Return)

### History
- Last 100 captures persisted to `~/Library/Application Support/ShotX/`
- Image, video, and GIF support side-by-side
- Hover any card for **3 actions**: Edit/Play, Copy, Save to Desktop
- Type badges (GIF or duration `M:SS`) in the corner of media items
- Double-click: image → copy, video/gif → play in default app
- Right-click for full menu (Reveal in Finder, Delete, etc.)

### Other
- **All-In-One** floating capture palette at cursor
- **Pin to screen** — float a screenshot above all apps, hover for actions
- **Show Desktop Icons** toggle (defaults + `killall Finder`)
- Configurable global shortcut (default ⌥X), live re-registration when changed
- Menu-bar accessory app — no Dock icon

## Requirements

- macOS 13.0 or later
- Screen Recording permission (granted on first capture)

## Install

1. Download `dist/ShotX-1.0.dmg`
2. Mount and drag **ShotX.app** onto **Applications**
3. Right-click → **Open** the first time (Gatekeeper warns since the app is ad-hoc signed, not Developer ID)
4. On first capture, macOS will prompt for **Screen Recording** permission. Grant it in System Settings, then quit and re-open ShotX once for the permission to take effect.

## Build from source

Requires Swift 5.9+ and the macOS 13 SDK (Xcode 15+).

```bash
git clone <repo>
cd shotx

# Run directly (development)
swift run

# Build a .app bundle
./Scripts/build-app.sh
open dist/ShotX.app

# Build a DMG installer
./Scripts/make-dmg.sh
open dist/ShotX-1.0.dmg

# Regenerate the icon (only needed if you change the design)
./Scripts/make-icon.swift
```

## Default shortcut

`⌥X` (Option+X) triggers **Capture Area** from anywhere. Change it in **Settings** — the new combo registers immediately, no restart needed.

## Project layout

| File                              | Role                                         |
|-----------------------------------|----------------------------------------------|
| `main.swift`                      | App entry                                    |
| `AppDelegate.swift`               | Status menu, hotkey wiring, capture pipeline |
| `HotKeyManager.swift`             | Carbon global hotkey registration            |
| `OverlayController.swift`         | Region-selection overlay                     |
| `OverlayWindow.swift`             | Per-screen borderless overlay window         |
| `SelectionView.swift`             | Drag-to-select view with crosshair + label   |
| `ScreenCapture.swift`             | `CGWindowListCreateImage` wrapper            |
| `WindowCapture.swift`             | Window-pick overlay + per-window capture     |
| `ScreenRecorder.swift`            | ScreenCaptureKit + AVAssetWriter pipeline    |
| `GIFConverter.swift`              | MP4 → GIF via `AVAssetImageGenerator`        |
| `RecordingController.swift`       | Recording flow orchestration (`@MainActor`)  |
| `RecordingUI.swift`               | Options panel + stop pill SwiftUI views      |
| `RecordingCompletePopup.swift`    | Bottom-left video/GIF popup with thumbnail   |
| `RecordingFrameOverlay.swift`     | Viewfinder rectangle around target region    |
| `Annotation.swift`                | Editor: canvas, toolbar, in-canvas text editor |
| `MainWindow.swift`                | History grid + Settings tabs                 |
| `HistoryStore.swift`              | Persistent capture index (image/video/gif)   |
| `ShortcutStore.swift`             | Shortcut persistence + key formatting        |
| `ShortcutRecorder.swift`          | NSViewRepresentable shortcut recorder        |
| `PostCapturePopup.swift`          | Bottom-left image popup                      |
| `PinnedImage.swift`               | Floating always-on-top pinned screenshots    |
| `AllInOne.swift`                  | Cursor-anchored capture palette              |
| `DesktopIcons.swift`              | Toggle Finder desktop icons                  |
| `SoundEffect.swift`               | Camera-shutter playback                      |
| `FloatingPanels.swift`            | Countdown + toast controllers                |
| `LastCaptureStore.swift`          | Persist last region for "Capture Previous"   |
| `ImageSaver.swift`                | PNG encode + clipboard + Desktop save        |

### Storage

`~/Library/Application Support/ShotX/`
- `History/` — capture files (`.png`, `.mp4`, `.gif`)
- `history.json` — index (id, kind, dimensions, duration, timestamp)

`UserDefaults` keys:
- `com.shotx.shortcut` — capture shortcut combo
- `com.shotx.lastCapture` — last region rect + screen index

## Roadmap

- Microphone + system audio in recording
- Webcam overlay
- Keystroke visualization
- Mouse-click highlights in recordings
- Scrolling capture (stitched long-form screenshots)
- Notarized / Developer ID-signed distribution
- Custom DMG background

## License

No license set — personal project.
