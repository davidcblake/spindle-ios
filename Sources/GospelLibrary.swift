import Foundation

/// Links from a study into Gospel Library.
///
/// Copied from the web app's `src/lib/links.ts`. churchofjesuschrist.org links
/// open the Gospel Library app when it is installed, so every reference in a
/// study is one tap from the text itself.
///
/// Talks are linked to a search, never to a guessed address: the model
/// misremembers a talk's address often enough that a search which lands beats
/// a link that goes nowhere.
enum GospelLibrary {
    /// A run of text, linked or not.
    struct Segment: Hashable, Sendable {
        var text: String
        var url: URL?
    }

    /// Book names as a study writes them, and where Gospel Library keeps them.
    static let books: [String: (volume: String, slug: String)] = [
        "1 Nephi": ("bofm", "1-ne"), "2 Nephi": ("bofm", "2-ne"), "Jacob": ("bofm", "jacob"),
        "Enos": ("bofm", "enos"), "Jarom": ("bofm", "jarom"), "Omni": ("bofm", "omni"),
        "Words of Mormon": ("bofm", "w-of-m"), "Mosiah": ("bofm", "mosiah"), "Alma": ("bofm", "alma"),
        "Helaman": ("bofm", "hel"), "3 Nephi": ("bofm", "3-ne"), "4 Nephi": ("bofm", "4-ne"),
        "Mormon": ("bofm", "morm"), "Ether": ("bofm", "ether"), "Moroni": ("bofm", "moro"),

        "Genesis": ("ot", "gen"), "Exodus": ("ot", "ex"), "Leviticus": ("ot", "lev"),
        "Numbers": ("ot", "num"), "Deuteronomy": ("ot", "deut"), "Joshua": ("ot", "josh"),
        "Judges": ("ot", "judg"), "Ruth": ("ot", "ruth"), "1 Samuel": ("ot", "1-sam"),
        "2 Samuel": ("ot", "2-sam"), "1 Kings": ("ot", "1-kgs"), "2 Kings": ("ot", "2-kgs"),
        "1 Chronicles": ("ot", "1-chr"), "2 Chronicles": ("ot", "2-chr"), "Ezra": ("ot", "ezra"),
        "Nehemiah": ("ot", "neh"), "Esther": ("ot", "esth"), "Job": ("ot", "job"),
        "Psalm": ("ot", "ps"), "Psalms": ("ot", "ps"), "Proverbs": ("ot", "prov"),
        "Ecclesiastes": ("ot", "eccl"), "Song of Solomon": ("ot", "song"), "Isaiah": ("ot", "isa"),
        "Jeremiah": ("ot", "jer"), "Lamentations": ("ot", "lam"), "Ezekiel": ("ot", "ezek"),
        "Daniel": ("ot", "dan"), "Hosea": ("ot", "hosea"), "Joel": ("ot", "joel"),
        "Amos": ("ot", "amos"), "Obadiah": ("ot", "obad"), "Jonah": ("ot", "jonah"),
        "Micah": ("ot", "micah"), "Nahum": ("ot", "nahum"), "Habakkuk": ("ot", "hab"),
        "Zephaniah": ("ot", "zeph"), "Haggai": ("ot", "hag"), "Zechariah": ("ot", "zech"),
        "Malachi": ("ot", "mal"),

        "Matthew": ("nt", "matt"), "Mark": ("nt", "mark"), "Luke": ("nt", "luke"),
        "John": ("nt", "john"), "Acts": ("nt", "acts"), "Romans": ("nt", "rom"),
        "1 Corinthians": ("nt", "1-cor"), "2 Corinthians": ("nt", "2-cor"), "Galatians": ("nt", "gal"),
        "Ephesians": ("nt", "eph"), "Philippians": ("nt", "philip"), "Colossians": ("nt", "col"),
        "1 Thessalonians": ("nt", "1-thes"), "2 Thessalonians": ("nt", "2-thes"),
        "1 Timothy": ("nt", "1-tim"), "2 Timothy": ("nt", "2-tim"), "Titus": ("nt", "titus"),
        "Philemon": ("nt", "philem"), "Hebrews": ("nt", "heb"), "James": ("nt", "james"),
        "1 Peter": ("nt", "1-pet"), "2 Peter": ("nt", "2-pet"), "1 John": ("nt", "1-jn"),
        "2 John": ("nt", "2-jn"), "3 John": ("nt", "3-jn"), "Jude": ("nt", "jude"),
        "Revelation": ("nt", "rev"),

        "Doctrine and Covenants": ("dc-testament", "dc"), "D&C": ("dc-testament", "dc"),

        "Moses": ("pgp", "moses"), "Abraham": ("pgp", "abr"),
        "Joseph Smith—Matthew": ("pgp", "js-m"), "Joseph Smith—History": ("pgp", "js-h"),
        "Articles of Faith": ("pgp", "a-of-f"),
    ]

    /// "Alma 7:11-12", "D&C 122:8", "3 Nephi 10", "Psalm 23:1". Longest book
    /// names are tried first, so "1 Nephi" is never read as something shorter.
    private static let referencePattern: String = {
        let names = books.keys
            .sorted { $0.count > $1.count }
            .map(NSRegularExpression.escapedPattern(for:))
            .joined(separator: "|")
        return "(\(names))\\s+(\\d{1,3})(?::(\\d{1,3})(?:[-–](\\d{1,3}))?)?"
    }()

    /// A talk as the prompts cite one: Speaker — "Title" (Session). Strict on
    /// purpose — a quoted title and a year — so ordinary prose with a dash and
    /// a "(see …)" is never mistaken for a talk.
    private static let talkPattern = #"^(.+?)\s*[—–]\s*["“”'](.+?)["“”']\s*\(([^)]*\d{4}[^)]*)\)\s*$"#

    static func url(book: String, chapter: String, verse: String? = nil, throughVerse: String? = nil) -> URL? {
        guard let place = books[book] else { return nil }
        var address = "https://www.churchofjesuschrist.org/study/scriptures/\(place.volume)/\(place.slug)/\(chapter)?lang=eng"
        if let verse {
            let id = throughVerse.map { "p\(verse)-p\($0)" } ?? "p\(verse)"
            address += "&id=\(id)#p\(verse)"
        }
        return URL(string: address)
    }

    /// Splits text into plain runs and linked references. Joined back together,
    /// the runs are always the original text.
    static func segments(of text: String) -> [Segment] {
        let expression = try! NSRegularExpression(pattern: referencePattern)
        var segments: [Segment] = []
        var last = text.startIndex
        for match in expression.matches(in: text, range: NSRange(text.startIndex..., in: text)) {
            func group(_ index: Int) -> String? {
                Range(match.range(at: index), in: text).map { String(text[$0]) }
            }
            guard
                let whole = Range(match.range, in: text),
                let book = group(1), let chapter = group(2),
                let link = url(book: book, chapter: chapter, verse: group(3), throughVerse: group(4))
            else { continue }
            if whole.lowerBound > last {
                segments.append(Segment(text: String(text[last..<whole.lowerBound])))
            }
            segments.append(Segment(text: String(text[whole]), url: link))
            last = whole.upperBound
        }
        if last < text.endIndex {
            segments.append(Segment(text: String(text[last...])))
        }
        return segments.isEmpty ? [Segment(text: text)] : segments
    }

    /// A conference-scoped Gospel Library search for a talk.
    static func searchURL(speaker: String, talk: String) -> URL {
        // The same characters JavaScript's encodeURIComponent leaves alone, so
        // the web app and this one produce the same address.
        let unreserved = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.!~*'()")
        let query = "\(talk) \(speaker)".addingPercentEncoding(withAllowedCharacters: unreserved) ?? ""
        return URL(string: "https://www.churchofjesuschrist.org/search?lang=eng&query=\(query)&facet=general-conference")!
    }

    /// Reads a `Speaker — "Title" (Session)` citation, or nil for anything not
    /// shaped like one, such as a scripture reference.
    static func talk(in citation: String) -> (speaker: String, talk: String)? {
        let expression = try! NSRegularExpression(pattern: talkPattern)
        let text = citation.trimmingCharacters(in: .whitespacesAndNewlines)
        guard
            let match = expression.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
            let speakerRange = Range(match.range(at: 1), in: text),
            let talkRange = Range(match.range(at: 2), in: text)
        else { return nil }
        let speaker = text[speakerRange].trimmingCharacters(in: .whitespaces)
        let title = text[talkRange].trimmingCharacters(in: .whitespaces)
        guard !speaker.isEmpty, !title.isEmpty else { return nil }
        return (speaker: speaker, talk: title)
    }

    /// Text ready for SwiftUI's `Text`, with every reference tappable. A whole
    /// string shaped like a talk citation becomes one search link.
    static func linked(_ text: String) -> AttributedString {
        if let citation = talk(in: text) {
            var whole = AttributedString(text)
            whole.link = searchURL(speaker: citation.speaker, talk: citation.talk)
            return whole
        }
        var result = AttributedString()
        for segment in segments(of: text) {
            var run = AttributedString(segment.text)
            run.link = segment.url
            result += run
        }
        return result
    }
}
