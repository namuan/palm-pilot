import AVFoundation
import CoreGraphics
import Vision

final class HandPoseDetector {

    private let visionQueue = DispatchQueue(label: "com.palmpilot.vision", qos: .userInitiated)
    private var lastFrame: HandPoseFrame?
    private var handPreviouslyDetected = false
    private var totalFramesProcessed: UInt64 = 0
    private var framesWithHand: UInt64 = 0

    var onHandPose: ((HandPoseFrame?) -> Void)?

    func processFrame(_ sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            Log.warning("Failed to get pixel buffer from sample buffer")
            return
        }

        let request = VNDetectHumanHandPoseRequest()
        request.maximumHandCount = 1

        let requestHandler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: .up,
            options: [:]
        )

        do {
            try requestHandler.perform([request])
            let observations = request.results ?? []
            totalFramesProcessed += 1

            if let observation = observations.first {
                framesWithHand += 1
                let frame = extractLandmarks(from: observation)

                if !handPreviouslyDetected {
                    Log.info("Hand detected — confidence: \(observation.confidence)")
                    handPreviouslyDetected = true
                }

                lastFrame = frame
                onHandPose?(frame)
            } else {
                if handPreviouslyDetected {
                    Log.info("Hand lost after \(totalFramesProcessed) frames (\(framesWithHand) with hand)")
                    handPreviouslyDetected = false
                }
                lastFrame = nil
                onHandPose?(nil)
            }
        } catch {
            if handPreviouslyDetected {
                Log.warning("Vision request failed: \(error.localizedDescription)")
            }
            lastFrame = nil
            onHandPose?(nil)
        }
    }

    private func extractLandmarks(from observation: VNHumanHandPoseObservation) -> HandPoseFrame {
        var landmarks: [HandJoint: CGPoint] = [:]

        let jointMapping: [(HandJoint, VNHumanHandPoseObservation.JointName)] = [
            (.wrist, .wrist),
            (.thumbCMC, .thumbCMC),
            (.thumbMP, .thumbMP),
            (.thumbIP, .thumbIP),
            (.thumbTip, .thumbTip),
            (.indexMCP, .indexMCP),
            (.indexPIP, .indexPIP),
            (.indexDIP, .indexDIP),
            (.indexTip, .indexTip),
            (.middleMCP, .middleMCP),
            (.middlePIP, .middlePIP),
            (.middleDIP, .middleDIP),
            (.middleTip, .middleTip),
            (.ringMCP, .ringMCP),
            (.ringPIP, .ringPIP),
            (.ringDIP, .ringDIP),
            (.ringTip, .ringTip),
            (.littleMCP, .littleMCP),
            (.littlePIP, .littlePIP),
            (.littleDIP, .littleDIP),
            (.littleTip, .littleTip),
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

        let confidence = Float(observation.confidence)
        Log.debug("Landmarks extracted: \(landmarks.count)/21 joints, confidence: \(confidence)")

        return HandPoseFrame(
            timestamp: CACurrentMediaTime(),
            landmarks: landmarks,
            confidence: confidence
        )
    }
}
