import Foundation

struct Bookmark: Identifiable, Codable, Hashable {
    let id: UUID
    let bookId: Int
    let bookName: String
    let chapter: Int
    let verse: Int
    let verses: [Int]? // optional multi-verse selection
    let text: String
    let note: String?
    let createdAt: Date

    init(bookId: Int, bookName: String, chapter: Int, verse: Int, verses: [Int]? = nil, text: String, note: String? = nil) {
        self.id = UUID()
        self.bookId = bookId
        self.bookName = bookName
        self.chapter = chapter
        self.verse = verse
        self.verses = verses
        self.text = text
        self.note = note
        self.createdAt = Date()
    }
}

struct UserNote: Identifiable, Codable, Hashable {
    let id: UUID
    let bookId: Int
    let bookName: String
    let chapter: Int
    let verse: Int
    let verses: [Int]? // optional multi-verse selection
    let text: String
    let createdAt: Date

    init(bookId: Int, bookName: String, chapter: Int, verse: Int, verses: [Int]? = nil, text: String) {
        self.id = UUID()
        self.bookId = bookId
        self.bookName = bookName
        self.chapter = chapter
        self.verse = verse
        self.verses = verses
        self.text = text
        self.createdAt = Date()
    }
}

struct VerseHighlight: Identifiable, Codable, Hashable {
    let id: UUID
    let bookId: Int
    let chapter: Int
    let startVerse: Int
    let endVerse: Int
    let colorHex: String
    let createdAt: Date

    init(bookId: Int, chapter: Int, startVerse: Int, endVerse: Int, colorHex: String) {
        self.id = UUID()
        self.bookId = bookId
        self.chapter = chapter
        self.startVerse = startVerse
        self.endVerse = endVerse
        self.colorHex = colorHex
        self.createdAt = Date()
    }
}
