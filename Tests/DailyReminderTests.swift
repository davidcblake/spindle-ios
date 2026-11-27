import Testing
import PPNotify
@testable import Spindle

@Suite("Daily reminder")
struct DailyReminderTests {
    @Test("Greets the person by name, at the time they chose, every day")
    func byName() {
        let profile = Profile()
        profile.firstName = "Dave"
        profile.reminderHour = 6
        profile.reminderMinute = 30
        let reminder = DailyReminder.reminder(for: profile)
        #expect(reminder.id == DailyReminder.id)
        #expect(reminder.title == "Hey Dave.")
        #expect(reminder.body == "What do you want to study today?")
        #expect(reminder.schedule == .everyDay(hour: 6, minute: 30))
        #expect(reminder.schedule.isValid)
    }

    @Test("Without a name, a plain title; the default time is seven in the morning")
    func noName() {
        let reminder = DailyReminder.reminder(for: Profile())
        #expect(reminder.title == "Time to study")
        #expect(reminder.schedule == .everyDay(hour: 7, minute: 0))
    }
}
