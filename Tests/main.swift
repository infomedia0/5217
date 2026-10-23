import Foundation
import AVFoundation

var checks = 0
func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    checks += 1
    guard condition() else { fatalError("FAIL: \(message)") }
}
let start = Date(timeIntervalSince1970: 1_800_000_000)
var timer = TimerEngine()
expect(timer.secondsLeft(at: start) == 3120, "initial focus is 52 minutes")
timer.start(at: start)
expect(timer.secondsLeft(at: start.addingTimeInterval(1)) == 3119, "countdown ticks by seconds")
expect(timer.secondsLeft(at: start.addingTimeInterval(0.2)) == 3120, "fractional seconds round upward")
timer.pause(at: start.addingTimeInterval(12.5))
expect(timer.secondsLeft(at: start.addingTimeInterval(100)) == 3108, "paused time stays fixed")
timer.start(at: start.addingTimeInterval(100))
let boundary = start.addingTimeInterval(3207.5)
expect(timer.advance(to: boundary).count == 1, "focus boundary occurs once")
expect(timer.phase == .rest && timer.secondsLeft(at: boundary) == 1020, "automatically starts 17-minute break")
expect(timer.completions.count == 1, "records completed focus")
expect(timer.advance(to: boundary).isEmpty, "does not duplicate a completion")
expect(timer.advance(to: boundary.addingTimeInterval(1020)).count == 1, "completes break")
expect(timer.phase == .focus && timer.secondsLeft(at: boundary.addingTimeInterval(1020)) == 3120, "automatically restarts focus")
expect(timer.completions.count == 1, "breaks do not count as focused sessions")
timer.reset()
expect(!timer.isRunning && timer.remaining == 3120, "reset stops and restores current phase")
timer.skip(at: start)
expect(timer.phase == .rest && !timer.isRunning, "skip while idle remains idle")
timer.start(at: start)
timer.skip(at: start.addingTimeInterval(2))
expect(timer.phase == .focus && timer.secondsLeft(at: start.addingTimeInterval(2)) == 3120 && timer.isRunning, "skip while running starts next phase")
expect(timer.completions.count == 1, "skip is not a completion")
var sleeping = TimerEngine()
sleeping.start(at: start)
let wake = start.addingTimeInterval(2 * 4140 + 45)
expect(sleeping.advance(to: wake).count == 4, "reconciles multiple phases after sleep")
expect(sleeping.phase == .focus && sleeping.secondsLeft(at: wake) == 3075, "wakeup retains elapsed time without drift")
expect(sleeping.completions.count == 2, "counts completed focus intervals after sleep")
let data = try JSONEncoder().encode(sleeping)
let restored = try JSONDecoder().decode(TimerEngine.self, from: data)
expect(restored.deadline == sleeping.deadline && restored.completions.count == 2, "state survives persistence")
var calendar = Calendar(identifier: .gregorian)
calendar.timeZone = TimeZone(secondsFromGMT: 0)!
expect(restored.sessionsToday(at: wake, calendar: calendar) == 2, "daily focus total")
expect(restored.sessionsToday(at: wake.addingTimeInterval(86400), calendar: calendar) == 0, "daily count rolls over")
var exactPause = TimerEngine()
exactPause.start(at: start)
exactPause.pause(at: start.addingTimeInterval(3120))
expect(exactPause.phase == .rest && !exactPause.isRunning && exactPause.remaining == 1020, "pause exactly at boundary preserves the next phase")
expect(QuoteLibrary.focus.count == 15 && QuoteLibrary.rest.count == 15, "exactly 15 quotes per mode")
let allQuotes = QuoteLibrary.focus + QuoteLibrary.rest
expect(Set(allQuotes.map { $0.id }).count == 30, "quote IDs are unique")
expect(Set(allQuotes.map { $0.text }).count == 30, "quote text does not repeat")
expect(allQuotes.allSatisfy { URL(string: $0.source)?.scheme == "https" && !$0.author.isEmpty && !$0.work.isEmpty }, "all quotes have attribution and HTTPS source links")
var rotation = QuoteRotation(phase: .focus, now: start)
let firstQuote = rotation.quote.id
rotation.advance(to: start.addingTimeInterval(59.9))
expect(rotation.quote.id == firstQuote, "does not rotate before 60 seconds")
rotation.advance(to: start.addingTimeInterval(60))
expect(rotation.quote.id != firstQuote && rotation.index == 1, "rotates at the 60-second boundary")
rotation.refresh(at: start.addingTimeInterval(90))
expect(rotation.index == 2, "manual refresh advances immediately")
rotation.advance(to: start.addingTimeInterval(120))
expect(rotation.index == 2, "manual refresh grants a full reading minute")
rotation.select(.rest, at: start.addingTimeInterval(130))
expect(rotation.quote.id == "r01", "phase switch selects the correct collection immediately")
rotation.advance(to: start.addingTimeInterval(150))
expect(rotation.index == 0, "phase switch resets automatic rotation interval")
rotation.refresh(at: start.addingTimeInterval(160))
rotation.select(.focus, at: start.addingTimeInterval(170))
expect(rotation.index == 2, "modes retain separate positions")
rotation.select(.rest, at: start.addingTimeInterval(180))
expect(rotation.index == 1, "rest position is retained")
rotation.advance(to: start.addingTimeInterval(3600))
expect(rotation.index == 2 && rotation.nextChange == start.addingTimeInterval(3660), "sleep advances once and allows a full minute to read")
for phase in [Phase.focus, Phase.rest] {
    var cycle = QuoteRotation(phase: phase, now: start)
    let initial = cycle.quote.id
    var seen: Set<String> = []
    for offset in 0..<15 {
        seen.insert(cycle.quote.id)
        cycle.refresh(at: start.addingTimeInterval(Double(offset)))
    }
    expect(seen.count == 15 && cycle.quote.id == initial, "\(phase.title) cycles through every quote before repeating")
}
let fixture = Data("""
[
 {"q":"Learn with attention and practice every day.","a":"Focus Fixture"},
 {"q":"Find peace in a quiet moment of rest.","a":"Rest Fixture"},
 {"q":"Learn with attention and practice every day.","a":"Duplicate"},
 {"q":"A purple elephant wears a hat.","a":"Unrelated Fixture"},
 {"q":"<script>work and focus</script>","a":"HTML Fixture"},
 {"q":"Too many requests. Please try again later.","a":"zenquotes.io"},
 {"a":"Missing text"}
]
""".utf8)
let onlineFeed = try ZenQuotesParser.parse(fixture, at: start)
expect(onlineFeed.focus.count == 1 && onlineFeed.rest.count == 1, "classifies Focus and Rest and drops duplicates, unrelated entries, and error messages")
expect(onlineFeed.focus[0].provider == "ZenQuotes" && onlineFeed.focus[0].source == "https://zenquotes.io/", "online quotes retain provider attribution")
expect(onlineFeed.isFresh(at: start.addingTimeInterval(86399)), "online cache is fresh for one day")
expect(!onlineFeed.isFresh(at: start.addingTimeInterval(86400)), "online cache expires after one day")
expect(!onlineFeed.isFresh(at: start.addingTimeInterval(-1)), "future cache timestamp does not suppress fetching indefinitely")
do {
    _ = try ZenQuotesParser.parse(Data("not JSON".utf8), at: start)
    fatalError("Malformed JSON should fail")
} catch { expect(true, "malformed JSON is rejected") }
do {
    _ = try ZenQuotesParser.parse(Data("[]".utf8), at: start)
    fatalError("Empty quote batches should fail")
} catch { expect(true, "empty batches do not replace a working cache") }
do {
    _ = try ZenQuotesParser.parse(Data(repeating: 32, count: 131073), at: start)
    fatalError("Oversized payload should fail")
} catch { expect(true, "oversized response is rejected") }
var dynamic = QuoteRotation(phase: .focus, now: start)
dynamic.useOnline(onlineFeed, at: start)
expect(dynamic.quote.provider == "ZenQuotes" && dynamic.count == 16, "online quotes appear immediately alongside curated Focus fallbacks")
dynamic.select(.rest, at: start)
expect(dynamic.quote.provider == "ZenQuotes" && dynamic.count == 16, "Rest receives its own API quotes and fallbacks")
dynamic.refresh(at: start)
expect(dynamic.quote.id == "r01", "manual refresh rotates locally into the fallback set")
let duplicateFeed = OnlineQuoteFeed(fetchedAt: start, focus: [TimerQuote(id: "duplicate", text: "LOST TIME is never found again!", author: "Benjamin Franklin", work: "API", source: "https://zenquotes.io/", provider: "ZenQuotes")], rest: [])
dynamic.useOnline(duplicateFeed, at: start)
dynamic.select(.focus, at: start)
expect(dynamic.count == 15, "online versus curated duplicates ignore case and punctuation")
dynamic.select(.rest, at: start)
expect(dynamic.count == 15 && dynamic.quote.id == "r01", "mode with no API matches keeps its curated collection")

final class StubProtocol: URLProtocol {
    static var status = 200
    static var body = Data()
    static var error: Error?
    static var requests = 0
    static var lastRequest: URLRequest?
    static var headers = ["Content-Type": "application/json"]
    static var chunks: [Data]?
    static var redirect: URL?
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        Self.requests += 1
        Self.lastRequest = request
        if let error = Self.error { client?.urlProtocol(self, didFailWithError: error); return }
        let response = HTTPURLResponse(url: request.url!, statusCode: Self.status, httpVersion: "HTTP/1.1", headerFields: Self.headers)!
        if let redirect = Self.redirect {
            client?.urlProtocol(self, wasRedirectedTo: URLRequest(url: redirect), redirectResponse: response)
            return
        }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        for chunk in Self.chunks ?? [Self.body] { client?.urlProtocol(self, didLoad: chunk) }
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}
let testDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("5217-quote-tests-\(UUID().uuidString)")
defer { try? FileManager.default.removeItem(at: testDirectory) }
let configuration = URLSessionConfiguration.ephemeral
configuration.protocolClasses = [StubProtocol.self]
let session = URLSession(configuration: configuration)
defer { session.invalidateAndCancel() }
var serviceNow = start
let service = OnlineQuoteService(directory: testDirectory, configuration: configuration, clock: { serviceNow })
expect(service.shouldRefreshAutomatically(at: serviceNow), "first launch fetches when cache is absent")
func fetchResult(_ service: OnlineQuoteService) -> Result<OnlineQuoteFeed, Error> {
    var result: Result<OnlineQuoteFeed, Error>?
    service.fetch { result = $0 }
    let deadline = Date().addingTimeInterval(5)
    while result == nil && Date() < deadline { RunLoop.main.run(until: Date().addingTimeInterval(0.01)) }
    guard let result else { fatalError("API test timed out") }
    return result
}
StubProtocol.body = fixture
if case .success(let feed) = fetchResult(service) {
    expect(feed.count == 2 && service.cached?.count == 2, "successful HTTP fetch is parsed and cached")
} else { fatalError("Expected successful API fixture response") }
expect(StubProtocol.lastRequest?.url?.absoluteString == "https://zenquotes.io/api/quotes", "uses public HTTPS batch endpoint")
expect(StubProtocol.lastRequest?.httpBody == nil && StubProtocol.lastRequest?.value(forHTTPHeaderField: "Authorization") == nil, "requests do not include user data or credentials")
expect(!service.shouldRefreshAutomatically(at: serviceNow), "fresh cache avoids extra automatic requests")
let requestCount = StubProtocol.requests
if case .failure(QuoteAPIError.cooldown) = fetchResult(service) {
    expect(StubProtocol.requests == requestCount, "rapid manual refresh is blocked without a network request")
} else { fatalError("Expected refresh cooldown") }
let reloaded = OnlineQuoteService(directory: testDirectory, configuration: configuration, clock: { serviceNow })
expect(reloaded.cached?.count == 2 && !reloaded.mayRequest, "cache and cooldown survive relaunch")
serviceNow = serviceNow.addingTimeInterval(61)
StubProtocol.status = 429
if case .failure(QuoteAPIError.http(429)) = fetchResult(service) {
    expect(service.cached?.count == 2, "rate limiting preserves existing cache")
} else { fatalError("Expected HTTP 429") }
serviceNow = serviceNow.addingTimeInterval(61)
StubProtocol.status = 200
StubProtocol.body = Data("invalid JSON".utf8)
if case .failure = fetchResult(service) {
    expect(service.cached?.count == 2, "malformed response preserves existing cache")
} else { fatalError("Expected decoding failure") }
let offline = OnlineQuoteService(directory: testDirectory.appendingPathComponent("offline"), configuration: configuration, clock: { serviceNow })
StubProtocol.error = URLError(.notConnectedToInternet)
if case .failure = fetchResult(offline) {
    expect(offline.cached == nil && !offline.shouldRefreshAutomatically(at: serviceNow), "offline start retains local fallback without repeated requests")
} else { fatalError("Expected offline failure") }
expect(offline.shouldRefreshAutomatically(at: serviceNow.addingTimeInterval(3600)), "offline automatic retry waits an hour")
let sourceRoot = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let chimeURL = sourceRoot.appendingPathComponent("Resources/TimerEnd.wav")
let preferenceURL = testDirectory.appendingPathComponent("preferences/sound-settings.json")
expect(SoundPreferences.load(from: preferenceURL).selectedID == SoundChoice.chimeID, "upgrading without sound settings retains the 5217 chime")
try SoundPreferences(selectedID: "mac-alert/Glass.aiff").save(to: preferenceURL)
expect(SoundPreferences.load(from: preferenceURL).selectedID == "mac-alert/Glass.aiff", "selected notification tone survives relaunch")
try Data("broken settings".utf8).write(to: preferenceURL)
expect(SoundPreferences.load(from: preferenceURL).selectedID == SoundChoice.chimeID, "corrupt settings use the bundled chime safely")
let missing = testDirectory.appendingPathComponent("missing")
let minimalCatalog = SoundCatalog.discover(chimeURL: chimeURL, system: missing, tones: missing)
expect(minimalCatalog.count == 1 && minimalCatalog[0].id == SoundChoice.chimeID, "missing optional tone directories keep the bundled sound available")
let catalog = SoundCatalog.discover(chimeURL: chimeURL)
expect(catalog.count > 1 && Set(catalog.map { $0.id }).count == catalog.count, "installed tones have unique stable identifiers")
expect(catalog.allSatisfy { FileManager.default.fileExists(atPath: $0.url.path) }, "catalog includes only installed sound files")
let notificationDirectory = testDirectory.appendingPathComponent("NotificationSounds")
let originalChime = try SoundPreparer.prepare(catalog[0], directory: notificationDirectory)
expect(originalChime.url == chimeURL && originalChime.filename == "TimerEnd.wav", "bundled chime uses its original notification resource")
var failures: [String] = []
var durations: [TimeInterval] = []
var encodedCount = 0
for choice in catalog.dropFirst() {
    do {
        let prepared = try SoundPreparer.prepare(choice, directory: notificationDirectory)
        let file = try AVAudioFile(forReading: prepared.url)
        let duration = Double(file.length) / file.fileFormat.sampleRate
        durations.append(duration)
        if duration <= 0 || duration > 29.001 || prepared.url.pathExtension != "caf" { failures.append(choice.name + " (format)") }
        encodedCount += 1
    } catch { failures.append(choice.name + ": " + error.localizedDescription) }
}
expect(failures.isEmpty, "all installed tones decode and prepare for notifications: \(failures.joined(separator: "; "))")
expect(encodedCount == catalog.count - 1 && durations.allSatisfy { $0 <= 29.001 }, "prepared tones stay below the 30-second notification limit")
if let choice = catalog.dropFirst().first {
    let first = try SoundPreparer.prepare(choice, directory: notificationDirectory)
    let initialData = try Data(contentsOf: first.url)
    let second = try SoundPreparer.prepare(choice, directory: notificationDirectory)
    let secondData = try Data(contentsOf: second.url)
    expect(first.url == second.url && initialData == secondData, "preview and completion reuse the same cached audio file")
}
let invalidURL = testDirectory.appendingPathComponent("invalid.wav")
try Data("not audio".utf8).write(to: invalidURL)
do {
    _ = try SoundPreparer.prepare(SoundChoice(id: "invalid", name: "Invalid", group: "Tests", url: invalidURL), directory: notificationDirectory)
    fatalError("Invalid audio should not be accepted")
} catch { expect(true, "invalid audio fails safely without replacing the selected sound") }


// Security regressions: bounded persistence, malicious data, and request races.
let securityRoot = testDirectory.appendingPathComponent("security")
let secureURL = securityRoot.appendingPathComponent("private.json")
try LocalStorage.save(["value": "private"], to: secureURL)
let secureMetadata = try FileManager.default.attributesOfItem(atPath: secureURL.path)
expect((secureMetadata[.posixPermissions] as? NSNumber)?.intValue == 0o600, "saved JSON files are owner-only")
let directoryMetadata = try FileManager.default.attributesOfItem(atPath: securityRoot.path)
expect((directoryMetadata[.posixPermissions] as? NSNumber)?.intValue == 0o700, "new app storage directories are owner-only")
let sentinel = securityRoot.appendingPathComponent("original.json")
try Data("original".utf8).write(to: sentinel)
let link = securityRoot.appendingPathComponent("link.json")
try FileManager.default.createSymbolicLink(at: link, withDestinationURL: sentinel)
do { _ = try LocalStorage.read(link, limit: 100); fatalError("Symlinks should be rejected") }
catch { expect(true, "saved-data reads reject symbolic links") }
try LocalStorage.save(["new": "value"], to: link)
let sentinelData = try Data(contentsOf: sentinel)
expect(sentinelData == Data("original".utf8), "atomic save replaces a link rather than overwriting its target")
try Data(repeating: 32, count: 4097).write(to: secureURL)
expect(LocalStorage.load(SoundPreferences.self, from: secureURL, limit: 4096) == nil, "oversized settings are rejected before JSON decoding")

var corrupt = try JSONDecoder().decode(TimerEngine.self, from: Data("{\"phase\":\"focus\",\"remaining\":1e300,\"deadline\":1e300,\"completions\":[],\"soundEnabled\":true}".utf8))
corrupt.validate(at: start)
expect(!corrupt.isRunning && corrupt.secondsLeft(at: start) == 3120, "untrusted extreme dates and durations restore safely without integer overflow")
corrupt.remaining = .infinity
expect(corrupt.secondsLeft(at: start) == 3120, "countdown display guards nonfinite values")
corrupt.remaining = -10
corrupt.completions = [Completion(phase: .rest, date: start), Completion(phase: .focus, date: start.addingTimeInterval(10)), Completion(phase: .focus, date: start.addingTimeInterval(-40 * 86400))]
corrupt.validate(at: start)
expect(corrupt.remaining == 3120 && corrupt.completions.isEmpty, "restored history drops invalid phases, future records, and expired entries")
corrupt.completions = Array(repeating: Completion(phase: .focus, date: start), count: 5000)
corrupt.validate(at: start)
expect(corrupt.completions.count == TimerEngine.maximumHistory, "restored history is bounded")
var ancient = TimerEngine()
ancient.start(at: start.addingTimeInterval(-100 * 365 * 86400))
let catchupEvents = ancient.advance(to: start)
expect(catchupEvents.count < 1400 && ancient.completions.count <= TimerEngine.maximumHistory, "century-old deadlines skip old cycles rather than looping over the full interval")
expect(ancient.secondsLeft(at: start) > 0 && ancient.secondsLeft(at: start) <= Int(ancient.phase.seconds), "bounded catch-up still reaches a valid live phase")

var delivery = NotificationDeliveryState()
let staleID = delivery.begin()
_ = delivery.cancel()
let activeID = delivery.begin()
expect(staleID != activeID && !delivery.complete(id: staleID, failed: true) && !delivery.failed, "old notification callbacks cannot corrupt a newer request")
expect(delivery.complete(id: activeID, failed: true) && delivery.failed, "current notification failures remain observable")
_ = delivery.cancel()
expect(!delivery.complete(id: activeID, failed: true), "callbacks after pause or shutdown are ignored")

expect(QuoteEndpoint.allows(URL(string: "https://zenquotes.io/api/quotes")), "documented API endpoint is allowed")
expect(!QuoteEndpoint.allows(URL(string: "http://zenquotes.io/api/quotes")) && !QuoteEndpoint.allows(URL(string: "https://example.com/api/quotes")), "HTTP and off-origin API endpoints are rejected")
expect(!QuoteEndpoint.allows(URL(string: "https://zenquotes.io:8443/api/quotes")) && !QuoteEndpoint.allows(URL(string: "https://user:password@zenquotes.io/api/quotes")), "unexpected ports and embedded credentials are rejected")
let futureAttemptRoot = securityRoot.appendingPathComponent("future-attempt")
try LocalStorage.save(start.addingTimeInterval(86400 * 100), to: futureAttemptRoot.appendingPathComponent("quote-fetch-attempt.json"))
let futureAttemptService = OnlineQuoteService(directory: futureAttemptRoot, configuration: configuration, clock: { start })
expect(futureAttemptService.mayRequest, "tampered future request timestamps do not lock refresh indefinitely")
let invalidQuote = TimerQuote(id: "injected", text: "Learn \u{202E}with focus and attention.", author: "Fixture", work: "untrusted", source: "https://zenquotes.io/", provider: "ZenQuotes")
expect(ZenQuotesParser.validatedCache(OnlineQuoteFeed(fetchedAt: start, focus: [invalidQuote], rest: []), at: start) == nil, "cached quotes receive the same control-character validation as API data")
let poisonedQuote = TimerQuote(id: "injected", text: "Learn with focus and attention.", author: "Fixture", work: "untrusted", source: "file:///etc/passwd", provider: "ZenQuotes")
expect(ZenQuotesParser.validatedCache(OnlineQuoteFeed(fetchedAt: start, focus: [poisonedQuote], rest: []), at: start) == nil, "cached quote links cannot escape the fixed provider URL")
let cacheRoot = securityRoot.appendingPathComponent("oversized-cache")
try FileManager.default.createDirectory(at: cacheRoot, withIntermediateDirectories: true)
try Data(repeating: 32, count: QuoteEndpoint.maximumBytes + 1).write(to: cacheRoot.appendingPathComponent("online-quotes.json"))
expect(OnlineQuoteService(directory: cacheRoot, configuration: configuration).cached == nil, "oversized quote cache is rejected before decoding")

StubProtocol.error = nil
StubProtocol.status = 200
StubProtocol.body = fixture
StubProtocol.headers = ["Content-Type": "text/html"]
let wrongMIME = OnlineQuoteService(directory: securityRoot.appendingPathComponent("mime"), configuration: configuration)
if case .failure(QuoteAPIError.invalidResponse) = fetchResult(wrongMIME) { expect(true, "HTML API responses are rejected") }
else { fatalError("Expected content type rejection") }
StubProtocol.headers = ["Content-Type": "application/json", "Content-Length": "9999999"]
let oversizedHeader = OnlineQuoteService(directory: securityRoot.appendingPathComponent("header"), configuration: configuration)
if case .failure(QuoteAPIError.responseTooLarge) = fetchResult(oversizedHeader) { expect(true, "oversized declared responses are cancelled at the header") }
else { fatalError("Expected declared size rejection") }
StubProtocol.headers = ["Content-Type": "application/json"]
StubProtocol.chunks = [Data(repeating: 32, count: 65536), Data(repeating: 32, count: 65536), Data([32])]
let oversizedStream = OnlineQuoteService(directory: securityRoot.appendingPathComponent("stream"), configuration: configuration)
if case .failure(QuoteAPIError.responseTooLarge) = fetchResult(oversizedStream) { expect(true, "chunked responses cannot grow the app-owned buffer past 128 KiB") }
else { fatalError("Expected streaming size rejection") }
StubProtocol.chunks = nil
StubProtocol.status = 302
StubProtocol.redirect = URL(string: "https://example.com/unexpected")
let redirected = OnlineQuoteService(directory: securityRoot.appendingPathComponent("redirect"), configuration: configuration)
if case .failure = fetchResult(redirected) { expect(redirected.cached == nil, "redirected responses are rejected without caching their contents") }
else { fatalError("Expected redirect rejection") }
StubProtocol.redirect = nil
StubProtocol.status = 200

if let choice = catalog.dropFirst().first {
    let prepared = try SoundPreparer.prepare(choice, directory: notificationDirectory)
    try FileManager.default.removeItem(at: prepared.url)
    try FileManager.default.createSymbolicLink(at: prepared.url, withDestinationURL: sentinel)
    let repaired = try SoundPreparer.prepare(choice, directory: notificationDirectory)
    let repairedValues = try repaired.url.resourceValues(forKeys: [.isSymbolicLinkKey])
    expect(repairedValues.isSymbolicLink == false, "sound cache symlinks are replaced with prepared audio")
    let originalAfterRepair = try Data(contentsOf: sentinel)
    expect(originalAfterRepair == Data("original".utf8), "repair does not overwrite the sound cache symlink target")
}



// History uses only finished focus sessions and survives monthly rollover/relaunch.
let historyRoot = testDirectory.appendingPathComponent("history")
let archive = try FocusHistoryStore(directory: historyRoot)
let iso = ISO8601DateFormatter()
let monday = iso.date(from: "2025-03-03T12:00:00Z")!
let sunday = iso.date(from: "2025-03-09T20:00:00Z")!
let nextMonday = iso.date(from: "2025-03-10T12:00:00Z")!
let older = iso.date(from: "2024-12-31T23:00:00Z")!
let records = [Completion(phase: .focus, date: monday), Completion(phase: .rest, date: monday.addingTimeInterval(1020)),
    Completion(phase: .focus, date: sunday), Completion(phase: .focus, date: nextMonday), Completion(phase: .focus, date: older)]
try archive.record(records)
expect(archive.sessions.count == 4, "history excludes all rest completions")
try archive.record(records)
expect(archive.sessions.count == 4, "history migration and event replay are idempotent")
let archiveReloaded = try FocusHistoryStore(directory: historyRoot)
expect(archiveReloaded.sessions == archive.sessions, "monthly JSON history survives relaunch")
expect(archiveReloaded.sessions.contains { $0.completedAt == older }, "history older than 31 days remains available")
expect(archiveReloaded.sessions.first?.completedAt == nextMonday, "history is newest first")
let months = try FileManager.default.contentsOfDirectory(atPath: historyRoot.path).sorted()
expect(months == ["2024-12.json", "2025-03.json"], "history is partitioned into simple monthly JSON files")
let historyAttributes = try FileManager.default.attributesOfItem(atPath: historyRoot.appendingPathComponent("2025-03.json").path)
expect((historyAttributes[.posixPermissions] as? NSNumber)?.intValue == 0o600, "history JSON uses owner-only permissions")
var weekCalendar = Calendar(identifier: .iso8601)
weekCalendar.timeZone = TimeZone(identifier: "America/New_York")!
let weekDays = FocusHistorySummary.days(containing: sunday, sessions: archive.sessions, calendar: weekCalendar)
expect(weekDays.count == 7, "calendar week contains seven days across daylight-saving change")
expect(weekCalendar.component(.weekday, from: weekDays[0].date) == 2, "calendar week begins Monday")
expect(weekCalendar.component(.weekday, from: weekDays[6].date) == 1, "calendar week ends Sunday")
expect(weekDays.reduce(0) { $0 + $1.count } == 2, "week graph excludes other weeks and includes Sunday")
expect(weekDays.reduce(0) { $0 + $1.minutes } == 104, "weekly duration sums completed 52-minute sessions")
expect(weekDays.filter { $0.count == 0 }.count == 5, "week graph keeps zero-session days")
expect(FocusHistorySummary.duration(104) == "1h 44m", "duration displays hours and minutes")
expect(FocusHistorySummary.duration(52) == "52m", "sub-hour duration displays minutes")
expect(FocusHistorySummary.duration(0) == "0m", "empty days display zero minutes")
let emptyHistory = try FocusHistoryStore(directory: testDirectory.appendingPathComponent("empty-history"))
expect(emptyHistory.sessions.isEmpty, "first launch has empty history without fake records")
try emptyHistory.record([Completion(phase: .focus, date: Date(timeIntervalSince1970: -1e100)), Completion(phase: .focus, date: Date().addingTimeInterval(86400))])
expect(emptyHistory.sessions.isEmpty, "invalid and future history dates are excluded")
let brokenFile = historyRoot.appendingPathComponent("2025-03.json")
try Data("broken JSON".utf8).write(to: brokenFile)
do { _ = try FocusHistoryStore(directory: historyRoot); fatalError("Expected malformed history rejection") }
catch { let preserved = try LocalStorage.read(brokenFile, limit: 100); expect(preserved == Data("broken JSON".utf8), "malformed archive remains untouched") }
print("Validated \(catalog.count) installed sound choices.")


var stopSequence = StopControl()
expect(!stopSequence.armed, "Stop begins with silence action")
expect(stopSequence.press() == .silence, "first Stop press only silences")
expect(stopSequence.armed, "first Stop arms a separate confirmation request")
expect(stopSequence.press() == .requestConfirmation, "second Stop asks before changing the timer")
stopSequence.reset()
expect(!stopSequence.armed, "cancel and timer changes reset Stop sequence")
expect(stopSequence.press() == .silence, "after cancellation another first click cannot stop the timer")


let themeCases: [(String, Phase?)] = [
    ("Keep going, one small step at a time.", .focus),
    ("Learn with attention and practice every day.", .focus),
    ("Build discipline and make progress on your goal.", .focus),
    ("Never give up on yourself.", .focus),
    ("Believe in yourself and take action.", .focus),
    ("Find peace in a quiet moment of rest.", .rest),
    ("Take a break and enjoy the present moment.", .rest),
    ("Breathe deeply and let go of worry.", .rest),
    ("Be still and listen to nature.", .rest),
    ("Let the rest of the work wait until tomorrow.", nil),
    ("Never rest until you reach your goal.", nil),
    ("There is no peace in chasing success.", nil),
    ("Rest and work are both important.", nil),
    ("Today is a gift and time is precious.", nil),
    ("Joy comes in many different forms.", nil),
    ("Worry about what tomorrow may bring.", nil),
    ("Anxiety can disturb your peace.", nil),
    ("Success means killing the competition.", nil),
    ("The RESTAURANT serves wonderful food.", nil),
    ("Take\na\tbreak, and be present.", .rest),
    ("Do not work yourself into exhaustion.", nil)
]
for (quote, expected) in themeCases {
    expect(QuoteClassifier.classify(quote) == expected, "theme classification: \(quote)")
}
let mixedOld = OnlineQuoteFeed(fetchedAt: start, focus: [onlineFeed.focus[0]], rest: [onlineFeed.rest[0]])
let focusOnly = OnlineQuoteFeed(fetchedAt: start.addingTimeInterval(86400), focus: onlineFeed.focus, rest: [])
let retainedModes = focusOnly.retainingPools(from: mixedOld)
expect(retainedModes.focus.count == 1 && retainedModes.rest.count == 1, "focus-only batch keeps older Rest pool without duplicates")
expect(retainedModes.fetchedAt == focusOnly.fetchedAt, "merged cache tracks the last successful batch fetch")
let manyFocus = (0..<40).map { index in TimerQuote(id: "f\(index)", text: "Practice your focus skill number \(index) each day.", author: "Fixture", work: "Fixture", source: "https://zenquotes.io/", provider: "ZenQuotes") }
let manyRest = (0..<40).map { index in TimerQuote(id: "r\(index)", text: "Find quiet peace in moment number \(index).", author: "Fixture", work: "Fixture", source: "https://zenquotes.io/", provider: "ZenQuotes") }
let capped = OnlineQuoteFeed(fetchedAt: start, focus: manyFocus, rest: manyRest).retainingPools(from: nil)
expect(capped.focus.count == 25 && capped.rest.count == 25 && capped.count == 50, "independent pools stay within existing cache record limit")
let generic = TimerQuote(id: "generic", text: "Today is a gift and time is precious.", author: "Fixture", work: "Fixture", source: "https://zenquotes.io/", provider: "ZenQuotes")
let migratedThemes = ZenQuotesParser.validatedCache(OnlineQuoteFeed(fetchedAt: start, focus: [generic, onlineFeed.rest[0]], rest: [onlineFeed.focus[0]]), at: start)
expect(migratedThemes?.focus.count == 1 && migratedThemes?.rest.count == 1, "old caches are reclassified and ambiguous quotes dropped without discarding valid entries")
let canonicalRows = [["q":"Practice makes progress every day!", "a":"Fixture"], ["q":"PRACTICE makes progress every day.", "a":"Fixture"]]
let canonicalData = try JSONSerialization.data(withJSONObject: canonicalRows)
expect(try! ZenQuotesParser.parse(canonicalData, at: start).count == 1, "punctuation and case variants do not duplicate online quotes")
var themeNow = start
let themeDirectory = testDirectory.appendingPathComponent("mode-pools")
let themeService = OnlineQuoteService(directory: themeDirectory, configuration: configuration, clock: { themeNow })
StubProtocol.status = 200
StubProtocol.headers = ["Content-Type": "application/json"]
StubProtocol.chunks = nil
StubProtocol.redirect = nil
StubProtocol.body = fixture
if case .failure = fetchResult(themeService) { fatalError("Expected initial theme cache") }
themeNow = themeNow.addingTimeInterval(61)
StubProtocol.body = try JSONSerialization.data(withJSONObject: [["q":"Keep learning and make progress each day.", "a":"New Focus"]])
if case .success(let feed) = fetchResult(themeService) {
    expect(feed.focus.count == 2 && feed.rest.count == 1, "service returns independent retained pools after focus-only API refresh")
} else { fatalError("Expected Focus-only refresh") }
let themeReloaded = OnlineQuoteService(directory: themeDirectory, configuration: configuration, clock: { themeNow })
expect(themeReloaded.cached?.focus.count == 2 && themeReloaded.cached?.rest.count == 1, "separate mode collections persist in JSON and survive relaunch")
var fallbackOnly = QuoteRotation(phase: .rest, now: start)
fallbackOnly.useOnline(OnlineQuoteFeed(fetchedAt: start, focus: onlineFeed.focus, rest: []), at: start)
expect(fallbackOnly.count == 15 && fallbackOnly.quote.provider == nil, "Rest stays curated rather than borrowing motivational Focus quotes when online Rest is absent")


let oldSoundPrefs = try JSONDecoder().decode(SoundPreferences.self, from: Data(#"{"selectedID":"mac-alert/Ping.aiff"}"#.utf8))
expect(oldSoundPrefs.selectedID == "mac-alert/Ping.aiff" && oldSoundPrefs.durationSeconds == 5, "legacy sound selection survives migration with a 5-second duration")
for seconds in SoundPreferences.durations {
    let preference = SoundPreferences(selectedID: "test-sound", durationSeconds: seconds)
    let encoded = try JSONEncoder().encode(preference)
    let decoded = try JSONDecoder().decode(SoundPreferences.self, from: encoded)
    expect(decoded.selectedID == "test-sound" && decoded.durationSeconds == seconds, "sound duration \(seconds)s survives JSON round trip")
}
for invalid in [0, -1, 2, 30, Int.max] {
    expect(SoundPreferences(durationSeconds: invalid).durationSeconds == 5, "invalid sound duration is bounded: \(invalid)")
}
let wrongDuration = try JSONDecoder().decode(SoundPreferences.self, from: Data(#"{"selectedID":"kept","durationSeconds":"forever"}"#.utf8))
expect(wrongDuration.selectedID == "kept" && wrongDuration.durationSeconds == 5, "malformed duration does not discard selected tone")
print("Passed \(checks) checks including duration preferences and quote/history/security regressions.")
