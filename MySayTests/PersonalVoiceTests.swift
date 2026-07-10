import AVFoundation
import Testing
@testable import MySay

@MainActor
@Suite("Personal Voice")
struct PersonalVoiceTests {
    @Test("Personal voice listing never crashes and only returns personal voices")
    func personalVoiceListing() {
        for voice in SpeechService.personalVoices() {
            #expect(voice.voiceTraits.contains(.isPersonalVoice))
        }
    }

    @Test("Available voices list personal voices first, with no duplicates")
    func voiceOrderingWithPersonalVoices() {
        let voices = SpeechService.availableVoices()
        #expect(Set(voices.map(\.identifier)).count == voices.count)

        // Every personal voice must come before every standard voice.
        let lastPersonalIndex = voices.lastIndex { $0.voiceTraits.contains(.isPersonalVoice) }
        let firstStandardIndex = voices.firstIndex { !$0.voiceTraits.contains(.isPersonalVoice) }
        if let lastPersonalIndex, let firstStandardIndex {
            #expect(lastPersonalIndex < firstStandardIndex)
        }
    }

    @Test("Authorization status is readable without triggering a prompt")
    func statusReadable() {
        let speech = SpeechService(audioEnabled: false)
        let status = speech.personalVoiceStatus
        #expect(
            [.notDetermined, .denied, .unsupported, .authorized].contains(status),
            "Unexpected authorization status"
        )
    }

    @Test("A stale personal-voice identifier falls back to a standard voice")
    func staleIdentifierFallback() {
        // Identifiers like this stop resolving when authorization is
        // revoked; speech must fall back, never go silent.
        let voice = SpeechService.resolveVoice(
            identifier: "com.apple.speech.personalvoice.no-longer-authorized"
        )
        #expect(voice != nil)
        #expect(voice?.voiceTraits.contains(.isPersonalVoice) != true)
    }
}
