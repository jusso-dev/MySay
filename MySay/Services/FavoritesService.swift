import Foundation
import SwiftData

/// Manages the favourites flag, manual ordering, and sorted retrieval.
final class FavoritesService {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func toggleFavourite(_ icon: IconItem) {
        if icon.isFavourite {
            icon.isFavourite = false
            icon.favouriteOrder = 0
        } else {
            icon.isFavourite = true
            icon.favouriteOrder = nextManualOrder()
        }
        try? context.save()
    }

    func favourites(sortedBy mode: FavouriteSortMode) -> [IconItem] {
        let descriptor = FetchDescriptor<IconItem>(
            predicate: #Predicate { $0.isFavourite }
        )
        let items = (try? context.fetch(descriptor)) ?? []
        return Self.sort(items, by: mode)
    }

    /// Persist a new manual order after a drag-to-reorder.
    func setManualOrder(_ icons: [IconItem]) {
        for (index, icon) in icons.enumerated() {
            icon.favouriteOrder = index + 1
        }
        try? context.save()
    }

    private func nextManualOrder() -> Int {
        let descriptor = FetchDescriptor<IconItem>(
            predicate: #Predicate { $0.isFavourite }
        )
        let highest = ((try? context.fetch(descriptor)) ?? [])
            .map(\.favouriteOrder)
            .max() ?? 0
        return highest + 1
    }

    /// Pure sorting logic, exposed for unit tests.
    nonisolated static func sort(_ icons: [IconItem], by mode: FavouriteSortMode) -> [IconItem] {
        switch mode {
        case .manual:
            icons.sorted { $0.favouriteOrder < $1.favouriteOrder }
        case .mostUsed:
            icons.sorted {
                $0.usageCount != $1.usageCount
                    ? $0.usageCount > $1.usageCount
                    : $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }
        case .alphabetical:
            icons.sorted {
                $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }
        }
    }
}
