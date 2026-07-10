import AVFoundation
import CryptoKit
import Foundation
import Observation

/// How the Favourites section is ordered.
nonisolated enum FavouriteSortMode: String, CaseIterable, Codable, Sendable {
    case manual
    case mostUsed
    case alphabetical

    var displayName: String {
        switch self {
        case .manual: "Manual"
        case .mostUsed: "Most used"
        case .alphabetical: "A–Z"
        }
    }
}

/// All user preferences, persisted in `UserDefaults`.
///
/// Observable so every view updates live when a setting changes. A custom
/// suite can be injected for tests.
@Observable
final class SettingsStore {
    nonisolated enum Keys {
        static let speechRate = "settings.speechRate"
        static let speechPitch = "settings.speechPitch"
        static let voiceIdentifier = "settings.voiceIdentifier"
        static let gridColumns = "settings.gridColumns"
        static let showLabels = "settings.showLabels"
        static let showSentenceStrip = "settings.showSentenceStrip"
        static let autoAddToSentence = "settings.autoAddToSentence"
        static let highContrast = "settings.highContrast"
        static let favouriteSort = "settings.favouriteSort"
        static let parentPasscodeHash = "settings.parentPasscodeHash"
        static let hasCompletedOnboarding = "settings.hasCompletedOnboarding"
        static let hasSeededData = "settings.hasSeededData"
    }

    static let speechRateRange: ClosedRange<Double> = 0.3...0.65
    static let speechPitchRange: ClosedRange<Double> = 0.8...1.4
    static let gridColumnOptions = [2, 3, 4, 5]

    private let defaults: UserDefaults

    var speechRate: Double {
        didSet { defaults.set(speechRate, forKey: Keys.speechRate) }
    }
    var speechPitch: Double {
        didSet { defaults.set(speechPitch, forKey: Keys.speechPitch) }
    }
    var voiceIdentifier: String? {
        didSet { defaults.set(voiceIdentifier, forKey: Keys.voiceIdentifier) }
    }
    /// Tiles per row on category and search grids (2–5).
    var gridColumns: Int {
        didSet { defaults.set(gridColumns, forKey: Keys.gridColumns) }
    }
    var showLabels: Bool {
        didSet { defaults.set(showLabels, forKey: Keys.showLabels) }
    }
    /// Show the message window (sentence strip) on every screen, so any
    /// tapped word can join a sentence — the convention in full AAC apps.
    var showSentenceStrip: Bool {
        didSet { defaults.set(showSentenceStrip, forKey: Keys.showSentenceStrip) }
    }
    /// When on, every tapped picture anywhere is appended to the sentence
    /// strip. Off by default: taps just speak, and sentences are built
    /// deliberately in the Phrases tab.
    var autoAddToSentence: Bool {
        didSet { defaults.set(autoAddToSentence, forKey: Keys.autoAddToSentence) }
    }
    var highContrast: Bool {
        didSet { defaults.set(highContrast, forKey: Keys.highContrast) }
    }
    var favouriteSort: FavouriteSortMode {
        didSet { defaults.set(favouriteSort.rawValue, forKey: Keys.favouriteSort) }
    }
    var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: Keys.hasCompletedOnboarding) }
    }

    private var parentPasscodeHash: String? {
        didSet { defaults.set(parentPasscodeHash, forKey: Keys.parentPasscodeHash) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let storedRate = defaults.double(forKey: Keys.speechRate)
        speechRate = storedRate == 0
            ? Double(AVSpeechUtteranceDefaultSpeechRate)
            : storedRate.clamped(to: Self.speechRateRange)
        let storedPitch = defaults.double(forKey: Keys.speechPitch)
        speechPitch = storedPitch == 0 ? 1.0 : storedPitch.clamped(to: Self.speechPitchRange)
        voiceIdentifier = defaults.string(forKey: Keys.voiceIdentifier)
        let storedColumns = defaults.integer(forKey: Keys.gridColumns)
        gridColumns = Self.gridColumnOptions.contains(storedColumns) ? storedColumns : 4
        showLabels = defaults.object(forKey: Keys.showLabels) as? Bool ?? true
        showSentenceStrip = defaults.object(forKey: Keys.showSentenceStrip) as? Bool ?? true
        autoAddToSentence = defaults.bool(forKey: Keys.autoAddToSentence)
        highContrast = defaults.bool(forKey: Keys.highContrast)
        favouriteSort = FavouriteSortMode(
            rawValue: defaults.string(forKey: Keys.favouriteSort) ?? ""
        ) ?? .manual
        hasCompletedOnboarding = defaults.bool(forKey: Keys.hasCompletedOnboarding)
        parentPasscodeHash = defaults.string(forKey: Keys.parentPasscodeHash)
    }

    // MARK: - Parent passcode

    /// True once a parent has chosen a passcode.
    var isParentPasscodeSet: Bool {
        parentPasscodeHash != nil
    }

    func setParentPasscode(_ passcode: String) {
        parentPasscodeHash = Self.hash(passcode)
    }

    func validateParentPasscode(_ passcode: String) -> Bool {
        guard let parentPasscodeHash else { return false }
        return Self.hash(passcode) == parentPasscodeHash
    }

    func clearParentPasscode() {
        parentPasscodeHash = nil
    }

    /// SHA-256 keeps the passcode out of plain-text defaults. This is a
    /// child gate, not a security boundary.
    nonisolated static func hash(_ value: String) -> String {
        SHA256.hash(data: Data(value.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }
}
