import Foundation
import HeartRateCoachCore

extension UserProfile {
    static var fixture: UserProfile {
        UserProfile(age: 30, restingHR: 60, goal: .fatBurn, preferredWorkout: .continuous)
    }
}

extension UserProfileV2 {
    /// A v5-complete profile (dual experience + program state present).
    static var fixture: UserProfileV2 {
        UserProfileV2(
            age: 30, gender: .preferNotToSay, unitsPreference: .metric, restingHR: 60,
            goals: [.cardioFitness], fitnessExperience: .intermediate,
            mentality: Mentality(motivationDriver: .process, missedResponse: .habit, routinePreference: .fixed),
            q1TrainingHistory: .recentReturnOrUnderYear, q2SelfSelect: .intermediate,
            classificationMismatch: false, program: .newUser(),
            schedule: Schedule(sessionLengthMin: 35, frequencyPerWeek: 3),
            consent: Consent(healthDataConsent: true, remindersConsent: true, consentedAt: nil, consentVersion: "1.0"),
            v2Completed: true
        )
    }

    /// A pre-v5 (Phase-1) profile: no dual-experience answers, no program state.
    /// Should report `isV5Complete == false` and route to re-onboarding.
    static var preV5Fixture: UserProfileV2 {
        UserProfileV2(
            age: 30, gender: .preferNotToSay, unitsPreference: .metric, restingHR: 60,
            goals: [.cardioFitness], fitnessExperience: .intermediate,
            mentality: Mentality(motivationDriver: .process, missedResponse: .habit, routinePreference: .fixed),
            schedule: Schedule(sessionLengthMin: 35, frequencyPerWeek: 3),
            consent: Consent(healthDataConsent: true, remindersConsent: true, consentedAt: nil, consentVersion: "1.0"),
            v2Completed: true
        )
    }
}

extension Session {
    static var fixture: Session {
        Session(date: Date(), programType: .continuous, durationSec: 2100,
                avgHR: 145, timeInZones: [3: 1200, 4: 600, 2: 300], hrStream: [])
    }
}
