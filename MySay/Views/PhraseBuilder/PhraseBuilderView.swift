import SwiftData
import SwiftUI

/// Build a sentence from icons: a sentence strip across the top, big
/// Speak / Clear buttons, and the icon library below for adding words.
struct PhraseBuilderView: View {
    @Environment(SpeechService.self) private var speech
    @Environment(SettingsStore.self) private var settings
    @Environment(PhraseBuilderViewModel.self) private var viewModel

    @Query(sort: \IconCategory.sortOrder) private var categories: [IconCategory]

    @State private var selectedCategoryID: UUID?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                SentenceStripView(viewModel: viewModel)
                    .padding()

                controlButtons
                    .padding(.horizontal)
                    .padding(.bottom, 12)

                Divider()

                categoryPicker
                    .padding(.vertical, 10)

                ScrollView {
                    // Tiles append to the shared sentence themselves
                    // (alwaysAddToPhrase), so this works even when the
                    // global strip setting is off.
                    IconGridView(icons: currentIcons, alwaysAddToPhrase: true)
                        .padding(.vertical)
                }
            }
            .navigationTitle("Phrases")
            .onAppear {
                if selectedCategoryID == nil {
                    selectedCategoryID = categories.first?.id
                }
            }
        }
    }

    private var controlButtons: some View {
        HStack(spacing: 16) {
            Button {
                viewModel.speak(using: speech, settings: settings)
            } label: {
                Label("Speak Phrase", systemImage: "speaker.wave.2.fill")
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 56)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isEmpty)
            .accessibilityHint("Speaks the whole sentence aloud")

            Button {
                viewModel.removeLast()
            } label: {
                Label("Undo", systemImage: "arrow.uturn.backward")
                    .font(.title3.weight(.semibold))
                    .frame(minWidth: 120, minHeight: 56)
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.isEmpty)
            .accessibilityHint("Removes the last word")

            Button(role: .destructive) {
                viewModel.clear()
            } label: {
                Label("Clear", systemImage: "trash")
                    .font(.title3.weight(.semibold))
                    .frame(minWidth: 120, minHeight: 56)
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.isEmpty)
            .accessibilityHint("Removes every word from the sentence")
        }
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 10) {
                ForEach(categories) { category in
                    Button {
                        selectedCategoryID = category.id
                    } label: {
                        Label(category.name, systemImage: category.symbolName)
                            .font(.headline)
                            .foregroundStyle(
                                selectedCategoryID == category.id
                                    ? TileColor.ink
                                    : Color.primary
                            )
                            .padding(.horizontal, 16)
                            .frame(minHeight: 44)
                            .background(
                                Capsule().fill(
                                    selectedCategoryID == category.id
                                        ? category.tileColor.fill
                                        : Color(.systemGray6)
                                )
                            )
                            .overlay(
                                Capsule().strokeBorder(
                                    selectedCategoryID == category.id
                                        ? category.tileColor.accent
                                        : .clear,
                                    lineWidth: 2
                                )
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selectedCategoryID == category.id ? [.isSelected] : [])
                }
            }
            .padding(.horizontal)
        }
        .scrollIndicators(.hidden)
    }

    private var currentIcons: [IconItem] {
        guard let selectedCategoryID,
              let category = categories.first(where: { $0.id == selectedCategoryID })
        else { return [] }
        return category.icons
            .filter { !$0.isHidden }
            .sorted(by: IconItem.displaySort)
    }
}
