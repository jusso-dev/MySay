import AVFoundation
import Testing
@testable import MySay

/// End-to-end audio checks: these drive the real `AVSpeechSynthesizer`
/// (audio enabled), not the silent test double, so they prove the speech
/// pipeline actually produces output on this OS.
@MainActor
@Suite("Speech audio pipeline", .serialized)
struct SpeechAudioTests {
    @Test(
        "Synthesizer genuinely starts speaking",
        .disabled(
            if: ProcessInfo.processInfo.environment["CI"] == "true",
            "Hosted simulators do not provide a reliable speech audio service"
        )
    )
    func synthesizerSpeaks() async throws {
        let speech = SpeechService()
        let settings = SettingsStore(defaults: TestSupport.makeDefaults())

        speech.speak("Drink", settings: settings)

        var started = false
        for _ in 0..<100 { // up to 5 s for first-utterance voice loading
            if speech.isSpeaking {
                started = true
                break
            }
            try await Task.sleep(for: .milliseconds(50))
        }
        speech.stop()
        #expect(started, "AVSpeechSynthesizer never started speaking — audio pipeline broken")
    }

    @Test(
        "Replay speaks the previous word again",
        .disabled(
            if: ProcessInfo.processInfo.environment["CI"] == "true",
            "Hosted simulators do not provide a reliable speech audio service"
        )
    )
    func replaySpeaks() async throws {
        let speech = SpeechService()
        let settings = SettingsStore(defaults: TestSupport.makeDefaults())

        speech.speak("More", settings: settings)
        try await Task.sleep(for: .milliseconds(200))
        speech.stop()
        try await Task.sleep(for: .milliseconds(200))

        speech.replay(settings: settings)
        var started = false
        for _ in 0..<100 {
            if speech.isSpeaking {
                started = true
                break
            }
            try await Task.sleep(for: .milliseconds(50))
        }
        speech.stop()
        #expect(started)
    }

    @Test("An en-AU or English voice is installed and resolvable")
    func voiceInstalled() {
        let voice = SpeechService.resolveVoice(identifier: nil)
        #expect(voice != nil, "No speech voice available on this system")
    }

    @Test("Audio session is configured for playback")
    func audioSessionConfigured() {
        _ = SpeechService()
        let session = AVAudioSession.sharedInstance()
        #expect(session.category == .playback)
        #expect(session.mode == .spokenAudio)
    }
}
