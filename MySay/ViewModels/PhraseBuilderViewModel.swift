import Foundation
import Observation

/// One word/icon placed in the sentence strip.
nonisolated struct PhraseToken: Identifiable, Hashable, Sendable {
    let id: UUID
    let title: String
    let spokenText: String
    let imageName: String
    let customImageData: Data?
    let colorName: String

    init(
        id: UUID = UUID(),
        title: String,
        spokenText: String,
        imageName: String,
        customImageData: Data? = nil,
        colorName: String = TileColor.sky.rawValue
    ) {
        self.id = id
        self.title = title
        self.spokenText = spokenText
        self.imageName = imageName
        self.customImageData = customImageData
        self.colorName = colorName
    }
}

/// Drives the Phrase Builder screen: a sentence strip of tokens that can be
/// spoken as one natural utterance ("I" + "want" + "drink" → "I want drink").
@Observable
final class PhraseBuilderViewModel {
    private(set) var tokens: [PhraseToken] = []

    /// Practical ceiling keeps the strip readable; AAC phrases are short.
    static let maxTokens = 12

    var isEmpty: Bool { tokens.isEmpty }

    var canAddToken: Bool { tokens.count < Self.maxTokens }

    /// The sentence as spoken: words joined, first letter capitalised.
    var sentenceText: String {
        Self.sentence(from: tokens.map(\.spokenText))
    }

    func add(_ icon: IconItem) {
        guard canAddToken else { return }
        tokens.append(PhraseToken(
            title: icon.title,
            spokenText: icon.spokenText,
            imageName: icon.imageName,
            customImageData: icon.customImageData,
            colorName: icon.colorName
        ))
    }

    func remove(_ token: PhraseToken) {
        tokens.removeAll { $0.id == token.id }
    }

    func removeLast() {
        guard !tokens.isEmpty else { return }
        tokens.removeLast()
    }

    func clear() {
        tokens.removeAll()
    }

    func speak(using speech: SpeechService, settings: SettingsStore) {
        guard !isEmpty else { return }
        speech.speak(sentenceText, settings: settings)
    }

    /// Join words into a natural sentence. Pure and unit-testable.
    nonisolated static func sentence(from words: [String]) -> String {
        let cleaned = words
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !cleaned.isEmpty else { return "" }
        var sentence = cleaned
            .map { $0.lowercased() }
            .joined(separator: " ")
        // Keep the pronoun "I" capitalised wherever it appears.
        sentence = sentence
            .replacingOccurrences(of: " i ", with: " I ")
        if sentence.hasSuffix(" i") {
            sentence = String(sentence.dropLast()) + "I"
        }
        return sentence.prefix(1).uppercased() + sentence.dropFirst()
    }
}
