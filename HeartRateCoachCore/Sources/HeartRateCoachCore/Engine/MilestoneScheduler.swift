import Foundation

/// Biweekly milestone cadence + weight-entry gating (§H, Q1/Q3). Pure; `now` injected.
public enum MilestoneScheduler {
    public static let intervalDays = 14

    /// A milestone is due 14 days after the last one, or if never logged (BR-6-1).
    public static func isDue(lastMilestoneDate last: Date?, now: Date) -> Bool {
        guard let last else { return true }
        return daysBetween(last, now) >= intervalDays
    }

    /// The due date = last + 14 days (or `now` if never logged).
    public static func dueDate(lastMilestoneDate last: Date?, now: Date) -> Date {
        guard let last else { return now }
        return last.addingTimeInterval(TimeInterval(intervalDays) * 86_400)
    }

    /// Whole days the weight entry is overdue past the due date (0 if not due yet).
    public static func weightOverdueDays(lastMilestoneDate last: Date?, now: Date) -> Int {
        let due = dueDate(lastMilestoneDate: last, now: now)
        guard now >= due else { return 0 }
        return daysBetween(due, now)
    }

    /// BR-6-3 — Day 0: ok · Day 1: remind · Day ≥2: block workout start.
    public static func weightGate(lastMilestoneDate last: Date?, now: Date) -> WeightGateState {
        switch weightOverdueDays(lastMilestoneDate: last, now: now) {
        case 0: return .ok
        case 1: return .remind
        default: return .blockWorkout
        }
    }

    private static func daysBetween(_ a: Date, _ b: Date) -> Int {
        Int(b.timeIntervalSince(a) / 86_400)
    }
}
