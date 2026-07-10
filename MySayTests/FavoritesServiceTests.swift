import Foundation
import SwiftData
import Testing
@testable import MySay

@MainActor
@Suite("Favourites")
struct FavoritesServiceTests {
    @Test("Toggling adds and removes a favourite")
    func toggle() throws {
        let store = try TestSupport.makeStore(seeded: true)
        let service = FavoritesService(context: store.context)
        let icon = try #require(
            try store.context.fetch(FetchDescriptor<IconItem>()).first
        )

        #expect(!icon.isFavourite)
        service.toggleFavourite(icon)
        #expect(icon.isFavourite)
        #expect(icon.favouriteOrder == 1)

        service.toggleFavourite(icon)
        #expect(!icon.isFavourite)
    }

    @Test("New favourites append to the end of the manual order")
    func manualOrderAppends() throws {
        let store = try TestSupport.makeStore(seeded: true)
        let service = FavoritesService(context: store.context)
        let icons = try store.context.fetch(FetchDescriptor<IconItem>(
            sortBy: [SortDescriptor(\.title)]
        ))

        service.toggleFavourite(icons[0])
        service.toggleFavourite(icons[1])
        service.toggleFavourite(icons[2])

        let favourites = service.favourites(sortedBy: .manual)
        #expect(favourites.map(\.favouriteOrder) == [1, 2, 3])
    }

    @Test("Sort modes order correctly")
    func sortModes() {
        let apple = TestSupport.makeIcon(title: "Apple", usageCount: 1, favouriteOrder: 3, isFavourite: true)
        let drink = TestSupport.makeIcon(title: "Drink", usageCount: 9, favouriteOrder: 1, isFavourite: true)
        let mum = TestSupport.makeIcon(title: "Mum", usageCount: 5, favouriteOrder: 2, isFavourite: true)
        let icons = [apple, drink, mum]

        #expect(FavoritesService.sort(icons, by: .manual).map(\.title) == ["Drink", "Mum", "Apple"])
        #expect(FavoritesService.sort(icons, by: .mostUsed).map(\.title) == ["Drink", "Mum", "Apple"])
        #expect(FavoritesService.sort(icons, by: .alphabetical).map(\.title) == ["Apple", "Drink", "Mum"])
    }

    @Test("Most-used sort breaks ties alphabetically")
    func mostUsedTieBreak() {
        let banana = TestSupport.makeIcon(title: "Banana", usageCount: 2, isFavourite: true)
        let apple = TestSupport.makeIcon(title: "Apple", usageCount: 2, isFavourite: true)
        #expect(
            FavoritesService.sort([banana, apple], by: .mostUsed).map(\.title)
                == ["Apple", "Banana"]
        )
    }

    @Test("Manual reorder persists new positions")
    func manualReorder() throws {
        let store = try TestSupport.makeStore(seeded: true)
        let service = FavoritesService(context: store.context)
        let icons = Array(
            try store.context.fetch(FetchDescriptor<IconItem>(
                sortBy: [SortDescriptor(\.title)]
            )).prefix(3)
        )
        for icon in icons { service.toggleFavourite(icon) }

        service.setManualOrder([icons[2], icons[0], icons[1]])
        let favourites = service.favourites(sortedBy: .manual)
        #expect(favourites.map(\.id) == [icons[2].id, icons[0].id, icons[1].id])
    }
}
