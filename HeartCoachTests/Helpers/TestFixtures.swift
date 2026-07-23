import Foundation
import HeartRateCoachCore

extension UserProfile {
    static var fixture: UserProfile {
        UserProfile(age: 30, restingHR: 60, goal: .fatBurn, preferredWorkout: .continuous)
    }
}

extension Session {
    static var fixture: Session {
        Session(date: Date(), programType: .continuous, durationSec: 2100,
                avgHR: 145, timeInZones: [3: 1200, 4: 600, 2: 300], hrStream: [])
    }
}
