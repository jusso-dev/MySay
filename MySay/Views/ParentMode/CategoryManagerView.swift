import SwiftData
import SwiftUI

/// Parent-mode category management: add, rename, recolour, reorder, delete.
struct CategoryManagerView: View {
    @Environment(\.modelContext) private var context

    @Query(sort: \IconCategory.sortOrder) private var categories: [IconCategory]

    @State private var editingCategory: IconCategory?
    @State private var showAddSheet = false
    @State private var pendingDelete: IconCategory?

    var body: some View {
        List {
            Section {
                ForEach(categories) { category in
                    Button {
                        editingCategory = category
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: category.symbolName)
                                .font(.title3)
                                .foregroundStyle(category.tileColor.accent)
                                .frame(width: 36)
                            Text(category.name)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.primary)
                            Spacer()
                            Text("\(category.icons.count) icons")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .swipeActions {
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            pendingDelete = category
                        }
                    }
                }
                .onMove(perform: move)
            } footer: {
                Text("Deleting a category also deletes every icon inside it.")
            }
        }
        .navigationTitle("Manage Categories")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddSheet = true
                } label: {
                    Label("Add Category", systemImage: "plus")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
        }
        .sheet(item: $editingCategory) { category in
            CategoryEditorSheet(category: category)
        }
        .sheet(isPresented: $showAddSheet) {
            CategoryEditorSheet(category: nil)
        }
        .confirmationDialog(
            "Delete “\(pendingDelete?.name ?? "")” and its \(pendingDelete?.icons.count ?? 0) icons?",
            isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete Category", role: .destructive) {
                if let category = pendingDelete {
                    context.delete(category)
                    try? context.save()
                }
                pendingDelete = nil
            }
        }
    }

    private func move(from source: IndexSet, to destination: Int) {
        var reordered = categories
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, category) in reordered.enumerated() {
            category.sortOrder = index
        }
        try? context.save()
    }
}

/// Add/rename a category and pick its symbol and colour.
private struct CategoryEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    let category: IconCategory?

    @State private var name = ""
    @State private var symbolName = "folder.fill"
    @State private var color = TileColor.sky

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Category name", text: $name)
                }
                Section("Symbol") {
                    TextField("SF Symbol name", text: $symbolName)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    IconImageView(imageName: symbolName, customImageData: nil, accent: color.accent)
                        .frame(width: 60, height: 60)
                        .accessibilityLabel("Symbol preview")
                }
                Section("Colour") {
                    Picker("Tile colour", selection: $color) {
                        ForEach(TileColor.allCases, id: \.self) { tileColor in
                            HStack {
                                Circle()
                                    .fill(tileColor.accent)
                                    .frame(width: 22, height: 22)
                                Text(tileColor.displayName)
                            }
                            .tag(tileColor)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
            }
            .navigationTitle(category == nil ? "New Category" : "Edit Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
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
                if let category {
                    name = category.name
                    symbolName = category.symbolName
                    color = category.tileColor
                }
            }
        }
    }

    private func save() {
        let cleanName = name.trimmingCharacters(in: .whitespaces)
        if let category {
            category.name = cleanName
            category.symbolName = symbolName
            category.colorName = color.rawValue
        } else {
            let maxOrder = (try? context.fetch(FetchDescriptor<IconCategory>()))?
                .map(\.sortOrder).max() ?? 0
            context.insert(IconCategory(
                name: cleanName,
                symbolName: symbolName,
                colorName: color.rawValue,
                sortOrder: maxOrder + 1,
                isBuiltIn: false
            ))
        }
        try? context.save()
    }
}
