import SwiftData
import SwiftUI

/// Parent-mode list of custom boards: create, edit, reorder, delete.
struct BoardManagerView: View {
    @Environment(\.modelContext) private var context

    @Query(sort: \Board.sortOrder) private var boards: [Board]

    @State private var editingBoard: Board?
    @State private var showAddSheet = false

    var body: some View {
        List {
            Section {
                if boards.isEmpty {
                    Text("Boards group words for a routine or place — like Morning, School, or At Grandma's. They appear on the Home screen.")
                        .foregroundStyle(.secondary)
                }
                ForEach(boards) { board in
                    Button {
                        editingBoard = board
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: board.symbolName)
                                .font(.title3)
                                .foregroundStyle(.tint)
                                .frame(width: 36)
                            Text(board.name)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.primary)
                            Spacer()
                            Text("\(board.iconIDs.count) words")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onMove(perform: move)
                .onDelete(perform: delete)
            } footer: {
                Text("Deleting a board never deletes any words.")
            }
        }
        .navigationTitle("Manage Boards")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddSheet = true
                } label: {
                    Label("Add Board", systemImage: "plus")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
        }
        .sheet(item: $editingBoard) { board in
            BoardEditorView(board: board)
        }
        .sheet(isPresented: $showAddSheet) {
            BoardEditorView(board: nil)
        }
    }

    private func move(from source: IndexSet, to destination: Int) {
        var reordered = boards
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, board) in reordered.enumerated() {
            board.sortOrder = index
        }
        try? context.save()
    }

    private func delete(_ offsets: IndexSet) {
        for offset in offsets where boards.indices.contains(offset) {
            context.delete(boards[offset])
        }
        try? context.save()
    }
}
