import Foundation
import SwiftData
import Testing
@testable import MySay

@Suite("Tile ordering and hiding")
struct OrderingAndHidingTests {
    @Test("Seeded icons get stable, sequential positions per category")
    func seedPositions() throws {
        let store = try TestSupport.makeStore(seeded: true)
        let categories = try store.context.fetch(FetchDescriptor<IconCategory>())
        for category in categories {
            let positions = category.icons
                .sorted(by: IconItem.displaySort)
                .map(\.sortOrder)
            #expect(positions == Array(0..<category.icons.count))
        }
    }

    @Test("Display sort orders by position, then title")
    func displaySort() {
        let second = TestSupport.makeIcon(title: "Zebra")
        second.sortOrder = 1
        let first = TestSupport.makeIcon(title: "Apple")
        first.sortOrder = 5
        let legacyA = TestSupport.makeIcon(title: "Ant")
        let legacyB = TestSupport.makeIcon(title: "Bee")

        let sorted = [first, legacyB, second, legacyA].sorted(by: IconItem.displaySort)
        #expect(sorted.map(\.title) == ["Ant", "Bee", "Zebra", "Apple"])
    }

    @Test("Hidden icons are excluded from search")
    func hiddenExcludedFromSearch() throws {
        let store = try TestSupport.makeStore(seeded: true)
        let icons = try store.context.fetch(FetchDescriptor<IconItem>())
        let drink = try #require(icons.first { $0.title == "Drink" })

        #expect(SearchViewModel.filter(icons, matching: "Drink").contains { $0.id == drink.id })
        drink.isHidden = true
        #expect(!SearchViewModel.filter(icons, matching: "Drink").contains { $0.id == drink.id })
    }

    @Test("Hiding preserves the icon's position for later re-showing")
    func hidingKeepsPosition() throws {
        let store = try TestSupport.makeStore(seeded: true)
        let category = try #require(
            try store.context.fetch(FetchDescriptor<IconCategory>())
                .first { $0.name == "Drinks" }
        )
        let icon = try #require(category.icons.sorted(by: IconItem.displaySort).first)
        let position = icon.sortOrder

        icon.isHidden = true
        try store.context.save()
        #expect(icon.sortOrder == position)

        icon.isHidden = false
        let visible = category.icons.filter { !$0.isHidden }.sorted(by: IconItem.displaySort)
        #expect(visible.first?.id == icon.id)
    }

    @Test("New icons append after existing positions")
    func newIconsAppend() throws {
        let store = try TestSupport.makeStore(seeded: true)
        let categories = try store.context.fetch(FetchDescriptor<IconCategory>())
        let drinks = try #require(categories.first { $0.name == "Drinks" })
        let maxBefore = drinks.icons.map(\.sortOrder).max() ?? 0

        let editor = IconEditorViewModel(defaultCategoryID: drinks.id)
        editor.title = "Smoothie"
        editor.save(in: store.context, categories: categories)

        let added = try #require(drinks.icons.first { $0.title == "Smoothie" })
        #expect(added.sortOrder == maxBefore + 1)
    }
}

@Suite("Library upgrades")
struct LibraryUpgradeTests {
    @Test("Existing libraries gain new seed categories without duplication")
    func quickPhrasesAddedOnUpgrade() throws {
        let store = try TestSupport.makeStore()
        // Simulate a v1 library: seed, then strip the Quick Phrases
        // category as if it never existed.
        store.seed()
        let categories = try store.context.fetch(FetchDescriptor<IconCategory>())
        let quick = try #require(categories.first { $0.name == "Quick Phrases" })
        store.context.delete(quick)
        try store.context.save()

        store.seedIfNeeded()

        let after = try store.context.fetch(FetchDescriptor<IconCategory>())
        #expect(after.filter { $0.name == "Quick Phrases" }.count == 1)

        // Running again must not duplicate.
        store.seedIfNeeded()
        let again = try store.context.fetch(FetchDescriptor<IconCategory>())
        #expect(again.filter { $0.name == "Quick Phrases" }.count == 1)
    }

    @Test("Position backfill freezes the legacy alphabetical layout")
    func positionBackfill() throws {
        let store = try TestSupport.makeStore(seeded: true)
        let category = try #require(
            try store.context.fetch(FetchDescriptor<IconCategory>())
                .first { $0.name == "Drinks" }
        )
        // Simulate a v1 library where positions were never assigned.
        for icon in category.icons { icon.sortOrder = 0 }
        try store.context.save()

        store.upgradeExistingLibrary()

        let ordered = category.icons.sorted(by: IconItem.displaySort)
        let alphabetical = category.icons.sorted {
            $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
        }
        #expect(ordered.map(\.id) == alphabetical.map(\.id))
        #expect(Set(ordered.map(\.sortOrder)).count == ordered.count)
    }

    @Test("Version-1 archives (no positions, hidden flags, or boards) still import")
    func importsVersionOneArchive() throws {
        let json = """
        {
          "version": 1,
          "categories": [
            {
              "name": "Drinks",
              "symbolName": "cup.and.saucer.fill",
              "colorName": "sky",
              "sortOrder": 0,
              "isBuiltIn": true,
              "icons": [
                {
                  "id": "11111111-1111-1111-1111-111111111111",
                  "title": "Water",
                  "imageName": "drop.fill",
                  "phraseText": "water",
                  "colorName": "sky",
                  "symbolSource": "systemSymbol",
                  "isCustom": false,
                  "isFavourite": true,
                  "favouriteOrder": 1,
                  "usageCount": 3
                },
                {
                  "id": "22222222-2222-2222-2222-222222222222",
                  "title": "Juice",
                  "imageName": "takeoutbag.and.cup.and.straw.fill",
                  "phraseText": "juice",
                  "colorName": "sky",
                  "symbolSource": "systemSymbol",
                  "isCustom": false,
                  "isFavourite": false,
                  "favouriteOrder": 0,
                  "usageCount": 0
                }
              ]
            }
          ]
        }
        """
        let store = try TestSupport.makeStore()
        try store.importData(Data(json.utf8))

        let icons = try store.context.fetch(FetchDescriptor<IconItem>())
        #expect(icons.count == 2)
        let water = try #require(icons.first { $0.title == "Water" })
        #expect(water.sortOrder == 0)
        #expect(!water.isHidden)
        let juice = try #require(icons.first { $0.title == "Juice" })
        #expect(juice.sortOrder == 1)
    }

    @Test("Boards round-trip through export and import")
    func boardsRoundTrip() throws {
        let source = try TestSupport.makeStore(seeded: true)
        let icons = Array(
            try source.context.fetch(FetchDescriptor<IconItem>(
                sortBy: [SortDescriptor(\.title)]
            )).prefix(3)
        )
        source.context.insert(Board(
            name: "Morning",
            symbolName: "sunrise.fill",
            sortOrder: 1,
            iconIDs: icons.map(\.id)
        ))
        try source.context.save()

        let destination = try TestSupport.makeStore()
        try destination.importData(try source.exportData())

        let board = try #require(
            try destination.context.fetch(FetchDescriptor<Board>()).first
        )
        #expect(board.name == "Morning")
        #expect(board.iconIDs == icons.map(\.id))
    }
}

@Suite("Recorded voice")
struct RecordedVoiceTests {
    @Test("Icons with a recording play it; replay repeats the recording")
    func recordedPlayback() {
        let speech = SpeechService(audioEnabled: false)
        let settings = SettingsStore(defaults: TestSupport.makeDefaults())
        let clip = Data([0x01, 0x02, 0x03])
        let icon = TestSupport.makeIcon(title: "Drink")
        icon.recordedAudioData = clip

        speech.speak(icon: icon, settings: settings)
        #expect(speech.lastSpokenText == "drink")
        #expect(speech.lastRecordedAudio == clip)

        speech.replay(settings: settings)
        #expect(speech.lastRecordedAudio == clip)
    }

    @Test("Icons without a recording fall back to synthesis")
    func synthesisFallback() {
        let speech = SpeechService(audioEnabled: false)
        let settings = SettingsStore(defaults: TestSupport.makeDefaults())
        let icon = TestSupport.makeIcon(title: "More")

        speech.speak(icon: icon, settings: settings)
        #expect(speech.lastSpokenText == "more")
        #expect(speech.lastRecordedAudio == nil)
    }

    @Test("Speaking text clears any prior recording state")
    func textSpeechClearsRecording() {
        let speech = SpeechService(audioEnabled: false)
        let settings = SettingsStore(defaults: TestSupport.makeDefaults())
        let icon = TestSupport.makeIcon(title: "Drink")
        icon.recordedAudioData = Data([0xFF])

        speech.speak(icon: icon, settings: settings)
        speech.speak("I want drink", settings: settings)
        #expect(speech.lastRecordedAudio == nil)
        #expect(speech.lastSpokenText == "I want drink")
    }

    @Test("Editor saves and removes recordings")
    func editorRecordingPersistence() throws {
        let store = try TestSupport.makeStore(seeded: true)
        let categories = try store.context.fetch(FetchDescriptor<IconCategory>())
        let icon = try #require(
            try store.context.fetch(FetchDescriptor<IconItem>())
                .first { $0.title == "Drink" }
        )

        let editor = IconEditorViewModel(icon: icon)
        editor.recordedAudioData = Data([0x0A, 0x0B])
        editor.save(in: store.context, categories: categories)
        #expect(icon.recordedAudioData == Data([0x0A, 0x0B]))

        let remover = IconEditorViewModel(icon: icon)
        remover.recordedAudioData = nil
        remover.save(in: store.context, categories: categories)
        #expect(icon.recordedAudioData == nil)
    }
}

@Suite("Lizard easter egg")
struct LizardEasterEggTests {
    @Test("Seeded Lizard tile carries the bundled recording")
    func lizardHasRecording() throws {
        let store = try TestSupport.makeStore(seeded: true)
        let lizard = try #require(
            try store.context.fetch(FetchDescriptor<IconItem>())
                .first { $0.title == "Lizard" }
        )
        let recording = try #require(lizard.recordedAudioData)
        #expect(recording.count > 1_000, "Bundled lizard recording looks truncated")
    }

    @Test("Upgrade attaches the recording to existing libraries, once")
    func upgradeAttachesRecording() throws {
        let store = try TestSupport.makeStore(seeded: true)
        let lizard = try #require(
            try store.context.fetch(FetchDescriptor<IconItem>())
                .first { $0.title == "Lizard" }
        )
        // Simulate a pre-easter-egg library.
        lizard.recordedAudioData = nil
        try store.context.save()

        store.seedIfNeeded()
        #expect(lizard.recordedAudioData != nil)

        // A parent's own re-recording must never be overwritten.
        let parentClip = Data([0x01, 0x02])
        lizard.recordedAudioData = parentClip
        store.seedIfNeeded()
        #expect(lizard.recordedAudioData == parentClip)
    }
}

@Suite("Sentence strip settings")
struct SentenceStripSettingTests {
    @Test("Strip defaults to on and persists")
    func stripDefaultAndPersistence() {
        let suite = TestSupport.makeDefaults()
        let settings = SettingsStore(defaults: suite)
        #expect(settings.showSentenceStrip)

        settings.showSentenceStrip = false
        let reloaded = SettingsStore(defaults: suite)
        #expect(!reloaded.showSentenceStrip)
    }

    @Test("Build-sentences-from-taps defaults to off and persists")
    func autoAddDefaultAndPersistence() {
        let suite = TestSupport.makeDefaults()
        let settings = SettingsStore(defaults: suite)
        #expect(!settings.autoAddToSentence)

        settings.autoAddToSentence = true
        let reloaded = SettingsStore(defaults: suite)
        #expect(reloaded.autoAddToSentence)
    }
}
