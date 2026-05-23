import CoreGraphics
import Foundation

final class MotionTracker {

    struct MotionState {
        let centroid: CGPoint
        let timestamp: TimeInterval
    }

    private var history: [MotionState] = []
    private let maxHistory = 30
    private let minSwipeDistance: CGFloat = 0.08
    private let minSwipeVelocity: CGFloat = 0.15
    private var lastSwipeTime: TimeInterval = 0
    private let swipeCooldown: TimeInterval = 0.5

    private var lastGesture: Gesture = .unknown

    func process(frame: HandPoseFrame?, staticGesture: Gesture) -> Gesture {
        defer { lastGesture = staticGesture }

        guard let frame = frame,
              let centroid = frame.centroid,
              frame.confidence >= 0.5 else {
            if !history.isEmpty {
                Log.debug("Motion history cleared — frame invalid or low confidence")
            }
            history.removeAll()
            return staticGesture
        }

        let now = frame.timestamp
        history.append(MotionState(centroid: centroid, timestamp: now))

        while history.count > maxHistory {
            history.removeFirst()
        }

        guard history.count >= 5 else {
            return staticGesture
        }

        let recentFrames = history.suffix(15)
        guard let first = recentFrames.first,
              let last = recentFrames.last,
              first.timestamp < last.timestamp else {
            return staticGesture
        }

        let dx = last.centroid.x - first.centroid.x
        let dt = last.timestamp - first.timestamp
        let velocity = abs(dx) / CGFloat(dt)

        if velocity >= minSwipeVelocity && abs(dx) >= minSwipeDistance {
            if now - lastSwipeTime >= swipeCooldown {
                lastSwipeTime = now
                let direction = dx > 0 ? "right" : "left"
                Log.info("Swipe \(direction) detected — dx: \(dx), velocity: \(velocity)")
                return dx > 0 ? .swipeRight : .swipeLeft
            } else {
                Log.debug("Swipe candidate suppressed (cooldown active) — dx: \(dx), velocity: \(velocity)")
            }
        }

        return staticGesture
    }
}
