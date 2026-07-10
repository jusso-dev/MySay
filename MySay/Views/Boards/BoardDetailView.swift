import SwiftData
import SwiftUI

/// A custom board: a parent-curated, ordered set of icons for a routine
/// or situation ("Morning", "At Grandma's"). Tiles speak like everywhere
/// else; the pencil opens the (passcode-gated) board editor.
struct BoardDetailView: View {
    @Environment(SettingsStore.self) private var settings

    let board: Board

    @Query private var allIcons: [IconItem]

    @State private var showGate = false
    @State private var showEditor = false

    var body: some View {
        ScrollView {
            if resolvedIcons.isEmpty {
                EmptyStateView(
                    symbolName: "rectangle.3.group",
                    title: "This board is empty",
                    message: "A parent can add words with the pencil button."
                )
                .frame(maxWidth: .infinity)
                .padding(.top, 80)
            } else {
                IconGridView(icons: resolvedIcons)
                    .padding(.vertical)
            }
        }
        .navigationTitle(board.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showGate = true
                } label: {
                    Label("Edit Board", systemImage: "pencil")
                }
                .accessibilityHint("Requires the parent passcode")
            }
        }
        .sheet(isPresented: $showGate) {
            PasscodeGateView {
                showGate = false
                showEditor = true
            }
        }
        .sheet(isPresented: $showEditor) {
            BoardEditorView(board: board)
        }
    }

    /// Icons in the board's stored order, skipping hidden words and any
    /// IDs whose icon was deleted.
    private var resolvedIcons: [IconItem] {
        let byID = Dictionary(uniqueKeysWithValues: allIcons.map { ($0.id, $0) })
        return board.iconIDs.compactMap { byID[$0] }.filter { !$0.isHidden }
    }
}
