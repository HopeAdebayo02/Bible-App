import Foundation

class HeaderService {
    static let shared = HeaderService()

    private var headersByBookChapter: [String: [Int: [Int: String]]] = [:] // [bookName: [chapter: [verse: heading]]]

    private init() {
        loadHeaders()
    }

    private func loadHeaders() {
        guard let url = Bundle.main.url(forResource: "Header", withExtension: "md"),
              let content = try? String(contentsOf: url, encoding: .utf8) else {
            print("Could not load Header.md file")
            return
        }

        let lines = content.components(separatedBy: .newlines)
        var currentBook: String?
        var currentChapter: Int?

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmed.hasPrefix("# ") && !trimmed.hasPrefix("## ") {
                // Book header like "# Genesis"
                currentBook = String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                currentChapter = nil
            } else if trimmed.hasPrefix("## Chapter ") {
                // Chapter header like "## Chapter 1"
                let chapterStr = trimmed.replacingOccurrences(of: "## Chapter ", with: "")
                currentChapter = Int(chapterStr)
            } else if trimmed.hasPrefix("- v") {
                // Verse heading like "- v1: The Creation"
                if let book = currentBook, let chapter = currentChapter {
                    let pattern = "- v(\\d+): (.+)"
                    if let regex = try? NSRegularExpression(pattern: pattern, options: []),
                       let match = regex.firstMatch(in: trimmed, options: [], range: NSRange(location: 0, length: trimmed.count)),
                       match.numberOfRanges == 3 {

                        let verseRange = match.range(at: 1)
                        let headingRange = match.range(at: 2)

                        if let verseNum = Int((trimmed as NSString).substring(with: verseRange)),
                           let heading = (trimmed as NSString).substring(with: headingRange) as String? {

                            if headersByBookChapter[book] == nil {
                                headersByBookChapter[book] = [:]
                            }
                            if headersByBookChapter[book]?[chapter] == nil {
                                headersByBookChapter[book]?[chapter] = [:]
                            }
                            headersByBookChapter[book]?[chapter]?[verseNum] = heading.trimmingCharacters(in: .whitespaces)
                        }
                    }
                }
            }
        }

        print("Loaded headers for \(headersByBookChapter.count) books")
    }

    func getHeading(forBook bookName: String, chapter: Int, verse: Int) -> String? {
        return headersByBookChapter[bookName]?[chapter]?[verse]
    }

    func getAllHeadings(forBook bookName: String, chapter: Int) -> [Int: String] {
        return headersByBookChapter[bookName]?[chapter] ?? [:]
    }

    func getBooks() -> [String] {
        return Array(headersByBookChapter.keys).sorted()
    }
}
