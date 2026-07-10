import SwiftData
import SwiftUI

/// The main screen: Favourites, Most Used, Recently Used, custom boards,
/// then all categories as large tappable cards.
struct HomeView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var context

    @Query(sort: \IconCategory.sortOrder) private var categories: [IconCategory]
    @Query(sort: \Board.sortOrder) private var boards: [Board]
    @Query(filter: #Predicate<IconItem> { $0.isFavourite && !$0.isHidden })
    private var favourites: [IconItem]
    @Query(
        filter: #Predicate<IconItem> { $0.usageCount > 0 && !$0.isHidden },
        sort: [SortDescriptor(\IconItem.usageCount, order: .reverse)]
    )
    private var usedIcons: [IconItem]
    @Query(
        filter: #Predicate<IconItem> { $0.lastUsedAt != nil && !$0.isHidden },
        sort: [SortDescriptor(\IconItem.lastUsedAt, order: .reverse)]
    )
    private var recentIcons: [IconItem]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    if !favourites.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeaderView(title: "Favourites", symbolName: "star.fill")
                            IconRowView(icons: sortedFavourites)
                        }
                    }

                    if !usedIcons.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeaderView(title: "Most Used", symbolName: "chart.bar.fill")
                            IconRowView(icons: Array(usedIcons.prefix(10)))
                        }
                    }

                    if !recentIcons.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeaderView(title: "Recently Used", symbolName: "clock.fill")
                            IconRowView(icons: Array(recentIcons.prefix(10)))
                        }
                    }

                    if !boards.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeaderView(title: "My Boards", symbolName: "rectangle.3.group.fill")
                            LazyVGrid(columns: cardColumns, spacing: 16) {
                                ForEach(boards) { board in
                                    NavigationLink(value: board) {
                                        BoardCardView(board: board)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeaderView(title: "Categories", symbolName: "square.grid.2x2.fill")
                        LazyVGrid(columns: cardColumns, spacing: 16) {
                            ForEach(categories) { category in
                                NavigationLink(value: category) {
                                    CategoryCardView(category: category)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("MySay")
            .navigationDestination(for: IconCategory.self) { category in
                CategoryDetailView(category: category)
            }
            .navigationDestination(for: Board.self) { board in
                BoardDetailView(board: board)
            }
        }
    }

    private var sortedFavourites: [IconItem] {
        FavoritesService.sort(favourites, by: settings.favouriteSort)
    }

    private var cardColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 16), count: 3)
    }
}
