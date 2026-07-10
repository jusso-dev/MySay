import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// The protected parent area: manage icons and categories, reset usage
/// statistics, and back up / restore the library as JSON.
struct ParentModeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @Query(sort: \IconCategory.sortOrder) private var categories: [IconCategory]

    @State private var showResetConfirmation = false
    @State private var showImporter = false
    @State private var exportDocument: JSONDocument?
    @State private var showExporter = false
    @State private var statusMessage: String?

    var body: some View {
        NavigationStack {
            List {
                Section("Vocabulary") {
                    NavigationLink {
                        IconManagerView()
                    } label: {
                        Label("Manage Icons", systemImage: "square.grid.2x2")
                    }
                    NavigationLink {
                        CategoryManagerView()
                    } label: {
                        Label("Manage Categories", systemImage: "folder")
                    }
                    NavigationLink {
                        BoardManagerView()
                    } label: {
                        Label("Manage Boards", systemImage: "rectangle.3.group")
                    }
                }

                Section("Statistics") {
                    Button(role: .destructive) {
                        showResetConfirmation = true
                    } label: {
                        Label("Reset Usage Statistics", systemImage: "arrow.counterclockwise")
                    }
                }

                Section {
                    Button {
                        prepareExport()
                    } label: {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                    }
                    Button {
                        showImporter = true
                    } label: {
                        Label("Import Data", systemImage: "square.and.arrow.down")
                    }
                } header: {
                    Text("Backup")
                } footer: {
                    Text("Exports the whole library — categories, icons, photos, favourites, and usage counts — as a single JSON file you can AirDrop to another iPad. Importing replaces the current library.")
                }

                if let statusMessage {
                    Section {
                        Text(statusMessage)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Parent Mode")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog(
                "Reset all usage statistics?",
                isPresented: $showResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset Statistics", role: .destructive) {
                    UsageTrackingService(context: context).resetAllStatistics()
                    statusMessage = "Usage statistics were reset."
                }
            } message: {
                Text("Clears every icon's tap count and history. This cannot be undone.")
            }
            .fileExporter(
                isPresented: $showExporter,
                document: exportDocument,
                contentType: .json,
                defaultFilename: "MySay Backup"
            ) { result in
                if case .success = result {
                    statusMessage = "Backup exported."
                }
            }
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: [.json]
            ) { result in
                handleImport(result)
            }
        }
    }

    private func prepareExport() {
        do {
            let data = try DataStoreActions.export(context: context)
            exportDocument = JSONDocument(data: data)
            showExporter = true
        } catch {
            statusMessage = "Export failed: \(error.localizedDescription)"
        }
    }

    private func handleImport(_ result: Result<URL, any Error>) {
        do {
            let url = try result.get()
            guard url.startAccessingSecurityScopedResource() else {
                statusMessage = "Couldn't open that file."
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }
            let data = try Data(contentsOf: url)
            try DataStoreActions.importArchive(data, context: context)
            statusMessage = "Library imported."
        } catch {
            statusMessage = "Import failed: \(error.localizedDescription)"
        }
    }
}

/// Simple JSON `FileDocument` wrapper for the exporter.
nonisolated struct JSONDocument: FileDocument {
    static let readableContentTypes: [UTType] = [.json]

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
