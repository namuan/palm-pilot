import SwiftUI
import AVFoundation
import Combine
import AppKit

final class AppViewModel: ObservableObject {

    @Published var cameraState: CameraManager.CameraState = .stopped
    @Published var isTracking = false
    @Published var currentGesture: Gesture?
    @Published var landmarks: [HandJoint: CGPoint] = [:]
    @Published var actionMappings: [ActionMapping] = ActionMapping.defaults

    let cameraManager = CameraManager()
    var cameraSession: AVCaptureSession { cameraManager.session }
    private let handPoseDetector = HandPoseDetector()
    private let gestureClassifier = GestureClassifier()
    private let motionTracker = MotionTracker()
    private let actionDispatcher = ActionDispatcher()

    private let processingQueue = DispatchQueue(label: "com.palmpilot.processing", qos: .userInitiated)
    private let mappingStoreKey = "com.palmpilot.actionMappings"
    private var previousGesture: Gesture = .unknown
    private var handPresent = false
    private var previewWindow: NSWindow?
    private var onboardingWindow: NSWindow?

    init() {
        Log.info("AppViewModel initializing")
        loadMappings()
        setupPipeline()
        observeCameraState()
        observePreviewLifecycle()
        Log.info("AppViewModel initialized. Mappings loaded: \(actionMappings.count)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.checkAndShowOnboardingIfNeeded()
        }
    }

    deinit {
        Log.info("AppViewModel deallocating")
    }

    // MARK: - Pipeline Wiring

    private func setupPipeline() {
        Log.info("Setting up processing pipeline")

        handPoseDetector.onHandPose = { [weak self] frame in
            self?.processingQueue.async {
                self?.processPipeline(frame: frame)
            }
        }

        cameraManager.onFrame = { [weak self] sampleBuffer in
            self?.handPoseDetector.processFrame(sampleBuffer)
        }

        Log.info("Pipeline wired: Camera → Vision → Classifier → Motion → Actions")
    }

    private func observeCameraState() {
        cameraManager.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newState in
                Log.info("Camera state: \(newState)")
                self?.cameraState = newState
            }
            .store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Frame Processing

    private func processPipeline(frame: HandPoseFrame?) {
        let staticGesture = gestureClassifier.classify(frame)
        let finalGesture = motionTracker.process(frame: frame, staticGesture: staticGesture)

        let isHandNow = (frame != nil && frame!.landmarks.count >= 15)
        if isHandNow != handPresent {
            handPresent = isHandNow
            if isHandNow {
                Log.info("Hand entered frame")
            } else {
                Log.info("Hand left frame — gesture reset to unknown")
            }
        }

        let frameLandmarks = frame?.landmarks ?? [:]

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.landmarks = frameLandmarks
            if finalGesture != .unknown || self.currentGesture == nil {
                self.currentGesture = finalGesture
            }
        }

        if finalGesture != .unknown && finalGesture != previousGesture {
            Log.info("Pipeline result: \(finalGesture.rawValue)")
            previousGesture = finalGesture

            let mappings = currentMappingsSnapshot()
            actionDispatcher.dispatch(finalGesture, mappings: mappings)
        } else if finalGesture == .unknown && previousGesture != .unknown {
            previousGesture = .unknown
        }
    }

    private func currentMappingsSnapshot() -> [ActionMapping] {
        var mappings: [ActionMapping] = []
        let semaphore = DispatchSemaphore(value: 0)
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            mappings = self.actionMappings
            semaphore.signal()
        }
        semaphore.wait()
        return mappings
    }

    // MARK: - Controls

    func toggleTracking() {
        Log.info("Toggle tracking (currently: \(isTracking))")
        if isTracking {
            stopTracking()
        } else {
            startTracking()
        }
    }

    func startTracking() {
        Log.info("Starting tracking session")

        Task {
            let granted = await cameraManager.requestPermission()
            guard granted else {
                Log.warning("Tracking start aborted — camera permission denied")
                await MainActor.run { self.cameraState = .unauthorized }
                return
            }

            Log.info("Configuring and starting camera")
            cameraManager.configure()
            cameraManager.start()
            await MainActor.run { self.isTracking = true }
            Log.info("Tracking session active")
        }
    }

    func stopTracking() {
        Log.info("Stopping tracking session")
        cameraManager.stop()
        isTracking = false
        currentGesture = nil
        landmarks = [:]
        previousGesture = .unknown
        handPresent = false
        Log.info("Tracking session stopped")
    }

    // MARK: - Preview Window

    private func observePreviewLifecycle() {
        $isTracking
            .receive(on: DispatchQueue.main)
            .sink { [weak self] tracking in
                if tracking {
                    self?.showPreview()
                } else {
                    self?.hidePreview()
                }
            }
            .store(in: &cancellables)
    }

    private func showPreview() {
        if let existing = previewWindow {
            existing.makeKeyAndOrderFront(nil)
            NSApplication.shared.activate(ignoringOtherApps: true)
            return
        }
        Log.info("Opening camera preview window")

        let hostingView = NSHostingView(
            rootView: _PreviewHost(viewModel: self)
        )

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 360),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Camera Preview"
        window.titlebarAppearsTransparent = true
        window.contentView = hostingView
        window.isReleasedWhenClosed = false
        window.center()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(previewWindowWillClose),
            name: NSWindow.willCloseNotification,
            object: window
        )

        window.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
        previewWindow = window
    }

    @objc private func previewWindowWillClose(_ notification: Notification) {
        Log.info("Preview window closed by user")
        guard let window = notification.object as? NSWindow else { return }
        NotificationCenter.default.removeObserver(self, name: NSWindow.willCloseNotification, object: window)
        previewWindow?.contentView = nil
        previewWindow = nil
        if isTracking {
            stopTracking()
        }
    }

    private func hidePreview() {
        guard let window = previewWindow else { return }
        Log.info("Closing camera preview window")
        NotificationCenter.default.removeObserver(self, name: NSWindow.willCloseNotification, object: window)
        window.contentView = nil
        window.close()
        previewWindow = nil
    }

    // MARK: - Onboarding

    private func checkAndShowOnboardingIfNeeded() {
        let cameraAuthorized = AVCaptureDevice.authorizationStatus(for: .video) == .authorized
        let accessibilityTrusted = AXIsProcessTrusted()

        if !cameraAuthorized || !accessibilityTrusted {
            Log.info("Permissions missing — showing onboarding (camera: \(cameraAuthorized), accessibility: \(accessibilityTrusted))")
            showOnboarding()
        }
    }

    private func showOnboarding() {
        if let existing = onboardingWindow {
            existing.makeKeyAndOrderFront(nil)
            NSApplication.shared.activate(ignoringOtherApps: true)
            return
        }
        Log.info("Opening onboarding window")

        let hostingView = NSHostingView(
            rootView: OnboardingView { [weak self] in
                self?.dismissOnboarding()
            }
        )

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 480),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Welcome"
        window.titlebarAppearsTransparent = true
        window.contentView = hostingView
        window.isReleasedWhenClosed = false
        window.center()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onboardingWindowWillClose),
            name: NSWindow.willCloseNotification,
            object: window
        )

        window.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
        onboardingWindow = window
    }

    @objc private func onboardingWindowWillClose(_ notification: Notification) {
        Log.info("Onboarding window closed by user")
        guard let window = notification.object as? NSWindow else { return }
        NotificationCenter.default.removeObserver(self, name: NSWindow.willCloseNotification, object: window)
        onboardingWindow?.contentView = nil
        onboardingWindow = nil
    }

    private func dismissOnboarding() {
        guard let window = onboardingWindow else { return }
        Log.info("Dismissing onboarding window")
        NotificationCenter.default.removeObserver(self, name: NSWindow.willCloseNotification, object: window)
        window.contentView = nil
        window.close()
        onboardingWindow = nil
    }

    // MARK: - Persistence

    private func loadMappings() {
        let decoder = JSONDecoder()
        guard let data = UserDefaults.standard.data(forKey: mappingStoreKey),
              let mappings = try? decoder.decode([ActionMapping].self, from: data) else {
            Log.info("No saved mappings found, using defaults")
            return
        }
        actionMappings = mappings
        Log.info("Loaded \(mappings.count) action mappings from UserDefaults")
    }

    func saveMappings() {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(actionMappings) else {
            Log.error("Failed to encode action mappings")
            return
        }
        UserDefaults.standard.set(data, forKey: mappingStoreKey)
        Log.info("Saved \(actionMappings.count) action mappings to UserDefaults")
    }
}

fileprivate struct _PreviewHost: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        CameraPreviewView(
            session: viewModel.cameraSession,
            landmarks: viewModel.landmarks,
            showOverlay: true
        )
        .ignoresSafeArea()
    }
}
