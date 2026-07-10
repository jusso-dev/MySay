import SwiftData
import SwiftUI

/// Parent-mode list of all icons, grouped by category, with add, edit,
/// and delete.
struct IconManagerView: View {
    @Environment(\.modelContext) private var context

    @Query(sort: \IconCategory.sortOrder) private var categories: [IconCategory]

    @State private var editingIcon: IconItem?
    @State private var addingToCategory: IconCategory?
    @State private var searchText = ""

    var body: some View {
        List {
            ForEach(categories) { category in
                Section(category.name) {
                    ForEach(filteredIcons(in: category)) { icon in
                        Button {
                            editingIcon = icon
                        } label: {
                            iconRow(icon)
                        }
                        .foregroundStyle(.primary)
                    }
                    .onDelete { offsets in
                        delete(offsets, in: category)
                    }

                    Button {
                        addingToCategory = category
                    } label: {
                        Label("Add Icon to \(category.name)", systemImage: "plus")
                    }
                }
            }
        }
        .navigationTitle("Manage Icons")
        .searchable(text: $searchText, prompt: "Filter icons")
        .sheet(item: $editingIcon) { icon in
            IconEditorView(icon: icon)
        }
        .sheet(item: $addingToCategory) { category in
            IconEditorView(icon: nil, defaultCategoryID: category.id)
        }
    }

    private func iconRow(_ icon: IconItem) -> some View {
        HStack(spacing: 14) {
            IconImageView(
                imageName: icon.imageName,
                customImageData: icon.customImageData,
                accent: icon.tileColor.accent
            )
            .frame(width: 44, height: 44)

            VStack(alignment: .leading) {
                Text(icon.title)
                    .font(.body.weight(.semibold))
                Text("Says “\(icon.spokenText)”")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if icon.isHidden {
                Image(systemName: "eye.slash.fill")
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Hidden from child")
            }
            if icon.recordedAudioData != nil {
                Image(systemName: "waveform.circle.fill")
                    .foregroundStyle(.tint)
                    .accessibilityLabel("Has recorded voice")
            }
            if icon.isFavourite {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                    .accessibilityLabel("Favourite")
            }
            if icon.usageCount > 0 {
                Text("\(icon.usageCount) taps")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func filteredIcons(in category: IconCategory) -> [IconItem] {
        let sorted = category.icons.sorted(by: IconItem.displaySort)
        guard !searchText.isEmpty else { return sorted }
        return sorted.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    private func delete(_ offsets: IndexSet, in category: IconCategory) {
        let icons = filteredIcons(in: category)
        for offset in offsets where icons.indices.contains(offset) {
            context.delete(icons[offset])
        }
        try? context.save()
    }
}
