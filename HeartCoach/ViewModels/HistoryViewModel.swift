import Foundation
import HeartRateCoachCore

@Observable
final class HistoryViewModel {

    private(set) var sessions: [Session] = []
    private(set) var isLoading: Bool = false
    private(set) var error: AppError?
    private(set) var hasMore: Bool = false

    private let firebaseService: FirebaseServiceProtocol
    private let offlineQueue: OfflineSessionQueueProtocol
    private var currentLimit: Int = 10
    private let pageSize: Int = 10

    init(firebaseService: FirebaseServiceProtocol, offlineQueue: OfflineSessionQueueProtocol) {
        self.firebaseService = firebaseService
        self.offlineQueue = offlineQueue
    }

    func loadInitial(userID: String) {
        currentLimit = pageSize
        load(userID: userID)
    }

    func loadMore(userID: String) {
        currentLimit += pageSize
        load(userID: userID)
    }

    private func load(userID: String) {
        isLoading = true
        error = nil
        Task {
            // Push any locally-queued sessions to the cloud before loading, so a
            // previously "queued" workout gets promoted to a real Firestore record.
            await firebaseService.syncPendingSessions(userID: userID)
            do {
                let remote = try await firebaseService.loadSessions(userID: userID, limit: currentLimit + 1)
                // Merge in anything still sitting in the offline queue (e.g. a write
                // that keeps failing) so a session marked "Saved" always appears here.
                let pending = (try? offlineQueue.pendingSessions()) ?? []
                var byID: [String: Session] = [:]
                for session in remote { byID[session.id] = session }
                for session in pending where byID[session.id] == nil { byID[session.id] = session }
                let merged = byID.values.sorted { $0.date > $1.date }
                await MainActor.run {
                    self.hasMore = remote.count > self.currentLimit
                    self.sessions = Array(merged.prefix(self.currentLimit))
                    self.isLoading = false
                }
            } catch let err as AppError {
                await MainActor.run {
                    self.error = err
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = .unknown
                    self.isLoading = false
                }
            }
        }
    }
}
