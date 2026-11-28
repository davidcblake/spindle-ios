#if DEBUG
import Foundation
import SwiftData
import SwiftUI

/// App Store screenshots, taken by `.github/workflows/screenshots.yml` on a
/// simulator. Debug builds only: no copy anyone installs contains this.
///
/// Launched with `-screenshot today` (or `study`, `journal`, `plans`), the app
/// opens on that screen with an in-memory journal holding sample studies, a
/// thought and a plan, and never touches the real journal or iCloud.
///
/// The sample content is written to the app's own standard: faithful,
/// Christ-centered, and accurate. Verses are quoted exactly, and both talks are
/// on the list of real general conference talks, with their real addresses.
enum Screenshot: String {
    case today, study, journal, plans

    /// The screen asked for on the command line, if any.
    static var requested: Screenshot? {
        UserDefaults.standard.string(forKey: "screenshot").flatMap(Screenshot.init(rawValue:))
    }

    /// A store in memory with the sample journal in it.
    @MainActor
    static func store(for screen: Screenshot) throws -> ModelContainer {
        let container = try ModelContainer(
            for: Schema(SpindleStore.models),
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let now = Date.now

        let profile = Profile()
        profile.firstName = "Emma"
        profile.createdAt = now.addingTimeInterval(-60 * 86_400)
        context.insert(profile)

        let older: [(String, String, String, Double)] = [
            ("Moses 1", "Pearl of Great Price", "For behold, this is my work and my glory—to bring to pass the immortality and eternal life of man.", 6),
            ("John 15", "New Testament", "I am the vine, ye are the branches: He that abideth in me, and I in him, the same bringeth forth much fruit: for without me ye can do nothing.", 3),
        ]
        for (reference, volume, anchor, daysAgo) in older {
            context.insert(JournalEntry(
                reference: reference, volume: volume, anchor: anchor,
                createdAt: now.addingTimeInterval(-daysAgo * 86_400)
            ))
        }

        let alma = JournalEntry(
            reference: "Alma 32",
            volume: "Book of Mormon",
            anchor: almaStudy.anchor,
            createdAt: now.addingTimeInterval(-3_600),
            content: (try? JSONEncoder().encode(almaStudy)) ?? Data()
        )
        context.insert(alma)
        let thought = Thought(
            body: "Alma doesn't ask them to be sure first, only to give place. This week I'll make room each morning before I look at my phone.",
            createdAt: now.addingTimeInterval(-1_800)
        )
        context.insert(thought)
        thought.entry = alma

        let plan = StudyPlan.save(faithPlan, request: "Faith in Jesus Christ across all four standard works", in: context)
        plan.createdAt = now.addingTimeInterval(-2 * 86_400)
        plan.orderedItems.first?.completedAt = now.addingTimeInterval(-3_600)

        try context.save()
        return container
    }

    /// The Alma 32 study, opened as if from the journal.
    struct StudyPage: View {
        @Query(filter: #Predicate<JournalEntry> { $0.reference == "Alma 32" })
        private var entries: [JournalEntry]

        var body: some View {
            NavigationStack {
                if let entry = entries.first {
                    StudyScreen(entry: entry)
                }
            }
        }
    }

    static let almaStudy = Study(
        placement: "Alma 32 comes in the middle of Alma's mission to the Zoramites (Alma 31–35), about 74 B.C. Alma has just watched them pray on the Rameumptom and leave God there for the week; now he turns to the poor who were cast out of their own synagogues.",
        background: "The Zoramites had built synagogues and then barred the poor from them because of their coarse apparel (Alma 32:2–3). Humbled by that rejection, a great multitude came to Alma asking what they should do. He answers with one of the Book of Mormon's great sermons on faith, comparing the word of God to a seed.",
        people: [
            .init(name: "Alma", who: "The high priest and former chief judge who gave up the judgment seat to preach the word (Alma 4:19), here teaching the outcast poor with tenderness.", elsewhere: "His own conversion, recounted to his son in Alma 36, shows why he trusts the word to change a heart."),
            .init(name: "The poor among the Zoramites", who: "Cast out of the synagogues they had built, they were \"in a preparation to hear the word\" (Alma 32:6).", elsewhere: "They echo the poor in spirit whom the Savior blesses in Matthew 5:3 and 3 Nephi 12:3."),
        ],
        principles: [
            .init(principle: "Humility prepares the heart for faith.", explanation: "Alma tells them it is well that they were cast out, because it brought them to lowliness of heart (Alma 32:12–16). Being humbled by circumstance is good; choosing humility is more blessed still.", elsewhere: "Ether 12:27: weakness given that we may be humble, and grace made sufficient."),
            .init(principle: "Faith grows by experiment upon the word.", explanation: "Faith begins with a desire to believe and giving place for the word (Alma 32:27). As it swells and enlarges the soul, we know the seed is good (Alma 32:28–34).", elsewhere: "John 7:17: \"If any man will do his will, he shall know of the doctrine.\""),
        ],
        patterns: [
            .init(pattern: "The seed and the tree", meaning: "A word planted and nourished with patience becomes \"a tree springing up unto everlasting life\" (Alma 32:41).", echoes: "Lehi's tree of life (1 Nephi 8:10–12), the mustard seed (Matthew 13:31–32), and Alma's own echo of the tree in Alma 32:42."),
            .init(pattern: "Nourishing with diligence and patience", meaning: "The tree withers when it is neglected, \"not because the seed was not good\" (Alma 32:38–39).", echoes: "D&C 4:6 and 2 Peter 1:5–8: virtues added to faith, line upon line."),
        ],
        christ: "In the next chapter Alma names the seed: \"believe in the Son of God, that he will come to redeem his people... and plant this word in your hearts\" (Alma 33:22–23). The word planted is faith in Jesus Christ Himself, and the tree that springs up is the everlasting life He gives.",
        conference: [
            .init(speaker: "Elder Jeffrey R. Holland", talk: "Lord, I Believe", session: "April 2013", point: "Elder Holland teaches that when doubts come, we hold fast to what we already know and let our faith, however small, grow from there.", url: "https://www.churchofjesuschrist.org/study/general-conference/2013/04/lord-i-believe?lang=eng"),
            .init(speaker: "President Russell M. Nelson", talk: "Let God Prevail", session: "October 2020", point: "President Nelson invites us to let God be the most important influence in our lives, the willingness Alma calls giving place for the word.", url: "https://www.churchofjesuschrist.org/study/general-conference/2020/10/46nelson?lang=eng"),
        ],
        crossRefs: [
            .init(ref: "Ether 12:6", note: "\"Ye receive no witness until after the trial of your faith.\""),
            .init(ref: "Hebrews 11:1", note: "Faith as \"the substance of things hoped for, the evidence of things not seen.\""),
        ],
        reflection: [
            "Where in my life am I being invited to give place for the word, even a small one?",
            "What has swelled within me lately that tells me a seed is good?",
            "What would nourishing my testimony with patience look like this week?",
        ],
        invitation: "Choose one verse from Alma 32 and plant it: read it each morning this week, and write down any way it begins to swell within you.",
        anchor: "Faith is not to have a perfect knowledge of things; therefore if ye have faith ye hope for things which are not seen, which are true. (Alma 32:21)"
    )

    static let faithPlan = GeneratedPlan(
        title: "Faith in Jesus Christ",
        description: "Faith across all four standard works, from a seed planted to a hope that is sure.",
        items: [
            .init(title: "Alma 32", subtitle: "Faith as a seed planted in the heart", reference: "Alma 32"),
            .init(title: "Ether 12", subtitle: "No witness until after the trial of your faith", reference: "Ether 12"),
            .init(title: "Hebrews 11", subtitle: "The faithful who looked for a better country", reference: "Hebrews 11"),
            .init(title: "Moroni 7", subtitle: "Faith, hope and charity", reference: "Moroni 7"),
            .init(title: "D&C 6", subtitle: "Look unto me in every thought", reference: "D&C 6:36"),
            .init(title: "\"Lord, I Believe\"", subtitle: "Holding fast to what we already know", reference: "Elder Jeffrey R. Holland — \"Lord, I Believe\" (April 2013)", url: "https://www.churchofjesuschrist.org/study/general-conference/2013/04/lord-i-believe?lang=eng"),
        ]
    )
}
#endif
