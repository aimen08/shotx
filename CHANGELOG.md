# Changelog

All notable changes to this project are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## 2026-08-31

### Fixed
- Escape cancels the window picker. Its overlay was a plain borderless `NSWindow`, and AppKit refuses key status to those by default, so the picker's Escape handler never saw a key press — the only way out of window capture was to click something.
- Escape cancels a running self-timer, the way clicking the countdown already did. The countdown panel is non-activating and the user is usually working in another app while it runs, so the key press never arrives as an AppKit event; it's grabbed as a system-wide hot key for as long as the countdown is on screen, and released the moment it goes away.

## 2026-08-30

### Changed
- Area capture is now synchronous. ShotX's own transient chrome (selection overlay, countdown, viewfinder, toasts, post-capture popup) is filtered out of the capture composite by window ID, so captures no longer hide their overlays and wait 120–200 ms for the window server to catch up. Fullscreen, previous-area, self-timer and window capture lost their settle delays too; menu-invoked captures keep a short one, because menu windows can't be filtered the same way.
- Captures are rasterized once, off the main thread. The post-capture popup now appears before encoding starts, and the clipboard is populated a moment later.
- The selection overlay repaints only the pixels that changed instead of the whole display on every mouse move.

### Fixed
- Transient windows were only ordered off screen, never closed, leaving their SwiftUI hosting controllers — and, for the post-capture popup, the full-resolution capture — alive for the rest of the session. Affected the post-capture popup, toasts, countdown, recording options and stop pill, recording-complete popup, pinned images, selection overlay, viewfinder, click highlighter and the window picker.
- Encoding a capture built a full uncompressed TIFF three times over (history PNG, clipboard PNG, clipboard TIFF), each one re-parsed into a second full-size buffer. It now goes straight from the backing CGImage.
- The webcam preview rendered and dispatched frames with no backpressure and no autorelease pool, so camera frames accumulated on the main queue during recording.
- Screen recorder sample handlers had no autorelease pool, deferring deallocation of pixel buffers for the length of a recording.
- The history thumbnail cache was bounded by count but not by size, letting decoded thumbnails hold ~140 MB until the system reported memory pressure.
- Opening a second annotator dropped the first controller while its window was still on screen, after which the orphan's close callback cleared the reference to the live one.

### Chore
- `Scripts/build-app.sh` builds each architecture separately and `lipo`s them together. The previous single `swift build --arch arm64 --arch x86_64` routed through xcbuild and needed a full Xcode install; universal builds now work with the Command Line Tools alone.
