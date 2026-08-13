import Foundation
import FirebaseAuth
import FirebaseFirestore
import HeartRateCoachCore

final class FirestoreService: FirebaseServiceProtocol {

    private let db = Firestore.firestore()
    private let networkMonitor: NetworkMonitor
    private let offlineQueue: OfflineSessionQueueProtocol

    init(networkMonitor: NetworkMonitor, offlineQueue: OfflineSessionQueueProtocol) {
        self.networkMonitor = networkMonitor
        self.offlineQueue = offlineQueue
        startSyncObserver()
    }

    // MARK: - Path Helpers

    private func userDoc(_ userID: String) -> DocumentReference {
        db.collection("users").document(userID)
    }

    private func sessionsCollection(_ userID: String) -> CollectionReference {
        userDoc(userID).collection("sessions")
    }

    // MARK: - Profile

    func saveProfile(_ profile: UserProfile, zones: HRZones, userID: String) async throws {
        let data: [String: Any] = [
            "profile": encodeProfile(profile),
            "zones": encodeZones(zones),
            "updatedAt": FieldValue.serverTimestamp()
        ]
        do {
            try await userDoc(userID).setData(data, merge: true)
        } catch {
            throw mapError(error)
        }
    }

    func loadProfile(userID: String) async throws -> UserProfile? {
        do {
            let snapshot = try await userDoc(userID).getDocument()
            guard snapshot.exists, let data = snapshot.data()?["profile"] as? [String: Any] else {
                return nil
            }
            return decodeProfile(data)
        } catch {
            throw mapError(error)
        }
    }

    func loadZones(userID: String) async throws -> HRZones? {
        do {
            let snapshot = try await userDoc(userID).getDocument()
            guard snapshot.exists, let data = snapshot.data()?["zones"] as? [String: Any] else {
                return nil
            }
            return decodeZones(data)
        } catch {
            throw mapError(error)
        }
    }

    // MARK: - Sessions

    func saveSession(_ session: Session, userID: String) async throws -> SessionSaveOutcome {
        let data = try encodeSession(session)
        do {
            // Always attempt the cloud write, bounded by a timeout so an offline /
            // stalled connection can't hang the UI on "Saving…". A satisfied network
            // path is no guarantee the write reaches the server (captive portals,
            // token refresh, transient Firestore errors), so we rely on the actual
            // write result rather than a cached connectivity flag.
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    try await self.sessionsCollection(userID).document(session.id).setData(data)
                }
                group.addTask {
                    try await Task.sleep(nanoseconds: 8_000_000_000)
                    throw AppError.networkUnavailable
                }
                try await group.next()
                group.cancelAll()
            }
            return .synced
        } catch {
            // Write failed or timed out — hold it locally and sync later.
            // Log only the error (never any health data — SECURITY-03).
            #if DEBUG
            print("[Sessions] Cloud write failed, queued offline: \(error.localizedDescription)")
            #endif
            try offlineQueue.enqueue(session)
            return .queued
        }
    }

    func loadSessions(userID: String, limit: Int = 1) async throws -> [Session] {
        do {
            let snapshot = try await sessionsCollection(userID)
                .order(by: "date", descending: true)
                .limit(to: limit)
                .getDocuments()
            return snapshot.documents.compactMap { decodeSession($0.data()) }
        } catch {
            throw mapError(error)
        }
    }

    // MARK: - Offline Sync

    func syncPendingSessions(userID: String) async {
        guard let pending = try? offlineQueue.pendingSessions() else { return }
        for session in pending {
            guard let data = try? encodeSession(session) else { continue }
            do {
                try await sessionsCollection(userID).document(session.id).setData(data)
                try? offlineQueue.markSynced(id: session.id)
            } catch {
                // Leave in queue — retry on next reconnect
            }
        }
    }

    private func startSyncObserver() {
        Task {
            for await isConnected in networkMonitor.isConnectedStream {
                if isConnected, let userID = Auth.currentUserID {
                    await syncPendingSessions(userID: userID)
                }
            }
        }
    }

    // MARK: - Error Mapping

    private func mapError(_ error: Error) -> AppError {
        let nsError = error as NSError
        if nsError.domain == FirestoreErrorDomain {
            switch FirestoreErrorCode.Code(rawValue: nsError.code) {
            case .unavailable: return .networkUnavailable
            case .permissionDenied: return .permissionDenied
            default: return .unknown
            }
        }
        return .unknown
    }

    // MARK: - Encoding/Decoding

    private func encodeProfile(_ p: UserProfile) -> [String: Any] {
        var d: [String: Any] = [
            "age": p.age,
            "restingHR": p.restingHR,
            "goal": p.goal.rawValue,
            "preferredWorkout": p.preferredWorkout.rawValue
        ]
        if let sex = p.sex { d["sex"] = sex.rawValue }
        if let weight = p.weight { d["weight"] = weight }
        return d
    }

    private func decodeProfile(_ d: [String: Any]) -> UserProfile? {
        guard
            let age = d["age"] as? Int,
            let rhr = d["restingHR"] as? Int,
            let goalRaw = d["goal"] as? String, let goal = Goal(rawValue: goalRaw),
            let workoutRaw = d["preferredWorkout"] as? String, let workout = WorkoutType(rawValue: workoutRaw)
        else { return nil }
        let sex = (d["sex"] as? String).flatMap(Sex.init(rawValue:))
        let weight = d["weight"] as? Double
        return UserProfile(age: age, restingHR: rhr, sex: sex, weight: weight,
                           goal: goal, preferredWorkout: workout)
    }

    private func encodeZones(_ z: HRZones) -> [String: Any] {
        func encodeZone(_ zone: Zone) -> [String: Any] {
            ["min": zone.min, "max": zone.max, "name": zone.name]
        }
        return [
            "zone1": encodeZone(z.zone1), "zone2": encodeZone(z.zone2),
            "zone3": encodeZone(z.zone3), "zone4": encodeZone(z.zone4),
            "zone5": encodeZone(z.zone5)
        ]
    }

    private func decodeZones(_ d: [String: Any]) -> HRZones? {
        func zone(_ key: String, number: Int, name: String) -> Zone? {
            guard let z = d[key] as? [String: Any],
                  let min = z["min"] as? Int, let max = z["max"] as? Int else { return nil }
            return Zone(number: number, name: z["name"] as? String ?? name, min: min, max: max)
        }
        guard let z1 = zone("zone1", number: 1, name: "Recovery"),
              let z2 = zone("zone2", number: 2, name: "Easy / Fat Burn"),
              let z3 = zone("zone3", number: 3, name: "Aerobic"),
              let z4 = zone("zone4", number: 4, name: "Threshold"),
              let z5 = zone("zone5", number: 5, name: "Max Effort") else { return nil }
        return HRZones(zone1: z1, zone2: z2, zone3: z3, zone4: z4, zone5: z5)
    }

    private func encodeSession(_ s: Session) throws -> [String: Any] {
        let hrData = try JSONEncoder().encode(s.hrStream)
        return [
            "id": s.id,
            "date": Timestamp(date: s.date),
            "programType": s.programType.rawValue,
            "durationSec": s.durationSec,
            "avgHR": s.avgHR,
            "timeInZones": Dictionary(uniqueKeysWithValues: s.timeInZones.map { ("\($0.key)", $0.value) }),
            "hrStream": (try? JSONSerialization.jsonObject(with: hrData)) ?? []
        ]
    }

    private func decodeSession(_ d: [String: Any]) -> Session? {
        guard
            let id = d["id"] as? String,
            let ts = d["date"] as? Timestamp,
            let typeRaw = d["programType"] as? String, let type = WorkoutType(rawValue: typeRaw),
            let duration = d["durationSec"] as? Int,
            let avgHR = d["avgHR"] as? Int
        else { return nil }
        let timeInZones = (d["timeInZones"] as? [String: Int]).map {
            Dictionary(uniqueKeysWithValues: $0.compactMap { k, v -> (Int, Int)? in
                guard let key = Int(k) else { return nil }
                return (key, v)
            })
        } ?? [:]
        // Reverse of encodeSession's hrStream serialization. Empty if absent/undecodable
        // (e.g. legacy records saved before the stream was persisted).
        let hrStream: [HRRecord]
        if let raw = d["hrStream"],
           let data = try? JSONSerialization.data(withJSONObject: raw),
           let decoded = try? JSONDecoder().decode([HRRecord].self, from: data) {
            hrStream = decoded
        } else {
            hrStream = []
        }
        return Session(id: id, date: ts.dateValue(), programType: type,
                       durationSec: duration, avgHR: avgHR, timeInZones: timeInZones, hrStream: hrStream)
    }
}

// Helper to access current Firebase Auth userID without importing FirebaseAuth everywhere
private enum Auth {
    static var currentUserID: String? {
        FirebaseAuth.Auth.auth().currentUser?.uid
    }
}
