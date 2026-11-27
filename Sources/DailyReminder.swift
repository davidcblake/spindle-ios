import Foundation
import PPNotify
import UserNotifications

/// The daily nudge to study, at a time the person picks in Settings.
///
/// One repeating reminder (`ReminderSchedule.everyDay`), so it costs one of
/// the 64 notifications iOS lets an app keep waiting. It is scheduled on the
/// phone and nothing about it reaches Spindle's server.
enum DailyReminder {
    static let id = "daily-study"

    /// The reminder for this person: their name, as Today greets them.
    static func reminder(for profile: Profile) -> Reminder {
        let name = profile.firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        return Reminder(
            id: id,
            title: name.isEmpty ? "Time to study" : "Hey \(name).",
            body: "What do you want to study today?",
            schedule: .everyDay(hour: profile.reminderHour, minute: profile.reminderMinute)
        )
    }
}

/// `PPNotify`'s `Reminders` seam, on the phone's own notifications.
///
/// The foundation ships the seam and its fakes, not this, so Spindle has its
/// own, as it does for speech (`OnDeviceTranscriber`). Permission is asked the
/// first time a reminder is turned on, never at launch.
struct NotificationReminders: Reminders {
    func pending() async -> [Reminder] {
        await UNUserNotificationCenter.current().pendingNotificationRequests().compactMap { request in
            guard let trigger = request.trigger as? UNCalendarNotificationTrigger, trigger.repeats,
                  let hour = trigger.dateComponents.hour else { return nil }
            return Reminder(
                id: request.identifier,
                title: request.content.title,
                body: request.content.body.isEmpty ? nil : request.content.body,
                schedule: .everyDay(hour: hour, minute: trigger.dateComponents.minute ?? 0)
            )
        }
        .sorted { $0.id < $1.id }
    }

    func schedule(_ reminder: Reminder) async throws {
        guard reminder.schedule.isValid else { throw NotifyFailure.impossibleTime }
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            let allowed = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
            guard allowed else { throw Self.notAllowed }
        case .denied:
            throw Self.notAllowed
        default:
            break
        }

        let content = UNMutableNotificationContent()
        content.title = reminder.title
        if let body = reminder.body { content.body = body }
        content.sound = .default

        let trigger: UNNotificationTrigger
        switch reminder.schedule {
        case .everyDay(let hour, let minute):
            trigger = UNCalendarNotificationTrigger(dateMatching: DateComponents(hour: hour, minute: minute), repeats: true)
        case .once(let date):
            let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
            trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
        }
        do {
            try await center.add(UNNotificationRequest(identifier: reminder.id, content: content, trigger: trigger))
        } catch {
            throw NotifyFailure(
                userMessage: "The reminder couldn't be set. Try again in a moment.",
                logMessage: "UNUserNotificationCenter.add failed: \(error)"
            )
        }
    }

    func cancel(id: String) async {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }

    func cancelAll() async {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    private static let notAllowed = NotifyFailure(
        userMessage: "Notifications are off for Spindle. You can turn them on in Settings › Notifications › Spindle.",
        logMessage: "Notification permission not granted."
    )
}
