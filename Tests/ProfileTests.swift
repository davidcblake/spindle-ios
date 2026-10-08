import Foundation
import Testing
@testable import Spindle

@MainActor
@Suite("Profile and settings")
struct ProfileTests {
    @Test("Every section shows until it is switched off, and comes back")
    func hiding() {
        let profile = Profile()
        #expect(profile.hidden.isEmpty)
        profile.toggle(.conference)
        #expect(profile.hidden == [.conference])
        #expect(profile.hiddenSections == ["conference"])
        profile.toggle(.conference)
        #expect(profile.hidden.isEmpty)
    }

    @Test("A key Spindle no longer knows is ignored, not a crash")
    func unknownKey() {
        let profile = Profile()
        profile.hiddenSections = ["placement", "somethingRetired"]
        #expect(profile.hidden == [.placement])
    }

    @Test("Conference voices default to the First Presidency and Twelve")
    func scope() {
        let profile = Profile()
        #expect(profile.scope == .core)
        profile.scope = .expanded
        #expect(profile.conferenceScope == "expanded")
    }

    @Test("With two profiles, the earliest is the one used")
    func earliest() {
        let first = Profile(createdAt: Date(timeIntervalSince1970: 1))
        let second = Profile(createdAt: Date(timeIntervalSince1970: 2))
        #expect(Profile.current(in: [second, first]) === first)
        #expect(Profile.current(in: []) == nil)
    }
}
