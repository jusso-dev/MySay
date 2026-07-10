import SwiftData
import SwiftUI

/// The core tappable communication tile.
///
/// Tap → speaks the word (parent's recording when present, else
/// synthesised), records usage, appends to the sentence strip when it's
/// enabled, and gives a brief calm pulse (skipped under Reduce Motion).
/// Long-press → context menu with favourite toggle. Minimum hit target
/// is 80×80.
///
/// In edit mode (parent-gated, owned by the surrounding board view) the
/// tile stops speaking: tap opens the editor, and an eye badge toggles
/// visibility without moving the tile — positions stay stable for motor
/// planning.
struct IconTileView: View {
    @Environment(SpeechService.self) private var speech
    @Environment(SettingsStore.self) private var settings
    @Environment(PhraseBuilderViewModel.self) private var phrase
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var systemContrast

    let icon: IconItem
    /// Extra action, e.g. a board view reacting to selection.
    var onSelect: ((IconItem) -> Void)?
    /// Add to the sentence strip even when the global strip is off
    /// (used by the Phrase Builder's own grid).
    var alwaysAddToPhrase = false
    /// Parent edit mode: tap edits instead of speaking.
    var editMode = false
    var onEdit: ((IconItem) -> Void)?

    @State private var isPulsing = false

    private var highContrast: Bool {
        settings.highContrast || systemContrast == .increased
    }

    var body: some View {
        Button(action: handleTap) {
            tileBody
        }
        .buttonStyle(.plain)
        .contextMenu {
            if !editMode {
                Button {
                    FavoritesService(context: context).toggleFavourite(icon)
                } label: {
                    Label(
                        icon.isFavourite ? "Remove from Favourites" : "Add to Favourites",
                        systemImage: icon.isFavourite ? "star.slash" : "star"
                    )
                }
            }
        }
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityHint(accessibilityHintText)
        .accessibilityAddTraits(icon.isFavourite && !editMode ? [.isSelected] : [])
    }

    private var tileBody: some View {
        VStack(spacing: 8) {
            IconImageView(
                imageName: icon.imageName,
                customImageData: icon.customImageData,
                accent: icon.tileColor.tileAccent(highContrast: highContrast)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(4)

            if settings.showLabels {
                Text(icon.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(icon.tileColor.tileText(highContrast: highContrast))
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .frame(minWidth: 80, minHeight: 80)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(icon.tileColor.tileFill(highContrast: highContrast))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    icon.tileColor.tileAccent(highContrast: highContrast)
                        .opacity(highContrast ? 1 : 0.25),
                    lineWidth: highContrast ? 3 : 1.5
                )
        )
        .overlay(alignment: .topTrailing) {
            if icon.isFavourite && !editMode {
                Image(systemName: "star.fill")
                    .font(.body)
                    .foregroundStyle(.yellow)
                    .padding(8)
                    .accessibilityHidden(true)
            }
        }
        .overlay(alignment: .topLeading) {
            if editMode {
                visibilityBadge
            }
        }
        .overlay(alignment: .topTrailing) {
            if editMode && icon.recordedAudioData != nil {
                Image(systemName: "waveform.circle.fill")
                    .font(.body)
                    .foregroundStyle(.tint)
                    .padding(8)
                    .accessibilityLabel("Has recorded voice")
            }
        }
        .opacity(editMode && icon.isHidden ? 0.35 : 1)
        .scaleEffect(isPulsing && !reduceMotion ? 0.95 : 1)
    }

    /// Eye badge: hide/show the word without moving any tiles.
    private var visibilityBadge: some View {
        Button {
            icon.isHidden.toggle()
            try? context.save()
        } label: {
            Image(systemName: icon.isHidden ? "eye.slash.fill" : "eye.fill")
                .font(.body)
                .foregroundStyle(.white)
                .padding(8)
                .background(Circle().fill(icon.isHidden ? Color.gray : Color.accentColor))
        }
        .buttonStyle(.plain)
        .padding(6)
        .accessibilityLabel(icon.isHidden ? "Show \(icon.title)" : "Hide \(icon.title)")
        .accessibilityHint("Hidden words keep their place and can be shown again later")
    }

    private var accessibilityLabelText: String {
        editMode && icon.isHidden ? "\(icon.title), hidden" : icon.title
    }

    private var accessibilityHintText: String {
        editMode
            ? "Opens the editor for this word"
            : "Speaks \(icon.spokenText). Double-tap and hold for favourite options."
    }

    private func handleTap() {
        if editMode {
            onEdit?(icon)
            return
        }
        speech.speak(icon: icon, settings: settings)
        UsageTrackingService(context: context).recordUsage(of: icon)
        if (settings.showSentenceStrip && settings.autoAddToSentence) || alwaysAddToPhrase {
            phrase.add(icon)
        }
        onSelect?(icon)
        guard !reduceMotion else { return }
        withAnimation(.easeOut(duration: 0.12)) { isPulsing = true }
        Task {
            try? await Task.sleep(for: .milliseconds(140))
            withAnimation(.easeOut(duration: 0.12)) { isPulsing = false }
        }
    }
}
