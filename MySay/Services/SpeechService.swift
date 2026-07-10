import AVFoundation
import Observation

/// Wraps `AVSpeechSynthesizer` for instant, offline speech output.
///
/// Defaults to an Australian English voice. Rate and pitch come from
/// `SettingsStore` at each call so changes apply immediately.
@Observable
final class SpeechService {
    private let synthesizer = AVSpeechSynthesizer()
    private var recordingPlayer: AVAudioPlayer?

    /// The last text spoken, used by the Replay button.
    private(set) var lastSpokenText: String?
    /// The recording behind the last output, when one was used; replay
    /// then repeats the familiar voice, not the synthesiser.
    private(set) var lastRecordedAudio: Data?

    /// When false (unit tests), utterances are built but not vocalised.
    private let audioEnabled: Bool

    init(audioEnabled: Bool = true) {
        self.audioEnabled = audioEnabled
        guard audioEnabled else { return }
        // .spokenAudio keeps speech clear over other audio without
        // permanently silencing it.
        try? AVAudioSession.sharedInstance().setCategory(
            .playback,
            mode: .spokenAudio,
            options: [.duckOthers]
        )
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    /// Speak text immediately, interrupting any in-progress speech so a
    /// child tapping quickly always hears the latest word.
    func speak(_ text: String, settings: SettingsStore) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        lastSpokenText = trimmed
        lastRecordedAudio = nil
        guard audioEnabled else { return }
        stopOutput()
        synthesizer.speak(Self.makeUtterance(
            text: trimmed,
            rate: settings.speechRate,
            pitch: settings.speechPitch,
            voiceIdentifier: settings.voiceIdentifier
        ))
    }

    /// Speak an icon: the parent's recorded voice when one exists,
    /// otherwise synthesised speech.
    func speak(icon: IconItem, settings: SettingsStore) {
        if let recording = icon.recordedAudioData {
            playRecording(recording, fallbackText: icon.spokenText, settings: settings)
        } else {
            speak(icon.spokenText, settings: settings)
        }
    }

    /// Play a recorded clip; falls back to synthesis if the data is
    /// unplayable (e.g. corrupted by a partial import).
    func playRecording(_ data: Data, fallbackText: String, settings: SettingsStore) {
        lastSpokenText = fallbackText
        lastRecordedAudio = data
        guard audioEnabled else { return }
        stopOutput()
        if let player = try? AVAudioPlayer(data: data) {
            recordingPlayer = player
            player.play()
        } else {
            lastRecordedAudio = nil
            speak(fallbackText, settings: settings)
        }
    }

    /// Repeat the most recent output — recording or synthesised text.
    func replay(settings: SettingsStore) {
        if let lastRecordedAudio, let lastSpokenText {
            playRecording(lastRecordedAudio, fallbackText: lastSpokenText, settings: settings)
        } else if let lastSpokenText {
            speak(lastSpokenText, settings: settings)
        }
    }

    func stop() {
        guard audioEnabled else { return }
        stopOutput()
    }

    private func stopOutput() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        recordingPlayer?.stop()
        recordingPlayer = nil
    }

    var isSpeaking: Bool {
        audioEnabled && synthesizer.isSpeaking
    }

    // MARK: - Personal Voice

    /// Authorization state for Personal Voice (the user's own voice,
    /// recorded in iPadOS Settings → Accessibility → Personal Voice).
    var personalVoiceStatus: AVSpeechSynthesizer.PersonalVoiceAuthorizationStatus {
        AVSpeechSynthesizer.personalVoiceAuthorizationStatus
    }

    /// Ask the system for access to the user's Personal Voice. Shows the
    /// system consent alert on first call; afterwards returns the stored
    /// decision immediately.
    func requestPersonalVoiceAuthorization() async -> AVSpeechSynthesizer.PersonalVoiceAuthorizationStatus {
        await withCheckedContinuation { continuation in
            AVSpeechSynthesizer.requestPersonalVoiceAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }

    /// Personal Voices the user has created and shared with apps.
    /// Empty until authorization is granted.
    nonisolated static func personalVoices() -> [AVSpeechSynthesisVoice] {
        AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.voiceTraits.contains(.isPersonalVoice) }
            .sorted { $0.name < $1.name }
    }

    // MARK: - Utterance construction (pure, unit-testable)

    nonisolated static func makeUtterance(
        text: String,
        rate: Double,
        pitch: Double,
        voiceIdentifier: String?
    ) -> AVSpeechUtterance {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = Float(rate).clamped(to: AVSpeechUtteranceMinimumSpeechRate...AVSpeechUtteranceMaximumSpeechRate)
        utterance.pitchMultiplier = Float(pitch).clamped(to: 0.5...2.0)
        utterance.voice = resolveVoice(identifier: voiceIdentifier)
        // A short lead-in pause keeps latency imperceptible while avoiding
        // clipped first syllables on some voices.
        utterance.preUtteranceDelay = 0
        return utterance
    }

    /// Resolve the configured voice, falling back to Australian English,
    /// then to whatever the system offers.
    nonisolated static func resolveVoice(identifier: String?) -> AVSpeechSynthesisVoice? {
        if let identifier, let chosen = AVSpeechSynthesisVoice(identifier: identifier) {
            return chosen
        }
        return AVSpeechSynthesisVoice(language: "en-AU")
            ?? AVSpeechSynthesisVoice(language: "en-GB")
            ?? AVSpeechSynthesisVoice(language: nil)
    }

    /// Installed voices: Personal Voices first, then Australian English,
    /// then other English voices.
    nonisolated static func availableVoices() -> [AVSpeechSynthesisVoice] {
        let english = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix("en") && !$0.voiceTraits.contains(.isPersonalVoice) }
        let australian = english.filter { $0.language == "en-AU" }
        let others = english
            .filter { $0.language != "en-AU" }
            .sorted { ($0.language, $0.name) < ($1.language, $1.name) }
        return personalVoices() + australian.sorted { $0.name < $1.name } + others
    }
}

nonisolated extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
