import SwiftUI
import AppKit
import AVFoundation

struct CameraPreviewView: NSViewRepresentable {
    let session: AVCaptureSession
    let landmarks: [HandJoint: CGPoint]
    let showOverlay: Bool

    func makeNSView(context: Context) -> PreviewNSView {
        let view = PreviewNSView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateNSView(_ nsView: PreviewNSView, context: Context) {
        nsView.updateLandmarks(landmarks, showOverlay: showOverlay)
    }
}

final class PreviewNSView: NSView {

    let previewLayer = AVCaptureVideoPreviewLayer()
    private let overlayLayer = CAShapeLayer()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.addSublayer(previewLayer)
        layer?.addSublayer(overlayLayer)
        overlayLayer.fillColor = NSColor.clear.cgColor
        overlayLayer.strokeColor = NSColor.systemGreen.cgColor
        overlayLayer.lineWidth = 2
        overlayLayer.lineJoin = .round
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        previewLayer.frame = bounds
        overlayLayer.frame = bounds
    }

    func updateLandmarks(_ landmarks: [HandJoint: CGPoint], showOverlay: Bool) {
        guard showOverlay, !landmarks.isEmpty else {
            overlayLayer.path = nil
            return
        }

        let path = CGMutablePath()
        let connections: [(HandJoint, HandJoint)] = [
            (.wrist, .thumbCMC), (.thumbCMC, .thumbMP), (.thumbMP, .thumbIP), (.thumbIP, .thumbTip),
            (.wrist, .indexMCP), (.indexMCP, .indexPIP), (.indexPIP, .indexDIP), (.indexDIP, .indexTip),
            (.wrist, .middleMCP), (.middleMCP, .middlePIP), (.middlePIP, .middleDIP), (.middleDIP, .middleTip),
            (.wrist, .ringMCP), (.ringMCP, .ringPIP), (.ringPIP, .ringDIP), (.ringDIP, .ringTip),
            (.wrist, .littleMCP), (.littleMCP, .littlePIP), (.littlePIP, .littleDIP), (.littleDIP, .littleTip),
            (.thumbMP, .indexMCP), (.indexMCP, .middleMCP), (.middleMCP, .ringMCP), (.ringMCP, .littleMCP),
        ]

        for (from, to) in connections {
            guard let fromPoint = landmarks[from],
                  let toPoint = landmarks[to] else { continue }

            let p1 = pointInView(from: fromPoint)
            let p2 = pointInView(from: toPoint)
            path.move(to: p1)
            path.addLine(to: p2)
        }

        for point in landmarks.values {
            let p = pointInView(from: point)
            let circle = CGPath(ellipseIn: CGRect(x: p.x - 3, y: p.y - 3, width: 6, height: 6), transform: nil)
            path.addPath(circle)
        }

        overlayLayer.path = path
    }

    private func pointInView(from normalizedPoint: CGPoint) -> CGPoint {
        CGPoint(
            x: normalizedPoint.x * bounds.width,
            y: (1.0 - normalizedPoint.y) * bounds.height
        )
    }
}
