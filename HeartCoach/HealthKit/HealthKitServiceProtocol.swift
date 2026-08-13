import Foundation

protocol HealthKitServiceProtocol: AnyObject {
    var isAuthorized: Bool { get }
    func requestAuthorization() async throws
    func fetchRestingHeartRate() async -> Int?
}
