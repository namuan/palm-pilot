import CoreGraphics
import AppKit

final class ActionDispatcher {

    private var lastActionTime: [String: TimeInterval] = [:]
    private let actionCooldown: TimeInterval = 1.0

    func dispatch(_ gesture: Gesture, mappings: [ActionMapping]) {
        let gestureName = gesture.rawValue
        guard let mapping = mappings.first(where: { $0.gesture == gestureName && $0.enabled }) else {
            Log.debug("No enabled mapping for gesture: \(gestureName)")
            return
        }

        let now = CACurrentMediaTime()
        if let last = lastActionTime[gestureName], now - last < actionCooldown {
            Log.debug("Action '\(mapping.label)' suppressed (cooldown)")
            return
        }
        lastActionTime[gestureName] = now

        Log.info("Dispatching action: '\(mapping.label)' (action: \(mapping.action))")
        executeAction(mapping.action)
    }

    // MARK: - Action Execution

    private func executeAction(_ action: String) {
        switch action {
        case "previousDesktop":
            Log.info("Executing: previous desktop (ctrl+left)")
            simulateKeyPress(keyCode: 123, flags: [.maskControl])
        case "nextDesktop":
            Log.info("Executing: next desktop (ctrl+right)")
            simulateKeyPress(keyCode: 124, flags: [.maskControl])
        case "playPause":
            Log.info("Executing: play/pause media key")
            simulateMediaKey(keyCode: NX_KEYTYPE_PLAY)
        case "muteMicrophone":
            Log.info("Executing: mute microphone")
            toggleMute()
        case "stop":
            Log.info("Executing: stop action (no-op)")
            break
        case "screenshot":
            Log.info("Executing: screenshot (cmd+shift+ctrl+4)")
            simulateKeyPress(keyCode: 28, flags: [.maskCommand, .maskShift, .maskControl])
        default:
            Log.warning("Unknown action: \(action)")
            break
        }
    }

    // MARK: - Keyboard Simulation

    private func simulateKeyPress(keyCode: CGKeyCode, flags: CGEventFlags = []) {
        guard let down = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true) else {
            Log.error("Failed to create key down event for keyCode: \(keyCode)")
            return
        }
        down.flags = flags
        down.post(tap: .cghidEventTap)

        guard let up = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false) else {
            Log.error("Failed to create key up event for keyCode: \(keyCode)")
            return
        }
        up.post(tap: .cghidEventTap)

        Log.debug("Key event posted: keyCode=\(keyCode), flags=\(flags.rawValue)")
    }

    private func simulateMediaKey(keyCode: Int32) {
        guard let down = NSEvent.otherEvent(
            with: .systemDefined,
            location: .zero,
            modifierFlags: [],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            subtype: 8,
            data1: Int((keyCode << 16) | (0x0A << 8)),
            data2: -1
        )?.cgEvent else {
            Log.error("Failed to create media key down event: \(keyCode)")
            return
        }
        down.post(tap: .cghidEventTap)

        guard let up = NSEvent.otherEvent(
            with: .systemDefined,
            location: .zero,
            modifierFlags: [],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            subtype: 8,
            data1: Int((keyCode << 16) | (0x0B << 8)),
            data2: -1
        )?.cgEvent else {
            Log.error("Failed to create media key up event: \(keyCode)")
            return
        }
        up.post(tap: .cghidEventTap)

        Log.debug("Media key event posted: keyCode=\(keyCode)")
    }

    private func toggleMute() {
        guard let down = NSEvent.otherEvent(
            with: .systemDefined,
            location: .zero,
            modifierFlags: [],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            subtype: 8,
            data1: Int((10 << 16) | (0x0A << 8)),
            data2: -1
        )?.cgEvent else {
            Log.error("Failed to create mute key down event")
            return
        }
        down.post(tap: .cghidEventTap)

        guard let up = NSEvent.otherEvent(
            with: .systemDefined,
            location: .zero,
            modifierFlags: [],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            subtype: 8,
            data1: Int((10 << 16) | (0x0B << 8)),
            data2: -1
        )?.cgEvent else {
            Log.error("Failed to create mute key up event")
            return
        }
        up.post(tap: .cghidEventTap)

        Log.debug("Mute toggle key event posted")
    }
}
