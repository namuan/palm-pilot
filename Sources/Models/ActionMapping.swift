import Foundation

struct ActionMapping: Identifiable, Codable {
    let id: UUID
    let gesture: Gesture
    let action: String
    let label: String
    var enabled: Bool

    init(gesture: Gesture, action: String, label: String, enabled: Bool = true) {
        id = UUID()
        self.gesture = gesture
        self.action = action
        self.label = label
        self.enabled = enabled
    }

    static let defaults: [ActionMapping] = [
        ActionMapping(gesture: .swipeLeft, action: "previousDesktop", label: "Previous Desktop"),
        ActionMapping(gesture: .swipeRight, action: "nextDesktop", label: "Next Desktop"),
        ActionMapping(gesture: .thumbsUp, action: "playPause", label: "Play / Pause"),
        ActionMapping(gesture: .fist, action: "muteMicrophone", label: "Mute Microphone"),
        ActionMapping(gesture: .openPalm, action: "stop", label: "Stop Actions"),
        ActionMapping(gesture: .peaceSign, action: "screenshot", label: "Screenshot"),
    ]
}
