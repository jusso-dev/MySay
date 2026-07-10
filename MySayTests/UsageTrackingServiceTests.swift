import Foundation
import SwiftData
import Testing
@testable import MySay

@MainActor
@Suite("Usage tracking")
struct UsageTrackingServiceTests {
    @Test("Recording usage increments the count and stamps the date")
    func recordUsage() throws {
        let store = try TestSupport.makeStore(seeded: true)
        let service = UsageTrackingService(context: store.context)
        let icon = try #require(
            try store.context.fetch(FetchDescriptor<IconItem>()).first
        )

        #expect(icon.usageCount == 0)
        #expect(icon.lastUsedAt == nil)

        service.recordUsage(of: icon)
        service.recordUsage(of: icon)

        #expect(icon.usageCount == 2)
        #expect(icon.lastUsedAt != nil)
    }

    @Test("Most used returns descending counts and respects the limit")
    func mostUsed() throws {
        let store = try TestSupport.makeStore(seeded: true)
        let service = UsageTrackingService(context: store.context)
        let icons = try store.context.fetch(FetchDescriptor<IconItem>(
            sortBy: [SortDescriptor(\.title)]
        ))

        for _ in 0..<5 { service.recordUsage(of: icons[0]) }
        for _ in 0..<3 { service.recordUsage(of: icons[1]) }
        service.recordUsage(of: icons[2])

        let top = service.mostUsed(limit: 2)
        #expect(top.count == 2)
        #expect(top[0].id == icons[0].id)
        #expect(top[1].id == icons[1].id)
    }

    @Test("Unused icons never appear in most used")
    func mostUsedExcludesUnused() throws {
        let store = try TestSupport.makeStore(seeded: true)
        let service = UsageTrackingService(context: store.context)
        #expect(service.mostUsed().isEmpty)
    }

    @Test("Recently used orders by recency")
    func recentlyUsed() throws {
        let store = try TestSupport.makeStore(seeded: true)
        let service = UsageTrackingService(context: store.context)
        let icons = try store.context.fetch(FetchDescriptor<IconItem>(
            sortBy: [SortDescriptor(\.title)]
        ))

        service.recordUsage(of: icons[0])
        icons[0].lastUsedAt = Date(timeIntervalSinceNow: -100)
        service.recordUsage(of: icons[1])

        let recent = service.recentlyUsed(limit: 5)
        #expect(recent.first?.id == icons[1].id)
        #expect(recent.count == 2)
    }

    @Test("Reset clears all statistics")
    func reset() throws {
        let store = try TestSupport.makeStore(seeded: true)
        let service = UsageTrackingService(context: store.context)
        let icons = try store.context.fetch(FetchDescriptor<IconItem>())

        for icon in icons.prefix(10) { service.recordUsage(of: icon) }
        service.resetAllStatistics()

        let used = try store.context.fetch(FetchDescriptor<IconItem>())
        #expect(used.allSatisfy { $0.usageCount == 0 && $0.lastUsedAt == nil })
        #expect(service.mostUsed().isEmpty)
        #expect(service.recentlyUsed().isEmpty)
    }
}
