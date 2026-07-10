import SwiftData
import SwiftUI

/// Global live search over icon names, phrases, and categories.
struct SearchView: View {
    @Query(sort: \IconItem.title) private var allIcons: [IconItem]
    @State private var viewModel = SearchViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                if viewModel.searchText.isEmpty {
                    EmptyStateView(
                        symbolName: "magnifyingglass",
                        title: "Search for a word",
                        message: "Type a word or category name. Tap any result to hear it spoken."
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.top, 80)
                } else if results.isEmpty {
                    EmptyStateView(
                        symbolName: "questionmark.circle",
                        title: "No matches",
                        message: "No words match “\(viewModel.searchText)”. A parent can add new words in Parent Mode."
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.top, 80)
                } else {
                    IconGridView(icons: results)
                        .padding(.vertical)
                }
            }
            .navigationTitle("Search")
            .searchable(
                text: $viewModel.searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search words and categories"
            )
        }
    }

    private var results: [IconItem] {
        viewModel.results(in: allIcons)
    }
}
