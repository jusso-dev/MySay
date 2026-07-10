import AVFoundation
import Testing
@testable import MySay

@MainActor
@Suite("Settings store")
struct SettingsStoreTests {
    @Test("Fresh install uses sensible defaults")
    func defaults() {
        let settings = SettingsStore(defaults: TestSupport.makeDefaults())
        #expect(settings.speechRate == Double(AVSpeechUtteranceDefaultSpeechRate))
        #expect(settings.speechPitch == 1.0)
        #expect(settings.voiceIdentifier == nil)
        #expect(settings.gridColumns == 4)
        #expect(settings.showLabels)
        #expect(!settings.highContrast)
        #expect(settings.favouriteSort == .manual)
        #expect(!settings.hasCompletedOnboarding)
        #expect(!settings.isParentPasscodeSet)
    }

    @Test("Settings persist across instances sharing a suite")
    func persistence() {
        let suite = TestSupport.makeDefaults()
        let first = SettingsStore(defaults: suite)
        first.speechRate = 0.6
        first.speechPitch = 1.3
        first.gridColumns = 3
        first.showLabels = false
        first.highContrast = true
        first.favouriteSort = .alphabetical
        first.hasCompletedOnboarding = true
        first.voiceIdentifier = "com.example.voice"

        let second = SettingsStore(defaults: suite)
        #expect(second.speechRate == 0.6)
        #expect(second.speechPitch == 1.3)
        #expect(second.gridColumns == 3)
        #expect(!second.showLabels)
        #expect(second.highContrast)
        #expect(second.favouriteSort == .alphabetical)
        #expect(second.hasCompletedOnboarding)
        #expect(second.voiceIdentifier == "com.example.voice")
    }

    @Test("Invalid stored grid size falls back to 4")
    func gridValidation() {
        let suite = TestSupport.makeDefaults()
        suite.set(99, forKey: SettingsStore.Keys.gridColumns)
        let settings = SettingsStore(defaults: suite)
        #expect(settings.gridColumns == 4)
    }

    @Test("Passcode set, validate, and clear")
    func passcode() {
        let settings = SettingsStore(defaults: TestSupport.makeDefaults())
        settings.setParentPasscode("4321")

        #expect(settings.isParentPasscodeSet)
        #expect(settings.validateParentPasscode("4321"))
        #expect(!settings.validateParentPasscode("1111"))

        settings.clearParentPasscode()
        #expect(!settings.isParentPasscodeSet)
        #expect(!settings.validateParentPasscode("4321"))
    }

    @Test("Passcode is stored hashed, not as plain text")
    func passcodeHashing() {
        let suite = TestSupport.makeDefaults()
        let settings = SettingsStore(defaults: suite)
        settings.setParentPasscode("4321")
        let stored = suite.string(forKey: SettingsStore.Keys.parentPasscodeHash)
        #expect(stored != nil)
        #expect(stored != "4321")
        #expect(stored == SettingsStore.hash("4321"))
    }
}
