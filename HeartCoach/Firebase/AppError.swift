import Foundation

/// Typed error vocabulary for the HeartCoach app.
/// All service implementations map infrastructure errors to these cases
/// before throwing — raw Firebase/HealthKit errors never reach ViewModels.
enum AppError: Error, LocalizedError {
    case networkUnavailable
    case permissionDenied
    case authenticationFailed
    case profileNotFound
    case saveFailed
    case healthKitUnauthorized
    case unknown

    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "No internet connection. Please try again."
        case .permissionDenied:
            return "Access denied. Please sign in again."
        case .authenticationFailed:
            return "Sign in failed. Please try again."
        case .profileNotFound:
            return "Profile not found. Please complete onboarding."
        case .saveFailed:
            return "Save failed. Please try again."
        case .healthKitUnauthorized:
            return "Heart rate access is required to use HeartCoach."
        case .unknown:
            return "Something went wrong. Please try again."
        }
    }
}
