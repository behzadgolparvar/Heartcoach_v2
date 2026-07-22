import Foundation
import HeartRateCoachCore

@Observable
final class HistoryViewModel {

    private(set) var sessions: [Session] = []
    private(set) var isLoading: Bool = false
    private(set) var error: AppError?
    private(set) var hasMore: Bool = false

    private let firebaseService: FirebaseServiceProtocol
    private var currentLimit: Int = 10
    private let pageSize: Int = 10

    init(firebaseService: FirebaseServiceProtocol) {
        self.firebaseService = firebaseService
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
            do {
                let loaded = try await firebaseService.loadSessions(userID: userID, limit: currentLimit + 1)
                await MainActor.run {
                    self.hasMore = loaded.count > self.currentLimit
                    self.sessions = Array(loaded.prefix(self.currentLimit))
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
