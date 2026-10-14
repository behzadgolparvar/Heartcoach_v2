import Foundation
import HeartRateCoachCore

@Observable
final class HomeViewModel {

    var profile: UserProfileV2?
    var zones: HRZones?
    var lastSession: Session?
    var isLoading = false
    var isHealthKitAuthorized = false

    /// Today's assigned session (Phase 3). nil until the profile loads.
    var assignment: SessionAssignment?
    /// Positive re-entry message after a relapse push-back (§C), shown once.
    var relapseMessage: String?

    /// Biweekly milestone is due (§H) — surface the check-in prompt.
    var isMilestoneDue = false
    /// Weight-entry gate state (§H, Q3) — `.blockWorkout` blocks starting a workout.
    var weightGate: WeightGateState = .ok

    private let firebaseService: FirebaseServiceProtocol
    private let healthKitService: HealthKitServiceProtocol
    private let notificationService: NotificationScheduling?

    init(firebaseService: FirebaseServiceProtocol, healthKitService: HealthKitServiceProtocol,
         notificationService: NotificationScheduling? = nil) {
        self.firebaseService = firebaseService
        self.healthKitService = healthKitService
        self.notificationService = notificationService
    }

    /// True when a workout cannot start until the overdue weight is logged (BR-6-3).
    var isWorkoutBlockedForWeight: Bool { weightGate == .blockWorkout }

    func loadData(userID: String) {
        isLoading = true
        recheckHealthKitStatus()
        Task {
            async let profileTask = firebaseService.loadProfileV2(userID: userID)
            async let sessionsTask = firebaseService.loadSessions(userID: userID, limit: 1)

            var p = try? await profileTask
            let sessions = (try? await sessionsTask) ?? []

            // Apply relapse push-back on open (§C), once per gap; persist if changed.
            var relapseMsg: String?
            if var profile = p, let program = profile.program {
                let (updated, outcome) = ProgressionEngine.applyRelapse(program: program, now: Date())
                if outcome.band != .none {
                    profile.program = updated
                    p = profile
                    try? await self.firebaseService.saveProfileV2(profile, userID: userID)
                    relapseMsg = Self.relapseMessage(outcome)
                }
            }
            let assignment = p.map { ProgressionEngine.assign(profile: $0) }
            let z = p.flatMap { try? $0.computeZones() }

            // Milestone cadence + weight gate (§H).
            let now = Date()
            let last = p?.milestones?.lastMilestoneDate
            let due = MilestoneScheduler.isDue(lastMilestoneDate: last, now: now)
            let gate = MilestoneScheduler.weightGate(lastMilestoneDate: last, now: now)

            // Schedule local reminders (FR-7) from the profile.
            if let profile = p, let assignment {
                let reminders = ReminderPlanner.plan(
                    schedule: profile.schedule,
                    todaySessionLabel: assignment.type.displayName,
                    sessionDurationMin: 37,
                    milestoneDue: due,
                    weightOverdueDays: MilestoneScheduler.weightOverdueDays(lastMilestoneDate: last, now: now))
                await notificationService?.replace(reminders)
            }

            // Bind to immutable values before crossing the actor hop (Swift 6 concurrency).
            let finalProfile = p
            let finalRelapseMsg = relapseMsg
            await MainActor.run {
                self.profile = finalProfile
                self.zones = z
                self.lastSession = sessions.first
                self.assignment = assignment
                self.relapseMessage = finalRelapseMsg
                self.isMilestoneDue = due
                self.weightGate = gate
                self.isLoading = false
            }
        }
    }

    /// Logs a biweekly milestone: manual weight + auto RHR (nil-tolerant) (§H, BR-6-2).
    func logMilestone(weightKg: Double?, userID: String) {
        guard let base = profile else { return }
        Task {
            let rhr = await healthKitService.fetchRestingHeartRate()
            var state = base.milestones ?? MilestoneState()
            let now = Date()
            state.history.append(Milestone(date: now, restingHR: rhr, weightKg: weightKg))
            state.lastMilestoneDate = now
            var updated = base
            updated.milestones = state
            let finalProfile = updated   // immutable across the actor hop
            await MainActor.run {
                self.profile = finalProfile
                self.isMilestoneDue = false
                self.weightGate = .ok
            }
            try? await firebaseService.saveProfileV2(finalProfile, userID: userID)
        }
    }

    /// Records the non-negotiable 15-min minimum: resets the relapse clock,
    /// does not advance progression (§I, BR-3-9).
    func recordMinimumWalk(userID: String) {
        guard var profile = profile, let program = profile.program else { return }
        let updated = ProgressionEngine.registerMinimumWalk(program: program, now: Date())
        profile.program = updated
        self.profile = profile
        Task { try? await firebaseService.saveProfileV2(profile, userID: userID) }
    }

    /// Injured leg joints implied by onboarding (`jointIssues`) — pre-fills the Level Up unlock.
    var prefilledInjuredJoints: Set<LegJoint> {
        LegJoint.injured(from: profile?.healthHistory?.jointIssues ?? [])
    }

    /// Completes the Level Up unlock (§E) and advances Foundation → Level Up (BR-4-15).
    func completeLevelUpUnlock(injuredJoints: Set<LegJoint>, comfortable: Bool,
                               approvedExerciseIDs: Set<String>?, userID: String) {
        guard var profile = profile, var program = profile.program else { return }
        profile.levelUpUnlock = LevelUpUnlock(
            injuredJoints: injuredJoints, comfortableWithBodyweight: comfortable,
            approvedExerciseIDs: comfortable ? nil : approvedExerciseIDs, unlockedAt: Date())
        program.currentStage = .levelUp
        program.stageProgress[.levelUp] = StageProgress(stage: .levelUp, sessionsCompleted: 0)
        profile.program = program
        self.profile = profile
        self.assignment = ProgressionEngine.assign(profile: profile)
        Task { try? await firebaseService.saveProfileV2(profile, userID: userID) }
    }

    /// Completes the Shape unlock (§E) and advances Level Up → Shape (BR-5-15).
    func completeShapeUnlock(equipmentPreference: ShapeOption, focusAreas: Set<MuscleGroup>,
                             acknowledgedPain: Bool, userID: String) {
        guard var profile = profile, var program = profile.program else { return }
        profile.shapeUnlock = ShapeUnlock(equipmentPreference: equipmentPreference, focusAreas: focusAreas,
                                          acknowledgedLevelUpPain: acknowledgedPain, unlockedAt: Date())
        program.currentStage = .shape
        program.stageProgress[.shape] = StageProgress(stage: .shape, sessionsCompleted: 0)
        profile.program = program
        self.profile = profile
        self.assignment = ProgressionEngine.assign(profile: profile)
        Task { try? await firebaseService.saveProfileV2(profile, userID: userID) }
    }

    private static func relapseMessage(_ o: RelapseOutcome) -> String {
        switch o.band {
        case .resetToStart:
            return "Welcome back! We've reset your Foundation to the start so you can rebuild safely."
        case .none:
            return ""
        default:
            return "Welcome back! We've eased you back a few sessions so you return strong."
        }
    }

    func recheckHealthKitStatus() {
        isHealthKitAuthorized = healthKitService.isAuthorized
    }

    func requestHealthKitAccess() {
        Task {
            try? await healthKitService.requestAuthorization()
            await MainActor.run {
                isHealthKitAuthorized = healthKitService.isAuthorized
            }
        }
    }
}
