import SwiftData
import Testing
@testable import MySay

@MainActor
@Suite("Seed data")
struct SeedDataTests {
    @Test("Ships at least 100 icons")
    func iconCount() {
        #expect(SeedData.icons.count >= 100)
    }

    @Test("Every icon belongs to a defined category")
    func iconsHaveValidCategories() {
        let categoryNames = Set(SeedData.categories.map(\.name))
        for icon in SeedData.icons {
            #expect(
                categoryNames.contains(icon.category),
                "\(icon.title) references unknown category \(icon.category)"
            )
        }
    }

    @Test("No icon has an empty title, image, or phrase")
    func iconsAreComplete() {
        for icon in SeedData.icons {
            #expect(!icon.title.isEmpty)
            #expect(!icon.imageName.isEmpty)
            #expect(!icon.phraseText.isEmpty)
        }
    }

    @Test("Required starter vocabulary is present")
    func requiredVocabulary() {
        let titles = Set(SeedData.icons.map { "\($0.category)/\($0.title)" })
        let required = [
            "People/Mum", "People/Dad", "People/Brother", "People/Sister", "People/Friend",
            "Food/Apple", "Food/Banana", "Food/Sandwich",
            "Drinks/Water", "Drinks/Juice", "Drinks/Drink",
            "Feelings/Happy", "Feelings/Sad", "Feelings/Angry", "Feelings/Tired", "Feelings/Excited",
            "Needs/Toilet", "Needs/Help", "Needs/Stop", "Needs/More", "Needs/Finished",
            "Activities/Play", "Activities/Read", "Activities/Sleep", "Activities/Outside", "Activities/iPad",
            "Places/Home", "Places/School", "Places/Park", "Places/Car",
            "Core Words/I", "Core Words/Want",
        ]
        for entry in required {
            #expect(titles.contains(entry), "Missing required icon: \(entry)")
        }
    }

    @Test("Category sort orders are unique")
    func categorySortOrders() {
        let orders = SeedData.categories.map(\.sortOrder)
        #expect(Set(orders).count == orders.count)
    }

    @Test("Seeding populates the store and is idempotent")
    func seedingIsIdempotent() throws {
        let store = try TestSupport.makeStore()
        store.seedIfNeeded()
        let context = store.context
        let firstCount = try context.fetchCount(FetchDescriptor<IconItem>())
        #expect(firstCount == SeedData.icons.count)

        store.seedIfNeeded()
        let secondCount = try context.fetchCount(FetchDescriptor<IconItem>())
        #expect(secondCount == firstCount)

        let categoryCount = try context.fetchCount(FetchDescriptor<IconCategory>())
        #expect(categoryCount == SeedData.categories.count)
    }

    @Test("Seeded icons inherit their category's colour")
    func seededIconColours() throws {
        let store = try TestSupport.makeStore(seeded: true)
        let icons = try store.context.fetch(FetchDescriptor<IconItem>())
        for icon in icons {
            #expect(icon.colorName == icon.category?.colorName)
        }
    }
}
