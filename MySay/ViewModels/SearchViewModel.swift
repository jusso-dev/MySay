import Foundation
import Observation

/// Live, on-device search over the icon library.
///
/// Filtering is pure and in-memory: even with thousands of icons a single
/// case-insensitive pass is well under a frame, and it keeps results
/// identical between the app and unit tests.
@Observable
final class SearchViewModel {
    var searchText: String = ""

    func results(in icons: [IconItem]) -> [IconItem] {
        Self.filter(icons, matching: searchText)
    }

    nonisolated static func filter(_ icons: [IconItem], matching query: String) -> [IconItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        // Hidden words are masked from the child's view everywhere,
        // including search.
        return icons.filter { icon in
            !icon.isHidden && (
                icon.title.localizedCaseInsensitiveContains(trimmed)
                    || icon.phraseText.localizedCaseInsensitiveContains(trimmed)
                    || (icon.category?.name.localizedCaseInsensitiveContains(trimmed) ?? false)
            )
        }
        .sorted { lhs, rhs in
            // Title prefix matches rank first so "ap" surfaces "Apple"
            // ahead of icons that merely contain the letters.
            let lhsPrefix = lhs.title.lowercased().hasPrefix(trimmed.lowercased())
            let rhsPrefix = rhs.title.lowercased().hasPrefix(trimmed.lowercased())
            if lhsPrefix != rhsPrefix { return lhsPrefix }
            return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
        }
    }
}
