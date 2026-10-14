import XCTest
import HeartRateCoachCore

/// BR-1b-1/2/3. PBT (partial): exhaustive over all
/// (TrainingHistory × FitnessExperience × Ozempic) = 4 × 3 × 2 = 24 combinations.
final class ExperienceResolverTests: XCTestCase {

    func test_exhaustive_allCombinations() {
        for q1 in TrainingHistory.allCases {
            for q2 in FitnessExperience.allCases {
                for ozempic in [false, true] {
                    let r = ExperienceResolver.resolve(q1: q1, q2: q2, onGLP1: ozempic)
                    let q1Tier = q1.mappedTier

                    // Expected matrix result (BR-1b-2).
                    let expectedMatrix: FitnessExperience
                    let expectedMismatch: Bool
                    switch (q1Tier, q2) {
                    case (.beginner, .advanced), (.advanced, .beginner):
                        expectedMatrix = .intermediate; expectedMismatch = true
                    default:
                        expectedMatrix = q1Tier; expectedMismatch = false
                    }

                    // BR-1b-3: Ozempic forces beginner, but mismatch is matrix-only.
                    let expectedResolved: FitnessExperience = ozempic ? .beginner : expectedMatrix
                    XCTAssertEqual(r.resolved, expectedResolved,
                                   "q1=\(q1) q2=\(q2) ozempic=\(ozempic)")
                    XCTAssertEqual(r.mismatch, expectedMismatch,
                                   "mismatch q1=\(q1) q2=\(q2) ozempic=\(ozempic)")
                }
            }
        }
    }

    func test_extremeDisagreement_resolvesIntermediateWithMismatch() {
        // Q1 says never trained (beginner), Q2 self-rates advanced.
        let a = ExperienceResolver.resolve(q1: .neverTrained, q2: .advanced, onGLP1: false)
        XCTAssertEqual(a.resolved, .intermediate)
        XCTAssertTrue(a.mismatch)
        // Q1 says 1+ yr consistent (advanced), Q2 self-rates beginner.
        let b = ExperienceResolver.resolve(q1: .overYearConsistent, q2: .beginner, onGLP1: false)
        XCTAssertEqual(b.resolved, .intermediate)
        XCTAssertTrue(b.mismatch)
    }

    func test_q1Wins_onNonExtremeDisagreement() {
        // beginner vs intermediate → Q1 wins, no mismatch.
        let r = ExperienceResolver.resolve(q1: .neverTrained, q2: .intermediate, onGLP1: false)
        XCTAssertEqual(r.resolved, .beginner)
        XCTAssertFalse(r.mismatch)
    }

    func test_ozempic_preservesMismatchFlag() {
        // Extreme disagreement + Ozempic: resolved forced to beginner, mismatch still true.
        let r = ExperienceResolver.resolve(q1: .overYearConsistent, q2: .beginner, onGLP1: true)
        XCTAssertEqual(r.resolved, .beginner)
        XCTAssertTrue(r.mismatch)
    }

    func test_trainingHistoryMapping() {
        XCTAssertEqual(TrainingHistory.neverTrained.mappedTier, .beginner)
        XCTAssertEqual(TrainingHistory.stoppedOverYear.mappedTier, .beginner)
        XCTAssertEqual(TrainingHistory.recentReturnOrUnderYear.mappedTier, .intermediate)
        XCTAssertEqual(TrainingHistory.overYearConsistent.mappedTier, .advanced)
    }
}
