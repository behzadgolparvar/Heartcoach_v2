import Foundation
import HeartRateCoachCore

protocol FirebaseServiceProtocol: AnyObject {
    func saveProfile(_ profile: UserProfile, zones: HRZones, userID: String) async throws
    func loadProfile(userID: String) async throws -> UserProfile?
    func loadZones(userID: String) async throws -> HRZones?
    func saveSession(_ session: Session, userID: String) async throws
    func loadSessions(userID: String, limit: Int) async throws -> [Session]
    func syncPendingSessions(userID: String) async
}
