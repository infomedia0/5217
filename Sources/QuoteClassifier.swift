import Foundation

/// Conservative, deterministic theme matching, not semantic/AI classification.
/// Generic words alone and quotes mixing both themes stay out of online pools.
enum QuoteClassifier {
    private static let focus: Set<String> = ["focus", "focused", "attention", "work", "effort", "learn", "learning", "practice", "discipline", "progress", "success", "goal", "goals", "purpose", "persistence", "perseverance", "diligence", "courage", "create", "creativity", "habit", "habits", "achieve", "achievement", "enthusiasm", "task", "dedication", "determination", "motivation", "motivated", "improve", "improvement"]
    private static let rest: Set<String> = ["rest", "relax", "relaxation", "calm", "peace", "peaceful", "quiet", "silence", "breathe", "breath", "nature", "stillness", "gentle", "serenity", "contentment", "mindfulness", "tranquility", "tranquillity", "unwind", "recharge"]
    private static let focusPhrases = ["keep going", "never give up", "one step at a time", "believe in yourself", "take action", "small steps", "do your best"]
    private static let restPhrases = ["let go", "slow down", "take a break", "be still", "present moment", "be present", "take it easy", "at ease"]
    private static let excluded: Set<String> = ["suicide", "suicidal", "murder", "kill", "killing", "death", "dead", "violence", "violent", "hatred"]
    private static let unrest: Set<String> = ["worry", "worrying", "anxiety", "panic", "stress", "deadline", "hustle", "pressure"]

    static func classify(_ text: String) -> Phase? {
        let tokens = text.lowercased().components(separatedBy: CharacterSet.letters.inverted).filter { !$0.isEmpty }
        let words = Set(tokens)
        let normalized = " " + tokens.joined(separator: " ") + " "
        guard words.isDisjoint(with: excluded) else { return nil }
        let focusMatch = !words.isDisjoint(with: focus) || focusPhrases.contains { normalized.contains(" " + $0 + " ") }
        let restPhrase = restPhrases.contains { normalized.contains(" " + $0 + " ") }
        let restMatch = !words.isDisjoint(with: rest) || restPhrase
        // Avoid treating a negated recommendation as a positive theme signal.
        let negations = ["not", "never", "no", "without", "stop", "avoid", "don", "t"]
        for (index, word) in tokens.enumerated() where focus.contains(word) || rest.contains(word) {
            if tokens[max(0, index - 2)..<index].contains(where: { negations.contains($0) }) { return nil }
        }
        guard focusMatch != restMatch else { return nil }
        if restMatch {
            guard words.isDisjoint(with: unrest) || restPhrase else { return nil }
            return .rest
        }
        return .focus
    }

    static func identity(_ text: String) -> String {
        text.lowercased().unicodeScalars.filter { CharacterSet.alphanumerics.contains($0) }.map(String.init).joined()
    }
}
