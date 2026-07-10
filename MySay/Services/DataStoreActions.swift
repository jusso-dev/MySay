import Foundation
import SwiftData

/// Export/import working on any `ModelContext`, so parent-mode views can
/// act on the app's live context (the `DataStore` instance owns the
/// container; these are the same routines exposed context-first for views
/// and tests).
enum DataStoreActions {
    static func export(context: ModelContext) throws -> Data {
        let categories = try context.fetch(
            FetchDescriptor<IconCategory>(sortBy: [SortDescriptor(\.sortOrder)])
        )
        let boards = try context.fetch(
            FetchDescriptor<Board>(sortBy: [SortDescriptor(\.sortOrder)])
        )
        let archive = ExportArchive(
            version: 2,
            categories: categories.map { category in
                ExportArchive.Category(
                    name: category.name,
                    symbolName: category.symbolName,
                    colorName: category.colorName,
                    sortOrder: category.sortOrder,
                    isBuiltIn: category.isBuiltIn,
                    icons: category.icons.sorted(by: IconItem.displaySort).map { icon in
                        ExportArchive.Icon(
                            id: icon.id,
                            title: icon.title,
                            imageName: icon.imageName,
                            phraseText: icon.phraseText,
                            colorName: icon.colorName,
                            symbolSource: icon.symbolSourceRaw,
                            isCustom: icon.isCustom,
                            isFavourite: icon.isFavourite,
                            favouriteOrder: icon.favouriteOrder,
                            usageCount: icon.usageCount,
                            sortOrder: icon.sortOrder,
                            isHidden: icon.isHidden,
                            customImageBase64: icon.customImageData?.base64EncodedString(),
                            recordedAudioBase64: icon.recordedAudioData?.base64EncodedString()
                        )
                    }
                )
            },
            boards: boards.map { board in
                ExportArchive.BoardEntry(
                    id: board.id,
                    name: board.name,
                    symbolName: board.symbolName,
                    sortOrder: board.sortOrder,
                    iconIDs: board.iconIDs
                )
            }
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(archive)
    }

    /// Replace the current library with the archive's contents.
    static func importArchive(_ data: Data, context: ModelContext) throws {
        let archive = try JSONDecoder().decode(ExportArchive.self, from: data)
        for category in try context.fetch(FetchDescriptor<IconCategory>()) {
            context.delete(category)
        }
        for orphan in try context.fetch(FetchDescriptor<IconItem>()) {
            context.delete(orphan)
        }
        for board in try context.fetch(FetchDescriptor<Board>()) {
            context.delete(board)
        }
        for categoryDef in archive.categories {
            let category = IconCategory(
                name: categoryDef.name,
                symbolName: categoryDef.symbolName,
                colorName: categoryDef.colorName,
                sortOrder: categoryDef.sortOrder,
                isBuiltIn: categoryDef.isBuiltIn
            )
            context.insert(category)
            for (position, iconDef) in categoryDef.icons.enumerated() {
                let icon = IconItem(
                    id: iconDef.id,
                    title: iconDef.title,
                    imageName: iconDef.imageName,
                    phraseText: iconDef.phraseText,
                    colorName: iconDef.colorName,
                    symbolSource: SymbolSource(rawValue: iconDef.symbolSource) ?? .systemSymbol,
                    customImageData: iconDef.customImageBase64.flatMap { Data(base64Encoded: $0) },
                    recordedAudioData: iconDef.recordedAudioBase64.flatMap { Data(base64Encoded: $0) },
                    isCustom: iconDef.isCustom,
                    // Version-1 archives predate explicit positions; their
                    // array order becomes the position.
                    sortOrder: iconDef.sortOrder ?? position,
                    isHidden: iconDef.isHidden ?? false,
                    category: category
                )
                icon.isFavourite = iconDef.isFavourite
                icon.favouriteOrder = iconDef.favouriteOrder
                icon.usageCount = iconDef.usageCount
                context.insert(icon)
            }
        }
        for boardDef in archive.boards ?? [] {
            context.insert(Board(
                id: boardDef.id,
                name: boardDef.name,
                symbolName: boardDef.symbolName,
                sortOrder: boardDef.sortOrder,
                iconIDs: boardDef.iconIDs
            ))
        }
        try context.save()
    }
}
