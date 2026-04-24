<div align="center">

<img src="Resources/icon.png" width="160" alt="ShotX">

# ShotX

<img width="300" height="500" alt="image" src="https://github.com/user-attachments/assets/951f6284-b027-4c16-a01d-eb6a435ff180" />


**Modern macOS screen capture for the menu bar.**
Screenshots, screen recording, GIF export, in-place annotation, color picker, and a searchable history — without ever leaving your keyboard.

![macOS](https://img.shields.io/badge/macOS-13%2B-007AFF?style=flat&logo=apple&logoColor=white)
![Swift](https://img.shields.io/badge/Swift-5.9-F05138?style=flat&logo=swift&logoColor=white)
![Menu bar](https://img.shields.io/badge/menu%20bar-only-1F2937?style=flat)
[![Latest release](https://img.shields.io/github/v/release/aimen08/shotx?style=flat&color=22C55E)](https://github.com/aimen08/shotx/releases/latest)

[**↓ Download**](https://github.com/aimen08/shotx/releases/latest) · [Features](#features) · [Build from source](#build-from-source) · [Project layout](#project-layout)

</div>

---

## Features

### 📸 Screenshots
- Capture **region**, **window** (with shadow), **fullscreen**, or repeat the **previous area**
- **Self-timer** (3 / 5 / 10 s) with a live viewfinder around the picked region
- **Open from clipboard** / **Open file** to annotate any existing image
- Camera-shutter sound on capture
- Every shot lands on the clipboard, in History, and pops a bottom-left card with **Save** / **Edit**

### 🎥 Screen Recording
- **Record video** (H.264 MP4) of any region via `ScreenCaptureKit`
- **Record GIF** (auto-converted, 12 fps, 720 px max)
- Floating stop pill with elapsed time + `⌘.` to stop
- Subtle bottom-center options panel (dimensions, cursor toggle)
- Viewfinder rectangle around the region — accent during setup, **red while recording**
- ShotX's own UI is excluded from the captured frames automatically

### ✏️ Annotation
- Editor opens for any captured image (also from History)
- Tools: **Arrow** (chunky filled polygon), **Rectangle**, **Text** (in-canvas, drag/resize/typing live), **Numbered Step**
- 8-color palette, undo (`⌘Z`), drop shadows
- Preview-style centered canvas with a glass-material toolbar
- Cancel / Save (Desktop) / **Copy** (clipboard, default — `⏎`)

### 📚 History
- Last 100 captures persisted to disk — images, video, and GIFs side-by-side
- Hover for **Edit/Play · Copy · Save** action buttons
- Type badges in the corner: `GIF` (purple) or `M:SS` duration (red)
- Double-click: image → copy, video/GIF → play in default app
- Right-click for full menu (Reveal, Delete, …)

### 🎨 Color picker
- Native `NSColorSampler` loupe — click any pixel on any screen
- Hex value (`#FF8C00`) copied to clipboard with a color-tinted toast
- Configurable global shortcut (default `⌥⇧C`)

### ⚡ Quick access
- **All-In-One** floating capture palette at the cursor
- **Pin to screen** — float a screenshot above all apps with hover actions
- **Drag-out** — drag screenshots straight from the popup into Slack / Mail / Finder
- **Show Desktop Icons** toggle (defaults + `killall Finder`)
- **Auto-updates** via [Sparkle](https://sparkle-project.org/) — prompts when a new version ships
- Two configurable global shortcuts, **live re-registration** on change
- Menu-bar accessory app — no Dock icon

---

## Default shortcuts

| Action                  | Shortcut |
|-------------------------|----------|
| Capture region          | `⌥X`     |
| Pick color              | `⌥⇧C`    |
| Stop recording          | `⌘.`     |
| Open from clipboard     | `⇧⌘V`    |
| Settings                | `⌘,`     |
| Quit                    | `⌘Q`     |

Both the capture and color-picker shortcuts are configurable in **Settings → Shortcuts** — changes apply immediately, no restart needed.

---

## Install

1. Grab the latest **`ShotX-x.y.dmg`** from [Releases](https://github.com/aimen08/shotx/releases/latest)
2. Mount and drag **ShotX.app** to **Applications**
3. **Right-click → Open** the first launch (Gatekeeper warning since the app is ad-hoc signed, not Developer ID)
4. Grant **Screen Recording** permission when prompted, quit and re-open ShotX once

> **Requires macOS 13.0 or later.**

---

## Build from source

Requires Swift 5.9 + macOS 13 SDK (Xcode 15+).

```bash
git clone git@github.com:aimen08/shotx.git
cd shotx

# Run in development
swift run

# Bundle as .app
./Scripts/build-app.sh
open dist/ShotX.app

# Bundle as DMG installer
./Scripts/make-dmg.sh
open dist/ShotX-*.dmg

# Regenerate the app icon (only if you change the design)
./Scripts/make-icon.swift

# One-shot release: build + commit + push + GitHub release
./Scripts/release.sh                  # auto-bump patch
./Scripts/release.sh 1.5              # specific version
./Scripts/release.sh 1.5 "Fix bug"    # version + commit message
```

---

## Marketing website

A Vite + React homepage lives in `website/`, ready to deploy on Netlify (point it at the repo — `website/netlify.toml` handles the build settings).

```bash
cd website
npm install
npm run dev       # local preview at http://localhost:5173
npm run build     # static bundle → website/dist
```

Highlights:
- Two hero sections ported from a Claude-designed artboard — scaled pixel-perfect on desktop via `ScaledArtboard`, and a dedicated stacked layout below 820px.
- Sections: Features grid, keyboard-shortcuts showcase, final CTA, footer.
- All download / view-source CTAs link to this repo's [latest release](https://github.com/aimen08/shotx/releases/latest).

---

## Stable code signing (optional, recommended)

By default, builds are **ad-hoc signed**, which means each rebuild produces a new code identity and macOS revokes Screen Recording permission on every update. To keep permissions persistent across updates without paying for an Apple Developer ID:

1. Open **Keychain Access** → menu **Keychain Access → Certificate Assistant → Create a Certificate…**
2. Name it (e.g., `ShotX Signing`), Identity Type **Self Signed Root**, Certificate Type **Code Signing**, click Create
3. Save the cert name to `.signing-identity` (gitignored, per-machine):
   ```bash
   echo "ShotX Signing" > .signing-identity
   ```
4. Future `Scripts/build-app.sh` / `Scripts/release.sh` runs sign with that cert. The first install still triggers a Gatekeeper "from unidentified developer" warning (right-click → Open once); subsequent updates run silently and **Screen Recording permission persists**.

Alternative: set `CODE_SIGN_IDENTITY` env var per-build instead of the file.

## Auto-updates (Sparkle)

Each release ships a signed DMG and an entry in `appcast.xml`; existing installs poll it daily and prompt when a new version is available.

First-time setup (one-time, per machine):

```bash
./Scripts/sparkle-setup.sh
```

This downloads Sparkle's CLI tools into `.sparkle-tools/` and generates an Ed25519 key pair. The **private key** stays in your Keychain; the **public key** is saved to `.sparkle-public-key` (committed — it's embedded in the app at build time).

After setup, `Scripts/release.sh` automatically:
1. Signs the DMG with `sign_update` (Ed25519 signature over the file bytes)
2. Appends a new `<item>` to `appcast.xml` with the signature
3. Commits both source and appcast changes in one commit
4. Pushes, then publishes the GitHub release with the signed DMG

## Project layout

| File                              | Role                                              |
|-----------------------------------|---------------------------------------------------|
| `main.swift`                      | App entry                                         |
| `AppDelegate.swift`               | Status menu, hotkey wiring, capture pipeline      |
| `HotKeyManager.swift`             | Carbon global hotkey registration                 |
| `OverlayController.swift`         | Region-selection overlay                          |
| `OverlayWindow.swift`             | Per-screen borderless overlay window              |
| `SelectionView.swift`             | Drag-to-select view with crosshair + size label   |
| `ScreenCapture.swift`             | `CGWindowListCreateImage` wrapper                 |
| `WindowCapture.swift`             | Window-pick overlay + per-window capture          |
| `ScreenRecorder.swift`            | ScreenCaptureKit + AVAssetWriter pipeline         |
| `GIFConverter.swift`              | MP4 → GIF via `AVAssetImageGenerator`             |
| `RecordingController.swift`       | Recording flow orchestration (`@MainActor`)       |
| `RecordingUI.swift`               | Options panel + stop pill SwiftUI views           |
| `RecordingCompletePopup.swift`    | Bottom-left video/GIF popup with thumbnail        |
| `RecordingFrameOverlay.swift`     | Viewfinder rectangle around target region         |
| `Annotation.swift`                | Editor: canvas, toolbar, in-canvas text editor    |
| `MainWindow.swift`                | History grid + Settings tabs                      |
| `HistoryStore.swift`              | Persistent capture index (image / video / GIF)    |
| `ShortcutStore.swift`             | Shortcut persistence + key formatting             |
| `ShortcutRecorder.swift`          | NSViewRepresentable shortcut recorder             |
| `PostCapturePopup.swift`          | Bottom-left image popup                           |
| `PinnedImage.swift`               | Floating always-on-top pinned screenshots         |
| `AllInOne.swift`                  | Cursor-anchored capture palette                   |
| `DesktopIcons.swift`              | Toggle Finder desktop icons                       |
| `SoundEffect.swift`               | Camera-shutter playback                           |
| `FloatingPanels.swift`            | Countdown + toast controllers                     |
| `LastCaptureStore.swift`          | Persist last region for "Capture Previous"        |
| `ImageSaver.swift`                | PNG encode + clipboard + Desktop save             |
| `ColorPicker.swift`               | NSColorSampler wrapper + hex-to-clipboard         |
| `Permission.swift`                | Screen Recording permission prompt controller     |
| `Updater.swift`                   | Sparkle auto-update bootstrap                     |

### Storage

`~/Library/Application Support/ShotX/`
- `History/` — capture files (`.png`, `.mp4`, `.gif`)
- `history.json` — index (id, kind, dimensions, duration, timestamp)

`UserDefaults`:
- `com.shotx.shortcut` — capture shortcut combo
- `com.shotx.colorPickerShortcut` — color-picker shortcut combo
- `com.shotx.lastCapture` — last region rect + screen index

---

## Roadmap

- [ ] Microphone + system audio in recording
- [ ] Webcam overlay
- [ ] Keystroke visualization in recordings
- [ ] Mouse-click highlights in recordings
- [ ] Scrolling capture (stitched long-form screenshots)
- [ ] Notarized / Developer ID-signed distribution
- [ ] Custom DMG background

---

<div align="center">
<sub>Built with Swift, AppKit, SwiftUI, and Claude.</sub>
</div>
