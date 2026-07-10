import Foundation

/// Value-type representation of a communication icon.
///
/// Used for the bundled seed dataset, JSON export/import, and as the
/// transfer format for future symbol-library integrations (ARASAAC,
/// OpenSymbols). The persisted SwiftData counterpart is `IconItem`.
nonisolated struct CommunicationIcon: Codable, Sendable, Identifiable, Hashable {
    let id: UUID
    let title: String
    let imageName: String
    let category: String
    let phraseText: String

    init(
        id: UUID = UUID(),
        title: String,
        imageName: String,
        category: String,
        phraseText: String? = nil
    ) {
        self.id = id
        self.title = title
        self.imageName = imageName
        self.category = category
        self.phraseText = phraseText ?? title.lowercased()
    }
}

/// Where an icon's artwork comes from. Stored as a raw string on `IconItem`
/// so new providers can be added without a data migration.
nonisolated enum SymbolSource: String, Codable, Sendable, CaseIterable {
    /// An SF Symbol bundled with the OS (development placeholder artwork).
    case systemSymbol
    /// A photo taken or chosen by a parent, stored in the database.
    case customPhoto
    /// An image bundled in the asset catalog.
    case bundledAsset
    /// Imported from the ARASAAC open symbol library (extension point).
    case arasaac
    /// Imported from OpenSymbols.org (extension point).
    case openSymbols
}
