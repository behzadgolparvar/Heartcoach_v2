import Foundation
import HeartRateCoachCore

/// Result of attempting to persist a session.
enum SessionSaveOutcome {
    /// Written to the cloud (Firestore) and confirmed.
    case synced
    /// Stored locally in the offline queue; will sync when the write succeeds later.
    case queued
}

protocol FirebaseServiceProtocol: AnyObject {
    func saveProfile(_ profile: UserProfile, zones: HRZones, userID: String) async throws
    func loadProfile(userID: String) async throws -> UserProfile?
    func loadZones(userID: String) async throws -> HRZones?
    func saveSession(_ session: Session, userID: String) async throws -> SessionSaveOutcome
    func loadSessions(userID: String, limit: Int) async throws -> [Session]
    func syncPendingSessions(userID: String) async
}
