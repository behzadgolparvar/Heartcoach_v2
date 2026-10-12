import Foundation
import UserNotifications
import HeartRateCoachCore

/// Schedules local reminders (FR-7). Behind a protocol for testability.
protocol NotificationScheduling: AnyObject {
    func requestAuthorization() async -> Bool
    func replace(_ reminders: [ScheduledReminder]) async
    func cancelAll()
}

/// `UserNotifications`-backed implementation. Local-only (no APNs). Payloads carry
/// no health values (SECURITY-03 / BR-6-7).
final class NotificationService: NotificationScheduling {
    private let center = UNUserNotificationCenter.current()

    func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
    }

    func replace(_ reminders: [ScheduledReminder]) async {
        // Cancel our managed kinds, then re-add — keeps scheduling idempotent (BR-6-5).
        let ids = ReminderKind.allCases.map(\.rawValue)
        center.removePendingNotificationRequests(withIdentifiers: scheduledIdentifiers(ids))
        for (i, r) in reminders.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = r.title
            content.body = r.body               // no health values
            content.sound = .default
            let trigger: UNNotificationTrigger
            if let dc = r.dateComponents {
                trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
            } else if let fire = r.fireDate {
                let interval = max(1, fire.timeIntervalSinceNow)
                trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
            } else {
                trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: false)
            }
            let id = "\(r.kind.rawValue)_\(i)"
            try? await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        }
    }

    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }

    /// Identifier prefixes we manage (each reminder is `<kind>_<index>`).
    private func scheduledIdentifiers(_ kinds: [String]) -> [String] {
        // Over-cancel a reasonable range of indices per kind.
        kinds.flatMap { kind in (0..<14).map { "\(kind)_\($0)" } }
    }
}
