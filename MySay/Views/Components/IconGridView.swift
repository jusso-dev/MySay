import SwiftUI

/// Lazy grid of icon tiles sized by the user's grid preference.
struct IconGridView: View {
    @Environment(SettingsStore.self) private var settings

    let icons: [IconItem]
    var onSelect: ((IconItem) -> Void)?
    var alwaysAddToPhrase = false

    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(icons) { icon in
                IconTileView(
                    icon: icon,
                    onSelect: onSelect,
                    alwaysAddToPhrase: alwaysAddToPhrase
                )
            }
        }
        .padding(.horizontal)
    }

    private var columns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: 16),
            count: settings.gridColumns
        )
    }
}

/// Horizontally scrolling row of fixed-size tiles used on the Home screen
/// for Favourites, Most Used, and Recently Used.
struct IconRowView: View {
    let icons: [IconItem]
    var onSelect: ((IconItem) -> Void)?

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 16) {
                ForEach(icons) { icon in
                    IconTileView(icon: icon, onSelect: onSelect)
                        .frame(width: 150, height: 150)
                }
            }
            .padding(.horizontal)
        }
        .scrollIndicators(.hidden)
    }
}

/// Section heading used across the Home screen.
struct SectionHeaderView: View {
    let title: String
    let symbolName: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbolName)
                .font(.title3)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.title2.weight(.bold))
            Spacer()
        }
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

/// Calm placeholder for empty sections.
struct EmptyStateView: View {
    let symbolName: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: symbolName)
                .font(.largeTitle)
                .imageScale(.large)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.title3.weight(.semibold))
            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: 420)
        .padding(32)
        .accessibilityElement(children: .combine)
    }
}
