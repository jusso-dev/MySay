import SwiftData
import Testing
@testable import MySay

@Suite("Search")
struct SearchViewModelTests {
    @Test("Empty query returns nothing")
    func emptyQuery() throws {
        let store = try TestSupport.makeStore(seeded: true)
        let icons = try store.context.fetch(FetchDescriptor<IconItem>())
        #expect(SearchViewModel.filter(icons, matching: "").isEmpty)
        #expect(SearchViewModel.filter(icons, matching: "   ").isEmpty)
    }

    @Test("Matches icon titles case-insensitively")
    func titleMatch() throws {
        let store = try TestSupport.makeStore(seeded: true)
        let icons = try store.context.fetch(FetchDescriptor<IconItem>())
        let results = SearchViewModel.filter(icons, matching: "drink")
        #expect(results.contains { $0.title == "Drink" })
    }

    @Test("Matches by category name")
    func categoryMatch() throws {
        let store = try TestSupport.makeStore(seeded: true)
        let icons = try store.context.fetch(FetchDescriptor<IconItem>())
        let results = SearchViewModel.filter(icons, matching: "Feelings")
        let feelingsCount = SeedData.icons.filter { $0.category == "Feelings" }.count
        #expect(results.count >= feelingsCount)
    }

    @Test("Prefix matches rank before substring matches")
    func prefixRanking() {
        let apple = TestSupport.makeIcon(title: "Apple")
        let pineapple = TestSupport.makeIcon(title: "Pineapple")
        let results = SearchViewModel.filter([pineapple, apple], matching: "app")
        #expect(results.map(\.title) == ["Apple", "Pineapple"])
    }

    @Test("No match returns an empty list")
    func noMatch() throws {
        let store = try TestSupport.makeStore(seeded: true)
        let icons = try store.context.fetch(FetchDescriptor<IconItem>())
        #expect(SearchViewModel.filter(icons, matching: "zzzxqwy").isEmpty)
    }
}
