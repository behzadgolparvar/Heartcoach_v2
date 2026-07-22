import Foundation
import HeartRateCoachCore

@Observable
final class WorkoutSummaryViewModel {

    enum SaveState {
        case idle
        case saving
        case saved
        case failed(AppError)
    }

    // MARK: - State

    private(set) var session: Session?
    var saveState: SaveState = .idle

    // MARK: - Computed Stats (derived from session on load)

    private(set) var avgHR: Int = 0
    private(set) var peakHR: Int = 0
    private(set) var timePerZone: [Int: TimeInterval] = [:]

    // MARK: - Dependencies

    private let firebaseService: FirebaseServiceProtocol

    init(firebaseService: FirebaseServiceProtocol) {
        self.firebaseService = firebaseService
    }

    // MARK: - Actions

    func load(session: Session) {
        self.session = session
        computeStats(from: session)
    }

    func saveSession(userID: String) {
        guard let session, case .idle = saveState else { return }
        saveState = .saving
        Task {
            do {
                try await firebaseService.saveSession(session, userID: userID)
                await MainActor.run { self.saveState = .saved }
            } catch let error as AppError {
                await MainActor.run { self.saveState = .failed(error) }
            } catch {
                await MainActor.run { self.saveState = .failed(.unknown) }
            }
        }
    }

    // MARK: - Private

    private func computeStats(from session: Session) {
        let hrs = session.hrStream.map(\.hr)
        avgHR = hrs.isEmpty ? 0 : Int(ceil(Double(hrs.reduce(0, +)) / Double(hrs.count)))
        peakHR = hrs.max() ?? 0

        var zones: [Int: TimeInterval] = [:]
        for record in session.hrStream {
            let z = record.currentZone
            if z >= 1 && z <= 5 {
                zones[z, default: 0] += 5
            }
        }
        timePerZone = zones
    }
}
