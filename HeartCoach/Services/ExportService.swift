import Foundation
import FirebaseStorage
import HeartRateCoachCore

/// Uploads per-session research CSV to Firebase Storage (FR-8). Behind a protocol.
protocol ExportUploading: AnyObject {
    /// Best-effort; never throws to the caller (non-blocking, BR-6-10).
    func uploadSessionCSV(_ session: Session, userID: String) async
}

/// Firebase Storage implementation. Path: `users/{uid}/exports/<sessionId>.csv`.
/// Own-data Storage rules enforce access (SECURITY-02). Hidden from the UI.
final class ExportService: ExportUploading {
    private let storage = Storage.storage()

    func uploadSessionCSV(_ session: Session, userID: String) async {
        let csv = SessionCSV.rows(for: session)
        guard let data = csv.data(using: .utf8) else { return }
        let ref = storage.reference(withPath: "users/\(userID)/exports/\(session.id).csv")
        let meta = StorageMetadata()
        meta.contentType = "text/csv"
        // Best-effort: swallow errors (retried on next save). No health values logged.
        _ = try? await ref.putDataAsync(data, metadata: meta)
    }
}
