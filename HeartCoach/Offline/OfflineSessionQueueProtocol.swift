import Foundation
import HeartRateCoachCore

protocol OfflineSessionQueueProtocol: AnyObject {
    func enqueue(_ session: Session) throws
    func pendingSessions() throws -> [Session]
    func markSynced(id: String) throws
}
