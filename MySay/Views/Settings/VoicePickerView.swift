import AVFoundation
import SwiftUI

/// Choose a speech voice. The user's Personal Voice (recorded in iPadOS
/// Settings → Accessibility → Personal Voice) is offered first, then
/// Australian English, then other English voices.
struct VoicePickerView: View {
    @Environment(SpeechService.self) private var speech
    @Environment(SettingsStore.self) private var settings

    @State private var voices = SpeechService.availableVoices()
    @State private var personalVoiceStatus = AVSpeechSynthesizer.personalVoiceAuthorizationStatus

    var body: some View {
        List {
            personalVoiceSection

            Section {
                ForEach(voices, id: \.identifier) { voice in
                    voiceRow(voice)
                }
            } header: {
                Text("Voices")
            } footer: {
                Text("Tap a voice to hear a sample. Higher-quality voices can be downloaded in iPad Settings → Accessibility → Spoken Content → Voices.")
            }
        }
        .navigationTitle("Voice")
    }

    /// Personal Voice: request access, list granted voices, or explain
    /// how to set one up.
    private var personalVoiceSection: some View {
        Section {
            switch personalVoiceStatus {
            case .authorized:
                if SpeechService.personalVoices().isEmpty {
                    Text("No Personal Voice found. Create one in iPad Settings → Accessibility → Personal Voice, then turn on “Allow Apps to Request to Use”.")
                        .foregroundStyle(.secondary)
                }
                // Granted voices appear at the top of the Voices list
                // below, marked with a waveform.
            case .notDetermined:
                Button {
                    requestPersonalVoice()
                } label: {
                    Label("Use My Personal Voice", systemImage: "person.wave.2.fill")
                }
                .accessibilityHint("Asks for permission to speak with a Personal Voice recorded on this iPad")
            case .denied:
                Text("Personal Voice access is off for MySay. Enable it in iPad Settings → Accessibility → Personal Voice → Allow Apps to Request to Use.")
                    .foregroundStyle(.secondary)
            case .unsupported:
                Text("Personal Voice isn't supported on this iPad.")
                    .foregroundStyle(.secondary)
            @unknown default:
                EmptyView()
            }
        } header: {
            Text("Personal Voice")
        } footer: {
            Text("A Personal Voice is a recreation of a real person's voice — for example a parent's — made in iPadOS Accessibility settings. MySay can speak every word and phrase with it.")
        }
    }

    private func voiceRow(_ voice: AVSpeechSynthesisVoice) -> some View {
        Button {
            settings.voiceIdentifier = voice.identifier
            speech.speak("Hello, my name is \(voice.name).", settings: settings)
        } label: {
            HStack {
                if voice.voiceTraits.contains(.isPersonalVoice) {
                    Image(systemName: "person.wave.2.fill")
                        .foregroundStyle(.tint)
                        .accessibilityHidden(true)
                }
                VStack(alignment: .leading) {
                    Text(voice.name)
                        .foregroundStyle(.primary)
                    Text(
                        voice.voiceTraits.contains(.isPersonalVoice)
                            ? "Personal Voice"
                            : languageName(for: voice.language)
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                Spacer()
                if settings.voiceIdentifier == voice.identifier {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                        .accessibilityHidden(true)
                }
            }
        }
        .accessibilityLabel(voiceAccessibilityLabel(voice))
        .accessibilityAddTraits(
            settings.voiceIdentifier == voice.identifier ? [.isSelected] : []
        )
    }

    private func requestPersonalVoice() {
        Task {
            personalVoiceStatus = await speech.requestPersonalVoiceAuthorization()
            voices = SpeechService.availableVoices()
            if personalVoiceStatus == .authorized,
               let personal = SpeechService.personalVoices().first {
                settings.voiceIdentifier = personal.identifier
                speech.speak("Hello! I can speak with your voice now.", settings: settings)
            }
        }
    }

    private func voiceAccessibilityLabel(_ voice: AVSpeechSynthesisVoice) -> String {
        voice.voiceTraits.contains(.isPersonalVoice)
            ? "\(voice.name), Personal Voice"
            : "\(voice.name), \(languageName(for: voice.language))"
    }

    private func languageName(for code: String) -> String {
        Locale.current.localizedString(forIdentifier: code) ?? code
    }
}
