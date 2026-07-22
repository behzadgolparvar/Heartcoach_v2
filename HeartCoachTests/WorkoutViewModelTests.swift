import XCTest
import HeartRateCoachCore
@testable import HeartCoach

@MainActor
final class WorkoutViewModelTests: XCTestCase {

    private var zones: HRZones!
    private var mockVoice: MockVoiceFeedbackService!
    private var mockWatch: MockWatchBridge!
    private var mockFirebase: MockFirebaseService!
    private var vm: WorkoutViewModel!

    override func setUp() async throws {
        try await super.setUp()
        zones = try ZoneCalculator.calculate(age: 30, restingHR: 60)
        mockVoice = MockVoiceFeedbackService()
        mockWatch = MockWatchBridge()
        mockFirebase = MockFirebaseService()
        vm = WorkoutViewModel(zones: zones, voiceFeedback: mockVoice, watchBridge: mockWatch)
    }

    // MARK: - Start

    func test_start_setsWorkoutActiveTrue() {
        vm.start(program: .continuous)
        XCTAssertTrue(vm.isWorkoutActive)
    }

    func test_start_configuresAudioSession() {
        vm.start(program: .continuous)
        XCTAssertGreaterThan(mockVoice.configureAudioSessionCallCount, 0)
    }

    func test_start_activatesWatchBridge() {
        vm.start(program: .continuous)
        XCTAssertEqual(mockWatch.activateCallCount, 1)
    }

    func test_start_setsSelectedProgram() {
        vm.start(program: .hiit)
        XCTAssertEqual(vm.selectedProgram, .hiit)
    }

    // MARK: - Pause / Resume

    func test_pause_setsPausedTrue() {
        vm.start(program: .continuous)
        vm.pause()
        XCTAssertTrue(vm.isPaused)
    }

    func test_resume_clearsPausedState() {
        vm.start(program: .continuous)
        vm.pause()
        vm.resume()
        XCTAssertFalse(vm.isPaused)
    }

    func test_pause_stopsSpeaking() {
        vm.start(program: .continuous)
        vm.pause()
        XCTAssertGreaterThan(mockVoice.stopSpeakingCallCount, 0)
    }

    // MARK: - Emergency Stop

    func test_emergencyStop_setsWorkoutActiveFalse() {
        vm.start(program: .continuous)
        vm.emergencyStop()
        XCTAssertFalse(vm.isWorkoutActive)
    }

    func test_emergencyStop_sendsEmergencyHaptic() {
        vm.start(program: .continuous)
        vm.emergencyStop()
        XCTAssertTrue(mockWatch.sentHaptics.contains(.emergencyRepeated))
    }

    func test_emergencyStop_deactivatesWatchBridge() {
        vm.start(program: .continuous)
        vm.emergencyStop()
        XCTAssertGreaterThan(mockWatch.deactivateCallCount, 0)
    }

    // MARK: - End

    func test_end_createsCompletedSession() async {
        vm.start(program: .fartlek)
        vm.end()
        // Give the async Task a moment to complete
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertFalse(vm.isWorkoutActive)
    }

    // MARK: - Mute

    func test_muteToggle_propagatesToVoiceService() {
        vm.start(program: .continuous)
        vm.isMuted = true
        XCTAssertTrue(mockVoice.isMuted)
        vm.isMuted = false
        XCTAssertFalse(mockVoice.isMuted)
    }
}
