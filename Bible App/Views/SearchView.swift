import SwiftUI

struct SearchView: View {
    @State private var query: String = ""
    @State private var results: [BibleVerse] = []
    @State private var isSearching: Bool = false
    @State private var errorMessage: String? = nil
    @EnvironmentObject private var bibleRouter: BibleRouter
    @ObservedObject private var translation = TranslationService.shared
    @State private var scheduledTask: Task<Void, Never>? = nil
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                TextField("Search scripture", text: $query)
                    .textInputAutocapitalization(.none)
                    .disableAutocorrection(true)
                    .submitLabel(.search)
                    .focused($isFocused)
                    .onSubmit { Task { await performSearch(openFirstMatch: true) } }
                Button(action: { query = ""; results = [] }) { Image(systemName: "xmark.circle.fill") }
                    .opacity(query.isEmpty ? 0 : 1)
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.horizontal, 16)
            .padding(.top, 12)

            List {
            if query.trimmingCharacters(in: .whitespacesAndNewlines).count < 3 {
                Text("Type at least 3 characters to search")
                    .foregroundColor(.secondary)
            }
            if isSearching { ProgressView().tint(.secondary) }
            if let errorMessage { Text(errorMessage).foregroundColor(.red) }
            if !isSearching && results.isEmpty && query.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3 {
                Text("No results for \"\(query)\"")
                    .foregroundColor(.secondary)
            }
                ForEach(results) { verse in
                    Button(action: { open(verse) }) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(reference(for: verse))
                            .font(.headline)
                            HStack(alignment: .top, spacing: 8) {
                                Text(verse.text)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(3)
                                Spacer(minLength: 8)
                                Text(verse.version)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color(.tertiarySystemFill))
                                    .clipShape(Capsule())
                            }
                    }
                }
                .buttonStyle(.plain)
                    .contextMenu {
                        ForEach(translation.available, id: \.self) { v in
                            Button("Open in \(v)") {
                                open(verse, forceVersion: v)
                            }
                        }
                    }
            }
            }
        }
        .navigationTitle("Search")
        .task { isFocused = true }
        .onChange(of: query) { _, new in
            // Debounce
            scheduledTask?.cancel()
            let text = new.trimmingCharacters(in: .whitespacesAndNewlines)
            if text.count < 3 { results = []; return }
            scheduledTask = Task {
                try? await Task.sleep(nanoseconds: 350_000_000)
                if Task.isCancelled { return }
                await performSearch(openFirstMatch: false)
            }
        }
    }

    private func performSearch(openFirstMatch: Bool) async {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.count >= 2 else { return }
        await MainActor.run { self.isSearching = true; self.errorMessage = nil }
        do {
            let verses = try await BibleService.shared.searchVerses(query: text)
            await MainActor.run {
                self.results = verses
                self.isSearching = false
                if openFirstMatch, let first = verses.first { open(first) }
            }
        } catch {
            await MainActor.run { self.errorMessage = error.localizedDescription; self.isSearching = false }
        }
    }

    private func reference(for v: BibleVerse) -> String {
        let book = BibleService.shared.getBookName(byId: v.book_id) ?? "Book \(v.book_id)"
        return "\(book) \(v.chapter):\(v.verse)"
    }

    private func open(_ v: BibleVerse, forceVersion: String? = nil) {
        let bookName = BibleService.shared.getBookName(byId: v.book_id) ?? ""
        let book = BibleBook(id: v.book_id, name: bookName, abbreviation: "", testament: nil, chapters: 150)
        // Switch translation to match desired version
        TranslationService.shared.version = forceVersion ?? v.version
        bibleRouter.goToChapter(book: book, chapter: v.chapter)
    }
}


