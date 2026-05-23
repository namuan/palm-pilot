import Foundation

enum Gesture: String, CaseIterable {
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

    var symbolName: String {
        switch self {
        case .openPalm: return "hand.raised"
        case .fist: return "hand.raised.slash"
        case .thumbsUp: return "hand.thumbsup"
        case .peaceSign: return "hand.wave"
        case .swipeLeft: return "arrow.left"
        case .swipeRight: return "arrow.right"
        case .unknown: return "questionmark"
        }
    }
}
