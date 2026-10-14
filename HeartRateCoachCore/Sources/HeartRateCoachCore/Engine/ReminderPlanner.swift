import Foundation

/// Kinds of local reminder (FR-7 + deferred, Q4).
public enum ReminderKind: String, Sendable, CaseIterable {
    case sessionDue, milestoneDue, weightReminder, relapseNudge
}

/// A planned local notification. Text carries NO health values (SECURITY-03, BR-6-7).
public struct ScheduledReminder: Sendable, Equatable {
    public let kind: ReminderKind
    public let title: String
    public let body: String
    /// Calendar components for repeating triggers (session/milestone); nil → one-shot `fireDate`.
    public let dateComponents: DateComponents?
    public let fireDate: Date?

    public init(kind: ReminderKind, title: String, body: String,
                dateComponents: DateComponents? = nil, fireDate: Date? = nil) {
        self.kind = kind; self.title = title; self.body = body
        self.dateComponents = dateComponents; self.fireDate = fireDate
    }
}

/// Plans the local reminders from the user's schedule + state (BR-6-4). Pure.
public enum ReminderPlanner {

    /// - Parameters:
    ///   - todaySessionLabel: e.g. "Continuous" / "HIIT" (type only — no health data).
    ///   - sessionDurationMin: approximate duration for the session reminder body.
    public static func plan(schedule: Schedule,
                            todaySessionLabel: String,
                            sessionDurationMin: Int,
                            milestoneDue: Bool,
                            weightOverdueDays: Int,
                            morningHour: Int = 8) -> [ScheduledReminder] {
        var out: [ScheduledReminder] = []

        // Session reminders on preferred days at preferred time (repeating).
        if let tod = schedule.preferredTimeOfDay {
            let hour = preferredHour(tod)
            let days = schedule.preferredDays.isEmpty ? Set(Weekday.allCases) : schedule.preferredDays
            for day in days {
                var dc = DateComponents()
                dc.weekday = weekdayNumber(day); dc.hour = hour
                out.append(ScheduledReminder(
                    kind: .sessionDue,
                    title: "Time to train",
                    body: "Today: \(todaySessionLabel) · about \(sessionDurationMin) min",
                    dateComponents: dc))
            }
        }

        // Milestone-due morning nudge.
        if milestoneDue {
            var dc = DateComponents(); dc.hour = morningHour
            out.append(ScheduledReminder(kind: .milestoneDue,
                title: "Biweekly check-in",
                body: "Log your weight this morning to track your progress.",
                dateComponents: dc))
        }

        // Weight Day-1 reminder.
        if weightOverdueDays == 1 {
            out.append(ScheduledReminder(kind: .weightReminder,
                title: "Quick reminder",
                body: "Don't forget to log your weight for this check-in.",
                fireDate: nil))
        }

        return out
    }

    /// A relapse/minimum nudge (scheduled when a gap is detected; P3 deferral).
    public static func relapseNudge() -> ScheduledReminder {
        ScheduledReminder(kind: .relapseNudge,
            title: "Keep your momentum",
            body: "Not feeling it? A 15-minute minimum walk keeps your streak alive.")
    }

    private static func preferredHour(_ t: TimeOfDay) -> Int {
        switch t { case .morning: return 8; case .afternoon: return 13; case .evening: return 18 }
    }
    private static func weekdayNumber(_ d: Weekday) -> Int {
        // Calendar weekday: Sunday = 1 … Saturday = 7.
        switch d { case .sun: return 1; case .mon: return 2; case .tue: return 3
        case .wed: return 4; case .thu: return 5; case .fri: return 6; case .sat: return 7 }
    }
}
