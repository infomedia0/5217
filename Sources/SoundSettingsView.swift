import SwiftUI

struct SoundSettingsView: View {
    @ObservedObject var model: TimerModel
    @ObservedObject var sound: SoundController
    private var search: String { sound.searchText }
    private let accent = Color(red: 0.82, green: 0.96, blue: 0.44)
    private var filteredSounds: [SoundChoice] {
        guard !search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return sound.available }
        return sound.available.filter { $0.name.localizedCaseInsensitiveContains(search) || $0.group.localizedCaseInsensitiveContains(search) }
    }
    private var groups: [String] {
        var seen = Set<String>()
        return filteredSounds.map { $0.group }.filter { seen.insert($0).inserted }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Notification sound").font(.system(size: 22, weight: .semibold))
                Text("Choose a sound for Focus and Break alerts.")
                    .font(.system(size: 12)).foregroundColor(.secondary)
            }
            Toggle("Play sounds when a timer ends", isOn: Binding(get: { model.engine.soundEnabled }, set: { model.setSound($0) }))
                .toggleStyle(.switch).tint(accent)
            VStack(alignment: .leading, spacing: 6) {
                Text("Notification duration").font(.system(size: 12, weight: .medium))
                Picker("Notification duration", selection: Binding(get: { sound.durationSeconds }, set: { sound.setDuration($0) })) {
                    ForEach(SoundPreferences.durations, id: \.self) { seconds in
                        Text("\(seconds)s").tag(seconds)
                    }
                }.pickerStyle(.segmented).labelsHidden()
                Text("Sound stops at this limit; shorter tones finish naturally.")
                    .font(.system(size: 11)).foregroundColor(.secondary)
            }
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("SELECTED SOUND").font(.system(size: 9, weight: .semibold, design: .monospaced)).tracking(1.2).foregroundColor(.secondary)
                    Text(sound.selectedName).font(.system(size: 15, weight: .medium)).foregroundColor(accent)
                }
                Spacer()
                Button(action: sound.playSelected) { Label("Test sound", systemImage: "play.fill") }
                Button(action: sound.stop) { Image(systemName: "stop.fill") }
                    .disabled(!sound.isPlaying).help("Stop preview").accessibilityLabel("Stop sound preview")
            }
            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                TextField("Search sounds", text: $sound.searchText).textFieldStyle(.plain)
                    .accessibilityLabel("Search notification sounds")
                if !search.isEmpty {
                    Button { sound.searchText = "" } label: { Image(systemName: "xmark.circle.fill").foregroundColor(.secondary) }
                        .buttonStyle(.plain).accessibilityLabel("Clear sound search")
                }
            }.padding(10).background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 9))
            List {
                ForEach(groups, id: \.self) { group in
                    Section(group) {
                        ForEach(filteredSounds.filter { $0.group == group }) { choice in
                            HStack(spacing: 10) {
                                Button { sound.select(choice.id) } label: {
                                    HStack(spacing: 10) {
                                        Image(systemName: sound.selectedID == choice.id ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(sound.selectedID == choice.id ? accent : Color.secondary)
                                        Text(choice.name).foregroundColor(.primary)
                                        Spacer(minLength: 0)
                                    }.padding(.vertical, 6).contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Select \(choice.name), \(choice.group)\(sound.selectedID == choice.id ? ", selected" : "")")
                                Button { sound.preview(choice.id) } label: {
                                    Image(systemName: "play.circle").font(.system(size: 17)).foregroundColor(.secondary)
                                }.buttonStyle(.plain).help("Preview \(choice.name)")
                                    .accessibilityLabel("Preview \(choice.name), \(choice.group)")
                            }
                        }
                    }
                }
                if filteredSounds.isEmpty { Text("No sounds match your search.").foregroundColor(.secondary) }
            }
            .listStyle(.inset)
            .background(Color.white.opacity(0.025), in: RoundedRectangle(cornerRadius: 10))
            if let error = sound.errorMessage {
                Text(error).font(.system(size: 11)).foregroundColor(.orange)
            } else {
                Text("\(sound.available.count) sounds available on this Mac. Selecting a sound previews and saves it. Sounds follow your selected duration limit.")
                    .font(.system(size: 11)).foregroundColor(.secondary).fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(24).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(red: 0.075, green: 0.09, blue: 0.085))
        .preferredColorScheme(.dark)
        .onDisappear { sound.stop() }
    }
}
