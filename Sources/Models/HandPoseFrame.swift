import Foundation
import CoreGraphics

struct HandPoseFrame {
    let timestamp: TimeInterval
    let landmarks: [HandJoint: CGPoint]
    let confidence: Float

    var wrist: CGPoint? { landmarks[.wrist] }
    var thumbTip: CGPoint? { landmarks[.thumbTip] }
    var indexTip: CGPoint? { landmarks[.indexTip] }
    var middleTip: CGPoint? { landmarks[.middleTip] }
    var ringTip: CGPoint? { landmarks[.ringTip] }
    var littleTip: CGPoint? { landmarks[.littleTip] }

    var centroid: CGPoint? {
        let points = landmarks.values
        guard !points.isEmpty else { return nil }
        let x = points.reduce(0) { $0 + $1.x } / CGFloat(points.count)
        let y = points.reduce(0) { $0 + $1.y } / CGFloat(points.count)
        return CGPoint(x: x, y: y)
    }

    func joint(_ name: HandJoint) -> CGPoint? {
        landmarks[name]
    }

    func isFingerExtended(_ finger: FingerGroup) -> Bool {
        guard let mcp = mcpJoint(for: finger),
              let tip = tipJoint(for: finger),
              let wrist = wrist else {
            return false
        }
        let tipDistance = tip.distance(to: wrist)
        let mcpDistance = mcp.distance(to: wrist)
        return tipDistance > mcpDistance * 1.1
    }

    private func mcpJoint(for finger: FingerGroup) -> CGPoint? {
        switch finger {
        case .thumb: return landmarks[.thumbMP]
        case .index: return landmarks[.indexMCP]
        case .middle: return landmarks[.middleMCP]
        case .ring: return landmarks[.ringMCP]
        case .little: return landmarks[.littleMCP]
        }
    }

    private func tipJoint(for finger: FingerGroup) -> CGPoint? {
        switch finger {
        case .thumb: return landmarks[.thumbTip]
        case .index: return landmarks[.indexTip]
        case .middle: return landmarks[.middleTip]
        case .ring: return landmarks[.ringTip]
        case .little: return landmarks[.littleTip]
        }
    }
}

extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        let dx = x - point.x
        let dy = y - point.y
        return sqrt(dx * dx + dy * dy)
    }
}
