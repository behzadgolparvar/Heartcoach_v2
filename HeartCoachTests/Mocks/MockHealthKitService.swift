import Foundation
@testable import HeartCoach

final class MockHealthKitService: HealthKitServiceProtocol {
    var isAuthorized: Bool = false
    var shouldThrowOnAuthorization = false

    func requestAuthorization() async throws {
        if shouldThrowOnAuthorization { throw AppError.healthKitUnauthorized }
        isAuthorized = true
    }
}
