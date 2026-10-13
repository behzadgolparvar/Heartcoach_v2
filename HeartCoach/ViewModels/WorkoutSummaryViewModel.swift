import Foundation
import HeartRateCoachCore

@Observable
final class WorkoutSummaryViewModel {

    enum SaveState {
        case idle
        case saving
        case saved
        case savedPendingSync
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
    private let exportService: ExportUploading?

    init(firebaseService: FirebaseServiceProtocol, exportService: ExportUploading? = nil) {
        self.firebaseService = firebaseService
        self.exportService = exportService
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
                let outcome = try await firebaseService.saveSession(session, userID: userID)
                await self.advanceProgression(for: session, userID: userID)
                // Research data lives in the Firestore session doc (hr_stream with epoch-ms
                // timestamps); export CSVs on demand from Firestore instead. The Storage
                // upload is kept but disabled for now — re-enable if per-session CSVs in
                // Storage are wanted again.
                // await exportService?.uploadSessionCSV(session, userID: userID)
                await MainActor.run {
                    self.saveState = outcome == .synced ? .saved : .savedPendingSync
                }
            } catch let error as AppError {
                await MainActor.run { self.saveState = .failed(error) }
            } catch {
                await MainActor.run { self.saveState = .failed(.unknown) }
            }
        }
    }

    /// Advances the progression counter once, at save time, for a qualifying
    /// session (BR-3-5/6). Non-qualifying sessions (minimum walk, <20 min) are no-ops.
    private func advanceProgression(for session: Session, userID: String) async {
        guard var profile = try? await firebaseService.loadProfileV2(userID: userID),
              let program = profile.program else { return }
        let flag = session.sessionFlag ?? session.programType.rawValue
        let training = session.trainingDurationSec ?? session.durationSec
        let updated = ProgressionEngine.advance(program: program, sessionFlag: flag,
                                                trainingDurationSec: training, date: session.date)
        guard updated != program else { return }
        profile.program = updated
        try? await firebaseService.saveProfileV2(profile, userID: userID)
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
