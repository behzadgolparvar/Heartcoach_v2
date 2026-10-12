import XCTest
import HeartRateCoachCore

/// BR-6-1..13 — milestones, weight gate, reminders, CSV, session plan.
final class EngagementTests: XCTestCase {

    private func daysAgo(_ d: Int) -> Date { Date().addingTimeInterval(-Double(d) * 86_400) }

    // MARK: - Milestone cadence / gate (Q1/Q3)

    func test_milestoneDue_boundaries() {
        XCTAssertTrue(MilestoneScheduler.isDue(lastMilestoneDate: nil, now: Date()))        // never logged
        XCTAssertFalse(MilestoneScheduler.isDue(lastMilestoneDate: daysAgo(13), now: Date()))
        XCTAssertTrue(MilestoneScheduler.isDue(lastMilestoneDate: daysAgo(14), now: Date()))
    }

    func test_weightGate_transitions() {
        XCTAssertEqual(MilestoneScheduler.weightGate(lastMilestoneDate: daysAgo(13), now: Date()), .ok)   // not due
        XCTAssertEqual(MilestoneScheduler.weightGate(lastMilestoneDate: daysAgo(15), now: Date()), .remind)       // 1 day overdue
        XCTAssertEqual(MilestoneScheduler.weightGate(lastMilestoneDate: daysAgo(16), now: Date()), .blockWorkout) // 2 days overdue
    }

    // MARK: - Reminders (Q4) — no health values in text (BR-6-7)

    func test_reminderPlanner_setAndNoHealthValues() {
        let schedule = Schedule(sessionLengthMin: 35, frequencyPerWeek: 3,
                                preferredDays: [.mon, .wed], preferredTimeOfDay: .morning)
        let reminders = ReminderPlanner.plan(schedule: schedule, todaySessionLabel: "HIIT",
                                             sessionDurationMin: 37, milestoneDue: true, weightOverdueDays: 1)
        XCTAssertTrue(reminders.contains { $0.kind == .sessionDue })
        XCTAssertTrue(reminders.contains { $0.kind == .milestoneDue })
        XCTAssertTrue(reminders.contains { $0.kind == .weightReminder })
        // No HR/score/weight numbers in any body.
        for r in reminders {
            XCTAssertFalse(r.body.contains("bpm"))
            XCTAssertFalse(r.body.lowercased().contains("zone"))
        }
    }

    // MARK: - CSV (Q6)

    func test_sessionCSV_headerAndRows() {
        let records = [
            HRRecord(timestamp: Date(), second: 0, hr: 120, currentZone: 2, targetZone: 2, phase: .warmup, phaseKind: .warmup),
            HRRecord(timestamp: Date(), second: 5, hr: 150, currentZone: 3, targetZone: 3, phase: .exercise, phaseKind: .block, coachingMessage: "Ease back"),
        ]
        let session = Session(date: Date(), programType: .hiit, durationSec: 2100, avgHR: 135,
                              timeInZones: [:], hrStream: records, scorePercent: 82, scoreTier: .great,
                              trainingDurationSec: 1200, sessionFlag: "hiit")
        let csv = SessionCSV.rows(for: session)
        XCTAssertTrue(csv.contains("time_sec,hr,current_zone,phase,target_zone,phrase_type,phrase_time"))
        XCTAssertTrue(csv.contains("# score_tier,great"))
        XCTAssertTrue(csv.contains("0,120,2,warmup,2,,"))        // no cue
        XCTAssertTrue(csv.contains("5,150,3,block,3,cue,5"))     // cue fired at second 5
    }

    // MARK: - Session plan (Q9)

    func test_sessionPlan_60rows_typesMatchSchedule() {
        var profile = UserProfileV2.fixture   // intermediate, cardioFitness
        profile = UserProfileV2(
            age: 30, gender: .preferNotToSay, unitsPreference: .metric, restingHR: 60,
            goals: [.fastWeightLoss], fitnessExperience: .beginner,
            mentality: Mentality(motivationDriver: .outcome, missedResponse: .goal, routinePreference: .variety),
            program: .newUser(),
            schedule: Schedule(sessionLengthMin: 35, frequencyPerWeek: 5),
            consent: Consent(healthDataConsent: true, remindersConsent: true, consentedAt: nil, consentVersion: "1.0"),
            v2Completed: true)
        let rows = SessionPlanBuilder.plan(stage: .foundation, profile: profile)
        XCTAssertEqual(rows.count, 60)
        XCTAssertEqual(rows.first?.sessionNumber, 1)
        // Beginner-FWL/outcome SubPhase1 = 1:2 → session 1 is HIIT (front-loaded).
        XCTAssertEqual(rows[0].type, .hiit)
        XCTAssertEqual(rows[1].type, .continuous)
    }

    func test_projectedCompletionNote_frequency() {
        XCTAssertTrue(SessionPlanBuilder.projectedCompletionNote(frequencyPerWeek: 5, stage: .foundation).contains("3 months"))
        XCTAssertTrue(SessionPlanBuilder.projectedCompletionNote(frequencyPerWeek: 3, stage: .foundation).contains("4.5"))
    }

    // MARK: - Persistence

    func test_milestoneState_codableRoundTrip() throws {
        var profile = UserProfileV2.fixture
        profile.milestones = MilestoneState(lastMilestoneDate: Date(timeIntervalSince1970: 100),
            history: [Milestone(date: Date(timeIntervalSince1970: 100), restingHR: 58, weightKg: 80)])
        let data = try JSONEncoder().encode(profile)
        let decoded = try JSONDecoder().decode(UserProfileV2.self, from: data)
        XCTAssertEqual(decoded.milestones?.history.first?.restingHR, 58)
        XCTAssertEqual(decoded.milestones?.history.first?.weightKg, 80)
    }
}
