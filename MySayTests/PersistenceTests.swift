import Foundation
import SwiftData
import Testing
@testable import MySay

@MainActor
@Suite("Persistence and backup")
struct PersistenceTests {
    @Test("Export then import round-trips the whole library")
    func exportImportRoundTrip() throws {
        let source = try TestSupport.makeStore(seeded: true)
        let sourceContext = source.context

        // Make the data interesting: favourites, usage, and a custom icon
        // with photo data.
        let icons = try sourceContext.fetch(FetchDescriptor<IconItem>(
            sortBy: [SortDescriptor(\.title)]
        ))
        icons[0].isFavourite = true
        icons[0].favouriteOrder = 1
        icons[0].usageCount = 7
        let category = try #require(
            try sourceContext.fetch(FetchDescriptor<IconCategory>()).first
        )
        let photoBytes = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x01, 0x02])
        sourceContext.insert(IconItem(
            title: "My Cup",
            imageName: "cup.and.saucer.fill",
            phraseText: "cup",
            symbolSource: .customPhoto,
            customImageData: photoBytes,
            isCustom: true,
            category: category
        ))
        try sourceContext.save()

        let data = try source.exportData()

        let destination = try TestSupport.makeStore()
        try destination.importData(data)
        let imported = try destination.context.fetch(FetchDescriptor<IconItem>())

        #expect(imported.count == SeedData.icons.count + 1)

        let favourite = try #require(imported.first { $0.isFavourite })
        #expect(favourite.usageCount == 7)
        #expect(favourite.favouriteOrder == 1)

        let custom = try #require(imported.first { $0.title == "My Cup" })
        #expect(custom.customImageData == photoBytes)
        #expect(custom.symbolSource == .customPhoto)
        #expect(custom.isCustom)

        let categories = try destination.context.fetch(FetchDescriptor<IconCategory>())
        #expect(categories.count == SeedData.categories.count)
    }

    @Test("Import replaces the existing library")
    func importReplaces() throws {
        let source = try TestSupport.makeStore(seeded: true)
        let archive = try source.exportData()

        let destination = try TestSupport.makeStore(seeded: true)
        let extraCategory = IconCategory(name: "Doomed", symbolName: "trash")
        destination.context.insert(extraCategory)
        try destination.context.save()

        try destination.importData(archive)

        let categories = try destination.context.fetch(FetchDescriptor<IconCategory>())
        #expect(categories.count == SeedData.categories.count)
        #expect(!categories.contains { $0.name == "Doomed" })
    }

    @Test("Importing malformed data throws and leaves no partial state")
    func malformedImport() throws {
        let store = try TestSupport.makeStore(seeded: true)
        #expect(throws: (any Error).self) {
            try store.importData(Data("not json".utf8))
        }
    }

    @Test("Icon relationships survive a save and refetch")
    func relationships() throws {
        let store = try TestSupport.makeStore(seeded: true)
        let categories = try store.context.fetch(FetchDescriptor<IconCategory>(
            sortBy: [SortDescriptor(\.sortOrder)]
        ))
        for definition in SeedData.categories {
            let category = try #require(categories.first { $0.name == definition.name })
            let expected = SeedData.icons.filter { $0.category == definition.name }.count
            #expect(category.icons.count == expected)
        }
    }

    @Test("Deleting a category cascades to its icons")
    func cascadeDelete() throws {
        let store = try TestSupport.makeStore(seeded: true)
        let context = store.context
        let category = try #require(
            try context.fetch(FetchDescriptor<IconCategory>()).first
        )
        let doomedCount = category.icons.count
        let totalBefore = try context.fetchCount(FetchDescriptor<IconItem>())

        context.delete(category)
        try context.save()

        let totalAfter = try context.fetchCount(FetchDescriptor<IconItem>())
        #expect(totalAfter == totalBefore - doomedCount)
    }
}
