import Foundation
import SwiftData
import Testing
@testable import MySay

@MainActor
@Suite("Icon editor")
struct IconEditorViewModelTests {
    @Test("Cannot save without a title and category")
    func validation() throws {
        let store = try TestSupport.makeStore(seeded: true)
        let category = try #require(
            try store.context.fetch(FetchDescriptor<IconCategory>()).first
        )

        let viewModel = IconEditorViewModel()
        #expect(!viewModel.canSave)

        viewModel.title = "Cup"
        #expect(!viewModel.canSave)

        viewModel.selectedCategoryID = category.id
        #expect(viewModel.canSave)
    }

    @Test("Phrase falls back to the lowercased title")
    func phraseFallback() {
        let viewModel = IconEditorViewModel()
        viewModel.title = "My Cup"
        #expect(viewModel.effectivePhrase == "my cup")

        viewModel.phraseText = "I want my cup"
        #expect(viewModel.effectivePhrase == "I want my cup")
    }

    @Test("Saving creates a custom icon in the chosen category")
    func saveNewIcon() throws {
        let store = try TestSupport.makeStore(seeded: true)
        let categories = try store.context.fetch(FetchDescriptor<IconCategory>())
        let category = try #require(categories.first { $0.name == "Drinks" })

        let viewModel = IconEditorViewModel(defaultCategoryID: category.id)
        viewModel.title = "My Cup"
        viewModel.symbolName = "cup.and.saucer.fill"
        viewModel.tileColor = .teal
        viewModel.save(in: store.context, categories: categories)

        let saved = try #require(
            try store.context.fetch(FetchDescriptor<IconItem>())
                .first { $0.title == "My Cup" }
        )
        #expect(saved.isCustom)
        #expect(saved.category?.id == category.id)
        #expect(saved.phraseText == "my cup")
        #expect(saved.tileColor == .teal)
        #expect(saved.symbolSource == .systemSymbol)
    }

    @Test("Editing updates the existing icon in place")
    func editExisting() throws {
        let store = try TestSupport.makeStore(seeded: true)
        let categories = try store.context.fetch(FetchDescriptor<IconCategory>())
        let icon = try #require(
            try store.context.fetch(FetchDescriptor<IconItem>())
                .first { $0.title == "Drink" }
        )
        let countBefore = try store.context.fetchCount(FetchDescriptor<IconItem>())

        let viewModel = IconEditorViewModel(icon: icon)
        viewModel.title = "Cuppa"
        viewModel.phraseText = "cuppa"
        viewModel.save(in: store.context, categories: categories)

        #expect(icon.title == "Cuppa")
        #expect(icon.phraseText == "cuppa")
        let countAfter = try store.context.fetchCount(FetchDescriptor<IconItem>())
        #expect(countAfter == countBefore)
    }

    @Test("Setting a photo marks the icon as a custom photo")
    func photoSourceTracking() throws {
        let store = try TestSupport.makeStore(seeded: true)
        let categories = try store.context.fetch(FetchDescriptor<IconCategory>())
        let category = try #require(categories.first)

        let viewModel = IconEditorViewModel(defaultCategoryID: category.id)
        viewModel.title = "Cup"
        // Tiny valid-enough JPEG header; resize keeps nil for invalid
        // image data, so emulate the post-resize assignment directly.
        viewModel.customImageData = Data([0xFF, 0xD8, 0xFF])
        viewModel.save(in: store.context, categories: categories)

        let saved = try #require(
            try store.context.fetch(FetchDescriptor<IconItem>())
                .first { $0.title == "Cup" && $0.isCustom }
        )
        #expect(saved.symbolSource == .customPhoto)
        #expect(saved.customImageData == Data([0xFF, 0xD8, 0xFF]))
    }
}
