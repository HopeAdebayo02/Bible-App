import SwiftUI

struct BookmarksNotesView: View {
    @ObservedObject private var lib = LibraryService.shared

    var body: some View {
        List {
            if lib.bookmarks.isEmpty && lib.notes.isEmpty {
                Text("No bookmarks or notes yet.")
                    .foregroundColor(.secondary)
            }
            if !lib.bookmarks.isEmpty {
                Section("Bookmarks") {
                    ForEach(lib.bookmarks) { b in
                        NavigationLink(destination: FocusedVersesView(bookId: b.bookId, bookName: b.bookName, chapter: b.chapter, verses: b.verses ?? [b.verse], note: b.note)) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(referenceText(bookName: b.bookName, chapter: b.chapter, verses: b.verses ?? [b.verse])).font(.headline)
                                Text(b.text).font(.subheadline).lineLimit(2)
                            }
                        }
                        .swipeActions {
                            Button(role: .destructive) { LibraryService.shared.deleteBookmark(id: b.id) } label: { Label("Delete", systemImage: "trash") }
                        }
                    }
                }
            }
            if !lib.notes.isEmpty {
                Section("Notes") {
                    ForEach(lib.notes) { n in
                        NavigationLink(destination: FocusedVersesView(bookId: n.bookId, bookName: n.bookName, chapter: n.chapter, verses: n.verses ?? [n.verse], note: n.text)) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(referenceText(bookName: n.bookName, chapter: n.chapter, verses: n.verses ?? [n.verse])).font(.headline)
                                Text(n.text).font(.subheadline).lineLimit(2)
                            }
                        }
                        .swipeActions {
                            Button(role: .destructive) { LibraryService.shared.deleteNote(id: n.id) } label: { Label("Delete", systemImage: "trash") }
                        }
                    }
                }
            }
        }
        .navigationTitle("Bookmarks & Notes")
    }
}

// MARK: - Reference formatting
private func referenceText(bookName: String, chapter: Int, verses: [Int]) -> String {
    let uniqueSorted = Array(Set(verses)).sorted()
    guard uniqueSorted.isEmpty == false else { return "\(bookName) \(chapter)" }

    var parts: [String] = []
    var index = 0
    while index < uniqueSorted.count {
        let start = uniqueSorted[index]
        var end = start
        while index + 1 < uniqueSorted.count && uniqueSorted[index + 1] == end + 1 {
            index += 1
            end = uniqueSorted[index]
        }
        parts.append(start == end ? "\(start)" : "\(start)-\(end)")
        index += 1
    }
    return "\(bookName) \(chapter):\(parts.joined(separator: ","))"
}
