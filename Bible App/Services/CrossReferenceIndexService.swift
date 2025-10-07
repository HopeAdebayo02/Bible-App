import Foundation

final class CrossReferenceIndexService {
    static let shared = CrossReferenceIndexService()
    private init() {}

    private var isLoaded: Bool = false
    private var pairKeys: Set<String> = []

    // MARK: - Public API
    func contains(sourceBookName: String, sourceChapter: Int, sourceVerse: Int,
                  targetBookName: String, targetChapter: Int, targetVerse: Int) -> Bool {
        if isLoaded == false {
            loadIndex()
        }
        guard let sId = bookId(for: sourceBookName), let tId = bookId(for: targetBookName) else {
            return false
        }
        let key = makeKey(sb: sId, sc: sourceChapter, sv: sourceVerse, tb: tId, tc: targetChapter, tv: targetVerse)
        return pairKeys.contains(key)
    }

    // MARK: - Loading and parsing
    private func loadIndex() {
        defer { isLoaded = true }
        guard let url = Bundle.main.url(forResource: "cross_references", withExtension: "txt") else {
            // Fallback: try common subpath variants if resource bundling differs
            if let alt = Bundle.main.url(forResource: "Models/cross_references", withExtension: "txt") {
                parseFile(at: alt)
            }
            return
        }
        parseFile(at: url)
    }

    private func parseFile(at url: URL) {
        guard let data = try? Data(contentsOf: url), let text = String(data: data, encoding: .utf8) else { return }
        var isFirstLine = true
        pairKeys.reserveCapacity(300_000)
        text.enumerateLines { [weak self] rawLine, _ in
            guard let self = self else { return }
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty { return }
            if isFirstLine { // header
                isFirstLine = false
                return
            }
            let cols = line.components(separatedBy: "\t")
            guard cols.count >= 2 else { return }
            let fromToken = cols[0]
            let toToken = cols[1]

            guard let from = parseRefToken(fromToken) else { return }

            // Handle toToken possibly being a range: Book.Ch.V1-Book.Ch.V2
            if let range = parseRangeToken(toToken) {
                if range.sameBookAndChapter {
                    let start = min(range.start.verse, range.end.verse)
                    let end = max(range.start.verse, range.end.verse)
                    for v in start...end {
                        let key = makeKey(sb: from.bookId, sc: from.chapter, sv: from.verse,
                                          tb: range.start.bookId, tc: range.start.chapter, tv: v)
                        pairKeys.insert(key)
                    }
                } else {
                    // Fallback: add endpoints if cross-chapter/book range appears
                    let k1 = makeKey(sb: from.bookId, sc: from.chapter, sv: from.verse,
                                     tb: range.start.bookId, tc: range.start.chapter, tv: range.start.verse)
                    let k2 = makeKey(sb: from.bookId, sc: from.chapter, sv: from.verse,
                                     tb: range.end.bookId, tc: range.end.chapter, tv: range.end.verse)
                    pairKeys.insert(k1)
                    pairKeys.insert(k2)
                }
            } else if let single = parseRefToken(toToken) {
                let key = makeKey(sb: from.bookId, sc: from.chapter, sv: from.verse,
                                  tb: single.bookId, tc: single.chapter, tv: single.verse)
                pairKeys.insert(key)
            }
        }
    }

    // MARK: - Parsing helpers
    private struct RefTriple { let bookId: Int; let chapter: Int; let verse: Int }
    private struct RefRange { let start: RefTriple; let end: RefTriple; var sameBookAndChapter: Bool { start.bookId == end.bookId && start.chapter == end.chapter } }

    private func parseRangeToken(_ token: String) -> RefRange? {
        let parts = token.split(separator: "-")
        guard parts.count == 2 else { return nil }
        guard let a = parseRefToken(String(parts[0])), let b = parseRefToken(String(parts[1])) else { return nil }
        return RefRange(start: a, end: b)
    }

    private func parseRefToken(_ token: String) -> RefTriple? {
        // Expect formats like: Gen.1.1 or 1John.3.16
        let pieces = token.split(separator: ".")
        guard pieces.count >= 3 else { return nil }
        let abbr = String(pieces[0])
        guard let full = fullName(forAbbreviation: abbr), let bookId = bookId(for: full) else { return nil }
        guard let chapter = Int(pieces[1]), let verse = Int(pieces[2]) else { return nil }
        return RefTriple(bookId: bookId, chapter: chapter, verse: verse)
    }

    private func makeKey(sb: Int, sc: Int, sv: Int, tb: Int, tc: Int, tv: Int) -> String {
        return "s:\(sb):\(sc):\(sv)|t:\(tb):\(tc):\(tv)"
    }

    private func bookId(for name: String) -> Int? {
        return BibleService.shared.canonicalBookId(for: name)
    }

    // MARK: - Abbreviation mapping for cross reference index
    private func fullName(forAbbreviation abbrRaw: String) -> String? {
        // Normalize by removing trailing punctuation and spaces
        let abbr = abbrRaw.replacingOccurrences(of: " ", with: "")
        if let hit = abbrToFull[abbr] { return hit }
        // Try without a trailing period if present
        let trimmed = abbr.trimmingCharacters(in: CharacterSet(charactersIn: "."))
        if let hit = abbrToFull[trimmed] { return hit }
        // As a last resort, return the input if it's already a full name present in our canon
        return abbrRaw
    }

    // Common OpenBible-style abbreviations to full names
    private let abbrToFull: [String: String] = [
        // Old Testament
        "Gen": "Genesis", "Exod": "Exodus", "Lev": "Leviticus", "Num": "Numbers", "Deut": "Deuteronomy",
        "Josh": "Joshua", "Judg": "Judges", "Ruth": "Ruth", "1Sam": "1 Samuel", "2Sam": "2 Samuel",
        "1Kgs": "1 Kings", "2Kgs": "2 Kings", "1Chr": "1 Chronicles", "2Chr": "2 Chronicles",
        "Ezra": "Ezra", "Neh": "Nehemiah", "Esth": "Esther", "Est": "Esther", "Job": "Job",
        "Ps": "Psalms", "Psa": "Psalms", "Prov": "Proverbs", "Eccl": "Ecclesiastes", "Song": "Song of Solomon",
        "Isa": "Isaiah", "Jer": "Jeremiah", "Lam": "Lamentations", "Ezek": "Ezekiel", "Eze": "Ezekiel", "Dan": "Daniel",
        "Hos": "Hosea", "Joel": "Joel", "Amos": "Amos", "Obad": "Obadiah", "Oba": "Obadiah", "Jonah": "Jonah", "Jon": "Jonah",
        "Mic": "Micah", "Nah": "Nahum", "Hab": "Habakkuk", "Zeph": "Zephaniah", "Zep": "Zephaniah",
        "Hag": "Haggai", "Zech": "Zechariah", "Zec": "Zechariah", "Mal": "Malachi",
        // New Testament
        "Matt": "Matthew", "Mat": "Matthew", "Mark": "Mark", "Mar": "Mark", "Luke": "Luke", "Luk": "Luke", "John": "John", "Joh": "John",
        "Acts": "Acts", "Act": "Acts", "Rom": "Romans", "1Cor": "1 Corinthians", "2Cor": "2 Corinthians", "Gal": "Galatians",
        "Eph": "Ephesians", "Phil": "Philippians", "Php": "Philippians", "Col": "Colossians",
        "1Thess": "1 Thessalonians", "2Thess": "2 Thessalonians", "1Thes": "1 Thessalonians", "2Thes": "2 Thessalonians",
        "1Tim": "1 Timothy", "2Tim": "2 Timothy", "Titus": "Titus", "Tit": "Titus", "Philem": "Philemon", "Phm": "Philemon",
        "Heb": "Hebrews", "Jas": "James", "Jam": "James", "1Pet": "1 Peter", "2Pet": "2 Peter",
        "1John": "1 John", "2John": "2 John", "3John": "3 John", "Jude": "Jude", "Rev": "Revelation"
    ]
}


