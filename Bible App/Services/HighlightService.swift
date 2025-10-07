import Foundation
import Combine

final class HighlightService: ObservableObject {
    static let shared = HighlightService()

    @Published private(set) var highlights: [VerseHighlight] = []

    private let highlightsKey = "highlight.verseHighlights"

    private init() {
        loadHighlights()
    }

    // Add or update a highlight for a verse range
    func setHighlight(bookId: Int, chapter: Int, startVerse: Int, endVerse: Int, colorHex: String) {
        // Remove any existing highlights that overlap with this range
        removeHighlight(bookId: bookId, chapter: chapter, startVerse: startVerse, endVerse: endVerse)

        // Add the new highlight
        let highlight = VerseHighlight(
            bookId: bookId,
            chapter: chapter,
            startVerse: startVerse,
            endVerse: endVerse,
            colorHex: colorHex
        )
        highlights.append(highlight)
        saveHighlights()
    }

    // Remove highlight for a specific verse range
    func removeHighlight(bookId: Int, chapter: Int, startVerse: Int, endVerse: Int) {
        highlights.removeAll { highlight in
            highlight.bookId == bookId &&
            highlight.chapter == chapter &&
            highlight.startVerse <= endVerse &&
            highlight.endVerse >= startVerse
        }
        saveHighlights()
    }

    // Remove a specific highlight by ID
    func removeHighlight(id: UUID) {
        highlights.removeAll { $0.id == id }
        saveHighlights()
    }

    // Get highlights for a specific chapter
    func highlightsForChapter(bookId: Int, chapter: Int) -> [VerseHighlight] {
        return highlights.filter { $0.bookId == bookId && $0.chapter == chapter }
    }

    // Check if a verse is highlighted
    func isVerseHighlighted(bookId: Int, chapter: Int, verse: Int) -> Bool {
        return highlights.contains { highlight in
            highlight.bookId == bookId &&
            highlight.chapter == chapter &&
            verse >= highlight.startVerse &&
            verse <= highlight.endVerse
        }
    }

    // Get the highlight color for a verse (if highlighted)
    func colorForVerse(bookId: Int, chapter: Int, verse: Int) -> String? {
        return highlights.first { highlight in
            highlight.bookId == bookId &&
            highlight.chapter == chapter &&
            verse >= highlight.startVerse &&
            verse <= highlight.endVerse
        }?.colorHex
    }

    private func loadHighlights() {
        let d = UserDefaults.standard
        if let data = d.data(forKey: highlightsKey), let list = try? JSONDecoder().decode([VerseHighlight].self, from: data) {
            highlights = list
        }
    }

    private func saveHighlights() {
        let d = UserDefaults.standard
        if let data = try? JSONEncoder().encode(highlights) {
            d.set(data, forKey: highlightsKey)
        }
        objectWillChange.send()
    }
}
