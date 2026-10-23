import Foundation

struct TimerQuote: Identifiable, Codable {
    let id: String
    let text: String
    let author: String
    let work: String
    let source: String
    var provider: String? = nil
}

enum QuoteLibrary {
    private static let walden = "https://www.gutenberg.org/cache/epub/205/pg205-images.html"
    private static let essays = "https://www.gutenberg.org/files/2944/2944-h/2944-h.htm"
    private static let franklin = "https://www.gutenberg.org/cache/epub/36151/pg36151-images.html"
    private static let lubbock = "https://www.quotecatalog.com/source/the-use-of-life-1894"
    private static let wordsworth = "https://www.poetryfoundation.org/poems/45557/the-tables-turned"
    static let focus: [TimerQuote] = [
        .init(id: "f01", text: "My experience is what I agree to attend to.", author: "William James", work: "The Principles of Psychology, vol. I, Attention (1890)", source: "https://www.gutenberg.org/cache/epub/57628/pg57628-images.html"),
        .init(id: "f02", text: "Do your work, and you shall reinforce yourself.", author: "Ralph Waldo Emerson", work: "Self-Reliance, Essays: First Series (1841)", source: essays),
        .init(id: "f03", text: "Simplicity, simplicity, simplicity!", author: "Henry David Thoreau", work: "Walden, Where I Lived, and What I Lived For (1854)", source: walden),
        .init(id: "f04", text: "Little strokes fell great oaks.", author: "Benjamin Franklin", work: "The Way to Wealth (1758), excerpt", source: franklin),
        .init(id: "f05", text: "Let no act be done without a purpose, nor otherwise than according to the perfect principles of art.", author: "Marcus Aurelius", work: "Meditations IV.2, translated by George Long (1862)", source: "https://classics.mit.edu/Antoninus/meditations.4.four.html"),
        .init(id: "f06", text: "To affect the quality of the day, that is the highest of arts.", author: "Henry David Thoreau", work: "Walden, Where I Lived, and What I Lived For (1854)", source: walden),
        .init(id: "f07", text: "Diligence is the mother of good luck.", author: "Benjamin Franklin", work: "The Way to Wealth (1758), excerpt", source: franklin),
        .init(id: "f08", text: "Nothing great was ever achieved without enthusiasm.", author: "Ralph Waldo Emerson", work: "Circles, Essays: First Series (1841)", source: essays),
        .init(id: "f09", text: "Our life is frittered away by detail.", author: "Henry David Thoreau", work: "Walden, Where I Lived, and What I Lived For (1854)", source: walden),
        .init(id: "f10", text: "One to-day is worth two to-morrows.", author: "Benjamin Franklin", work: "The Way to Wealth (1758), excerpt", source: franklin),
        .init(id: "f11", text: "Give thyself time to learn something new and good, and cease to be whirled around.", author: "Marcus Aurelius", work: "Meditations II.7, translated by George Long (1862)", source: "https://classics.mit.edu/Antoninus/meditations.2.two.html"),
        .init(id: "f12", text: "By doing his own work he unfolds himself.", author: "Ralph Waldo Emerson", work: "Spiritual Laws, Essays: First Series (1841)", source: essays),
        .init(id: "f13", text: "Lost time is never found again.", author: "Benjamin Franklin", work: "The Way to Wealth (1758), excerpt", source: franklin),
        .init(id: "f14", text: "To be awake is to be alive.", author: "Henry David Thoreau", work: "Walden, Where I Lived, and What I Lived For (1854)", source: walden),
        .init(id: "f15", text: "Drive thy business, let not that drive thee.", author: "Benjamin Franklin", work: "The Way to Wealth (1758), excerpt", source: franklin)
    ]
    static let rest: [TimerQuote] = [
        .init(id: "r01", text: "Rest is not idleness.", author: "John Lubbock", work: "The Use of Life (1894), excerpt", source: lubbock),
        .init(id: "r02", text: "I love a broad margin to my life.", author: "Henry David Thoreau", work: "Walden, Sounds (1854)", source: walden),
        .init(id: "r03", text: "Nothing can bring you peace but yourself.", author: "Ralph Waldo Emerson", work: "Self-Reliance, Essays: First Series (1841)", source: essays),
        .init(id: "r04", text: "But in every walk with Nature one receives far more than he seeks.", author: "John Muir", work: "Steep Trails, Mormon Lilies (1918)", source: "https://www.gutenberg.org/files/326/326-h/326-h.htm"),
        .init(id: "r05", text: "Come forth into the light of things,\nLet Nature be your teacher.", author: "William Wordsworth", work: "The Tables Turned (1798), excerpt", source: wordsworth),
        .init(id: "r06", text: "To sit in the shade on a fine day, and look upon verdure, is the most perfect refreshment.", author: "Jane Austen", work: "Mansfield Park, chapter IX (1814), Fanny Price speaking; excerpt", source: "https://www.gutenberg.org/files/141/141-h/141-h.htm"),
        .init(id: "r07", text: "What is this life if, full of care,\nWe have no time to stand and stare.", author: "W. H. Davies", work: "Leisure, Songs of Joy and Others (1911), opening lines", source: "https://rpo.library.utoronto.ca/content/leisure"),
        .init(id: "r08", text: "Heaven is under our feet as well as over our heads.", author: "Henry David Thoreau", work: "Walden, The Pond in Winter (1854)", source: walden),
        .init(id: "r09", text: "A day of worry is more exhausting than a week of work.", author: "John Lubbock", work: "The Use of Life (1894)", source: lubbock),
        .init(id: "r10", text: "Leave this military hurry and adopt the pace of Nature.", author: "Ralph Waldo Emerson", work: "Education, Lectures and Biographical Sketches (1883); Emerson concordance", source: "https://concordlibrary.org/special-collections/emerson-concordance/PAA-PARABL"),
        .init(id: "r11", text: "We need the tonic of wildness.", author: "Henry David Thoreau", work: "Walden, Spring (1854), excerpt", source: walden),
        .init(id: "r12", text: "A thing of beauty is a joy for ever.", author: "John Keats", work: "Endymion, book I (1818), opening line", source: "https://www.poetryfoundation.org/poems/44469/endymion-56d2239287ca5"),
        .init(id: "r13", text: "Constantly then give to thyself this retreat, and renew thyself.", author: "Marcus Aurelius", work: "Meditations IV.3, translated by George Long (1862), excerpt", source: "https://classics.mit.edu/Antoninus/meditations.4.four.html"),
        .init(id: "r14", text: "We can never have enough of Nature.", author: "Henry David Thoreau", work: "Walden, Spring (1854)", source: walden),
        .init(id: "r15", text: "Come forth, and bring with you a heart\nThat watches and receives.", author: "William Wordsworth", work: "The Tables Turned (1798), closing lines", source: wordsworth)
    ]

    static func quotes(for phase: Phase) -> [TimerQuote] { phase == .focus ? focus : rest }
}

/// Independent of the focus timer: refreshing a quote never changes a deadline.
struct QuoteRotation {
    static let interval: TimeInterval = 60
    private(set) var focusIndex = 0
    private(set) var restIndex = 0
    private(set) var phase: Phase
    private(set) var nextChange: Date
    private(set) var focusQuotes = QuoteLibrary.focus
    private(set) var restQuotes = QuoteLibrary.rest

    init(phase: Phase, now: Date) {
        self.phase = phase
        nextChange = now.addingTimeInterval(Self.interval)
    }

    var index: Int { phase == .focus ? focusIndex : restIndex }
    var collection: [TimerQuote] { phase == .focus ? focusQuotes : restQuotes }
    var quote: TimerQuote { collection[index] }
    var count: Int { collection.count }

    mutating func useOnline(_ feed: OnlineQuoteFeed, at now: Date) {
        focusQuotes = Self.merge(feed.focus, with: QuoteLibrary.focus)
        restQuotes = Self.merge(feed.rest, with: QuoteLibrary.rest)
        focusIndex = 0
        restIndex = 0
        nextChange = now.addingTimeInterval(Self.interval)
    }

    private static func merge(_ online: [TimerQuote], with curated: [TimerQuote]) -> [TimerQuote] {
        var seen = Set<String>()
        return (online + curated).filter {
            let key = $0.text.lowercased().unicodeScalars.filter { CharacterSet.alphanumerics.contains($0) }.map(String.init).joined()
            return seen.insert(key).inserted
        }
    }

    mutating func select(_ newPhase: Phase, at now: Date) {
        guard phase != newPhase else { return }
        phase = newPhase
        nextChange = now.addingTimeInterval(Self.interval)
    }

    mutating func refresh(at now: Date) {
        if phase == .focus { focusIndex = (focusIndex + 1) % focusQuotes.count }
        else { restIndex = (restIndex + 1) % restQuotes.count }
        nextChange = now.addingTimeInterval(Self.interval)
    }

    mutating func advance(to now: Date) {
        // Advance once after sleep, so the newly visible quote gets a full minute.
        if now >= nextChange { refresh(at: now) }
    }
}
