import XCTest
@testable import HeartRateCoachCore

/// Minimal property-check harness replacing SwiftCheck (v0.12 is unmaintained and
/// no longer type-checks on the current Swift toolchain). Runs `body` over `count`
/// seeded-random inputs and fails on the first counterexample — deterministic
/// because it uses the project's own `SeededGenerator`.
func pbtAssert<T>(_ description: String,
                  count: Int = 200,
                  seed: UInt64 = 0xC0FFEE,
                  gen: (inout SeededGenerator) -> T,
                  body: (T) -> Bool,
                  file: StaticString = #filePath,
                  line: UInt = #line) {
    var rng = SeededGenerator(seed: seed)
    for i in 0..<count {
        let input = gen(&rng)
        if !body(input) {
            XCTFail("\(description) — counterexample on iteration \(i): \(input)", file: file, line: line)
            return
        }
    }
}

// MARK: - Generators (replace the former SwiftCheck Gen values)

/// Valid (age, restingHR) pairs guaranteed to produce HRZones without throwing.
func genValidProfile(_ rng: inout SeededGenerator) -> (age: Int, restingHR: Int) {
    let age = Int.random(in: 15...100, using: &rng)
    let maxSafeRHR = min(100, 220 - age - 1)
    let minRHR = min(40, maxSafeRHR)
    let rhr = Int.random(in: minRHR...maxSafeRHR, using: &rng)
    return (age: age, restingHR: rhr)
}

/// CoachingEngineState with random buffer (0–2 readings), random anti-spam timestamp
/// (nil or 0–60s ago), and random in-zone counter (0–60s).
func genCoachingEngineState(_ rng: inout SeededGenerator) -> CoachingEngineState {
    let bufferSize = Int.random(in: 0...2, using: &rng)
    let buffer = (0..<bufferSize).map { _ in Int.random(in: 60...200, using: &rng) }
    let hasTimestamp = Bool.random(using: &rng)
    let lastLayer2: Date? = hasTimestamp
        ? Date().addingTimeInterval(-Double(Int.random(in: 0...60, using: &rng)))
        : nil
    let inZone = Double(Int.random(in: 0...60, using: &rng))
    return CoachingEngineState(hrBuffer: buffer, lastLayer2MessageAt: lastLayer2,
                               consecutiveInZoneSeconds: inZone)
}

/// WorkoutPhase with random target zone (nil or 1–5) and random grace flag.
func genWorkoutPhase(_ rng: inout SeededGenerator) -> WorkoutPhase {
    let index = Int.random(in: 0...30, using: &rng)
    let duration = Double(Int.random(in: 30...300, using: &rng))
    let hasTarget = Bool.random(using: &rng)
    let targetZone: Int? = hasTarget ? Int.random(in: 1...5, using: &rng) : nil
    let hasGrace = Bool.random(using: &rng)
    let phaseType: PhaseType = [.warmup, .exercise, .recovery, .cooldown][Int.random(in: 0...3, using: &rng)]
    return WorkoutPhase(index: index, duration: duration, targetZone: targetZone,
                        type: phaseType, hasGracePeriod: hasGrace)
}

/// WorkoutPhase that always has a target zone (for Layer 2/3 testing).
func genWorkoutPhaseWithZone(_ rng: inout SeededGenerator) -> WorkoutPhase {
    let index = Int.random(in: 0...30, using: &rng)
    let duration = Double(Int.random(in: 60...300, using: &rng))
    let targetZone = Int.random(in: 1...5, using: &rng)
    return WorkoutPhase(index: index, duration: duration, targetZone: targetZone,
                        type: .exercise, hasGracePeriod: false)
}
