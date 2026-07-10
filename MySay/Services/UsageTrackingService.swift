import Foundation
import SwiftData

/// Records icon usage and derives the Most Used / Recently Used sections.
/// All data stays on-device; nothing is ever transmitted.
final class UsageTrackingService {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    /// Increment the tap count and stamp the time. Called on every speak.
    func recordUsage(of icon: IconItem) {
        icon.usageCount += 1
        icon.lastUsedAt = Date()
        try? context.save()
    }

    /// Icons ordered by usage, most used first. Icons never used are excluded.
    func mostUsed(limit: Int = 10) -> [IconItem] {
        var descriptor = FetchDescriptor<IconItem>(
            predicate: #Predicate { $0.usageCount > 0 },
            sortBy: [
                SortDescriptor(\.usageCount, order: .reverse),
                SortDescriptor(\.title),
            ]
        )
        descriptor.fetchLimit = limit
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Icons ordered by recency of use, newest first.
    func recentlyUsed(limit: Int = 10) -> [IconItem] {
        var descriptor = FetchDescriptor<IconItem>(
            predicate: #Predicate { $0.lastUsedAt != nil },
            sortBy: [SortDescriptor(\.lastUsedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Parent-mode action: clear all counts and timestamps.
    func resetAllStatistics() {
        let all = (try? context.fetch(FetchDescriptor<IconItem>())) ?? []
        for icon in all {
            icon.usageCount = 0
            icon.lastUsedAt = nil
        }
        try? context.save()
    }
}
