import SwiftUI

/// Home-screen card for a custom board.
struct BoardCardView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.colorSchemeContrast) private var systemContrast

    let board: Board

    private var highContrast: Bool {
        settings.highContrast || systemContrast == .increased
    }

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: board.symbolName)
                .font(.largeTitle)
                .imageScale(.large)
                .foregroundStyle(TileColor.slate.tileAccent(highContrast: highContrast))
            Text(board.name)
                .font(.title3.weight(.semibold))
                .foregroundStyle(TileColor.slate.tileText(highContrast: highContrast))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text("\(board.iconIDs.count) words")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(TileColor.slate.tileText(highContrast: highContrast))
                .opacity(highContrast ? 1 : 0.8)
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 140)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(TileColor.slate.tileFill(highContrast: highContrast))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    TileColor.slate.tileAccent(highContrast: highContrast)
                        .opacity(highContrast ? 1 : 0.25),
                    lineWidth: highContrast ? 3 : 1.5
                )
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(board.name) board, \(board.iconIDs.count) words")
        .accessibilityHint("Opens the \(board.name) board")
    }
}
