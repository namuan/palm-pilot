import CoreGraphics
import Foundation

final class GestureClassifier {

    private let minimumConfidence: Float = 0.5
    private let minimumLandmarks: Int = 15
    private var lastClassifiedGesture: Gesture = .unknown

    func classify(_ frame: HandPoseFrame?) -> Gesture {
        guard let frame = frame,
              frame.confidence >= minimumConfidence,
              frame.landmarks.count >= minimumLandmarks else {
            let reason: String
            if frame == nil {
                reason = "no frame"
            } else {
                reason = "low confidence (\(frame!.confidence)) or insufficient landmarks (\(frame?.landmarks.count ?? 0)/\(minimumLandmarks))"
            }
            if lastClassifiedGesture != .unknown {
                Log.debug("Gesture → unknown (\(reason))")
            }
            lastClassifiedGesture = .unknown
            return .unknown
        }

        let fingers: [FingerGroup] = [.thumb, .index, .middle, .ring, .little]
        let extendedFingers = fingers.filter { frame.isFingerExtended($0) }

        let gesture: Gesture

        switch extendedFingers.count {
        case 5:
            gesture = .openPalm
        case 0:
            gesture = .fist
        case 1:
            if extendedFingers.contains(.thumb) {
                gesture = .thumbsUp
            } else {
                gesture = .unknown
            }
        case 2:
            if extendedFingers.contains(.index) && extendedFingers.contains(.middle) {
                gesture = .peaceSign
            } else {
                gesture = .unknown
            }
        default:
            gesture = .unknown
        }

        if gesture != lastClassifiedGesture {
            if gesture != .unknown {
                Log.info("Gesture: \(lastClassifiedGesture.rawValue) → \(gesture.rawValue)  (confidence: \(frame.confidence), extended: \(extendedFingers.map(\.rawValue)))")
            }
            lastClassifiedGesture = gesture
        }

        return gesture
    }
}
