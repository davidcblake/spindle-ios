import Testing
@testable import Spindle

@Suite("Speaking a thought")
struct SpokenThoughtTests {
    @Test("Spoken words go after what was typed, with one space between")
    func afterTyping() {
        #expect(SpokenThought.joined("Faith is a seed.", "It has to be planted.") == "Faith is a seed. It has to be planted.")
        #expect(SpokenThought.joined("Faith is a seed. ", "It grows.") == "Faith is a seed. It grows.")
        #expect(SpokenThought.joined("First line\n", "Second line") == "First line\nSecond line")
    }

    @Test("Nothing typed: just the spoken words")
    func nothingTyped() {
        #expect(SpokenThought.joined("", "  Nourish it with patience. ") == "Nourish it with patience.")
    }

    @Test("Nothing heard yet: the typed words are left exactly as they were")
    func nothingHeard() {
        #expect(SpokenThought.joined("Already typed ", "") == "Already typed ")
        #expect(SpokenThought.joined("Already typed", "   ") == "Already typed")
    }
}
