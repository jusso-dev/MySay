import Foundation
import SwiftData

/// Owns the SwiftData container, first-launch seeding, and JSON
/// export/import for backup or moving between iPads.
@MainActor
final class DataStore {
    let container: ModelContainer
    var context: ModelContext { container.mainContext }

    /// - Parameter inMemory: true for unit tests, previews, and UI tests
    ///   so runs never touch the real on-device store.
    init(inMemory: Bool = false) throws {
        let schema = Schema([
            IconItem.self,
            IconCategory.self,
            Board.self,
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory
        )
        container = try ModelContainer(for: schema, configurations: [configuration])
    }

    // MARK: - Seeding

    /// Load the bundled starter vocabulary on first launch, and apply
    /// in-place upgrades (new seed categories, position backfill) on
    /// existing libraries.
    func seedIfNeeded() {
        let count = (try? context.fetchCount(FetchDescriptor<IconCategory>())) ?? 0
        if count == 0 {
            seed()
        } else {
            upgradeExistingLibrary()
        }
    }

    func seed() {
        for definition in SeedData.categories {
            insertSeedCategory(definition)
        }
        attachLizardEasterEgg()
        try? context.save()
    }

    /// Easter egg: the Lizard tile ships with a real recording instead of
    /// synthesised speech. Uses the same recorded-voice path parents use.
    private func attachLizardEasterEgg() {
        guard let url = Bundle.main.url(forResource: "lizard-button", withExtension: "mp3"),
              let data = try? Data(contentsOf: url)
        else { return }
        let lizards = (try? context.fetch(FetchDescriptor<IconItem>(
            predicate: #Predicate { $0.title == "Lizard" }
        ))) ?? []
        for lizard in lizards where lizard.recordedAudioData == nil {
            lizard.recordedAudioData = data
        }
    }

    private func insertSeedCategory(_ definition: SeedData.CategoryDefinition) {
        let category = IconCategory(
            name: definition.name,
            symbolName: definition.symbolName,
            colorName: definition.color.rawValue,
            sortOrder: definition.sortOrder,
            isBuiltIn: true
        )
        context.insert(category)
        // Seed order becomes the stable tile position (motor planning:
        // words keep their place as the vocabulary grows).
        for (position, icon) in SeedData.icons
            .filter({ $0.category == definition.name }).enumerated() {
            context.insert(IconItem(
                id: icon.id,
                title: icon.title,
                imageName: icon.imageName,
                phraseText: icon.phraseText,
                colorName: definition.color.rawValue,
                symbolSource: .systemSymbol,
                sortOrder: position,
                category: category
            ))
        }
    }

    /// Upgrades applied to libraries created by earlier versions:
    /// 1. Add seed categories introduced later (e.g. Quick Phrases).
    /// 2. Backfill tile positions for categories that predate manual
    ///    ordering, freezing today's alphabetical layout so positions
    ///    stay stable from here on.
    func upgradeExistingLibrary() {
        let existing = (try? context.fetch(FetchDescriptor<IconCategory>())) ?? []
        let existingNames = Set(existing.map(\.name))
        for definition in SeedData.categories where !existingNames.contains(definition.name) {
            insertSeedCategory(definition)
        }
        for category in existing {
            let icons = category.icons
            guard icons.count > 1, icons.allSatisfy({ $0.sortOrder == 0 }) else { continue }
            let frozen = icons.sorted {
                $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }
            for (position, icon) in frozen.enumerated() {
                icon.sortOrder = position
            }
        }
        attachLizardEasterEgg()
        try? context.save()
    }

    // MARK: - Export / Import

    /// Snapshot everything a family would want to move to another iPad.
    func exportData() throws -> Data {
        try DataStoreActions.export(context: context)
    }

    /// Replace the current library with an exported archive.
    func importData(_ data: Data) throws {
        try DataStoreActions.importArchive(data, context: context)
    }
}

/// On-disk JSON format for backup and transfer. Versioned so future
/// releases (iCloud sync, shared family boards) can migrate old archives.
/// Version 2 added tile positions, hidden flags, recorded audio, and
/// boards; the new fields are optional so version-1 archives still import.
nonisolated struct ExportArchive: Codable, Sendable {
    var version: Int
    var categories: [Category]
    var boards: [BoardEntry]?

    struct Category: Codable, Sendable {
        var name: String
        var symbolName: String
        var colorName: String
        var sortOrder: Int
        var isBuiltIn: Bool
        var icons: [Icon]
    }

    struct Icon: Codable, Sendable {
        var id: UUID
        var title: String
        var imageName: String
        var phraseText: String
        var colorName: String
        var symbolSource: String
        var isCustom: Bool
        var isFavourite: Bool
        var favouriteOrder: Int
        var usageCount: Int
        var sortOrder: Int?
        var isHidden: Bool?
        var customImageBase64: String?
        var recordedAudioBase64: String?
    }

    struct BoardEntry: Codable, Sendable {
        var id: UUID
        var name: String
        var symbolName: String
        var sortOrder: Int
        var iconIDs: [UUID]
    }
}
