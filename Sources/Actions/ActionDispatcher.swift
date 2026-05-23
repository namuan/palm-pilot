import CoreGraphics
import AppKit

final class ActionDispatcher {

    private var lastActionTime: [String: TimeInterval] = [:]
    private let actionCooldown: TimeInterval = 1.0

    func dispatch(_ gesture: Gesture, mappings: [ActionMapping]) {
        guard let mapping = mappings.first(where: { $0.gesture == gesture && $0.enabled }) else {
            Log.debug("No enabled mapping for gesture: \(gesture.rawValue)")
            return
        }

        let now = CACurrentMediaTime()
        if let last = lastActionTime[gesture.rawValue], now - last < actionCooldown {
            Log.debug("Action '\(mapping.label)' suppressed (cooldown)")
            return
        }
        lastActionTime[gesture.rawValue] = now

        Log.info("Dispatching action: '\(mapping.label)' (action: \(mapping.action))")
        executeAction(mapping.action)
    }

    // MARK: - Action Execution

    private func executeAction(_ action: String) {
        switch action {
        case "previousDesktop":
            simulateKeyPress(keyCode: 123, flags: [.maskControl])
        case "nextDesktop":
            simulateKeyPress(keyCode: 124, flags: [.maskControl])
        case "playPause":
            simulateMediaKey(keyCode: NX_KEYTYPE_PLAY)
        case "muteMicrophone":
            simulateMediaKey(keyCode: NX_KEYTYPE_MUTE)
        case "stop":
            break
        case "screenshot":
            simulateKeyPress(keyCode: 28, flags: [.maskCommand, .maskShift, .maskControl])
        default:
            Log.warning("Unknown action: \(action)")
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
}
