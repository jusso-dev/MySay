import AVFoundation
import SwiftUI

/// Speech, layout, and appearance preferences, plus the gate into
/// Parent Mode.
struct SettingsView: View {
    @Environment(SpeechService.self) private var speech
    @Environment(SettingsStore.self) private var settings

    @State private var showParentGate = false
    @State private var parentUnlocked = false

    var body: some View {
        @Bindable var settings = settings
        NavigationStack {
            Form {
                Section("Speech") {
                    VStack(alignment: .leading) {
                        Text("Speed")
                        Slider(
                            value: $settings.speechRate,
                            in: SettingsStore.speechRateRange
                        ) {
                            Text("Speech speed")
                        } minimumValueLabel: {
                            Image(systemName: "tortoise.fill")
                                .accessibilityLabel("Slower")
                        } maximumValueLabel: {
                            Image(systemName: "hare.fill")
                                .accessibilityLabel("Faster")
                        }
                    }
                    VStack(alignment: .leading) {
                        Text("Pitch")
                        Slider(
                            value: $settings.speechPitch,
                            in: SettingsStore.speechPitchRange
                        ) {
                            Text("Speech pitch")
                        } minimumValueLabel: {
                            Image(systemName: "arrow.down")
                                .accessibilityLabel("Lower")
                        } maximumValueLabel: {
                            Image(systemName: "arrow.up")
                                .accessibilityLabel("Higher")
                        }
                    }
                    NavigationLink {
                        VoicePickerView()
                    } label: {
                        LabeledContent("Voice", value: currentVoiceName)
                    }
                    Button {
                        speech.speak("Hello! This is how I sound.", settings: settings)
                    } label: {
                        Label("Test Voice", systemImage: "speaker.wave.2.fill")
                    }
                    Button {
                        speech.replay(settings: settings)
                    } label: {
                        Label("Replay Last Word", systemImage: "arrow.counterclockwise")
                    }
                    .disabled(speech.lastSpokenText == nil)
                }

                Section {
                    Picker("Grid size", selection: $settings.gridColumns) {
                        ForEach(SettingsStore.gridColumnOptions, id: \.self) { columns in
                            Text("\(columns) × \(columns)").tag(columns)
                        }
                    }
                    Toggle("Show labels", isOn: $settings.showLabels)
                    Toggle("Sentence strip", isOn: $settings.showSentenceStrip)
                    if settings.showSentenceStrip {
                        Toggle("Build sentences from taps", isOn: $settings.autoAddToSentence)
                    }
                } header: {
                    Text("Layout")
                } footer: {
                    Text("The sentence strip keeps a message window at the top of every screen. With “Build sentences from taps” on, every tapped picture is added to the sentence; off, taps just speak and sentences are built in the Phrases tab.")
                }

                Section("Appearance") {
                    Toggle("High contrast", isOn: $settings.highContrast)
                }

                Section {
                    Button {
                        showParentGate = true
                    } label: {
                        Label("Parent Mode", systemImage: "lock.shield.fill")
                            .font(.body.weight(.semibold))
                    }
                    .accessibilityHint("Requires the parent passcode. Add and edit words, manage categories, and back up data.")
                } footer: {
                    Text("Parent Mode is protected by a passcode so children stay on their communication boards.")
                }

                Section {
                    LabeledContent("Version", value: appVersion)
                } footer: {
                    Text("MySay works completely offline. Nothing is ever collected, tracked, or sent anywhere.")
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showParentGate) {
                PasscodeGateView {
                    showParentGate = false
                    parentUnlocked = true
                }
            }
            .fullScreenCover(isPresented: $parentUnlocked) {
                ParentModeView()
            }
        }
    }

    private var currentVoiceName: String {
        SpeechService.resolveVoice(identifier: settings.voiceIdentifier)?.name ?? "Default"
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }
}
