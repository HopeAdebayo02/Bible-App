import Foundation

struct Footnote: Codable, Identifiable {
    let id: Int?
    let book_id: Int
    let chapter: Int
    let verse: Int
    let marker: String
    let text: String
}


