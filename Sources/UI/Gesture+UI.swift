import SwiftUI

extension Gesture {
    var symbolName: String {
        switch self {
        case .openPalm: return "hand.raised"
        case .fist: return "hand.raised.slash"
        case .thumbsUp: return "hand.thumbsup"
        case .peaceSign: return "hand.wave"
        case .swipeLeft: return "arrow.left"
        case .swipeRight: return "arrow.right"
        case .unknown: return "questionmark.circle"
        }
    }
}
