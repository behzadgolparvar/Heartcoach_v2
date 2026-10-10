import Foundation
import HeartRateCoachCore

/// The non-negotiable 15-min minimum walk (§I): 8 min fast + 7 min slow.
/// A simple timed flow with voice cues — no HR coaching, no scoring. On completion
/// it resets the relapse clock (via Home) but does not advance progression.
@Observable
@MainActor
final class MinimumWalkViewModel {

    enum Segment: Equatable { case fast, slow, done }

    var segment: Segment = .fast
    var secondsRemaining: Int = 8 * 60
    var isRunning = false

    /// Called once when the full 15 minutes complete (or the user taps Done).
    var onComplete: (() -> Void)?

    private let fastSec = 8 * 60
    private let slowSec = 7 * 60
    private var tickTask: Task<Void, Never>?
    private let voiceFeedback: VoiceFeedbackServiceProtocol

    init(voiceFeedback: VoiceFeedbackServiceProtocol) {
        self.voiceFeedback = voiceFeedback
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        voiceFeedback.configureAudioSession()
        segment = .fast
        secondsRemaining = fastSec
        voiceFeedback.speak(CoachingMessage(layer: 3, text: "Let's do your fifteen-minute minimum. Start with eight minutes at a brisk pace."))
        startTick()
    }

    func stop() {
        tickTask?.cancel(); tickTask = nil
        voiceFeedback.stopSpeaking()
        isRunning = false
    }

    /// User taps Done — finish early but still count as completing the minimum.
    func finishEarly() {
        complete()
    }

    private func startTick() {
        tickTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { return }
                await MainActor.run { self?.tick() }
            }
        }
    }

    private func tick() {
        guard secondsRemaining > 0 else { advanceSegment(); return }
        secondsRemaining -= 1
        if secondsRemaining == 0 { advanceSegment() }
    }

    private func advanceSegment() {
        switch segment {
        case .fast:
            segment = .slow
            secondsRemaining = slowSec
            voiceFeedback.speak(CoachingMessage(layer: 3, text: "Great. Now seven minutes at an easy pace to finish."))
        case .slow:
            complete()
        case .done:
            break
        }
    }

    private func complete() {
        tickTask?.cancel(); tickTask = nil
        segment = .done
        secondsRemaining = 0
        isRunning = false
        voiceFeedback.speak(CoachingMessage(layer: 3, text: "Nicely done. You kept your momentum today."))
        onComplete?()
    }
}
