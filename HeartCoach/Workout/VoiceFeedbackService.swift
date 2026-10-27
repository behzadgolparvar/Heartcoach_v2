import AVFoundation
import HeartRateCoachCore

protocol VoiceFeedbackServiceProtocol: AnyObject {
    var isMuted: Bool { get set }
    /// User-selected voice identifier; nil = pick the best available en-US voice.
    var voiceIdentifier: String? { get set }
    func speak(_ message: CoachingMessage)
    func stopSpeaking()
    func configureAudioSession()
}

final class VoiceFeedbackService: VoiceFeedbackServiceProtocol {

    var isMuted: Bool = false
    var voiceIdentifier: String?

    private let synthesizer = AVSpeechSynthesizer()
    /// Best en-US voice installed, computed once (enumerating voices is cheap but not free).
    private lazy var autoVoice: AVSpeechSynthesisVoice? = VoiceFeedbackService.bestEnglishVoice()

    private var voice: AVSpeechSynthesisVoice? {
        if let id = voiceIdentifier, let v = AVSpeechSynthesisVoice(identifier: id) { return v }
        return autoVoice
    }

    /// Prefers premium > enhanced > default among en-US voices (iOS's newer
    /// enhanced/premium voices sound far closer to human than the compact default).
    static func bestEnglishVoice() -> AVSpeechSynthesisVoice? {
        let enUS = AVSpeechSynthesisVoice.speechVoices().filter { $0.language == "en-US" }
        return enUS.max { $0.quality.rawValue < $1.quality.rawValue }
            ?? AVSpeechSynthesisVoice(language: "en-US")
    }

    func configureAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(
            .playback,
            mode: .default,
            options: [.duckOthers, .allowBluetoothHFP]
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
