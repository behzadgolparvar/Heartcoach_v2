# Component Methods — HeartRateCoach

**Note**: This document defines method signatures and high-level purposes. Detailed business logic (Karvonen formula steps, anti-spam rules, phase transition conditions) is defined in Functional Design (Construction Phase, per unit).

---

## Unit 1: HeartRateCoachCore

### ZoneCalculator
```swift
// Computes all 5 HR zones from age and resting HR using Karvonen formula
static func calculate(age: Int, restingHR: Int) -> HRZones

// Returns the zone number (1–5) for a given HR reading
// Returns 0 if HR is below Zone 1 minimum
static func zone(for hr: Int, in zones: HRZones) -> Int

// Returns HRmax for a given age (220 - age)
static func maxHR(for age: Int) -> Int
```

### WorkoutPhaseSequencer
```swift
// Creates a sequencer for the given program
init(program: WorkoutProgram)

// Returns the current active phase
var currentPhase: WorkoutPhase { get }

// Returns seconds remaining in the current phase
var timeRemainingInPhase: TimeInterval { get }

// Advances time by the given interval; moves to next phase if current has elapsed
// Returns true if a phase transition occurred
mutating func advance(by seconds: TimeInterval) -> Bool

// Returns true if all phases have completed
var isComplete: Bool { get }
```

---

## Unit 2: iPhone Foundation

### AuthService
```swift
// Signs in with Apple credential; creates Firebase Auth user if new
func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws -> User

// Signs out the current user
func signOut() throws

// Current authenticated user (nil if not signed in)
var currentUser: AnyPublisher<User?, Never> { get }
```

### FirebaseService
```swift
// User profile
func saveUserProfile(_ profile: UserProfile) async throws
func loadUserProfile() async throws -> UserProfile

// HR Zones
func saveZones(_ zones: HRZones) async throws
func loadZones() async throws -> HRZones

// Settings
func saveSettings(goal: Goal, preferredWorkout: WorkoutType) async throws
func loadSettings() async throws -> UserSettings

// Sessions
func saveSession(_ session: Session) async throws
func loadSessions() async throws -> [Session]

// HR stream — called every 5 sec during active workout
func appendHRRecord(_ record: HRRecord, toSession sessionId: String) async throws

// Emergency events
func saveEmergencyEvent(hr: Int, timestamp: Date) async throws
```

### HealthKitService
```swift
// Requests HealthKit authorisation for heart rate reading
func requestAuthorization() async throws

// Returns true if HealthKit HR reading is authorised
var isAuthorized: Bool { get }
```

### OfflineSessionQueue
```swift
// Adds a session to the local offline queue
func enqueue(_ session: Session)

// Returns all queued sessions without removing them
func peek() -> [Session]

// Removes all queued sessions and uploads them to Firebase
// Returns number of sessions successfully synced
func flush(using service: FirebaseServiceProtocol) async -> Int

// Number of sessions currently in the queue
var pendingCount: Int { get }
```

### OnboardingViewModel
```swift
// Validates and saves profile; triggers zone calculation
func saveProfile(age: Int, restingHR: Int, sex: Sex?, weight: Double?) async throws

// Returns calculated zones for preview before saving
func previewZones(age: Int, restingHR: Int) -> HRZones

// Validates RHR input — returns warning message if outside 40–100
func validateRHR(_ value: Int) -> String?
```

### SettingsViewModel
```swift
// Saves updated profile fields and triggers zone recalculation
func saveProfile(_ profile: UserProfile) async throws

// Saves goal and preferred workout
func saveSettings(goal: Goal, preferredWorkout: WorkoutType) async throws

// Loads current profile and settings from Firestore
func loadCurrentValues() async throws
```

---

## Unit 3: iPhone Workout Engine

### CoachingEngine
```swift
// Creates engine for a specific workout and user's zones
init(program: WorkoutProgram,
     zones: HRZones,
     voiceFeedback: VoiceFeedbackProtocol,
     watchBridge: WatchBridgeProtocol)

// Starts the workout — begins phase sequencing, subscribes to HR stream
func start()

// Stops the workout — returns completed session summary
func stop() -> Session

// Publishes current coaching state to subscribers (Combine)
var coachingStatePublisher: AnyPublisher<CoachingState, Never> { get }

// Processes a single HR reading through all 3 layers
// Called internally every 5 seconds via WatchBridge HR publisher
func processReading(_ reading: HRReading)
```

### VoiceFeedbackService
```swift
// Speaks the given message; respects anti-spam timing (managed by CoachingEngine)
func speak(_ message: String)

// Cancels any in-progress speech
func cancelSpeech()
```

### WatchBridge
```swift
init(session: WCSession)

// Activates the WatchConnectivity session
func activate()

// Sends haptic command to Watch — fire and forget
func sendHaptic(_ pattern: HapticPattern)

// Sends workout start signal to Watch
func notifyWorkoutStarted(program: WorkoutProgram, zones: HRZones)

// Sends workout stop signal to Watch
func notifyWorkoutStopped()

// Sends emergency stop signal to Watch
func notifyEmergencyStop()

// Publishes HR readings received from Watch (Combine)
var hrReadingsPublisher: AnyPublisher<HRReading, Never> { get }

// Connection status publisher
var isConnectedPublisher: AnyPublisher<Bool, Never> { get }
```

### WorkoutSessionManager
```swift
init(firebaseService: FirebaseServiceProtocol,
     watchBridge: WatchBridgeProtocol,
     offlineQueue: OfflineSessionQueueProtocol,
     voiceFeedback: VoiceFeedbackProtocol)

// Creates CoachingEngine and begins the workout session
func startWorkout(program: WorkoutProgram, zones: HRZones, userProfile: UserProfile)

// Ends the workout; saves session to Firebase or queues offline
func stopWorkout() async

// Publishes current coaching state (forwarded from CoachingEngine)
var coachingStatePublisher: AnyPublisher<CoachingState, Never> { get }

// Publishes sync status for UI banner
var syncStatusPublisher: AnyPublisher<SyncStatus, Never> { get }
```

### WorkoutViewModel
```swift
init(sessionManager: WorkoutSessionManagerProtocol,
     program: WorkoutProgram)

// Starts the workout — delegates to WorkoutSessionManager
func startWorkout(zones: HRZones, userProfile: UserProfile)

// Stops the workout early — prompts confirmation, then delegates
func requestStopWorkout()

// Confirms early stop after user confirmation
func confirmStopWorkout() async

// Published state (driven by CoachingEngine publisher via Combine)
var currentHR: Int
var currentZone: Int
var targetZone: Int
var zoneName: String
var coachingMessage: String
var phaseTimeRemaining: TimeInterval
var elapsedTime: TimeInterval
var phaseName: String
var syncStatus: SyncStatus
var showStopConfirmation: Bool
```

### HistoryViewModel
```swift
init(firebaseService: FirebaseServiceProtocol)

// Loads all past sessions from Firestore
func loadSessions() async

// Published state
var sessions: [Session]
var isLoading: Bool
var errorMessage: String?
```

---

## Unit 4: Apple Watch App

### WatchSessionManager
```swift
// Starts HKWorkoutSession on Watch
func startWorkout() async throws

// Stops HKWorkoutSession on Watch
func stopWorkout() async throws

// Publishes HR readings from HealthKit sensor (Combine)
var hrReadingsPublisher: AnyPublisher<HRReading, Never> { get }
```

### WatchConnectivityManager
```swift
// Activates WCSession on Watch
func activate()

// Sends HR reading to iPhone
func sendHRReading(_ reading: HRReading)

// Publishes coaching commands received from iPhone (Combine)
var coachingCommandPublisher: AnyPublisher<CoachingCommand, Never> { get }
```

### HapticManager
```swift
// Plays the haptic pattern corresponding to the given coaching event
func play(_ pattern: HapticPattern)
```

### WorkoutWatchViewModel
```swift
// Published state — driven by WatchConnectivityManager
var currentHR: Int
var currentZone: Int
var targetZone: Int
var phaseName: String
var showCoachingOverlay: Bool
var coachingOverlayText: String
var showEmergencyStop: Bool

// Dismisses emergency stop screen
func dismissEmergencyStop()
```
