import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// Grid of all icons in one category.
///
/// The toolbar pencil unlocks parent edit mode (passcode-gated): tap a
/// tile to edit it in place, drag tiles to reorder (positions persist —
/// motor planning), toggle the eye badge to hide a word without moving
/// anything, and add new words at the end.
struct CategoryDetailView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var context

    let category: IconCategory

    @State private var editMode = false
    @State private var showGate = false
    @State private var editingIcon: IconItem?
    @State private var addingIcon = false

    var body: some View {
        ScrollView {
            if displayedIcons.isEmpty && !editMode {
                EmptyStateView(
                    symbolName: "square.dashed",
                    title: "No words yet",
                    message: "A parent can add words using the pencil button, or from Parent Mode in Settings."
                )
                .frame(maxWidth: .infinity)
                .padding(.top, 80)
            } else {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(displayedIcons) { icon in
                        IconTileView(
                            icon: icon,
                            editMode: editMode,
                            onEdit: { editingIcon = $0 }
                        )
                        .draggable(icon.id.uuidString) {
                            dragPreview(icon)
                        }
                        .dropDestination(for: String.self) { items, _ in
                            guard editMode, let idString = items.first else { return false }
                            return moveIcon(idString: idString, before: icon)
                        }
                    }

                    if editMode {
                        addWordTile
                    }
                }
                .padding(.horizontal)
                .padding(.vertical)
            }
        }
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if editMode {
                    Button("Done") { editMode = false }
                        .font(.body.weight(.semibold))
                        .accessibilityHint("Leaves board editing")
                } else {
                    Button {
                        showGate = true
                    } label: {
                        Label("Edit Board", systemImage: "pencil")
                    }
                    .accessibilityHint("Requires the parent passcode. Edit, reorder, hide, and add words.")
                }
            }
        }
        .sheet(isPresented: $showGate) {
            PasscodeGateView {
                showGate = false
                editMode = true
            }
        }
        .sheet(item: $editingIcon) { icon in
            IconEditorView(icon: icon)
        }
        .sheet(isPresented: $addingIcon) {
            IconEditorView(icon: nil, defaultCategoryID: category.id)
        }
    }

    /// Children see visible words; edit mode shows hidden ones dimmed.
    private var displayedIcons: [IconItem] {
        category.icons
            .filter { editMode || !$0.isHidden }
            .sorted(by: IconItem.displaySort)
    }

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 16), count: settings.gridColumns)
    }

    private var addWordTile: some View {
        Button {
            addingIcon = true
        } label: {
            VStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.largeTitle)
                Text("Add Word")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .frame(minWidth: 80, minHeight: 80)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                    .foregroundStyle(.secondary)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add a word to \(category.name)")
    }

    private func dragPreview(_ icon: IconItem) -> some View {
        Image(systemName: icon.imageName)
            .font(.largeTitle)
            .padding(20)
            .background(RoundedRectangle(cornerRadius: 16).fill(icon.tileColor.fill))
    }

    /// Reposition `idString`'s icon in front of `target`, then persist a
    /// clean 0…n ordering for the whole category.
    private func moveIcon(idString: String, before target: IconItem) -> Bool {
        guard let id = UUID(uuidString: idString),
              id != target.id,
              let source = category.icons.first(where: { $0.id == id })
        else { return false }

        var ordered = category.icons.sorted(by: IconItem.displaySort)
        ordered.removeAll { $0.id == source.id }
        let insertAt = ordered.firstIndex { $0.id == target.id } ?? ordered.count
        ordered.insert(source, at: insertAt)
        for (position, icon) in ordered.enumerated() {
            icon.sortOrder = position
        }
        try? context.save()
        return true
    }
}
