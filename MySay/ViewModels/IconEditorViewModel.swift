import Foundation
import Observation
import SwiftData
import UIKit

/// Backs the parent-mode icon editor for both creating and editing icons.
@Observable
final class IconEditorViewModel {
    var title: String
    var phraseText: String
    var symbolName: String
    var tileColor: TileColor
    var customImageData: Data?
    var recordedAudioData: Data?
    var isHidden: Bool
    var selectedCategoryID: UUID?

    private let existingIcon: IconItem?

    /// Longest edge for stored photos; keeps the database lean while
    /// staying crisp on tile sizes the app actually renders.
    nonisolated static let maxImageDimension: CGFloat = 600

    init(icon: IconItem? = nil, defaultCategoryID: UUID? = nil) {
        existingIcon = icon
        title = icon?.title ?? ""
        phraseText = icon?.phraseText ?? ""
        symbolName = icon?.imageName ?? "photo"
        tileColor = icon?.tileColor ?? .sky
        customImageData = icon?.customImageData
        recordedAudioData = icon?.recordedAudioData
        isHidden = icon?.isHidden ?? false
        selectedCategoryID = icon?.category?.id ?? defaultCategoryID
    }

    var isEditing: Bool { existingIcon != nil }

    var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && selectedCategoryID != nil
    }

    /// The text spoken when the icon is tapped; falls back to the title.
    var effectivePhrase: String {
        let trimmed = phraseText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty
            ? title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            : trimmed
    }

    func setPhoto(_ data: Data) {
        customImageData = Self.resizedImageData(from: data)
    }

    func clearPhoto() {
        customImageData = nil
    }

    /// Persist as a new icon or apply edits to the existing one.
    func save(in context: ModelContext, categories: [IconCategory]) {
        guard canSave,
              let category = categories.first(where: { $0.id == selectedCategoryID })
        else { return }

        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if let icon = existingIcon {
            icon.title = cleanTitle
            icon.phraseText = effectivePhrase
            icon.imageName = symbolName
            icon.colorName = tileColor.rawValue
            icon.customImageData = customImageData
            icon.recordedAudioData = recordedAudioData
            icon.isHidden = isHidden
            icon.symbolSource = customImageData == nil ? .systemSymbol : .customPhoto
            icon.category = category
        } else {
            // New words append after the category's existing positions so
            // nothing already learned moves.
            let nextPosition = (category.icons.map(\.sortOrder).max() ?? -1) + 1
            let icon = IconItem(
                title: cleanTitle,
                imageName: symbolName,
                phraseText: effectivePhrase,
                colorName: tileColor.rawValue,
                symbolSource: customImageData == nil ? .systemSymbol : .customPhoto,
                customImageData: customImageData,
                recordedAudioData: recordedAudioData,
                isCustom: true,
                sortOrder: nextPosition,
                isHidden: isHidden,
                category: category
            )
            context.insert(icon)
        }
        try? context.save()
    }

    /// Downscale and JPEG-compress photo data before storing it.
    nonisolated static func resizedImageData(from data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let largestSide = max(image.size.width, image.size.height)
        guard largestSide > maxImageDimension else {
            return image.jpegData(compressionQuality: 0.8)
        }
        let scale = maxImageDimension / largestSide
        let newSize = CGSize(
            width: image.size.width * scale,
            height: image.size.height * scale
        )
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let resized = UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        return resized.jpegData(compressionQuality: 0.8)
    }
}
