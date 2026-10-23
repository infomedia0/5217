import Foundation

enum Phase: String, Codable {
    case focus, rest
    var seconds: TimeInterval { self == .focus ? 52 * 60 : 17 * 60 }
    var title: String { self == .focus ? "Focus" : "Break" }
    var next: Phase { self == .focus ? .rest : .focus }
}

struct Completion: Codable {
    let phase: Phase
    let date: Date
}

struct TimerEngine: Codable {
    var phase: Phase = .focus
    var remaining: TimeInterval = Phase.focus.seconds
    var deadline: Date?
    var completions: [Completion] = []
    var soundEnabled = true
    var isRunning: Bool { deadline != nil }

    static let historyRetention: TimeInterval = 31 * 86_400
    static let maximumHistory = 1024

    func secondsLeft(at now: Date) -> Int {
        let seconds = deadline?.timeIntervalSince(now) ?? remaining
        guard seconds.isFinite else { return Int(phase.seconds) }
        return Int(ceil(min(phase.seconds, max(0, seconds))))
    }

    /// Saved files are data, not trusted in-memory engine invariants.
    mutating func validate(at now: Date) {
        if !remaining.isFinite || remaining < 0 || remaining > phase.seconds { remaining = phase.seconds }
        if let boundary = deadline, !boundary.timeIntervalSinceReferenceDate.isFinite || boundary > now.addingTimeInterval(phase.seconds + 1) {
            deadline = nil
            remaining = phase.seconds
        }
        completions = Array(completions.filter {
            $0.phase == .focus && $0.date.timeIntervalSinceReferenceDate.isFinite && $0.date <= now && now.timeIntervalSince($0.date) <= Self.historyRetention
        }.suffix(Self.maximumHistory))
    }

    mutating func start(at now: Date) {
        guard deadline == nil else { return }
        deadline = now.addingTimeInterval(remaining)
    }

    mutating func pause(at now: Date) {
        _ = advance(to: now)
        remaining = max(0, deadline?.timeIntervalSince(now) ?? remaining)
        deadline = nil
    }

    mutating func reset() {
        deadline = nil
        remaining = phase.seconds
    }

    mutating func skip(at now: Date) {
        let running = isRunning
        phase = phase.next
        remaining = phase.seconds
        deadline = running ? now.addingTimeInterval(remaining) : nil
    }

    @discardableResult
    mutating func advance(to now: Date) -> [Completion] {
        var events: [Completion] = []
        guard now.timeIntervalSinceReferenceDate.isFinite else { return events }
        if let boundary = deadline {
            guard boundary.timeIntervalSinceReferenceDate.isFinite else { reset(); return events }
            let earliest = now.addingTimeInterval(-Self.historyRetention)
            let cycle = Phase.focus.seconds + Phase.rest.seconds
            let behind = earliest.timeIntervalSince(boundary)
            if behind >= cycle {
                // Skip complete old cycles arithmetically, retaining phase parity.
                deadline = earliest.addingTimeInterval(-behind.truncatingRemainder(dividingBy: cycle))
            }
        }
        while let boundary = deadline, boundary <= now {
            let event = Completion(phase: phase, date: boundary)
            events.append(event)
            if phase == .focus { completions.append(event) }
            phase = phase.next
            remaining = phase.seconds
            deadline = boundary.addingTimeInterval(remaining)
        }
        // Only retain a month of local history.
        completions.removeAll { now.timeIntervalSince($0.date) > Self.historyRetention || $0.date > now }
        if completions.count > Self.maximumHistory { completions = Array(completions.suffix(Self.maximumHistory)) }
        return events
    }

    func sessionsToday(at now: Date, calendar: Calendar = .current) -> Int {
        completions.filter { calendar.isDate($0.date, inSameDayAs: now) }.count
    }
}
