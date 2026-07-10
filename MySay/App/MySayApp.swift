import SwiftData
import SwiftUI

@main
struct MySayApp: App {
    private let dataStore: DataStore
    @State private var speechService: SpeechService
    @State private var settings: SettingsStore
    @State private var phraseViewModel = PhraseBuilderViewModel()

    init() {
        let arguments = CommandLine.arguments
        let isUITest = arguments.contains("--uitest")

        // UI tests run against an in-memory store and a throwaway defaults
        // suite so they never disturb real data.
        let defaults: UserDefaults
        if isUITest {
            defaults = UserDefaults(suiteName: "uitest")!
            defaults.removePersistentDomain(forName: "uitest")
        } else {
            defaults = .standard
        }

        let store: DataStore
        do {
            store = try DataStore(inMemory: isUITest)
        } catch {
            // Persistent store unavailable (e.g. corrupted). Fall back to
            // in-memory so the child can still communicate this session.
            store = (try? DataStore(inMemory: true))
                ?? { fatalError("Unable to create any data store: \(error)") }()
        }
        store.seedIfNeeded()
        dataStore = store

        let settingsStore = SettingsStore(defaults: defaults)
        if arguments.contains("--uitest-skip-onboarding") {
            settingsStore.hasCompletedOnboarding = true
        }
        if arguments.contains("--uitest-auto-sentence") {
            settingsStore.autoAddToSentence = true
        }
        _settings = State(initialValue: settingsStore)
        _speechService = State(initialValue: SpeechService())
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(speechService)
                .environment(settings)
                .environment(phraseViewModel)
                .modelContainer(dataStore.container)
        }
    }
}
