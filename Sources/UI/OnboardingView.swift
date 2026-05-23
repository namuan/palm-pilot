import SwiftUI
import AVFoundation
import AppKit

struct OnboardingView: View {
    let onDismiss: () -> Void

    @State private var cameraGranted = false
    @State private var cameraStatus: AVAuthorizationStatus = .notDetermined
    @State private var accessibilityGranted = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Image(systemName: "hand.raised")
                    .font(.system(size: 48))
                    .foregroundColor(.accentColor)

                Text("Welcome to Palm Pilot")
                    .font(.title)
                    .fontWeight(.bold)

                Text("To control your Mac with hand gestures, Palm Pilot needs a few permissions. All processing is done entirely on-device — nothing ever leaves your Mac.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 12) {
                PermissionRow(
                    icon: "camera.fill",
                    title: "Camera Access",
                    description: "Used to detect your hand gestures in real time.",
                    granted: cameraGranted,
                    action: {
                        if cameraStatus == .notDetermined {
                            Task { await AVCaptureDevice.requestAccess(for: .video) }
                        } else {
                            openSystemPrefs(pane: "Privacy_Camera")
                        }
                    }
                )

                PermissionRow(
                    icon: "accessibility",
                    title: "Accessibility Access",
                    description: "Needed to send keyboard shortcuts and system actions when you make gestures.",
                    granted: accessibilityGranted,
                    action: {
                        openSystemPrefs(pane: "Privacy_Accessibility")
                    }
                )
            }

            Spacer()

            VStack(spacing: 8) {
                if cameraGranted && accessibilityGranted {
                    Button("Get Started") {
                        onDismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                } else {
                    let missing: [String] = [
                        cameraGranted ? nil : "Camera",
                        accessibilityGranted ? nil : "Accessibility",
                    ].compactMap { $0 }

                    Text("Grant \(missing.joined(separator: " and ")) permission to continue")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Button("Skip for now") {
                    onDismiss()
                }
                .buttonStyle(.link)
                .foregroundColor(.secondary)
                .font(.caption)
            }
        }
        .padding(32)
        .frame(width: 420, height: 480)
        .onReceive(timer) { _ in
            refreshPermissions()
        }
        .onAppear {
            refreshPermissions()
        }
    }

    private func refreshPermissions() {
        let camStatus = AVCaptureDevice.authorizationStatus(for: .video)
        cameraStatus = camStatus
        cameraGranted = (camStatus == .authorized)
        accessibilityGranted = AXIsProcessTrusted()
    }

    private func openSystemPrefs(pane: String) {
        let urlString = "x-apple.systempreferences:com.apple.preference.security?\(pane)"
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
}

private struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String
    let granted: Bool
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .frame(width: 28)
                .foregroundColor(granted ? .green : .secondary)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            if granted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title3)
            } else {
                Button("Enable") {
                    action()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(granted ? Color.green.opacity(0.06) : Color.secondary.opacity(0.06))
        )
    }
}
