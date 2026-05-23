import AVFoundation
import CoreGraphics
import Vision

final class HandPoseDetector {

    private let handPoseRequest = VNDetectHumanHandPoseRequest()
    private var handPreviouslyDetected = false
    private var frameCount: UInt64 = 0

    var onHandPose: ((HandPoseFrame?) -> Void)?

    init() {
        handPoseRequest.maximumHandCount = 1
    }

    func processFrame(_ sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            Log.warning("Failed to get pixel buffer from sample buffer")
            return
        }

        let requestHandler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: .up,
            options: [:]
        )

        do {
            try requestHandler.perform([handPoseRequest])
            let observations = handPoseRequest.results ?? []
            frameCount += 1

            if let observation = observations.first {
                if !handPreviouslyDetected {
                    Log.info("Hand detected — confidence: \(observation.confidence)")
                    handPreviouslyDetected = true
                }
                onHandPose?(extractLandmarks(from: observation))
            } else {
                if handPreviouslyDetected {
                    Log.info("Hand lost after \(frameCount) frames")
                    handPreviouslyDetected = false
                }
                onHandPose?(nil)
            }
        } catch {
            if handPreviouslyDetected {
                Log.warning("Vision request failed: \(error.localizedDescription)")
            }
            onHandPose?(nil)
        }
    }

    private func extractLandmarks(from observation: VNHumanHandPoseObservation) -> HandPoseFrame {
        var landmarks: [HandJoint: CGPoint] = [:]

        let jointMapping: [(HandJoint, VNHumanHandPoseObservation.JointName)] = [
            (.wrist, .wrist),
            (.thumbCMC, .thumbCMC), (.thumbMP, .thumbMP), (.thumbIP, .thumbIP), (.thumbTip, .thumbTip),
            (.indexMCP, .indexMCP), (.indexPIP, .indexPIP), (.indexDIP, .indexDIP), (.indexTip, .indexTip),
            (.middleMCP, .middleMCP), (.middlePIP, .middlePIP), (.middleDIP, .middleDIP), (.middleTip, .middleTip),
            (.ringMCP, .ringMCP), (.ringPIP, .ringPIP), (.ringDIP, .ringDIP), (.ringTip, .ringTip),
            (.littleMCP, .littleMCP), (.littlePIP, .littlePIP), (.littleDIP, .littleDIP), (.littleTip, .littleTip),
        ]

        for (handJoint, visionJoint) in jointMapping {
            if let point = try? observation.recognizedPoint(visionJoint),
               point.confidence > 0.3 {
                landmarks[handJoint] = CGPoint(
                    x: CGFloat(point.location.x),
                    y: CGFloat(1.0 - point.location.y)
                )
            }
        }

        return HandPoseFrame(
            timestamp: CACurrentMediaTime(),
            landmarks: landmarks,
            confidence: Float(observation.confidence)
        )
    }
}
