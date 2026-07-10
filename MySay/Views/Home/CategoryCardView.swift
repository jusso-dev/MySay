import SwiftUI

/// Large rounded card representing one category on the Home screen.
struct CategoryCardView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.colorSchemeContrast) private var systemContrast

    let category: IconCategory

    private var highContrast: Bool {
        settings.highContrast || systemContrast == .increased
    }

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: category.symbolName)
                .font(.largeTitle)
                .imageScale(.large)
                .foregroundStyle(category.tileColor.tileAccent(highContrast: highContrast))
            Text(category.name)
                .font(.title3.weight(.semibold))
                .foregroundStyle(category.tileColor.tileText(highContrast: highContrast))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text("\(category.icons.count) words")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(category.tileColor.tileText(highContrast: highContrast))
                .opacity(highContrast ? 1 : 0.8)
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 140)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(category.tileColor.tileFill(highContrast: highContrast))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    category.tileColor.tileAccent(highContrast: highContrast)
                        .opacity(highContrast ? 1 : 0.25),
                    lineWidth: highContrast ? 3 : 1.5
                )
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(category.name) category, \(category.icons.count) words")
        .accessibilityHint("Opens the \(category.name) board")
    }
}
