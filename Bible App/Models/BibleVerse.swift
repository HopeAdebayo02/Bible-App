//
//  BibleVerse.swift
//  Bible App
//
//  Created by Hope Adebayo on 9/9/25.
//

import Foundation

struct BibleVerse: Codable, Identifiable {
    let id: Int
    let book_id: Int
    let chapter: Int
    let verse: Int
    let text: String
    let version: String
    let heading: String?

    enum CodingKeys: String, CodingKey {
        case id
        case book_id
        case chapter
        case verse
        case text
        case version
        // Potential heading keys used by different datasets
        case heading
        case subheading
        case title
        case pericope
        case section
        case section_title
    }

    init(id: Int, book_id: Int, chapter: Int, verse: Int, text: String, version: String, heading: String?) {
        self.id = id
        self.book_id = book_id
        self.chapter = chapter
        self.verse = verse
        self.text = text
        self.version = version
        self.heading = heading
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        book_id = try container.decode(Int.self, forKey: .book_id)
        chapter = try container.decode(Int.self, forKey: .chapter)
        verse = try container.decode(Int.self, forKey: .verse)
        text = try container.decode(String.self, forKey: .text)
        version = try container.decode(String.self, forKey: .version)
        // Try to decode heading from multiple possible keys (stepwise to satisfy the compiler)
        var decodedHeading: String? = nil
        if decodedHeading == nil { decodedHeading = try container.decodeIfPresent(String.self, forKey: .heading) }
        if decodedHeading == nil { decodedHeading = try container.decodeIfPresent(String.self, forKey: .subheading) }
        if decodedHeading == nil { decodedHeading = try container.decodeIfPresent(String.self, forKey: .title) }
        if decodedHeading == nil { decodedHeading = try container.decodeIfPresent(String.self, forKey: .pericope) }
        if decodedHeading == nil { decodedHeading = try container.decodeIfPresent(String.self, forKey: .section) }
        if decodedHeading == nil { decodedHeading = try container.decodeIfPresent(String.self, forKey: .section_title) }
        heading = decodedHeading
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(book_id, forKey: .book_id)
        try container.encode(chapter, forKey: .chapter)
        try container.encode(verse, forKey: .verse)
        try container.encode(text, forKey: .text)
        try container.encode(version, forKey: .version)
        // Encode heading under a canonical key
        try container.encodeIfPresent(heading, forKey: .heading)
    }
}

struct BibleBook: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let abbreviation: String
    let testament: String?
    let chapters: Int

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case abbreviation
        case testament
        case chapters
    }
}

// Highlight functionality removed
