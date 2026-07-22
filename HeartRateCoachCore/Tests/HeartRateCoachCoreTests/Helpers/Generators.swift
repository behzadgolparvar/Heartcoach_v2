import SwiftCheck
import Foundation
@testable import HeartRateCoachCore

// MARK: - Age Generators

/// Valid ages: 15–100
let validAgeGen: Gen<Int> = Gen<Int>.choose((15, 100))

/// Invalid ages: negative/zero or above 100
let invalidAgeGen: Gen<Int> = Gen<Int>.one(of: [
    Gen<Int>.choose((-50, 0)),
    Gen<Int>.choose((101, 200))
])

// MARK: - Resting HR Generators

/// Valid RHR in typical range: 40–100
let validRHRGen: Gen<Int> = Gen<Int>.choose((40, 100))

/// RHR outside typical range but still valid for calculation: 1–39 and 101–179
let warningRHRGen: Gen<Int> = Gen<Int>.one(of: [
    Gen<Int>.choose((1, 39)),
    Gen<Int>.choose((101, 179))
])

/// Hard-invalid RHR: zero or negative
let invalidRHRGen: Gen<Int> = Gen<Int>.one(of: [
    Gen.pure(0),
    Gen<Int>.choose((-100, -1))
])

// MARK: - Profile Generators

/// Valid (age, restingHR) pairs guaranteed to produce HRZones without throwing.
let validProfileGen: Gen<(age: Int, restingHR: Int)> = validAgeGen.flatMap { age in
    // Ensure restingHR < HRmax = 220 - age; use typical range for safety
    let maxSafeRHR = min(100, 220 - age - 1)
    let minRHR = min(40, maxSafeRHR)
    return Gen<Int>.choose((minRHR, maxSafeRHR)).map { rhr in
        (age: age, restingHR: rhr)
    }
}

/// Valid (age, restingHR) pairs including the warning range (1–39 and 101+).
let validProfileIncludingWarningGen: Gen<(age: Int, restingHR: Int)> = validAgeGen.flatMap { age in
    let hrMax = 220 - age
    return Gen<Int>.choose((1, hrMax - 1)).map { rhr in
        (age: age, restingHR: rhr)
    }
}

// MARK: - CoachingEngineState Generators

/// Generates a CoachingEngineState with random buffer (0–2 readings), random anti-spam
/// timestamp (nil or 0–60 seconds ago), and random in-zone counter (0–60 seconds).
let coachingEngineStateGen: Gen<CoachingEngineState> = Gen<CoachingEngineState>.compose { c in
    let bufferSize = c.generate(using: Gen<Int>.choose((0, 2)))
    let buffer = (0..<bufferSize).map { _ in c.generate(using: Gen<Int>.choose((60, 200))) }

    let hasTimestamp = c.generate(using: Gen<Bool>.bool)
    let lastLayer2: Date? = hasTimestamp
        ? Date().addingTimeInterval(-Double(c.generate(using: Gen<Int>.choose((0, 60)))))
        : nil

    let inZone = Double(c.generate(using: Gen<Int>.choose((0, 60))))

    return CoachingEngineState(
        hrBuffer: buffer,
        lastLayer2MessageAt: lastLayer2,
        consecutiveInZoneSeconds: inZone
    )
}

// MARK: - WorkoutPhase Generators

/// Generates a WorkoutPhase with random target zone (nil or 1–5) and random grace period flag.
let workoutPhaseGen: Gen<WorkoutPhase> = Gen<WorkoutPhase>.compose { c in
    let index = c.generate(using: Gen<Int>.choose((0, 30)))
    let duration = Double(c.generate(using: Gen<Int>.choose((30, 300))))
    let hasTarget = c.generate(using: Gen<Bool>.bool)
    let targetZone: Int? = hasTarget ? c.generate(using: Gen<Int>.choose((1, 5))) : nil
    let hasGrace = c.generate(using: Gen<Bool>.bool)
    let phaseTypeRaw = c.generate(using: Gen<Int>.choose((0, 3)))
    let phaseType: PhaseType = [.warmup, .exercise, .recovery, .cooldown][phaseTypeRaw]

    return WorkoutPhase(
        index: index,
        duration: duration,
        targetZone: targetZone,
        type: phaseType,
        hasGracePeriod: hasGrace
    )
}

/// Generates a WorkoutPhase that always has a target zone (for Layer 2/3 testing).
let workoutPhaseWithZoneGen: Gen<WorkoutPhase> = Gen<WorkoutPhase>.compose { c in
    let index = c.generate(using: Gen<Int>.choose((0, 30)))
    let duration = Double(c.generate(using: Gen<Int>.choose((60, 300))))
    let targetZone = c.generate(using: Gen<Int>.choose((1, 5)))

    return WorkoutPhase(
        index: index,
        duration: duration,
        targetZone: targetZone,
        type: .exercise,
        hasGracePeriod: false
    )
}
