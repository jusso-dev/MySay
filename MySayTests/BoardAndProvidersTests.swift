import Foundation
import SwiftData
import Testing
@testable import MySay

@MainActor
@Suite("Boards")
struct BoardTests {
    @Test("Boards persist an ordered icon list by reference")
    func boardPersistence() throws {
        let store = try TestSupport.makeStore(seeded: true)
        let context = store.context
        let icons = Array(
            try context.fetch(FetchDescriptor<IconItem>(
                sortBy: [SortDescriptor(\.title)]
            )).prefix(3)
        )

        let board = Board(
            name: "Morning Routine",
            symbolName: "sunrise.fill",
            sortOrder: 1,
            iconIDs: icons.map(\.id)
        )
        context.insert(board)
        try context.save()

        let fetched = try #require(
            try context.fetch(FetchDescriptor<Board>()).first
        )
        #expect(fetched.name == "Morning Routine")
        #expect(fetched.iconIDs == icons.map(\.id))
        #expect(fetched.symbolName == "sunrise.fill")
    }

    @Test("Deleting a board never deletes vocabulary")
    func boardDeletionKeepsIcons() throws {
        let store = try TestSupport.makeStore(seeded: true)
        let context = store.context
        let iconCountBefore = try context.fetchCount(FetchDescriptor<IconItem>())

        let board = Board(name: "Doomed", iconIDs: [])
        context.insert(board)
        try context.save()
        context.delete(board)
        try context.save()

        #expect(try context.fetchCount(FetchDescriptor<IconItem>()) == iconCountBefore)
        #expect(try context.fetchCount(FetchDescriptor<Board>()) == 0)
    }
}

@MainActor
@Suite("Symbol providers")
struct SymbolProviderTests {
    @Test("Providers expose stable identities and sources")
    func providerIdentities() {
        let arasaac = ArasaacSymbolProvider()
        #expect(arasaac.providerID == "arasaac")
        #expect(arasaac.source == .arasaac)

        let open = OpenSymbolsProvider()
        #expect(open.providerID == "opensymbols")
        #expect(open.source == .openSymbols)
    }

    @Test("Stub providers return no results until packs ship")
    func stubSearch() async throws {
        #expect(try await ArasaacSymbolProvider().searchSymbols(matching: "drink").isEmpty)
        #expect(try await OpenSymbolsProvider().searchSymbols(matching: "drink").isEmpty)
    }

    @Test("Fetching artwork without an installed pack throws a friendly error")
    func stubImageData() async {
        let symbol = ImportableSymbol(
            id: "1", title: "Drink", providerID: "arasaac", attribution: "CC BY-NC-SA"
        )
        await #expect(throws: SymbolProviderError.self) {
            _ = try await ArasaacSymbolProvider().imageData(for: symbol)
        }
        let error = SymbolProviderError.packNotInstalled("ARASAAC")
        #expect(error.errorDescription?.contains("ARASAAC") == true)
    }

    @Test("Symbol sources round-trip through raw values")
    func symbolSourceRoundTrip() {
        for source in SymbolSource.allCases {
            #expect(SymbolSource(rawValue: source.rawValue) == source)
        }
    }
}
