import AppKit

/// Owns sound selection, preparation, persistence, and playback. The timer only
/// requests playback of the selected sound; system banners stay silent.
final class SoundController: NSObject, ObservableObject, NSSoundDelegate {
    @Published var searchText = ""
    @Published private(set) var selectedID = SoundChoice.chimeID
    @Published private(set) var selectedName = "5217 chime"
    @Published private(set) var errorMessage: String?
    @Published private(set) var isPlaying = false
    @Published private(set) var durationSeconds = 5
    private var stopTask: DispatchWorkItem?
    private var playbackID: UUID?
    let available: [SoundChoice]
    var onSelectionChange: (() -> Void)?
    private let paths: AppPaths
    private var prepared: PreparedNotificationSound?
    private var playingSound: NSSound?

    init(paths: AppPaths, bundle: Bundle = .main) {
        self.paths = paths
        let chime = (bundle.resourceURL ?? bundle.bundleURL).appendingPathComponent("TimerEnd.wav")
        available = SoundCatalog.discover(chimeURL: chime)
        super.init()
        let preference = SoundPreferences.load(from: paths.soundPreferences)
        durationSeconds = preference.durationSeconds
        let choice = available.first { $0.id == preference.selectedID } ?? available[0]
        do {
            prepared = try SoundPreparer.prepare(choice, directory: paths.notificationSounds)
            selectedID = choice.id
            selectedName = choice.name
        } catch {
            prepared = try? SoundPreparer.prepare(available[0], directory: paths.notificationSounds)
            errorMessage = "Your previous sound could not be loaded. Using the 5217 chime."
        }
    }

    func select(_ id: String) {
        guard let choice = available.first(where: { $0.id == id }) else { return }
        do {
            let sound = try SoundPreparer.prepare(choice, directory: paths.notificationSounds)
            try SoundPreferences(selectedID: id, durationSeconds: durationSeconds).save(to: paths.soundPreferences)
            prepared = sound
            selectedID = choice.id
            selectedName = choice.name
            errorMessage = nil
            onSelectionChange?()
            play(at: sound.url)
        } catch { errorMessage = "This sound could not be prepared or saved. Please try another." }
    }

    func setDuration(_ seconds: Int) {
        guard SoundPreferences.durations.contains(seconds), seconds != durationSeconds else { return }
        do {
            try SoundPreferences(selectedID: selectedID, durationSeconds: seconds).save(to: paths.soundPreferences)
            stop()
            durationSeconds = seconds
            errorMessage = nil
        } catch { errorMessage = "The duration could not be saved. Please try again." }
    }

    func preview(_ id: String) {
        guard let choice = available.first(where: { $0.id == id }) else { return }
        do { play(at: try SoundPreparer.prepare(choice, directory: paths.notificationSounds).url) }
        catch { errorMessage = "This sound could not be previewed. Please try another." }
    }

    func playSelected() {
        guard let prepared else { errorMessage = "Choose another sound in Settings."; return }
        play(at: prepared.url)
    }

    func stop() {
        stopTask?.cancel()
        stopTask = nil
        playbackID = nil
        playingSound?.stop()
        playingSound = nil
        isPlaying = false
    }

    private func play(at url: URL) {
        stop()
        guard let sound = NSSound(contentsOf: url, byReference: false) else {
            errorMessage = "This sound could not be loaded. Please try another."; return
        }
        playingSound = sound
        sound.delegate = self
        isPlaying = sound.play()
        errorMessage = isPlaying ? nil : "Check your Mac’s audio output."
        guard isPlaying else { return }
        let id = UUID()
        playbackID = id
        let task = DispatchWorkItem { [weak self] in
            guard let self, self.playbackID == id else { return }
            self.stop()
        }
        stopTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(durationSeconds), execute: task)
    }

    func sound(_ sound: NSSound, didFinishPlaying flag: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self, self.playingSound === sound else { return }
            self.stop()
        }
    }
}
