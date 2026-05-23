import Foundation

enum Gesture: String, CaseIterable, Codable {
    case openPalm
    case fist
    case thumbsUp
    case peaceSign
    case swipeLeft
    case swipeRight
    case unknown

    var displayName: String {
        switch self {
        case .openPalm: return "Open Palm"
        case .fist: return "Fist"
        case .thumbsUp: return "Thumbs Up"
        case .peaceSign: return "Peace Sign"
        case .swipeLeft: return "Swipe Left"
        case .swipeRight: return "Swipe Right"
        case .unknown: return "No Gesture"
        }
    }
}
