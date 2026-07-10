import Foundation
import SwiftData

/// A single tappable communication tile.
///
/// `imageName` is an SF Symbol name unless `customImageData` is set, in
/// which case the stored photo wins. `symbolSourceRaw` records provenance
/// (see `SymbolSource`) so future importers can round-trip their assets.
///
/// `sortOrder` keeps tile positions stable as vocabulary grows (motor
/// planning: a child learns *where* a word lives). `isHidden` masks words
/// a child isn't ready for without moving anything — preferred over
/// deletion. `recordedAudioData` lets a parent's recorded voice replace
/// the synthesised one for this word.
@Model
final class IconItem {
    @Attribute(.unique) var id: UUID
    var title: String
    var imageName: String
    var phraseText: String
    var colorName: String
    var symbolSourceRaw: String
    @Attribute(.externalStorage) var customImageData: Data?
    @Attribute(.externalStorage) var recordedAudioData: Data?
    var isCustom: Bool

    var isFavourite: Bool
    var favouriteOrder: Int

    /// Position within its category. Stable across vocabulary growth.
    var sortOrder: Int
    /// Masked from the child's view, but kept (with its position) so it
    /// can be re-shown later without disrupting motor patterns.
    var isHidden: Bool

    var usageCount: Int
    var lastUsedAt: Date?
    var createdAt: Date

    var category: IconCategory?

    init(
        id: UUID = UUID(),
        title: String,
        imageName: String,
        phraseText: String,
        colorName: String = TileColor.sky.rawValue,
        symbolSource: SymbolSource = .systemSymbol,
        customImageData: Data? = nil,
        recordedAudioData: Data? = nil,
        isCustom: Bool = false,
        sortOrder: Int = 0,
        isHidden: Bool = false,
        category: IconCategory? = nil
    ) {
        self.id = id
        self.title = title
        self.imageName = imageName
        self.phraseText = phraseText
        self.colorName = colorName
        self.symbolSourceRaw = symbolSource.rawValue
        self.customImageData = customImageData
        self.recordedAudioData = recordedAudioData
        self.isCustom = isCustom
        self.isFavourite = false
        self.favouriteOrder = 0
        self.sortOrder = sortOrder
        self.isHidden = isHidden
        self.usageCount = 0
        self.lastUsedAt = nil
        self.createdAt = Date()
        self.category = category
    }
}

extension IconItem {
    var symbolSource: SymbolSource {
        get { SymbolSource(rawValue: symbolSourceRaw) ?? .systemSymbol }
        set { symbolSourceRaw = newValue.rawValue }
    }

    var tileColor: TileColor {
        TileColor(rawValue: colorName) ?? .sky
    }

    /// Text handed to the speech synthesiser when the tile is tapped.
    var spokenText: String {
        phraseText.isEmpty ? title : phraseText
    }

    /// Stable display ordering: explicit position first, title as the
    /// tiebreak for legacy items that share a position.
    nonisolated static func displaySort(_ lhs: IconItem, _ rhs: IconItem) -> Bool {
        if lhs.sortOrder != rhs.sortOrder {
            return lhs.sortOrder < rhs.sortOrder
        }
        return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
    }
}
