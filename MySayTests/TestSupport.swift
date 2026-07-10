import Foundation
import SwiftData
@testable import MySay

/// SwiftData also declares a `DataStore` protocol; prefer the app's type.
typealias DataStore = MySay.DataStore

/// Shared helpers for unit tests.
enum TestSupport {
    /// Fresh in-memory store, optionally pre-seeded with the bundled data.
    static func makeStore(seeded: Bool = false) throws -> DataStore {
        let store = try DataStore(inMemory: true)
        if seeded {
            store.seed()
        }
        return store
    }

    /// Isolated defaults so settings tests never touch real preferences.
    static func makeDefaults() -> UserDefaults {
        let name = "test-suite-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    static func makeIcon(
        title: String,
        usageCount: Int = 0,
        favouriteOrder: Int = 0,
        isFavourite: Bool = false
    ) -> IconItem {
        let icon = IconItem(
            title: title,
            imageName: "star.fill",
            phraseText: title.lowercased()
        )
        icon.usageCount = usageCount
        icon.favouriteOrder = favouriteOrder
        icon.isFavourite = isFavourite
        return icon
    }
}
