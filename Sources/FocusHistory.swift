import Foundation

struct FocusSession: Codable, Identifiable, Equatable {
    let completedAt: Date
    var id: Date { completedAt }
    var minutes: Int { 52 }
}

struct FocusDay: Identifiable {
    let date: Date
    let count: Int
    var id: Date { date }
    var minutes: Int { count * 52 }
}

enum FocusHistorySummary {
    static var calendar: Calendar {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = .current
        return calendar
    }
    static func duration(_ minutes: Int) -> String {
        let hours = minutes / 60, rest = minutes % 60
        return hours > 0 ? "\(hours)h \(rest)m" : "\(rest)m"
    }
    static func days(containing date: Date, sessions: [FocusSession], calendar: Calendar = calendar) -> [FocusDay] {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: date) else { return [] }
        return (0..<7).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: week.start),
                  let interval = calendar.dateInterval(of: .day, for: day) else { return nil }
            return FocusDay(date: day, count: sessions.filter { $0.completedAt >= interval.start && $0.completedAt < interval.end }.count)
        }
    }
}

/// One small JSON array per UTC month; records are never aged out.
/// Failed or malformed reads throw rather than silently overwrite existing history.
final class FocusHistoryStore {
    private let directory: URL
    private(set) var sessions: [FocusSession] = []
    private var pendingMonths = Set<String>()
    init(directory: URL, now: Date = Date()) throws {
        self.directory = directory
        if FileManager.default.fileExists(atPath: directory.path) {
            let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            for file in files where file.pathExtension == "json" {
                guard file.lastPathComponent.range(of: #"^\d{4}-\d{2}\.json$"#, options: .regularExpression) != nil else { continue }
                let data = try LocalStorage.read(file, limit: 1_048_576)
                let records = try JSONDecoder().decode([FocusSession].self, from: data)
                guard records.count <= 1000, records.allSatisfy({
                    $0.completedAt.timeIntervalSinceReferenceDate.isFinite && $0.completedAt.timeIntervalSince1970 >= 0 && $0.completedAt <= now && Self.month($0.completedAt) + ".json" == file.lastPathComponent
                }) else { throw StorageError.invalidFile }
                sessions += records
            }
            sessions = Array(Dictionary(grouping: sessions, by: \.id).compactMap { $0.value.first }).sorted { $0.completedAt > $1.completedAt }
        }
    }
    func record(_ completions: [Completion], now: Date = Date()) throws {
        var ids = Set(sessions.map(\.id))
        for completion in completions where completion.phase == .focus && completion.date.timeIntervalSinceReferenceDate.isFinite && completion.date.timeIntervalSince1970 >= 0 && completion.date <= now {
            guard ids.insert(completion.date).inserted else { continue }
            sessions.append(FocusSession(completedAt: completion.date))
            pendingMonths.insert(Self.month(completion.date))
        }
        sessions.sort { $0.completedAt > $1.completedAt }
        for month in pendingMonths.sorted() {
            try LocalStorage.save(sessions.filter { Self.month($0.completedAt) == month }, to: directory.appendingPathComponent(month + ".json"))
            pendingMonths.remove(month)
        }
    }
    private static func month(_ date: Date) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let parts = calendar.dateComponents([.year, .month], from: date)
        return String(format: "%04d-%02d", parts.year!, parts.month!)
    }
}
