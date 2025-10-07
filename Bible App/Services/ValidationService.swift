import Foundation

struct ChapterValidationIssue: Identifiable, Hashable {
    let id = UUID()
    let bookId: Int
    let bookName: String
    let chapter: Int
    let version: String?
    let problem: String
}

final class ValidationService {
    static let shared = ValidationService()
    private init() {}

    // Validate every book/chapter for the CURRENT selected version
    func validateAll() async -> [ChapterValidationIssue] {
        var issues: [ChapterValidationIssue] = []
        do {
            let books = try await BibleService.shared.fetchBooks()
            for book in books.sorted(by: { BibleService.shared.canonicalOrderIndex(for: $0.name) < BibleService.shared.canonicalOrderIndex(for: $1.name) }) {
                for chapter in 1...book.chapters {
                    do {
                        let verses = try await BibleService.shared.fetchVerses(bookId: book.id, chapter: chapter)
                        // Normalize locally as well (defensive) before validating
                        let normalized = ValidationService.normalizeLocally(verses: verses)
                        if verses.isEmpty {
                            issues.append(ChapterValidationIssue(bookId: book.id, bookName: book.name, chapter: chapter, version: TranslationService.shared.version, problem: "No verses returned"))
                            continue
                        }
                        // Basic sanity: ensure verse numbers are increasing (after normalization)
                        let numbers = normalized.map { $0.verse }
                        let sorted = numbers.sorted()
                        if sorted != numbers {
                            issues.append(ChapterValidationIssue(bookId: book.id, bookName: book.name, chapter: chapter, version: TranslationService.shared.version, problem: "Verse order is not strictly increasing"))
                        }
                        // Duplicates: any verse number appearing more than once
                        let counts = Dictionary(grouping: numbers, by: { $0 }).mapValues { $0.count }
                        let hasDuplicate = counts.values.contains { $0 > 1 }
                        // Gaps: after normalization, numbers should be contiguous from min..max
                        let minN = numbers.min() ?? 1
                        let maxN = numbers.max() ?? minN
                        var hasGap = false
                        if maxN >= minN {
                            for expected in minN...maxN {
                                if counts[expected] == nil { hasGap = true; break }
                            }
                        }
                        if hasGap {
                            issues.append(ChapterValidationIssue(bookId: book.id, bookName: book.name, chapter: chapter, version: TranslationService.shared.version, problem: "Missing verse numbers (gap detected)"))
                        }
                        if hasDuplicate {
                            issues.append(ChapterValidationIssue(bookId: book.id, bookName: book.name, chapter: chapter, version: TranslationService.shared.version, problem: "Duplicate verse numbers detected"))
                        }
                    } catch {
                        issues.append(ChapterValidationIssue(bookId: book.id, bookName: book.name, chapter: chapter, version: TranslationService.shared.version, problem: "Error: \(error.localizedDescription)"))
                    }
                }
            }
        } catch {
            issues.append(ChapterValidationIssue(bookId: -1, bookName: "All", chapter: 0, version: TranslationService.shared.version, problem: "Failed to fetch books: \(error.localizedDescription)"))
        }
        return issues
    }

    // Validate all versions defined in TranslationService.available
    func validateAllVersions() async -> [ChapterValidationIssue] {
        var issues: [ChapterValidationIssue] = []
        do {
            let books = try await BibleService.shared.fetchBooks()
            let versions = TranslationService.shared.available
            for version in versions {
                for book in books.sorted(by: { BibleService.shared.canonicalOrderIndex(for: $0.name) < BibleService.shared.canonicalOrderIndex(for: $1.name) }) {
                    for chapter in 1...book.chapters {
                        do {
                            let verses = try await BibleService.shared.fetchVerses(bookId: book.id, chapter: chapter, version: version)
                            // Already normalized by service; still run local check for gaps
                            let normalized = ValidationService.normalizeLocally(verses: verses)
                            if verses.isEmpty {
                                issues.append(ChapterValidationIssue(bookId: book.id, bookName: book.name, chapter: chapter, version: version, problem: "No verses returned"))
                                continue
                            }
                            let numbers = normalized.map { $0.verse }
                            let sorted = numbers.sorted()
                            if sorted != numbers {
                                issues.append(ChapterValidationIssue(bookId: book.id, bookName: book.name, chapter: chapter, version: version, problem: "Verse order is not strictly increasing"))
                            }
                            let counts = Dictionary(grouping: numbers, by: { $0 }).mapValues { $0.count }
                            let hasDuplicate = counts.values.contains { $0 > 1 }
                            let minN = numbers.min() ?? 1
                            let maxN = numbers.max() ?? minN
                            var hasGap = false
                            if maxN >= minN {
                                for expected in minN...maxN {
                                    if counts[expected] == nil { hasGap = true; break }
                                }
                            }
                            if hasGap {
                                issues.append(ChapterValidationIssue(bookId: book.id, bookName: book.name, chapter: chapter, version: version, problem: "Missing verse numbers (gap detected)"))
                            }
                            if hasDuplicate {
                                issues.append(ChapterValidationIssue(bookId: book.id, bookName: book.name, chapter: chapter, version: version, problem: "Duplicate verse numbers detected"))
                            }
                        } catch {
                            issues.append(ChapterValidationIssue(bookId: book.id, bookName: book.name, chapter: chapter, version: version, problem: "Error: \(error.localizedDescription)"))
                        }
                    }
                }
            }
        } catch {
            issues.append(ChapterValidationIssue(bookId: -1, bookName: "All", chapter: 0, version: nil, problem: "Failed to fetch books: \(error.localizedDescription)"))
        }
        return issues
    }

    // Local-only normalization identical in spirit to BibleService normalization; used to confirm gaps.
    private static func normalizeLocally(verses: [BibleVerse]) -> [BibleVerse] {
        guard verses.isEmpty == false else { return verses }
        let sorted = verses.sorted { (a, b) in
            if a.verse == b.verse { return a.id < b.id }
            return a.verse < b.verse
        }
        var out: [BibleVerse] = []
        var prev: Int? = nil
        let bookId = sorted.first!.book_id
        let chapter = sorted.first!.chapter
        let version = sorted.first!.version
        for v in sorted {
            if let p = prev {
                if v.verse > p + 1 {
                    for m in (p + 1)..<v.verse {
                        let synth = (bookId * 10_000_000) + (chapter * 10_000) + (m * 10) + 9
                        out.append(BibleVerse(id: synth, book_id: bookId, chapter: chapter, verse: m, text: "", version: version, heading: nil))
                    }
                }
            } else if v.verse > 1 {
                for m in 1..<v.verse {
                    let synth = (bookId * 10_000_000) + (chapter * 10_000) + (m * 10) + 9
                    out.append(BibleVerse(id: synth, book_id: bookId, chapter: chapter, verse: m, text: "", version: version, heading: nil))
                }
            }
            out.append(v)
            prev = v.verse
        }
        return out
    }
}


