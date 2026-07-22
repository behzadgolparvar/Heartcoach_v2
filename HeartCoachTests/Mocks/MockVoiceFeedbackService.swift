import Foundation
import HeartRateCoachCore
@testable import HeartCoach

final class MockVoiceFeedbackService: VoiceFeedbackServiceProtocol {
    var isMuted: Bool = false
    var spokenMessages: [CoachingMessage] = []
    var stopSpeakingCallCount: Int = 0
    var configureAudioSessionCallCount: Int = 0

    func speak(_ message: CoachingMessage) {
        if !isMuted || message.layer == 1 {
            spokenMessages.append(message)
        }
    }

    func stopSpeaking() {
        stopSpeakingCallCount += 1
    }

    func configureAudioSession() {
        configureAudioSessionCallCount += 1
    }
}
