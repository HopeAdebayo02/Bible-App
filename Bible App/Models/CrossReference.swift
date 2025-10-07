import Foundation

struct CrossReferenceLine: Identifiable, Codable, Hashable {
    let id: UUID
    let sourceBookId: Int
    let sourceBookName: String
    let sourceChapter: Int
    let sourceVerse: Int
    let targetBookId: Int
    let targetBookName: String
    let targetChapter: Int
    let targetVerse: Int
    let note: String?
    let createdAt: Date

    init(
        sourceBookId: Int,
        sourceBookName: String,
        sourceChapter: Int,
        sourceVerse: Int,
        targetBookId: Int,
        targetBookName: String,
        targetChapter: Int,
        targetVerse: Int,
        note: String? = nil
    ) {
        self.id = UUID()
        self.sourceBookId = sourceBookId
        self.sourceBookName = sourceBookName
        self.sourceChapter = sourceChapter
        self.sourceVerse = sourceVerse
        self.targetBookId = targetBookId
        self.targetBookName = targetBookName
        self.targetChapter = targetChapter
        self.targetVerse = targetVerse
        self.note = note
        self.createdAt = Date()
    }
}



