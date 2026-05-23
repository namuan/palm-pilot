# macOS Gesture Recognition App — MVP Plan

## Goal

Build a native macOS application that:

* runs fully offline
* uses the Mac camera
* detects a person and hand gestures
* maps gestures to actions
* is private/local-first
* performs in real time on Apple Silicon
* is written entirely in Swift

---

# MVP Definition

## Core User Story

> “I open the app, allow camera access, and use hand gestures to trigger actions on my Mac.”

---

# Recommended MVP Stack

| Layer              | Technology                   |
| ------------------ | ---------------------------- |
| UI                 | SwiftUI                      |
| Camera             | AVFoundation                 |
| Vision tracking    | Vision Framework             |
| ML/runtime         | Core ML                      |
| Rendering overlays | SwiftUI + CALayer            |
| Event triggering   | CGEvent / Accessibility APIs |
| Packaging          | Xcode native app             |

---

# MVP Scope

## Included

### Real-time camera feed

* webcam input
* live preview
* 30 FPS target

### Hand detection

* single hand initially
* landmark extraction

### Basic gesture recognition

Support:

* open palm
* fist
* thumbs up
* peace sign
* swipe left/right

### Gesture → Action mapping

Examples:

* swipe left → previous desktop
* swipe right → next desktop
* thumbs up → play/pause
* fist → mute microphone

### Privacy-first architecture

* no cloud
* no analytics
* no frame storage
* local-only processing

### Menu bar app

* lightweight UX
* start/stop detection
* gesture status indicator

---

## Excluded from MVP

Avoid:

* custom ML training
* multiple users
* sign language
* multi-camera
* iPhone continuity camera
* account system
* cloud sync
* gesture scripting engine
* advanced onboarding
* App Store deployment initially

---

# System Architecture

```text id="6i3x2s"
Camera Layer
    ↓
Frame Processing Pipeline
    ↓
Vision Hand Pose Detection
    ↓
Landmark Extraction
    ↓
Gesture Recognition Engine
    ↓
Action Dispatcher
    ↓
macOS System Actions
```

---

# Detailed Component Plan

# 1. Camera Subsystem

## Responsibilities

* access webcam
* stream frames
* convert buffers
* maintain low latency

---

## APIs

Use:

* AVCaptureSession
* AVCaptureVideoDataOutput

---

## Deliverables

### CameraManager.swift

Handles:

* permissions
* device selection
* session lifecycle

---

## Notes

### Use:

```swift id="6n5vv9"
AVCaptureVideoDataOutputSampleBufferDelegate
```

Avoid:

* recording APIs
* photo APIs

---

## FPS Target

* 30 FPS minimum
* 720p preferred initially

---

# 2. Vision Processing Layer

## Responsibilities

* detect hands
* extract joints
* normalize coordinates

---

## APIs

Use:

```swift id="ivm5xr"
VNDetectHumanHandPoseRequest
```

---

## Landmark Data

Extract:

* wrist
* fingertips
* knuckles

Apple returns:

* normalized coordinates
* confidence scores

---

## Deliverables

### HandPoseDetector.swift

Input:

```text id="f2wxbk"
CMSampleBuffer
```

Output:

```swift id="zx3gdh"
HandPoseFrame {
    landmarks: [CGPoint]
    confidence: Float
}
```

---

# 3. Gesture Recognition Engine

This is the heart of the MVP.

---

# Strategy

Use:

## Rule-based gesture classification

NOT machine learning yet.

This dramatically reduces complexity.

---

# Why Rule-Based First?

Advantages:

* easier debugging
* deterministic
* low latency
* no training dataset
* faster iteration

---

# Gesture Detection Logic

## Open Palm

Rules:

* all fingertips extended
* finger tip above knuckle

---

## Fist

Rules:

* fingertips close to palm center

---

## Thumbs Up

Rules:

* thumb extended upward
* other fingers folded

---

## Peace Sign

Rules:

* index + middle extended
* others folded

---

## Swipe Gestures

Need:

* temporal tracking

Approach:

* store hand centroid history
* detect directional velocity

---

# Deliverables

### GestureClassifier.swift

Input:

```swift id="2xqowj"
HandPoseFrame
```

Output:

```swift id="8w4dqo"
enum Gesture
```

---

# 4. Temporal Motion Engine

Needed for:

* swipes
* wave
* motion stability

---

# Approach

Maintain:

```swift id="z9vs13"
last 15–30 frames
```

Compute:

* velocity
* direction
* smoothing
* debounce timing

---

# Deliverables

### MotionTracker.swift

Features:

* frame history
* velocity calculations
* confidence smoothing

---

# 5. Action Dispatcher

## Responsibilities

Map gestures to:

* keyboard shortcuts
* media controls
* app automation

---

# APIs

Use:

* CGEvent
* Accessibility APIs

Potentially:

```swift id="tt0rw4"
AXIsProcessTrustedWithOptions
```

---

# MVP Actions

| Gesture     | Action           |
| ----------- | ---------------- |
| Swipe left  | Previous desktop |
| Swipe right | Next desktop     |
| Thumbs up   | Play/pause       |
| Fist        | Mute mic         |
| Open palm   | Stop actions     |

---

# Deliverables

### ActionDispatcher.swift

---

# 6. UI / UX

# Recommended UX

## Menu Bar App

Why:

* lightweight
* always available
* common macOS utility pattern

---

# Main UI Features

## Menu Bar Status

States:

* inactive
* camera active
* gesture detected
* permissions issue

---

## Mini Control Panel

Contains:

* start/stop
* camera preview
* detected gesture label
* gesture-action mappings

---

# SwiftUI Structure

```text id="xn7f0u"
App
 ├── MenuBarExtra
 ├── Main Settings Window
 └── Live Camera Preview
```

---

# Deliverables

### App.swift

### MenuBarView.swift

### SettingsView.swift

---

# 7. Permissions & Privacy

# Required Permissions

## Camera

```xml id="sn4jzm"
NSCameraUsageDescription
```

## Accessibility

Needed for automation.

---

# Privacy Requirements

## Important

Never:

* upload frames
* store video
* send telemetry

---

# Nice Privacy Feature

Add:

```text id="c2ck4l"
Offline Processing Guaranteed
```

indicator in settings.

This is valuable differentiation.

---

# 8. Performance Targets

# MVP Targets

| Metric            | Goal             |
| ----------------- | ---------------- |
| Startup           | <2 sec           |
| Detection latency | <100 ms          |
| FPS               | 30               |
| CPU               | <20% on M-series |
| RAM               | <300 MB          |

---

# Optimization Plan

## Process frames asynchronously

Avoid blocking:

```swift id="1kr8sq"
DispatchQueue.main
```

---

## Drop stale frames

Use:

```swift id="2j9r96"
alwaysDiscardsLateVideoFrames
```

---

## Downscale frames

Use:

* 720p
* maybe 540p internally

---

# Suggested File Structure

```text id="6nyv59"
Sources/
 ├── App/
 ├── Camera/
 ├── Vision/
 ├── Gesture/
 ├── Motion/
 ├── Actions/
 ├── UI/
 ├── Utilities/
 └── Models/
```

---

# Suggested Data Models

## Hand Pose

```swift id="xh7g4q"
struct HandPoseFrame {
    let timestamp: TimeInterval
    let landmarks: [HandJoint: CGPoint]
    let confidence: Float
}
```

---

## Gesture Event

```swift id="m7cn12"
struct GestureEvent {
    let gesture: Gesture
    let confidence: Float
    let timestamp: TimeInterval
}
```

---

# Development Phases

# Phase 1 — Camera + Detection

## Time: 2–4 days

Deliver:

* webcam stream
* hand landmarks
* overlay rendering

Success criteria:

* stable landmark tracking

---

# Phase 2 — Gesture Classification

## Time: 4–7 days

Deliver:

* open palm
* fist
* thumbs up
* peace sign

Success criteria:

* > 90% recognition reliability

---

# Phase 3 — Motion Gestures

## Time: 3–5 days

Deliver:

* swipe detection
* smoothing
* debounce

Success criteria:

* low false positives

---

# Phase 4 — System Actions

## Time: 2–4 days

Deliver:

* keyboard shortcuts
* media controls

Success criteria:

* stable automation

---

# Phase 5 — UX Polish

## Time: 3–5 days

Deliver:

* menu bar UX
* onboarding
* permission handling

---

# Estimated MVP Timeline

## Solo developer

| Phase                | Duration |
| -------------------- | -------- |
| Core camera pipeline | 1 week   |
| Gesture engine       | 1 week   |
| System actions       | 3 days   |
| UI/polish            | 1 week   |
| Testing/tuning       | 1 week   |

## Total

### ~4–5 weeks

---

# Biggest Technical Risks

# 1. False Positives

Mitigation:

* temporal smoothing
* confidence thresholds
* gesture cooldowns

---

# 2. Lighting Conditions

Mitigation:

* user calibration
* confidence gating

---

# 3. CPU Usage

Mitigation:

* frame skipping
* lower resolution
* background queues

---

# 4. Accessibility Permissions

macOS automation permissions can be confusing.

Mitigation:

* onboarding flow
* direct settings links

---

# Future Upgrades After MVP

## v2 Features

### Custom gesture training

Use:

* Core ML sequence classifier

---

### Multi-hand tracking

---

### Face/head gestures

---

### App-specific controls

Examples:

* Final Cut
* Spotify
* PowerPoint

---

### Plugin system

---

### Vision Pro support

---

# Suggested MVP Milestone

The first “wow” demo should be:

```text id="8a3az4"
Open app
↓
Raise hand
↓
Swipe right
↓
Desktop changes instantly
```

If that feels fast and reliable, you have a compelling MVP.

---

# Recommended Development Order

## Build in this exact sequence

1. Camera feed
2. Hand landmarks
3. Overlay drawing
4. Static gestures
5. Motion gestures
6. Action triggering
7. Menu bar UX
8. Optimization
9. Packaging

Avoid jumping ahead to ML too early.

---

# Recommendation Summary

## Best MVP Stack

```text id="jpkzxv"
SwiftUI
+ AVFoundation
+ Vision
+ CGEvent
```

## Best Gesture Strategy

```text id="7zv33d"
Rule-based + temporal smoothing
```

## Best Initial UX

```text id="5iwd2e"
Menu bar utility app
```

## Best Initial Goal

```text id="x5i7iw"
5 reliable gestures
mapped to macOS actions
with <100ms latency
```
