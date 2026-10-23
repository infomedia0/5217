import Foundation

struct OnlineQuoteFeed: Codable {
    let fetchedAt: Date
    let focus: [TimerQuote]
    let rest: [TimerQuote]
    var count: Int { focus.count + rest.count }
    /// Keep a mode's older matches when a new batch has nothing suitable for it.
    /// Each pool is capped at 25, preserving the existing 50-entry cache bound.
    func retainingPools(from previous: OnlineQuoteFeed?) -> OnlineQuoteFeed {
        func merge(_ incoming: [TimerQuote], _ old: [TimerQuote]) -> [TimerQuote] {
            var seen = Set<String>()
            return Array((incoming + old).filter {
                seen.insert(QuoteClassifier.identity($0.text)).inserted
            }.prefix(25))
        }
        return OnlineQuoteFeed(fetchedAt: fetchedAt,
            focus: merge(focus, previous?.focus ?? []), rest: merge(rest, previous?.rest ?? []))
    }
    func isFresh(at now: Date) -> Bool { now.timeIntervalSince(fetchedAt) >= 0 && now.timeIntervalSince(fetchedAt) < 86_400 }
}

enum QuoteAPIError: Error {
    case http(Int), invalidResponse, noMatchingQuotes, cooldown, busy, redirectRejected, responseTooLarge
}

enum ZenQuotesParser {
    private struct Entry: Decodable { let q: String?; let a: String? }

    static func parse(_ data: Data, at now: Date) throws -> OnlineQuoteFeed {
        guard data.count <= QuoteEndpoint.maximumBytes else { throw QuoteAPIError.invalidResponse }
        let entries = try JSONDecoder().decode([Entry].self, from: data)
        guard entries.count <= 50 else { throw QuoteAPIError.invalidResponse }
        var focus: [TimerQuote] = []
        var rest: [TimerQuote] = []
        var seen = Set<String>()
        for entry in entries.prefix(50) {
            guard let rawText = entry.q, let rawAuthor = entry.a else { continue }
            let text = normalize(rawText)
            let author = normalize(rawAuthor)
            guard (12...130).contains(text.count), (2...55).contains(author.count),
                  !text.contains("<"), !text.contains(">"), !author.contains("<"),
                  !author.contains(">"), !hasUnsafeControls(text), !hasUnsafeControls(author),
                  !author.lowercased().contains("zenquotes"),
                  !text.lowercased().contains("too many requests"),
                  seen.insert(QuoteClassifier.identity(text)).inserted else { continue }
            guard let phase = QuoteClassifier.classify(text) else { continue }
            let quote = TimerQuote(id: "zen-\(author)-\(text)", text: text, author: author,
                work: "Attribution supplied by ZenQuotes; original work not supplied by this API.",
                source: "https://zenquotes.io/", provider: "ZenQuotes")
            if phase == .rest { rest.append(quote) }
            else { focus.append(quote) }
        }
        let feed = OnlineQuoteFeed(fetchedAt: now, focus: focus, rest: rest)
        guard feed.count > 0 else { throw QuoteAPIError.noMatchingQuotes }
        return feed
    }

    static func validatedCache(_ feed: OnlineQuoteFeed, at now: Date) -> OnlineQuoteFeed? {
        guard feed.count > 0, feed.count <= 50, feed.fetchedAt.timeIntervalSinceReferenceDate.isFinite,
              feed.fetchedAt <= now.addingTimeInterval(300),
              (feed.focus + feed.rest).allSatisfy({ $0.provider == "ZenQuotes" && $0.source == "https://zenquotes.io/" }) else { return nil }
        let rows = (feed.focus + feed.rest).map { ["q": $0.text, "a": $0.author] }
        guard let data = try? JSONSerialization.data(withJSONObject: rows),
              let validated = try? parse(data, at: feed.fetchedAt), validated.count > 0 else { return nil }
        return validated
    }

    private static func hasUnsafeControls(_ value: String) -> Bool {
        value.unicodeScalars.contains { CharacterSet.controlCharacters.contains($0) || (0x202A...0x202E).contains($0.value) || (0x2066...0x2069).contains($0.value) }
    }

    private static func normalize(_ value: String) -> String {
        value.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.joined(separator: " ")
    }
}

/// Fetches a batch once daily, with hourly retries on failure and a persisted
/// 60-second minimum between manual requests. Timer controls never use the network.
final class OnlineQuoteService {
    private let cacheURL: URL
    private let attemptURL: URL
    private let client: QuoteHTTPClient
    private let clock: () -> Date
    private(set) var cached: OnlineQuoteFeed?
    private(set) var isFetching = false
    private var lastAttempt: Date?
    var mayRequest: Bool { !isFetching && (lastAttempt.map { clock().timeIntervalSince($0) >= 60 } ?? true) }

    init(directory: URL, configuration: URLSessionConfiguration = .ephemeral, clock: @escaping () -> Date = Date.init) {
        cacheURL = directory.appendingPathComponent("online-quotes.json")
        attemptURL = directory.appendingPathComponent("quote-fetch-attempt.json")
        self.clock = clock
        client = QuoteHTTPClient(configuration: configuration)
        if let feed = LocalStorage.load(OnlineQuoteFeed.self, from: cacheURL, limit: QuoteEndpoint.maximumBytes) {
            cached = ZenQuotesParser.validatedCache(feed, at: clock())
        }
        if let attempt = LocalStorage.load(Date.self, from: attemptURL, limit: 128),
           attempt.timeIntervalSinceReferenceDate.isFinite, attempt <= clock() { lastAttempt = attempt }
    }

    func shouldRefreshAutomatically(at now: Date) -> Bool {
        guard !isFetching, cached?.isFresh(at: now) != true else { return false }
        return lastAttempt.map { now.timeIntervalSince($0) >= 3600 } ?? true
    }

    func fetch(completion: @escaping (Result<OnlineQuoteFeed, Error>) -> Void) {
        guard !isFetching else { completion(.failure(QuoteAPIError.busy)); return }
        guard mayRequest else { completion(.failure(QuoteAPIError.cooldown)); return }
        isFetching = true
        lastAttempt = clock()
        try? LocalStorage.save(lastAttempt, to: attemptURL)
        client.fetch { [weak self] response in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isFetching = false
                let result = response.flatMap { data in Result { try ZenQuotesParser.parse(data, at: self.clock()) } }
                if case let .success(feed) = result {
                    let retained = feed.retainingPools(from: self.cached)
                    self.cached = retained
                    try? LocalStorage.save(retained, to: self.cacheURL)
                    completion(.success(retained))
                } else {
                    completion(result)
                }
            }
        }
    }
}
