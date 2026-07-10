import SwiftUI

/// The sentence strip: tokens added so far, each removable with a tap.
struct SentenceStripView: View {
    @Environment(SettingsStore.self) private var settings
    let viewModel: PhraseBuilderViewModel

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 10) {
                if viewModel.isEmpty {
                    Text("Tap pictures below to build a sentence")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                } else {
                    ForEach(viewModel.tokens) { token in
                        tokenChip(token)
                    }
                }
            }
            .padding(12)
            .frame(minHeight: 110)
        }
        .scrollIndicators(.hidden)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemGray6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color(.systemGray4), lineWidth: 1.5)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            viewModel.isEmpty
                ? "Sentence strip, empty"
                : "Sentence strip: \(viewModel.sentenceText)"
        )
    }

    private func tokenChip(_ token: PhraseToken) -> some View {
        Button {
            viewModel.remove(token)
        } label: {
            VStack(spacing: 6) {
                IconImageView(
                    imageName: token.imageName,
                    customImageData: token.customImageData,
                    accent: (TileColor(rawValue: token.colorName) ?? .sky)
                        .tileAccent(highContrast: settings.highContrast)
                )
                .frame(width: 44, height: 44)
                Text(token.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .foregroundStyle(TileColor.ink)
            }
            .padding(10)
            .frame(minWidth: 80, minHeight: 80)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill((TileColor(rawValue: token.colorName) ?? .sky)
                        .tileFill(highContrast: settings.highContrast))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(token.title), in sentence")
        .accessibilityHint("Removes this word from the sentence")
    }
}
