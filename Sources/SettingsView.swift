import SwiftUI

/// The installed bundle is the single source of truth for displayed version numbers.
enum AppVersion {
    static var current: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown" }
    static var build: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown" }
}

struct ReleaseNote: Identifiable {
    let version: String
    let summary: String
    var id: String { version }

    static let history: [ReleaseNote] = [
        .init(version: "2.4.7", summary: "Simplified Settings with equal-width tabs and shared navigation, moved version details to About, and added Built by Arjun Sabharwal."),
        .init(version: "2.4.6", summary: "Added Hide/Show quotes with a compact timer window. Quotes open expanded by default on every launch."),
        .init(version: "2.4.5", summary: "Added 1/5/10/15-second sound limits, expanded About with reading links, and clarified how to quit."),
        .init(version: "2.4.4", summary: "Improved Focus and Break quote filtering, retained separate online collections, and moved the footer slightly lower."),
        .init(version: "2.4.3", summary: "Stop beside Skip: first click silences alerts; second opens an integrated stop confirmation. Timer audio is now app-controlled. Added About in Settings."),
        .init(version: "2.4.2", summary: "Removed the header status dot and the Make room to focus / In your rhythm / On pause messages for a simpler header."),
        .init(version: "2.4.1", summary: "Settings and focus history now open inside the main app window with Back navigation, without separate sheets. History is now below the sound control."),
        .init(version: "2.4", summary: "Focus session history with a calendar-week graph, daily and weekly hours/minutes, and local monthly JSON archives."),
        .init(version: "2.3.4", summary: "Removed the duplicate Test sound button from the main screen. Sound previews remain available in Settings."),
        .init(version: "2.3.3", summary: "Fixed the initial Settings layout and made both tabs use a stable shared content area."),
        .init(version: "2.3.2", summary: "Current version and build number in Settings, plus release history."),
        .init(version: "2.3.1", summary: "Security audit: bounded downloads, safer saved data and sound caches, hardened runtime, and clearer sound and storage modules."),
        .init(version: "2.3", summary: "Searchable sound settings with installed Mac alert tones, previews, and a saved notification sound."),
        .init(version: "2.2", summary: "Online quotes from ZenQuotes with daily refresh, local caching, and offline fallback."),
        .init(version: "2.1", summary: "Test sound button beside the sound control to preview the timer-end sound."),
        .init(version: "2.0", summary: "15 quotes each for Focus and Rest, automatic rotation, and a Next quote button."),
        .init(version: "1.0", summary: "Native Apple silicon app: repeating 52-minute focus and 17-minute break timers, notifications, sound, menu bar controls, and local session history.")
    ]
}

enum SettingsTab: String, CaseIterable, Identifiable {
    case sounds = "Sounds", history = "Releases", about = "About"
    var id: Self { self }
}

struct SettingsView: View {
    @ObservedObject var model: TimerModel
    @ObservedObject var sound: SoundController

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Settings").font(.system(size: 25, weight: .semibold))
                Spacer()
                Button {
                    sound.stop()
                    model.screen = .timer
                } label: {
                    Label("Timer", systemImage: "chevron.left")
                        .font(.system(size: 12, weight: .medium))
                }
                .keyboardShortcut(.cancelAction)
                .help("Return to the timer")
                .accessibilityLabel("Back to timer")
            }.padding(.horizontal, 24).padding(.top, 22)
            HStack(spacing: 4) {
                ForEach(SettingsTab.allCases) { tab in
                    Button { model.settingsTab = tab } label: {
                        Text(tab.rawValue)
                            .font(.system(size: 12, weight: .medium))
                            .frame(maxWidth: .infinity).padding(.vertical, 8)
                            .foregroundColor(model.settingsTab == tab ? Color(red: 0.82, green: 0.96, blue: 0.44) : .secondary)
                            .background(model.settingsTab == tab ? Color.white.opacity(0.09) : .clear,
                                in: RoundedRectangle(cornerRadius: 7))
                            .contentShape(Rectangle())
                    }.buttonStyle(.plain)
                        .accessibilityAddTraits(model.settingsTab == tab ? .isSelected : [])
                }
            }
            .padding(4)
            .background(Color.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 24)

            // Both sections fill one stable content rectangle from the first render.
            // Avoid nesting fixed-size panes inside a size-negotiating native TabView.
            Group {
                if model.settingsTab == .sounds {
                    SoundSettingsView(model: model, sound: sound)
                } else if model.settingsTab == .about {
                    AboutView(model: model)
                } else {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Version history").font(.system(size: 22, weight: .semibold))
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            ForEach(ReleaseNote.history) { release in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text("Version \(release.version)").font(.headline)
                                        if release.version == AppVersion.current {
                                            Text("CURRENT").font(.caption.bold()).foregroundColor(.green)
                                        }
                                    }
                                    Text(release.summary).font(.system(size: 13))
                                        .foregroundColor(.secondary).fixedSize(horizontal: false, vertical: true)
                                }
                                Divider()
                            }
                        }.frame(maxWidth: .infinity, alignment: .leading)
                    }
                }.padding(24)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(red: 0.075, green: 0.09, blue: 0.085))
        .preferredColorScheme(.dark)
    }
}
