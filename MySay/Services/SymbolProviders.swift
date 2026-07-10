import Foundation

/// Extension point for open symbol libraries (ARASAAC, OpenSymbols, custom
/// SVG packs). The MVP ships only SF Symbol placeholders and parent photos;
/// these protocols define the seam future importers plug into without
/// touching the rest of the app.
///
/// A provider converts library entries into `CommunicationIcon` values plus
/// image data, which `DataStore.importData`-style logic persists as
/// `IconItem`s with the matching `SymbolSource`.
protocol SymbolProvider {
    /// Stable identifier, e.g. "arasaac".
    var providerID: String { get }
    var displayName: String { get }
    /// The provenance recorded on imported icons.
    var source: SymbolSource { get }

    /// Search the library. Offline-first: implementations should resolve
    /// against locally downloaded packs, never a live network dependency.
    func searchSymbols(matching query: String) async throws -> [ImportableSymbol]

    /// Fetch the artwork for a symbol from the local pack.
    func imageData(for symbol: ImportableSymbol) async throws -> Data
}

/// A symbol offered by a provider, prior to import.
nonisolated struct ImportableSymbol: Identifiable, Sendable, Hashable {
    let id: String
    let title: String
    let providerID: String
    /// Licence text that must be preserved on import (e.g. ARASAAC is
    /// CC BY-NC-SA and requires attribution).
    let attribution: String?
}

/// Placeholder ARASAAC provider. Implementation lands when downloadable
/// symbol packs ship; the type exists so the import UI and data layer can
/// be written against the protocol today.
struct ArasaacSymbolProvider: SymbolProvider {
    let providerID = "arasaac"
    let displayName = "ARASAAC"
    let source = SymbolSource.arasaac

    func searchSymbols(matching query: String) async throws -> [ImportableSymbol] {
        // Future: query a locally downloaded ARASAAC pack.
        []
    }

    func imageData(for symbol: ImportableSymbol) async throws -> Data {
        throw SymbolProviderError.packNotInstalled(displayName)
    }
}

/// Placeholder OpenSymbols.org provider.
struct OpenSymbolsProvider: SymbolProvider {
    let providerID = "opensymbols"
    let displayName = "OpenSymbols"
    let source = SymbolSource.openSymbols

    func searchSymbols(matching query: String) async throws -> [ImportableSymbol] {
        []
    }

    func imageData(for symbol: ImportableSymbol) async throws -> Data {
        throw SymbolProviderError.packNotInstalled(displayName)
    }
}

nonisolated enum SymbolProviderError: Error, LocalizedError {
    case packNotInstalled(String)

    var errorDescription: String? {
        switch self {
        case .packNotInstalled(let name):
            "The \(name) symbol pack is not installed yet."
        }
    }
}
