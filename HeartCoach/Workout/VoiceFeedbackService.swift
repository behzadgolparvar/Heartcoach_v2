import AVFoundation
import HeartRateCoachCore

protocol VoiceFeedbackServiceProtocol: AnyObject {
    var isMuted: Bool { get set }
    func speak(_ message: CoachingMessage)
    func stopSpeaking()
    func configureAudioSession()
}

final class VoiceFeedbackService: VoiceFeedbackServiceProtocol {

    var isMuted: Bool = false

    private let synthesizer = AVSpeechSynthesizer()
    private let voice = AVSpeechSynthesisVoice(language: "en-US")

    func configureAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(
            .playback,
            mode: .default,
            options: [.duckOthers, .allowBluetooth]
        )
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    func speak(_ message: CoachingMessage) {
        // Layer 1 safety messages always play regardless of mute setting
        guard !isMuted || message.layer == 1 else { return }

        synthesizer.stopSpeaking(at: .immediate)

        let utterance = AVSpeechUtterance(string: message.text)
        utterance.voice = voice
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        synthesizer.speak(utterance)
    }

    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}
