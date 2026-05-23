import SwiftUI
import AVFoundation

struct SettingsView: View {
    @ObservedObject var viewModel: AppViewModel

    @State private var selectedTab = "mappings"

    var body: some View {
        TabView(selection: $selectedTab) {
            cameraTab
                .tabItem {
                    Label("Camera", systemImage: "camera")
                }
                .tag("camera")

            mappingsTab
                .tabItem {
                    Label("Actions", systemImage: "hand.draw")
                }
                .tag("mappings")

            aboutTab
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
                .tag("about")
        }
        .frame(width: 480, height: 420)
    }

    // MARK: - Camera Tab

    private var cameraTab: some View {
        VStack(spacing: 16) {
            ZStack {
                if viewModel.cameraState == .running {
                    CameraPreviewView(
                        session: viewModel.cameraSession,
                        landmarks: viewModel.landmarks,
                        showOverlay: true
                    )
                    .aspectRatio(4 / 3, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.black.opacity(0.8))
                        .aspectRatio(4 / 3, contentMode: .fit)
                        .overlay(
                            Image(systemName: "video.slash")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                        )
                }
            }
            .frame(maxHeight: 240)

            HStack {
                if let gesture = viewModel.currentGesture {
                    Label(gesture.displayName, systemImage: gesture.symbolName)
                        .font(.headline)
                        .foregroundColor(gesture != .unknown ? .green : .secondary)
                } else {
                    Label("No hand detected", systemImage: "questionmark")
                        .foregroundColor(.secondary)
                }
            }

            Text("Offline Processing Guaranteed")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.green.opacity(0.1))
                )
        }
        .padding()
    }

    // MARK: - Mappings Tab

    private var mappingsTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Gesture -> Action Mappings")
                .font(.headline)

            ForEach($viewModel.actionMappings) { $mapping in
                HStack {
                    Image(systemName: Gesture(rawValue: mapping.gesture)?.symbolName ?? "questionmark")
                        .frame(width: 24)
                    Text(mapping.gesture.displayName)
                        .frame(width: 100, alignment: .leading)
                    Image(systemName: "arrow.right")
                        .foregroundColor(.secondary)
                    Text(mapping.label)
                        .frame(width: 150, alignment: .leading)
                    Toggle("", isOn: $mapping.enabled)
                        .toggleStyle(.switch)
                        .labelsHidden()
                }
                .padding(.vertical, 4)
            }

            Spacer()

            Text("Accessibility permissions needed to simulate keyboard shortcuts")
                .font(.caption)
                .foregroundColor(.secondary)

            Button("Open Accessibility Settings") {
                openAccessibilitySettings()
            }
            .font(.caption)
            .buttonStyle(.link)
        }
        .padding()
    }

    // MARK: - About Tab

    private var aboutTab: some View {
        VStack(spacing: 16) {
            Image(systemName: "hand.raised")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)
                .padding(.top, 24)

            Text("Palm Pilot")
                .font(.title)
                .fontWeight(.bold)

            Text("Control your Mac with hand gestures")
                .font(.subheadline)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                privacyItem(icon: "checkmark.shield", text: "100% offline — no data leaves your Mac")
                privacyItem(icon: "eye.slash", text: "No analytics, no telemetry")
                privacyItem(icon: "trash.slash", text: "No frame storage or recording")
                privacyItem(icon: "cpu", text: "Optimized for Apple Silicon")
            }
            .padding(.top, 12)

            Spacer()
        }
        .padding()
    }

    private func privacyItem(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .frame(width: 20)
            Text(text)
                .font(.caption)
        }
    }

    private func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}

private extension String {
    var displayName: String {
        switch self {
        case "openPalm": return "Open Palm"
        case "fist": return "Fist"
        case "thumbsUp": return "Thumbs Up"
        case "peaceSign": return "Peace Sign"
        case "swipeLeft": return "Swipe Left"
        case "swipeRight": return "Swipe Right"
        default: return self
        }
    }
}
