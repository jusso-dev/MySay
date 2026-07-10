import SwiftData
import SwiftUI

/// Create or edit a custom board: name, symbol, and an ordered word list.
/// Words on the board can be reordered (drag) or removed; the picker
/// below adds any word from the library.
struct BoardEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    /// nil = creating a new board.
    let board: Board?

    @Query(sort: \IconCategory.sortOrder) private var categories: [IconCategory]
    @Query private var allIcons: [IconItem]

    @State private var name = ""
    @State private var symbolName = "rectangle.3.group.fill"
    @State private var iconIDs: [UUID] = []
    @State private var pickerSearch = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Board") {
                    TextField("Board name (e.g. Morning Routine)", text: $name)
                    TextField("SF Symbol name", text: $symbolName)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                Section("Words on this board (drag to reorder)") {
                    if iconIDs.isEmpty {
                        Text("No words yet — add some below.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(iconIDs, id: \.self) { iconID in
                        if let icon = iconsByID[iconID] {
                            HStack(spacing: 12) {
                                IconImageView(
                                    imageName: icon.imageName,
                                    customImageData: icon.customImageData,
                                    accent: icon.tileColor.accent
                                )
                                .frame(width: 36, height: 36)
                                Text(icon.title)
                            }
                        }
                    }
                    .onMove { source, destination in
                        iconIDs.move(fromOffsets: source, toOffset: destination)
                    }
                    .onDelete { offsets in
                        iconIDs.remove(atOffsets: offsets)
                    }
                }

                Section("Add words") {
                    TextField("Search the word library", text: $pickerSearch)
                    ForEach(pickerResults) { icon in
                        Button {
                            iconIDs.append(icon.id)
                        } label: {
                            HStack(spacing: 12) {
                                IconImageView(
                                    imageName: icon.imageName,
                                    customImageData: icon.customImageData,
                                    accent: icon.tileColor.accent
                                )
                                .frame(width: 36, height: 36)
                                Text(icon.title)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.tint)
                                    .accessibilityHidden(true)
                            }
                        }
                        .accessibilityLabel("Add \(icon.title) to board")
                    }
                }
            }
            .navigationTitle(board == nil ? "New Board" : "Edit Board")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let board {
                    name = board.name
                    symbolName = board.symbolName
                    iconIDs = board.iconIDs
                }
            }
        }
    }

    private var iconsByID: [UUID: IconItem] {
        Dictionary(uniqueKeysWithValues: allIcons.map { ($0.id, $0) })
    }

    /// Library words matching the search, excluding ones already on the
    /// board. Empty search shows a starter slice so the list isn't blank.
    private var pickerResults: [IconItem] {
        let onBoard = Set(iconIDs)
        let candidates = allIcons
            .filter { !onBoard.contains($0.id) }
            .sorted {
                $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }
        let trimmed = pickerSearch.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return Array(candidates.prefix(8)) }
        return candidates.filter { $0.title.localizedCaseInsensitiveContains(trimmed) }
    }

    private func save() {
        let cleanName = name.trimmingCharacters(in: .whitespaces)
        if let board {
            board.name = cleanName
            board.symbolName = symbolName
            board.iconIDs = iconIDs
        } else {
            let maxOrder = (try? context.fetch(FetchDescriptor<Board>()))?
                .map(\.sortOrder).max() ?? 0
            context.insert(Board(
                name: cleanName,
                symbolName: symbolName,
                sortOrder: maxOrder + 1,
                iconIDs: iconIDs
            ))
        }
        try? context.save()
    }
}
