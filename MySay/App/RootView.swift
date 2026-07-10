import SwiftUI

/// Onboarding on first launch, then the main tab interface.
struct RootView: View {
    @Environment(SettingsStore.self) private var settings

    var body: some View {
        if settings.hasCompletedOnboarding {
            MainTabView()
        } else {
            OnboardingView()
        }
    }
}

enum AppTab: Hashable {
    case home, favourites, phrases, search, settings
}

/// The app's five sections plus the global sentence strip. Tabs are
/// deliberately few and stable so the layout never surprises a child.
struct MainTabView: View {
    @Environment(SettingsStore.self) private var settings

    @State private var selectedTab = AppTab.home

    var body: some View {
        VStack(spacing: 0) {
            // The Phrases tab has its own full-size strip; everywhere
            // else gets the compact message window.
            if settings.showSentenceStrip && selectedTab != .phrases {
                CompactSentenceStripView()
            }
            TabView(selection: $selectedTab) {
                Tab("Home", systemImage: "house.fill", value: .home) {
                    HomeView()
                }
                Tab("Favourites", systemImage: "star.fill", value: .favourites) {
                    FavoritesView()
                }
                Tab("Phrases", systemImage: "text.bubble.fill", value: .phrases) {
                    PhraseBuilderView()
                }
                Tab("Search", systemImage: "magnifyingglass", value: .search) {
                    SearchView()
                }
                Tab("Settings", systemImage: "gearshape.fill", value: .settings) {
                    SettingsView()
                }
            }
        }
    }
}
