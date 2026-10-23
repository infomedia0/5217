import Foundation
import AVFoundation
import CryptoKit
import Darwin

struct SoundChoice: Identifiable, Hashable {
    let id: String
    let name: String
    let group: String
    let url: URL
    static let chimeID = "5217-chime"
}

struct SoundPreferences: Codable {
    static let durations = [1, 5, 10, 15]
    var selectedID: String
    var durationSeconds: Int

    init(selectedID: String = SoundChoice.chimeID, durationSeconds: Int = 5) {
        self.selectedID = selectedID
        self.durationSeconds = Self.durations.contains(durationSeconds) ? durationSeconds : 5
    }
    private enum CodingKeys: String, CodingKey { case selectedID, durationSeconds }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let id = try values.decodeIfPresent(String.self, forKey: .selectedID) ?? SoundChoice.chimeID
        let duration = (try? values.decode(Int.self, forKey: .durationSeconds)) ?? 5
        self.init(selectedID: id, durationSeconds: duration)
    }

    static func load(from url: URL) -> SoundPreferences {
        LocalStorage.load(Self.self, from: url, limit: 4096) ?? Self()
    }

    func save(to url: URL) throws {
        try LocalStorage.save(self, to: url)
    }
}

enum SoundCatalog {
    static let systemRoot = URL(fileURLWithPath: "/System/Library/Sounds", isDirectory: true)
    static let toneRoot = URL(fileURLWithPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources", isDirectory: true)

    /// Uses public file and audio APIs only. Additional Apple tone resources are
    /// optional: their location and availability vary across macOS versions.
    static func discover(chimeURL: URL, system: URL = systemRoot, tones: URL = toneRoot) -> [SoundChoice] {
        var result = [SoundChoice(id: SoundChoice.chimeID, name: "5217 chime", group: "5217", url: chimeURL)]
        let systemNames = labels(URL(fileURLWithPath: "/System/Library/ExtensionKit/Extensions/Sound.appex/Contents/Resources/AlertSounds.loctable"))
        result += files(in: system).map { file in
            let key = file.deletingPathExtension().lastPathComponent
            return SoundChoice(id: "mac-alert/\(file.lastPathComponent)", name: systemNames[key] ?? key, group: "Mac alert sounds", url: file)
        }.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        let standardNames = labels(tones.appendingPathComponent("TL.loctable"))
        let modernNames = labels(tones.appendingPathComponent("TL-EncoreInfinitum.loctable"))
        let remixNames = labels(tones.appendingPathComponent("TL-EncoreRemix.loctable"))
        for (folder, group, keyPrefix) in [
            ("AlertTones/EncoreInfinitum", "Alert tones", "texttone:"),
            ("AlertTones/Modern", "Modern alert tones", "texttone:"),
            ("AlertTones/Classic", "Classic alert tones", "texttone:"),
            ("Ringtones/EncoreInfinitum", "Ringtones", "system:"),
            ("Ringtones/EncoreRemix", "Ringtones · alternate", "system:"),
            ("Ringtones/Modern", "Modern ringtones", "system:"),
            ("Ringtones/Classic", "Classic ringtones", "system:")
        ] {
            let extraNames = folder.contains("EncoreRemix") ? remixNames : modernNames
            let choices = files(in: tones.appendingPathComponent(folder)).map { file -> SoundChoice in
                let stem = file.deletingPathExtension().lastPathComponent
                let key = stem.components(separatedBy: "-Encore")[0]
                let name = extraNames[keyPrefix + key] ?? standardNames[keyPrefix + key] ?? key
                return SoundChoice(id: "apple-tone/\(folder)/\(file.lastPathComponent)", name: name, group: group, url: file)
            }
            result += choices.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        }
        // Older macOS versions may keep ringtones directly in the root folder.
        result += files(in: tones.appendingPathComponent("Ringtones")).map { file in
            let stem = file.deletingPathExtension().lastPathComponent
            let key = stem.components(separatedBy: "-Encore")[0]
            let extraNames = stem.contains("EncoreRemix") ? remixNames : modernNames
            return SoundChoice(id: "apple-tone/Ringtones/\(file.lastPathComponent)", name: extraNames["system:" + key] ?? standardNames["system:" + key] ?? key, group: "Ringtones", url: file)
        }.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        return result
    }

    private static func files(in directory: URL) -> [URL] {
        let allowed: Set<String> = ["aiff", "aif", "wav", "caf", "m4r", "m4a"]
        return ((try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.isRegularFileKey, .isSymbolicLinkKey])) ?? []).filter {
            let values = try? $0.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey])
            return allowed.contains($0.pathExtension.lowercased()) && values?.isRegularFile == true && values?.isSymbolicLink == false
        }
    }

    private static func labels(_ url: URL) -> [String: String] {
        guard let data = try? LocalStorage.read(url, limit: 524_288),
              let table = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else { return [:] }
        for language in Locale.preferredLanguages + ["en"] {
            if let dictionary = table[language] as? [String: String] { return dictionary }
            if let dictionary = table[String(language.prefix(2))] as? [String: String] { return dictionary }
        }
        return [:]
    }
}

struct PreparedNotificationSound {
    let url: URL
    var filename: String { url.lastPathComponent }
}

enum SoundPreparationError: Error { case unsupportedAudio, emptyAudio }

enum SoundPreparer {
    /// PCM CAF is accepted by UserNotifications and NSSound. Apple assets stay
    /// on the user's Mac; a local notification copy is prepared only when used.
    static func prepare(_ choice: SoundChoice, directory: URL) throws -> PreparedNotificationSound {
        if choice.id == SoundChoice.chimeID {
            guard FileManager.default.fileExists(atPath: choice.url.path) else { throw SoundPreparationError.emptyAudio }
            return PreparedNotificationSound(url: choice.url)
        }
        let values = try choice.url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey, .isRegularFileKey, .isSymbolicLinkKey])
        guard values.isRegularFile == true, values.isSymbolicLink == false else { throw SoundPreparationError.unsupportedAudio }
        let identity = "pcm-v1|\(choice.id)|\(values.fileSize ?? 0)|\(values.contentModificationDate?.timeIntervalSince1970 ?? 0)"
        let hash = SHA256.hash(data: Data(identity.utf8)).map { String(format: "%02x", $0) }.joined()
        let target = directory.appendingPathComponent("5217-\(hash.prefix(24)).caf")
        if validCache(target) {
            return PreparedNotificationSound(url: target)
        }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let source = try AVAudioFile(forReading: choice.url)
        let format = source.processingFormat
        guard (1...2).contains(format.channelCount), (8000...192000).contains(format.sampleRate) else { throw SoundPreparationError.unsupportedAudio }
        let limit = min(source.length, AVAudioFramePosition(format.sampleRate * 29))
        guard limit > 0 else { throw SoundPreparationError.emptyAudio }
        let temporary = directory.appendingPathComponent(".5217-\(UUID().uuidString).caf")
        let descriptor = open(temporary.path, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, 0o600)
        guard descriptor >= 0 else { throw StorageError.writeFailed }
        close(descriptor)
        do {
            // Match the input processing format for writes, and encode 16-bit PCM.
            let settings: [String: Any] = [AVFormatIDKey: kAudioFormatLinearPCM,
                AVSampleRateKey: format.sampleRate, AVNumberOfChannelsKey: format.channelCount,
                AVLinearPCMBitDepthKey: 16, AVLinearPCMIsFloatKey: false,
                AVLinearPCMIsBigEndianKey: false, AVLinearPCMIsNonInterleaved: false]
            do {
                let output = try AVAudioFile(forWriting: temporary, settings: settings, commonFormat: format.commonFormat, interleaved: format.isInterleaved)
                guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 8192) else { throw SoundPreparationError.unsupportedAudio }
                var written: AVAudioFramePosition = 0
                while written < limit {
                    try source.read(into: buffer, frameCount: AVAudioFrameCount(min(8192, limit - written)))
                    guard buffer.frameLength > 0 else { break }
                    try output.write(from: buffer)
                    written += AVAudioFramePosition(buffer.frameLength)
                }
                guard written > 0 else { throw SoundPreparationError.emptyAudio }
            }
            guard rename(temporary.path, target.path) == 0 else { throw StorageError.writeFailed }
        } catch {
            try? FileManager.default.removeItem(at: temporary)
            throw error
        }
        return PreparedNotificationSound(url: URL(fileURLWithPath: target.path))
    }

    private static func validCache(_ url: URL) -> Bool {
        guard let values = try? url.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey, .fileSizeKey]),
              values.isRegularFile == true, values.isSymbolicLink == false,
              let size = values.fileSize, size <= 24 * 1024 * 1024,
              let file = try? AVAudioFile(forReading: url), file.length > 0 else { return false }
        let format = file.fileFormat
        let description = format.streamDescription.pointee
        return description.mFormatID == kAudioFormatLinearPCM && description.mBitsPerChannel == 16 &&
            (1...2).contains(format.channelCount) && (8000...192000).contains(format.sampleRate) &&
            Double(file.length) / format.sampleRate <= 29.001
    }
}
