import Foundation
import HeartRateCoachCore
@testable import HeartCoach

final class MockFirebaseService: FirebaseServiceProtocol {
    var savedProfiles: [(UserProfile, HRZones, String)] = []
    var profileToReturn: UserProfile? = nil
    var zonesToReturn: HRZones? = nil
    var sessionsToReturn: [Session] = []
    var shouldThrow: AppError? = nil
    var syncCalled = false
    var savedSessions: [Session] = []
    var saveOutcome: SessionSaveOutcome = .synced

    func saveProfile(_ profile: UserProfile, zones: HRZones, userID: String) async throws {
        if let error = shouldThrow { throw error }
        savedProfiles.append((profile, zones, userID))
    }

    func loadProfile(userID: String) async throws -> UserProfile? {
        if let error = shouldThrow { throw error }
        return profileToReturn
    }

    func loadZones(userID: String) async throws -> HRZones? {
        if let error = shouldThrow { throw error }
        return zonesToReturn
    }

    func saveSession(_ session: Session, userID: String) async throws -> SessionSaveOutcome {
        if let error = shouldThrow { throw error }
        savedSessions.append(session)
        return saveOutcome
    }

    func loadSessions(userID: String, limit: Int) async throws -> [Session] {
        if let error = shouldThrow { throw error }
        return Array(sessionsToReturn.prefix(limit))
    }

    func syncPendingSessions(userID: String) async {
        syncCalled = true
    }
}
