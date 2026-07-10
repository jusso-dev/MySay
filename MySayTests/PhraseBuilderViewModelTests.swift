import Testing
@testable import MySay

@Suite("Phrase builder")
struct PhraseBuilderViewModelTests {
    @Test("Builds the canonical example: I + want + drink")
    func canonicalSentence() {
        #expect(PhraseBuilderViewModel.sentence(from: ["I", "Want", "Drink"]) == "I want drink")
    }

    @Test("Keeps the pronoun I capitalised mid-sentence")
    func pronounCapitalisation() {
        #expect(
            PhraseBuilderViewModel.sentence(from: ["Mum", "I", "Want", "More"])
                == "Mum I want more"
        )
    }

    @Test("Empty and whitespace-only words produce an empty sentence")
    func emptyInput() {
        #expect(PhraseBuilderViewModel.sentence(from: []) == "")
        #expect(PhraseBuilderViewModel.sentence(from: ["  ", ""]) == "")
    }

    @Test("Multi-word phrases stay intact")
    func multiWordPhrases() {
        #expect(
            PhraseBuilderViewModel.sentence(from: ["I", "don't like", "Bath"])
                == "I don't like bath"
        )
    }

    @Test("Adding icons builds tokens and the sentence")
    func addingTokens() {
        let viewModel = PhraseBuilderViewModel()
        viewModel.add(TestSupport.makeIcon(title: "I"))
        viewModel.add(TestSupport.makeIcon(title: "Want"))
        viewModel.add(TestSupport.makeIcon(title: "Drink"))

        #expect(viewModel.tokens.count == 3)
        #expect(viewModel.sentenceText == "I want drink")
    }

    @Test("Remove, undo, and clear")
    func removal() {
        let viewModel = PhraseBuilderViewModel()
        viewModel.add(TestSupport.makeIcon(title: "I"))
        viewModel.add(TestSupport.makeIcon(title: "Want"))
        viewModel.add(TestSupport.makeIcon(title: "Drink"))

        viewModel.removeLast()
        #expect(viewModel.sentenceText == "I want")

        let first = viewModel.tokens[0]
        viewModel.remove(first)
        #expect(viewModel.sentenceText == "Want")

        viewModel.clear()
        #expect(viewModel.isEmpty)
        #expect(viewModel.sentenceText == "")
    }

    @Test("Token count is capped")
    func tokenCap() {
        let viewModel = PhraseBuilderViewModel()
        for index in 0..<(PhraseBuilderViewModel.maxTokens + 5) {
            viewModel.add(TestSupport.makeIcon(title: "Word\(index)"))
        }
        #expect(viewModel.tokens.count == PhraseBuilderViewModel.maxTokens)
        #expect(!viewModel.canAddToken)
    }

    @Test("Speaking the phrase hands the sentence to the speech service")
    func speakPhrase() {
        let viewModel = PhraseBuilderViewModel()
        let speech = SpeechService(audioEnabled: false)
        let settings = SettingsStore(defaults: TestSupport.makeDefaults())

        viewModel.add(TestSupport.makeIcon(title: "I"))
        viewModel.add(TestSupport.makeIcon(title: "Want"))
        viewModel.add(TestSupport.makeIcon(title: "Drink"))
        viewModel.speak(using: speech, settings: settings)

        #expect(speech.lastSpokenText == "I want drink")
    }
}
