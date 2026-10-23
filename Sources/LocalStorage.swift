import Foundation
import Darwin

enum StorageError: Error { case invalidFile, tooLarge, writeFailed }

/// All JSON enters through a bounded, no-follow read and leaves through a
/// same-directory atomic rename of a newly created owner-only file.
enum LocalStorage {
    static func read(_ url: URL, limit: Int) throws -> Data {
        let descriptor = open(url.path, O_RDONLY | O_NOFOLLOW | O_NONBLOCK)
        guard descriptor >= 0 else { throw StorageError.invalidFile }
        defer { close(descriptor) }
        var metadata = stat()
        guard fstat(descriptor, &metadata) == 0, metadata.st_mode & S_IFMT == S_IFREG else { throw StorageError.invalidFile }
        guard metadata.st_size >= 0 && metadata.st_size <= limit else { throw StorageError.tooLarge }
        let handle = FileHandle(fileDescriptor: descriptor, closeOnDealloc: false)
        let data = try handle.read(upToCount: limit + 1) ?? Data()
        guard data.count <= limit else { throw StorageError.tooLarge }
        return data
    }

    static func load<T: Decodable>(_ type: T.Type, from url: URL, limit: Int) -> T? {
        guard let data = try? read(url, limit: limit) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    static func save<T: Encodable>(_ value: T, to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        let temporary = url.deletingLastPathComponent().appendingPathComponent(".5217-\(UUID().uuidString).json")
        let descriptor = open(temporary.path, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, 0o600)
        guard descriptor >= 0 else { throw StorageError.writeFailed }
        var committed = false
        defer {
            close(descriptor)
            if !committed { unlink(temporary.path) }
        }
        let data = try JSONEncoder().encode(value)
        let handle = FileHandle(fileDescriptor: descriptor, closeOnDealloc: false)
        try handle.write(contentsOf: data)
        try handle.synchronize()
        guard rename(temporary.path, url.path) == 0 else { throw StorageError.writeFailed }
        committed = true
    }
}

struct AppPaths {
    let directory: URL
    let notificationSounds: URL
    static var standard: AppPaths {
        AppPaths(directory: FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("5217", isDirectory: true),
            notificationSounds: FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0].appendingPathComponent("Sounds", isDirectory: true))
    }
    var timer: URL { directory.appendingPathComponent("timer.json") }
    var soundPreferences: URL { directory.appendingPathComponent("sound-settings.json") }
}

struct NotificationDeliveryState {
    private(set) var requestID: String?
    private(set) var failed = false
    mutating func begin() -> String {
        let id = "5217-\(UUID().uuidString)"
        requestID = id
        failed = false
        return id
    }
    @discardableResult mutating func cancel() -> String? {
        let old = requestID
        requestID = nil
        failed = false
        return old
    }
    @discardableResult mutating func complete(id: String, failed: Bool) -> Bool {
        guard requestID == id else { return false }
        self.failed = failed
        return true
    }
}
