import SwiftUI

struct MenuBarView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            statusSection
            Divider()
            controlsSection
            Divider()
            Button(action: { NSApplication.shared.terminate(nil) }) {
                HStack {
                    Image(systemName: "power")
                    Text("Quit Palm Pilot")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .padding(.vertical, 2)
        }
        .padding()
        .frame(width: 240)
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                Text(statusLabel)
                    .font(.headline)
            }

            if let gesture = viewModel.currentGesture, gesture != .unknown {
                HStack(spacing: 4) {
                    Image(systemName: gesture.symbolName)
                        .font(.caption)
                    Text(gesture.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 2)
            }
        }
    }

    private var controlsSection: some View {
        VStack(spacing: 4) {
            Button(action: viewModel.toggleTracking) {
                HStack {
                    Image(systemName: viewModel.isTracking ? "stop.fill" : "play.fill")
                    Text(viewModel.isTracking ? "Stop Tracking" : "Start Tracking")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .padding(.vertical, 2)

            Button(action: { openWindow(id: "settings") }) {
                HStack {
                    Image(systemName: "gearshape")
                    Text("Settings")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .padding(.vertical, 2)
        }
    }

    private var statusColor: Color {
        switch viewModel.cameraState {
        case .running: return .green
        case .unauthorized: return .red
        case .error: return .orange
        default: return .gray
        }
    }

    private var statusLabel: String {
        switch viewModel.cameraState {
        case .running: return "Active"
        case .unauthorized: return "Camera Denied"
        case .error: return "Error"
        case .stopped, .authorized: return "Idle"
        }
    }
}
