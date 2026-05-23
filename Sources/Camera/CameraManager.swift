import AVFoundation
import Combine
import Foundation

final class CameraManager: NSObject, ObservableObject {

    enum CameraState: Equatable {
        case unauthorized
        case authorized
        case running
        case stopped
        case error(String)
    }

    @Published private(set) var state: CameraState = .stopped
    @Published private(set) var isPermissionGranted = false

    private(set) var session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.palmpilot.camera.session", qos: .userInitiated)
    private let frameOutputQueue = DispatchQueue(label: "com.palmpilot.camera.frames", qos: .userInitiated)

    private var videoDeviceInput: AVCaptureDeviceInput?
    private var videoOutput: AVCaptureVideoDataOutput?

    var onFrame: ((CMSampleBuffer) -> Void)?
    private(set) var isConfigured = false

    private var frameCount: UInt64 = 0
    private var lastFrameLog: UInt64 = 0

    // MARK: - Permission

    func requestPermission() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        Log.info("Camera permission status: \(status.rawValue)")

        switch status {
        case .authorized:
            await MainActor.run { isPermissionGranted = true }
            Log.info("Camera already authorized")
            return true
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            await MainActor.run { isPermissionGranted = granted }
            Log.info("Camera permission request result: \(granted)")
            return granted
        case .denied, .restricted:
            await MainActor.run { state = .unauthorized }
            Log.warning("Camera access denied or restricted")
            return false
        @unknown default:
            Log.warning("Unknown camera authorization status")
            return false
        }
    }

    // MARK: - Configuration

    func configure() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            Log.info("Starting camera configuration")

            self.session.beginConfiguration()
            self.session.sessionPreset = .hd1280x720

            guard let device = self.frontCamera ?? self.defaultCamera else {
                self.session.commitConfiguration()
                Log.error("No camera device found")
                Task { @MainActor in self.state = .error("No camera available") }
                return
            }

            Log.info("Selected camera: \(device.localizedName)")

            do {
                let input = try AVCaptureDeviceInput(device: device)
                guard self.session.canAddInput(input) else {
                    self.session.commitConfiguration()
                    Log.error("Cannot add camera input")
                    Task { @MainActor in self.state = .error("Cannot add camera input") }
                    return
                }
                self.session.addInput(input)
                self.videoDeviceInput = input

                try device.lockForConfiguration()
                device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 30)
                device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: 30)
                device.unlockForConfiguration()
                Log.info("Camera configured for 30 FPS")
            } catch {
                self.session.commitConfiguration()
                Log.error("Camera input setup failed: \(error.localizedDescription)")
                Task { @MainActor in self.state = .error("Camera setup failed: \(error.localizedDescription)") }
                return
            }

            let output = AVCaptureVideoDataOutput()
            output.alwaysDiscardsLateVideoFrames = true
            output.setSampleBufferDelegate(self, queue: self.frameOutputQueue)
            output.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
            ]

            guard self.session.canAddOutput(output) else {
                self.session.commitConfiguration()
                Log.error("Cannot add video output")
                Task { @MainActor in self.state = .error("Cannot add video output") }
                return
            }
            self.session.addOutput(output)
            self.videoOutput = output

            if let connection = output.connection(with: .video) {
                if #available(macOS 14.0, *) {
                    connection.videoRotationAngle = 0
                } else {
                    connection.videoOrientation = .portrait
                }
            }

            self.session.commitConfiguration()
            self.isConfigured = true
            self.frameCount = 0
            Log.info("Camera configuration complete")
        }
    }

    // MARK: - Session Control

    func start() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            guard self.isConfigured, !self.session.isRunning else {
                if !self.isConfigured {
                    Log.warning("start() deferred — camera not yet configured, retrying after configuration")
                }
                return
            }
            Log.info("Starting camera session")
            self.session.startRunning()
            Task { @MainActor in self.state = .running }
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            Log.info("Stopping camera session (frames captured: \(self.frameCount))")
            self.session.stopRunning()
            Task { @MainActor in self.state = .stopped }
        }
    }

    // MARK: - Device Selection

    private var frontCamera: AVCaptureDevice? {
        AVCaptureDevice.DiscoverySession(
            deviceTypes: [.external, .builtInWideAngleCamera],
            mediaType: .video,
            position: .front
        ).devices.first
    }

    private var defaultCamera: AVCaptureDevice? {
        AVCaptureDevice.default(for: .video)
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        frameCount += 1

        if frameCount % 300 == 0 {
            Log.debug("Frame captured: #\(frameCount)")
        }

        onFrame?(sampleBuffer)
    }
}
