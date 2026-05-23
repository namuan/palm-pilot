# Palm Pilot

Control your Mac with hand gestures — fully offline, private, and local-first.
Built with Swift + AVFoundation + Vision. No data leaves your Mac.

## Gestures

| Gesture       | Action               |
| ------------- | -------------------- |
| Swipe left    | Previous desktop     |
| Swipe right   | Next desktop         |
| Thumbs up     | Play / Pause         |
| Fist          | Mute microphone      |
| Open palm     | Stop actions         |
| Peace sign    | Screenshot           |

## Requirements

- **Hardware:** Mac with Apple Silicon (M1 or later)
- **Software:** macOS 14.0 (Sonoma) or later
- **Swift toolchain:** `swift` on `$PATH` (comes with Xcode or Command Line Tools)

## Quick Start

```bash
make build      # compile with SwiftPM
make run        # build + launch .app bundle
```

That's it — no Xcode project required.

## Development

### SPM workflow (default, no Xcode needed)

```bash
make              # build (debug)
make build        # build (debug)
make build-release # build (release)
make run          # build + launch .app
make clean        # remove all build artifacts
make lint         # run SwiftLint
```

Under the hood, `make build` runs:

```bash
swift build
./build-app.sh    # packages binary + Info.plist into .app bundle
```

The output is `.build/debug/PalmPilot.app`.

### Xcode workflow (optional)

```bash
brew install xcodegen
make project  # generate PalmPilot.xcodeproj
make open     # open in Xcode
make xcbuild  # build with xcodebuild
```

## Permissions

The app needs two permissions on first launch:

1. **Camera access** — prompted automatically. All processing is on-device.
2. **Accessibility access** — needed for simulating keyboard shortcuts. Grant in **System Settings → Privacy & Security → Accessibility**.

## Privacy

- 100% offline — no internet connection required
- No telemetry, no analytics, no crash reporting
- Video frames are never stored or recorded
- All processing uses Apple's on-device Vision framework

## Architecture

```
Camera (AVFoundation)
    ↓ 30fps @ 720p
Vision Hand Pose Detection
    ↓ 21 landmarks per frame
Gesture Classifier (rule-based)
    ↓ 5 static gestures + temporal swipe
Motion Tracker (velocity from centroid history)
    ↓
Action Dispatcher (CGEvent)
    ↓
macOS system actions
```

All frames are processed on background queues. The main thread is never blocked.

### File Layout

```
Sources/
├── App/           PalmPilotApp.swift + AppViewModel.swift
├── Camera/        CameraManager.swift (AVFoundation)
├── Vision/        HandPoseDetector.swift (VNDetectHumanHandPoseRequest)
├── Gesture/       GestureClassifier.swift (rule-based)
├── Motion/        MotionTracker.swift (temporal smoothing)
├── Actions/       ActionDispatcher.swift (CGEvent)
├── UI/            MenuBarView.swift, SettingsView.swift, CameraPreviewView.swift
└── Models/        HandJoint.swift, HandPoseFrame.swift, Gesture.swift
```

### Gesture Detection

Rule-based (no ML training needed):

- **Finger extension:** tip-to-wrist distance vs MCP-to-wrist distance
- **Open palm:** all 5 fingers extended
- **Fist:** all 5 fingers folded
- **Thumbs up:** thumb extended, others folded
- **Peace sign:** index + middle extended, others folded
- **Swipe:** centroid velocity over 15–30 frame window

## License

MIT
