import SwiftUI
import KeyboardShortcuts
import ServiceManagement

struct SettingsView: View {
    private enum Tab: Hashable {
        case general
        case about
    }

    @State private var selectedTab: Tab = .general

    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralTab()
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
                .tag(Tab.general)

            AboutTab()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
                .tag(Tab.about)
        }
        .frame(width: 350)
    }
}

struct GeneralTab: View {
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        Form {
            Section {
                LabeledContent("Keyboard shortcut") {
                    KeyboardShortcuts.Recorder(for: .toggleMenuBar)
                }

                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        do {
                            if newValue {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            print("Failed to update launch at login: \(error)")
                            launchAtLogin = SMAppService.mainApp.status == .enabled
                        }
                    }
            }
        }
        .formStyle(.grouped)
    }
}

struct AboutTab: View {
    private let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    private let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    var body: some View {
        VStack(spacing: 16) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 92, height: 92)

            VStack(spacing: 4) {
                Text("Whisker")
                    .font(.headline)

                Text("Version \(version) (\(build))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Link(destination: URL(string: "https://github.com/vandamd/whisker")!) {
                HStack(spacing: 4) {
                    GitHubIcon()
                        .frame(width: 14, height: 14)
                    Text("GitHub")
                        .foregroundStyle(Color.accentColor)
                }
            }
            .buttonStyle(.plain)
            .font(.subheadline)

            Text("Made with 💛 by Vandam and Claudius Maximus")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
    }
}

struct GitHubIcon: View {
    @Environment(\.controlActiveState) private var controlActiveState

    var body: some View {
        GitHubShape()
            .fill(controlActiveState == .inactive ? Color.secondary : Color.accentColor)
    }
}

struct GitHubShape: Shape {
    func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 16
        var path = Path()

        path.move(to: CGPoint(x: 8 * scale, y: 0))
        path.addCurve(
            to: CGPoint(x: 0, y: 8 * scale),
            control1: CGPoint(x: 3.58 * scale, y: 0),
            control2: CGPoint(x: 0, y: 3.58 * scale)
        )
        path.addCurve(
            to: CGPoint(x: 5.47 * scale, y: 15.59 * scale),
            control1: CGPoint(x: 0, y: 11.54 * scale),
            control2: CGPoint(x: 2.29 * scale, y: 14.53 * scale)
        )
        path.addCurve(
            to: CGPoint(x: 6.02 * scale, y: 15.21 * scale),
            control1: CGPoint(x: 5.87 * scale, y: 15.66 * scale),
            control2: CGPoint(x: 6.02 * scale, y: 15.42 * scale)
        )
        path.addCurve(
            to: CGPoint(x: 6.01 * scale, y: 13.72 * scale),
            control1: CGPoint(x: 6.02 * scale, y: 15.02 * scale),
            control2: CGPoint(x: 6.01 * scale, y: 14.39 * scale)
        )
        path.addCurve(
            to: CGPoint(x: 3.32 * scale, y: 12.78 * scale),
            control1: CGPoint(x: 4 * scale, y: 14.09 * scale),
            control2: CGPoint(x: 3.48 * scale, y: 13.23 * scale)
        )
        path.addCurve(
            to: CGPoint(x: 2.5 * scale, y: 11.65 * scale),
            control1: CGPoint(x: 3.23 * scale, y: 12.55 * scale),
            control2: CGPoint(x: 2.84 * scale, y: 11.84 * scale)
        )
        path.addCurve(
            to: CGPoint(x: 2.49 * scale, y: 11.12 * scale),
            control1: CGPoint(x: 2.22 * scale, y: 11.5 * scale),
            control2: CGPoint(x: 1.82 * scale, y: 11.13 * scale)
        )
        path.addCurve(
            to: CGPoint(x: 3.72 * scale, y: 11.94 * scale),
            control1: CGPoint(x: 3.12 * scale, y: 11.11 * scale),
            control2: CGPoint(x: 3.57 * scale, y: 11.7 * scale)
        )
        path.addCurve(
            to: CGPoint(x: 6.05 * scale, y: 12.6 * scale),
            control1: CGPoint(x: 4.44 * scale, y: 13.15 * scale),
            control2: CGPoint(x: 5.59 * scale, y: 12.81 * scale)
        )
        path.addCurve(
            to: CGPoint(x: 6.56 * scale, y: 11.53 * scale),
            control1: CGPoint(x: 6.12 * scale, y: 12.08 * scale),
            control2: CGPoint(x: 6.33 * scale, y: 11.73 * scale)
        )
        path.addCurve(
            to: CGPoint(x: 2.92 * scale, y: 7.58 * scale),
            control1: CGPoint(x: 4.78 * scale, y: 11.33 * scale),
            control2: CGPoint(x: 2.92 * scale, y: 10.64 * scale)
        )
        path.addCurve(
            to: CGPoint(x: 3.74 * scale, y: 5.43 * scale),
            control1: CGPoint(x: 2.92 * scale, y: 6.71 * scale),
            control2: CGPoint(x: 3.23 * scale, y: 5.99 * scale)
        )
        path.addCurve(
            to: CGPoint(x: 3.82 * scale, y: 3.31 * scale),
            control1: CGPoint(x: 3.66 * scale, y: 5.23 * scale),
            control2: CGPoint(x: 3.38 * scale, y: 4.41 * scale)
        )
        path.addCurve(
            to: CGPoint(x: 6.02 * scale, y: 4.13 * scale),
            control1: CGPoint(x: 3.82 * scale, y: 3.31 * scale),
            control2: CGPoint(x: 4.49 * scale, y: 3.1 * scale)
        )
        path.addCurve(
            to: CGPoint(x: 8.02 * scale, y: 3.86 * scale),
            control1: CGPoint(x: 6.66 * scale, y: 3.95 * scale),
            control2: CGPoint(x: 7.34 * scale, y: 3.86 * scale)
        )
        path.addCurve(
            to: CGPoint(x: 10.02 * scale, y: 4.13 * scale),
            control1: CGPoint(x: 8.7 * scale, y: 3.86 * scale),
            control2: CGPoint(x: 9.38 * scale, y: 3.95 * scale)
        )
        path.addCurve(
            to: CGPoint(x: 12.22 * scale, y: 3.31 * scale),
            control1: CGPoint(x: 11.55 * scale, y: 3.09 * scale),
            control2: CGPoint(x: 12.22 * scale, y: 3.31 * scale)
        )
        path.addCurve(
            to: CGPoint(x: 12.3 * scale, y: 5.43 * scale),
            control1: CGPoint(x: 12.66 * scale, y: 4.41 * scale),
            control2: CGPoint(x: 12.38 * scale, y: 5.23 * scale)
        )
        path.addCurve(
            to: CGPoint(x: 13.12 * scale, y: 7.58 * scale),
            control1: CGPoint(x: 12.81 * scale, y: 5.99 * scale),
            control2: CGPoint(x: 13.12 * scale, y: 6.7 * scale)
        )
        path.addCurve(
            to: CGPoint(x: 9.47 * scale, y: 11.53 * scale),
            control1: CGPoint(x: 13.12 * scale, y: 10.65 * scale),
            control2: CGPoint(x: 11.25 * scale, y: 11.33 * scale)
        )
        path.addCurve(
            to: CGPoint(x: 10.01 * scale, y: 13.01 * scale),
            control1: CGPoint(x: 9.76 * scale, y: 11.78 * scale),
            control2: CGPoint(x: 10.01 * scale, y: 12.26 * scale)
        )
        path.addCurve(
            to: CGPoint(x: 10 * scale, y: 15.21 * scale),
            control1: CGPoint(x: 10.01 * scale, y: 14.08 * scale),
            control2: CGPoint(x: 10 * scale, y: 14.94 * scale)
        )
        path.addCurve(
            to: CGPoint(x: 10.55 * scale, y: 15.59 * scale),
            control1: CGPoint(x: 10 * scale, y: 15.42 * scale),
            control2: CGPoint(x: 10.15 * scale, y: 15.67 * scale)
        )
        path.addCurve(
            to: CGPoint(x: 16 * scale, y: 8 * scale),
            control1: CGPoint(x: 13.71 * scale, y: 14.53 * scale),
            control2: CGPoint(x: 16 * scale, y: 11.53 * scale)
        )
        path.addCurve(
            to: CGPoint(x: 8 * scale, y: 0),
            control1: CGPoint(x: 16 * scale, y: 3.58 * scale),
            control2: CGPoint(x: 12.42 * scale, y: 0)
        )
        path.closeSubpath()

        return path.offsetBy(dx: (rect.width - 16 * scale) / 2, dy: (rect.height - 16 * scale) / 2)
    }
}

#Preview {
    SettingsView()
}
