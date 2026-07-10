import SwiftData
import SwiftUI

/// Full-screen favourites board with sort control (manual / most used / A–Z).
struct FavoritesView: View {
    @Environment(SettingsStore.self) private var settings

    @Query(filter: #Predicate<IconItem> { $0.isFavourite && !$0.isHidden })
    private var favourites: [IconItem]

    var body: some View {
        @Bindable var settings = settings
        NavigationStack {
            ScrollView {
                if favourites.isEmpty {
                    EmptyStateView(
                        symbolName: "star",
                        title: "No favourites yet",
                        message: "Touch and hold any picture, then choose Add to Favourites. Favourite words appear here and on the Home screen."
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.top, 80)
                } else {
                    IconGridView(icons: sorted)
                        .padding(.vertical)
                }
            }
            .navigationTitle("Favourites")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Picker("Sort favourites", selection: $settings.favouriteSort) {
                        ForEach(FavouriteSortMode.allCases, id: \.self) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                    .accessibilityLabel("Sort favourites")
                }
            }
        }
    }

    private var sorted: [IconItem] {
        FavoritesService.sort(favourites, by: settings.favouriteSort)
    }
}
