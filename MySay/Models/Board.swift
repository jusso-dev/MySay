import Foundation
import SwiftData

/// A custom communication board: a named, ordered collection of icons
/// curated by a parent or therapist (e.g. "Morning routine", "At Grandma's").
///
/// Boards reference icons rather than owning them, so deleting a board
/// never deletes vocabulary. `iconIDs` keeps an explicit display order.
@Model
final class Board {
    @Attribute(.unique) var id: UUID
    var name: String
    var symbolName: String
    var sortOrder: Int
    var createdAt: Date

    /// Ordered icon IDs; resolved against the icon store at display time.
    var iconIDs: [UUID]

    init(
        id: UUID = UUID(),
        name: String,
        symbolName: String = "square.grid.2x2.fill",
        sortOrder: Int = 0,
        iconIDs: [UUID] = []
    ) {
        self.id = id
        self.name = name
        self.symbolName = symbolName
        self.sortOrder = sortOrder
        self.createdAt = Date()
        self.iconIDs = iconIDs
    }
}
