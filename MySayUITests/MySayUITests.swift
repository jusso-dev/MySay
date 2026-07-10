import XCTest

/// End-to-end UI tests. The app launches with `--uitest`, which switches it
/// to an in-memory store and throwaway defaults, so tests never touch real
/// data. `--uitest-skip-onboarding` jumps straight to the main interface.
final class MySayUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchApp(
        skipOnboarding: Bool = true,
        extraArguments: [String] = []
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = (skipOnboarding
            ? ["--uitest", "--uitest-skip-onboarding"]
            : ["--uitest"]) + extraArguments
        app.launch()
        return app
    }

    /// Category cards are single accessibility elements labelled
    /// "<Name> category, N words".
    private func categoryCard(_ app: XCUIApplication, _ name: String) -> XCUIElement {
        app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "\(name) category")
        ).firstMatch
    }

    /// Tab items surface differently across iPadOS versions (tab-bar
    /// buttons vs. cells in the new top tab strip); try each shape.
    private func openTab(_ app: XCUIApplication, _ name: String) {
        let candidates = [
            app.tabBars.buttons[name].firstMatch,
            app.buttons[name].firstMatch,
            app.cells[name].firstMatch,
            app.otherElements[name].firstMatch,
        ]
        for candidate in candidates where candidate.waitForExistence(timeout: 2) {
            if candidate.isHittable {
                candidate.tap()
                return
            }
        }
        XCTFail("Could not find a tappable tab named \(name)")
    }

    // MARK: - Onboarding

    func testOnboardingShowsOnFirstLaunchAndCanBeSkipped() throws {
        let app = launchApp(skipOnboarding: false)

        XCTAssertTrue(
            app.staticTexts["Tap pictures to speak"].waitForExistence(timeout: 10),
            "First onboarding page should appear on first launch"
        )

        app.buttons["Skip"].tap()

        XCTAssertTrue(
            app.navigationBars["MySay"].waitForExistence(timeout: 10),
            "Skipping onboarding should land on the Home screen"
        )
    }

    func testOnboardingCompletesViaNextButtons() throws {
        let app = launchApp(skipOnboarding: false)

        XCTAssertTrue(app.buttons["Next"].waitForExistence(timeout: 10))
        for _ in 0..<3 {
            app.buttons["Next"].tap()
        }
        app.buttons["Start Talking"].tap()

        XCTAssertTrue(app.navigationBars["MySay"].waitForExistence(timeout: 10))
    }

    // MARK: - Home

    func testHomeShowsCategories() throws {
        let app = launchApp()

        XCTAssertTrue(app.navigationBars["MySay"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Categories"].exists)
        XCTAssertTrue(categoryCard(app, "Core Words").exists)
        XCTAssertTrue(categoryCard(app, "Feelings").exists)
    }

    func testTappingCategoryOpensBoardAndIconSpeaks() throws {
        let app = launchApp()

        XCTAssertTrue(categoryCard(app, "Drinks").waitForExistence(timeout: 10))
        categoryCard(app, "Drinks").tap()
        XCTAssertTrue(app.navigationBars["Drinks"].waitForExistence(timeout: 10))

        let drink = app.buttons["Drink"]
        XCTAssertTrue(drink.waitForExistence(timeout: 10))
        drink.tap()
        // Speech is audible, not assertable; the tap registering without a
        // crash plus usage side-effects (next test) cover the behaviour.
    }

    func testUsedIconAppearsInRecentlyUsed() throws {
        let app = launchApp()

        XCTAssertTrue(categoryCard(app, "Drinks").waitForExistence(timeout: 10))
        categoryCard(app, "Drinks").tap()
        let drink = app.buttons["Drink"]
        XCTAssertTrue(drink.waitForExistence(timeout: 10))
        drink.tap()

        app.navigationBars.buttons.firstMatch.tap() // back to Home

        XCTAssertTrue(
            app.staticTexts["Recently Used"].waitForExistence(timeout: 10),
            "A Recently Used section should appear after using an icon"
        )
        XCTAssertTrue(app.staticTexts["Most Used"].exists)
    }

    // MARK: - Favourites

    func testFavouritesTabShowsEmptyStateThenFavourite() throws {
        let app = launchApp()

        openTab(app, "Favourites")
        XCTAssertTrue(app.staticTexts["No favourites yet"].waitForExistence(timeout: 10))

        // Favourite "Drink" via its context menu.
        openTab(app, "Home")
        XCTAssertTrue(categoryCard(app, "Drinks").waitForExistence(timeout: 10))
        categoryCard(app, "Drinks").tap()
        let drink = app.buttons["Drink"]
        XCTAssertTrue(drink.waitForExistence(timeout: 10))
        drink.press(forDuration: 1.0)
        let addFavourite = app.buttons["Add to Favourites"]
        XCTAssertTrue(addFavourite.waitForExistence(timeout: 10))
        addFavourite.tap()

        openTab(app, "Favourites")
        XCTAssertTrue(app.buttons["Drink"].waitForExistence(timeout: 10))
    }

    // MARK: - Phrase builder

    func testPhraseBuilderBuildsAndClearsSentence() throws {
        let app = launchApp()

        openTab(app, "Phrases")
        XCTAssertTrue(app.navigationBars["Phrases"].waitForExistence(timeout: 10))

        let speakButton = app.buttons["Speak Phrase"]
        XCTAssertTrue(speakButton.waitForExistence(timeout: 10))
        XCTAssertFalse(speakButton.isEnabled, "Speak should be disabled while the strip is empty")

        // Switch to the Core Words category, then add two words.
        let coreWordsChip = app.buttons["Core Words"].firstMatch
        XCTAssertTrue(coreWordsChip.waitForExistence(timeout: 10))
        coreWordsChip.tap()
        let iWord = app.buttons["I"].firstMatch
        XCTAssertTrue(iWord.waitForExistence(timeout: 10))
        iWord.tap()
        app.buttons["Want"].firstMatch.tap()

        XCTAssertTrue(speakButton.isEnabled)
        speakButton.tap()

        app.buttons["Clear"].tap()
        XCTAssertFalse(speakButton.isEnabled)
    }

    // MARK: - Search

    func testSearchFindsIconsLive() throws {
        let app = launchApp()

        openTab(app, "Search")
        let field = app.searchFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        field.typeText("drink")

        XCTAssertTrue(app.buttons["Drink"].waitForExistence(timeout: 10))
    }

    // MARK: - Settings & parent mode

    func testSettingsShowsControlsAndParentGate() throws {
        let app = launchApp()

        openTab(app, "Settings")
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Speed"].exists)
        XCTAssertTrue(app.staticTexts["Pitch"].exists)
        XCTAssertTrue(app.switches["Show labels"].exists)

        unlockParentMode(app)
        XCTAssertTrue(app.staticTexts["Manage Icons"].waitForExistence(timeout: 10))
        app.buttons["Done"].firstMatch.tap()
    }

    /// Opens Settings, enters Parent Mode, and creates the passcode 1234.
    /// Each test launch uses throwaway defaults, so the gate is always in
    /// "create" mode.
    private func unlockParentMode(_ app: XCUIApplication) {
        let parentModeButton = app.buttons["Parent Mode"].firstMatch
        XCTAssertTrue(parentModeButton.waitForExistence(timeout: 10))
        parentModeButton.tap()
        var prompt = app.staticTexts["Choose a 4-digit parent passcode"]
        if !prompt.waitForExistence(timeout: 10) {
            // A tap can land while the form is still settling on a cold
            // simulator; retry once.
            parentModeButton.tap()
            prompt = app.staticTexts["Choose a 4-digit parent passcode"]
        }
        XCTAssertTrue(
            prompt.waitForExistence(timeout: 10),
            "First parent-mode visit should ask to create a passcode"
        )
        for _ in 0..<2 {
            for digit in ["Digit 1", "Digit 2", "Digit 3", "Digit 4"] {
                app.buttons[digit].firstMatch.tap()
            }
        }
    }

    func testParentModeAddsCustomIcon() throws {
        let app = launchApp()

        openTab(app, "Settings")
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 10))
        unlockParentMode(app)

        XCTAssertTrue(app.staticTexts["Manage Icons"].waitForExistence(timeout: 10))
        app.staticTexts["Manage Icons"].tap()

        // Filter to nothing so each lazy section collapses to its
        // "Add Icon" row.
        let iconFilter = app.searchFields.firstMatch
        XCTAssertTrue(iconFilter.waitForExistence(timeout: 10))
        iconFilter.tap()
        iconFilter.typeText("zzz")
        let addIcon = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH 'Add Icon to'")
        ).firstMatch
        XCTAssertTrue(addIcon.waitForExistence(timeout: 10))
        addIcon.tap()

        let nameField = app.textFields["Name (shown on the tile)"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 10))
        nameField.tap()
        nameField.typeText("My Cup")
        app.buttons["Save"].firstMatch.tap()

        // Verify via the filter (the new row may be far down the list).
        XCTAssertTrue(iconFilter.waitForExistence(timeout: 10))
        iconFilter.tap()
        if iconFilter.buttons["Clear text"].exists {
            iconFilter.buttons["Clear text"].tap()
            iconFilter.tap()
        }
        iconFilter.typeText("My Cup")
        XCTAssertTrue(app.staticTexts["My Cup"].waitForExistence(timeout: 10))
    }

    func testParentModeAddsCategory() throws {
        let app = launchApp()

        openTab(app, "Settings")
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 10))
        unlockParentMode(app)

        XCTAssertTrue(app.staticTexts["Manage Categories"].waitForExistence(timeout: 10))
        app.staticTexts["Manage Categories"].tap()

        let addCategory = app.buttons["Add Category"].firstMatch
        XCTAssertTrue(addCategory.waitForExistence(timeout: 10))
        addCategory.tap()
        let categoryField = app.textFields["Category name"]
        XCTAssertTrue(categoryField.waitForExistence(timeout: 10))
        categoryField.tap()
        categoryField.typeText("Holidays")
        app.buttons["Save"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Holidays"].waitForExistence(timeout: 10))
    }

    func testVoicePickerListsVoices() throws {
        let app = launchApp()

        openTab(app, "Settings")
        let voiceRow = app.descendants(matching: .any).matching(
            NSPredicate(format: "label BEGINSWITH 'Voice'")
        ).firstMatch
        XCTAssertTrue(voiceRow.waitForExistence(timeout: 10))
        voiceRow.tap()

        XCTAssertTrue(app.navigationBars["Voice"].waitForExistence(timeout: 10))
        // Simulators always ship at least one English voice; tapping one
        // selects it and speaks a sample.
        let firstVoice = app.buttons.matching(
            NSPredicate(format: "label CONTAINS 'English'")
        ).firstMatch
        XCTAssertTrue(firstVoice.waitForExistence(timeout: 10))
        firstVoice.tap()
    }

    // MARK: - Sentence strip

    func testTapDoesNotBuildSentenceByDefault() throws {
        let app = launchApp()

        XCTAssertTrue(categoryCard(app, "Drinks").waitForExistence(timeout: 10))
        categoryCard(app, "Drinks").tap()
        if !app.navigationBars["Drinks"].waitForExistence(timeout: 10) {
            // Retry once: the tap can land while Home is still settling.
            categoryCard(app, "Drinks").tap()
        }
        let drink = app.buttons["Drink"]
        XCTAssertTrue(drink.waitForExistence(timeout: 10))
        drink.tap()

        XCTAssertFalse(
            app.buttons["Drink, in sentence"].waitForExistence(timeout: 3),
            "With 'Build sentences from taps' off (the default), tapping a word should only speak it"
        )
        XCTAssertTrue(app.staticTexts["Tap pictures to build a sentence"].exists)
    }

    func testSentenceStripBuildsFromAnyScreen() throws {
        let app = launchApp(extraArguments: ["--uitest-auto-sentence"])

        XCTAssertTrue(
            app.staticTexts["Tap pictures to build a sentence"].waitForExistence(timeout: 10),
            "The message window should be visible on the Home screen"
        )

        XCTAssertTrue(categoryCard(app, "Drinks").waitForExistence(timeout: 10))
        categoryCard(app, "Drinks").tap()
        let drink = app.buttons["Drink"]
        XCTAssertTrue(drink.waitForExistence(timeout: 10))
        drink.tap()

        XCTAssertTrue(
            app.buttons["Drink, in sentence"].waitForExistence(timeout: 10),
            "Tapping a word should add it to the sentence strip"
        )

        let speak = app.buttons["Speak sentence"]
        XCTAssertTrue(speak.isEnabled)
        speak.tap()

        app.buttons["Clear sentence"].tap()
        XCTAssertTrue(app.staticTexts["Tap pictures to build a sentence"].waitForExistence(timeout: 10))
    }

    // MARK: - Edit in place

    func testEditModeHidesWordWithoutDeleting() throws {
        let app = launchApp()

        XCTAssertTrue(categoryCard(app, "Drinks").waitForExistence(timeout: 10))
        categoryCard(app, "Drinks").tap()
        XCTAssertTrue(app.buttons["Drink"].waitForExistence(timeout: 10))

        // Enter edit mode through the passcode gate.
        app.buttons["Edit Board"].tap()
        XCTAssertTrue(
            app.staticTexts["Choose a 4-digit parent passcode"].waitForExistence(timeout: 10)
        )
        for _ in 0..<2 {
            for digit in ["Digit 1", "Digit 2", "Digit 3", "Digit 4"] {
                app.buttons[digit].firstMatch.tap()
            }
        }

        let hideDrink = app.buttons["Hide Drink"]
        XCTAssertTrue(hideDrink.waitForExistence(timeout: 10))
        hideDrink.tap()
        XCTAssertTrue(app.buttons["Show Drink"].waitForExistence(timeout: 10))

        app.buttons["Done"].firstMatch.tap()
        XCTAssertFalse(
            app.buttons["Drink"].waitForExistence(timeout: 3),
            "Hidden words should disappear from the child's view"
        )
    }

    // MARK: - Boards

    func testParentCreatesBoardAndItAppearsOnHome() throws {
        let app = launchApp()

        openTab(app, "Settings")
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 10))
        unlockParentMode(app)

        XCTAssertTrue(app.staticTexts["Manage Boards"].waitForExistence(timeout: 10))
        app.staticTexts["Manage Boards"].tap()

        let addBoard = app.buttons["Add Board"].firstMatch
        XCTAssertTrue(addBoard.waitForExistence(timeout: 10))
        addBoard.tap()

        let nameField = app.textFields["Board name (e.g. Morning Routine)"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 10))
        nameField.tap()
        nameField.typeText("Morning")

        // Add the first suggested word from the library.
        let addWord = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH 'Add ' AND label ENDSWITH ' to board'")
        ).firstMatch
        XCTAssertTrue(addWord.waitForExistence(timeout: 10))
        addWord.tap()

        app.buttons["Save"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Morning"].waitForExistence(timeout: 10))

        // Back to the Parent Mode root, then close it.
        let backButton = app.navigationBars.buttons["Parent Mode"].firstMatch
        XCTAssertTrue(backButton.waitForExistence(timeout: 10))
        backButton.tap()
        app.buttons["Done"].firstMatch.tap()

        openTab(app, "Home")
        XCTAssertTrue(app.staticTexts["My Boards"].waitForExistence(timeout: 10))
        let boardCard = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH 'Morning board'")
        ).firstMatch
        XCTAssertTrue(boardCard.exists)

        boardCard.tap()
        if !app.navigationBars["Morning"].waitForExistence(timeout: 10) {
            // Retry once: the tap can land while Home is still settling.
            boardCard.tap()
        }
        XCTAssertTrue(app.navigationBars["Morning"].waitForExistence(timeout: 10))
    }

    // MARK: - Accessibility

    func testHomeScreenPassesAccessibilityAudit() throws {
        let app = launchApp()
        XCTAssertTrue(app.navigationBars["MySay"].waitForExistence(timeout: 10))
        // Dynamic Type is audited separately by hand: AAC tiles live in a
        // fixed grid (the user-facing "grid size" setting is the supported
        // way to enlarge them), so unbounded text growth is intentionally
        // not supported inside tiles.
        try app.performAccessibilityAudit(for: [
            .sufficientElementDescription,
            .contrast,
            .hitRegion,
            .elementDetection,
            .trait,
        ])
    }

    // MARK: - Performance

    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
