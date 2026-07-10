import SwiftUI

/// The always-available message window shown above every screen when the
/// Sentence Strip setting is on. Tapping any word in the app appends it
/// here; the strip can speak, undo, and clear the sentence.
struct CompactSentenceStripView: View {
    @Environment(SpeechService.self) private var speech
    @Environment(SettingsStore.self) private var settings
    @Environment(PhraseBuilderViewModel.self) private var phrase

    var body: some View {
        HStack(spacing: 12) {
            ScrollViewReader { proxy in
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        if phrase.isEmpty {
                            Text("Tap pictures to build a sentence")
                                .font(.body)
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 6)
                        } else {
                            ForEach(phrase.tokens) { token in
                                tokenChip(token)
                                    .id(token.id)
                            }
                        }
                    }
                    .padding(.vertical, 6)
                }
                .scrollIndicators(.hidden)
                .onChange(of: phrase.tokens.count) { _, _ in
                    if let last = phrase.tokens.last {
                        proxy.scrollTo(last.id, anchor: .trailing)
                    }
                }
            }
            .frame(minHeight: 56)
            .accessibilityElement(children: .contain)
            .accessibilityLabel(
                phrase.isEmpty
                    ? "Sentence strip, empty"
                    : "Sentence strip: \(phrase.sentenceText)"
            )

            HStack(spacing: 8) {
                Button {
                    phrase.speak(using: speech, settings: settings)
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.title3)
                        .frame(width: 52, height: 52)
                }
                .buttonStyle(.borderedProminent)
                .disabled(phrase.isEmpty)
                .accessibilityLabel("Speak sentence")

                Button {
                    phrase.removeLast()
                } label: {
                    Image(systemName: "delete.left")
                        .font(.title3)
                        .frame(width: 52, height: 52)
                }
                .buttonStyle(.bordered)
                .disabled(phrase.isEmpty)
                .accessibilityLabel("Remove last word")

                Button(role: .destructive) {
                    phrase.clear()
                } label: {
                    Image(systemName: "trash")
                        .font(.title3)
                        .frame(width: 52, height: 52)
                }
                .buttonStyle(.bordered)
                .disabled(phrase.isEmpty)
                .accessibilityLabel("Clear sentence")
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    private func tokenChip(_ token: PhraseToken) -> some View {
        Button {
            phrase.remove(token)
        } label: {
            HStack(spacing: 6) {
                IconImageView(
                    imageName: token.imageName,
                    customImageData: token.customImageData,
                    accent: (TileColor(rawValue: token.colorName) ?? .sky)
                        .tileAccent(highContrast: settings.highContrast)
                )
                .frame(width: 30, height: 30)
                Text(token.title)
                    .font(.headline)
                    .lineLimit(1)
                    .foregroundStyle(TileColor.ink)
            }
            .padding(.horizontal, 10)
            .frame(minHeight: 48)
            .background(
                Capsule().fill(
                    (TileColor(rawValue: token.colorName) ?? .sky)
                        .tileFill(highContrast: settings.highContrast)
                )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(token.title), in sentence")
        .accessibilityHint("Removes this word from the sentence")
    }
}
