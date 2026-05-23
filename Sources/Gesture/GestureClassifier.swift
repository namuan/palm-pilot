import CoreGraphics
import Foundation

final class GestureClassifier {

    private let minimumConfidence: Float = 0.5
    private let minimumLandmarks: Int = 15

    func classify(_ frame: HandPoseFrame?) -> Gesture {
        guard let frame = frame,
              frame.confidence >= minimumConfidence,
              frame.landmarks.count >= minimumLandmarks else {
            return .unknown
        }

        let fingers: [FingerGroup] = [.thumb, .index, .middle, .ring, .little]
        let extendedFingers = fingers.filter { frame.isFingerExtended($0) }

        switch extendedFingers.count {
        case 5:
            return .openPalm
        case 0:
            return .fist
        case 1:
            return extendedFingers.contains(.thumb) ? .thumbsUp : .unknown
        case 2:
            return (extendedFingers.contains(.index) && extendedFingers.contains(.middle)) ? .peaceSign : .unknown
        default:
            return .unknown
        }
    }
}
