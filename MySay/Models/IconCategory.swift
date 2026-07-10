import Foundation
import SwiftData

/// A vocabulary category such as People, Food, or Feelings.
@Model
final class IconCategory {
    @Attribute(.unique) var id: UUID
    var name: String
    var symbolName: String
    var colorName: String
    var sortOrder: Int
    var isBuiltIn: Bool

    @Relationship(deleteRule: .cascade, inverse: \IconItem.category)
    var icons: [IconItem]

    init(
        id: UUID = UUID(),
        name: String,
        symbolName: String,
        colorName: String = TileColor.sky.rawValue,
        sortOrder: Int = 0,
        isBuiltIn: Bool = false
    ) {
        self.id = id
        self.name = name
        self.symbolName = symbolName
        self.colorName = colorName
        self.sortOrder = sortOrder
        self.isBuiltIn = isBuiltIn
        self.icons = []
    }
}

extension IconCategory {
    var tileColor: TileColor {
        TileColor(rawValue: colorName) ?? .sky
    }
}
