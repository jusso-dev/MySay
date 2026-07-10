import AVFoundation
import Testing
@testable import MySay

@MainActor
@Suite("Speech service")
struct SpeechServiceTests {
    @Test("Utterance uses the requested rate and pitch")
    func utteranceConfiguration() {
        let utterance = SpeechService.makeUtterance(
            text: "Drink",
            rate: 0.5,
            pitch: 1.2,
            voiceIdentifier: nil
        )
        #expect(utterance.speechString == "Drink")
        #expect(utterance.rate == 0.5)
        #expect(utterance.pitchMultiplier == 1.2)
    }

    @Test("Rate is clamped into AVSpeech bounds")
    func rateClamping() {
        let tooFast = SpeechService.makeUtterance(
            text: "Hi", rate: 5.0, pitch: 1.0, voiceIdentifier: nil
        )
        #expect(tooFast.rate <= AVSpeechUtteranceMaximumSpeechRate)

        let tooSlow = SpeechService.makeUtterance(
            text: "Hi", rate: -1.0, pitch: 1.0, voiceIdentifier: nil
        )
        #expect(tooSlow.rate >= AVSpeechUtteranceMinimumSpeechRate)
    }

    @Test("Pitch is clamped to 0.5–2.0")
    func pitchClamping() {
        let high = SpeechService.makeUtterance(
            text: "Hi", rate: 0.5, pitch: 9.0, voiceIdentifier: nil
        )
        #expect(high.pitchMultiplier == 2.0)

        let low = SpeechService.makeUtterance(
            text: "Hi", rate: 0.5, pitch: 0.1, voiceIdentifier: nil
        )
        #expect(low.pitchMultiplier == 0.5)
    }

    @Test("Unknown voice identifier falls back to an English voice")
    func voiceFallback() {
        let voice = SpeechService.resolveVoice(identifier: "does.not.exist")
        // Simulators always ship at least one English voice.
        #expect(voice != nil)
        #expect(voice?.language.hasPrefix("en") == true)
    }

    @Test("Available voices list Australian English first when installed")
    func voiceOrdering() {
        let voices = SpeechService.availableVoices()
        #expect(!voices.isEmpty)
        if let firstAU = voices.firstIndex(where: { $0.language == "en-AU" }) {
            let anyOtherBefore = voices.prefix(firstAU).contains { $0.language != "en-AU" }
            #expect(!anyOtherBefore, "Non-AU voice listed before Australian voices")
        }
    }

    @Test("Speaking records the text for replay")
    func replayTracking() {
        let speech = SpeechService(audioEnabled: false)
        let settings = SettingsStore(defaults: TestSupport.makeDefaults())
        #expect(speech.lastSpokenText == nil)

        speech.speak("Drink", settings: settings)
        #expect(speech.lastSpokenText == "Drink")

        speech.speak("  More  ", settings: settings)
        #expect(speech.lastSpokenText == "More")
    }

    @Test("Blank text is ignored")
    func blankTextIgnored() {
        let speech = SpeechService(audioEnabled: false)
        let settings = SettingsStore(defaults: TestSupport.makeDefaults())
        speech.speak("   ", settings: settings)
        #expect(speech.lastSpokenText == nil)
    }
}
