import SwiftUI
import HeartRateCoachCore

/// Live workout — Direction D "Broadcast + Trace".
struct WorkoutView: View {
    let onFinish: () -> Void
    @Environment(WorkoutViewModel.self) private var workoutVM
    @State private var showStopConfirm = false
    @State private var navigateToSummary = false

    var body: some View {
        ZStack {
            WT.bg.ignoresSafeArea()

            switch workoutVM.startupState {
            case .warmingUp:
                startupView(big: nil, caption: "Getting your heart rate…", showSpinner: true)
            case .countdown(let n):
                startupView(big: "\(n)", caption: "GET READY", showSpinner: false)
            case .running:
                runningContent
            }

            if workoutVM.isPaused { pausedOverlay }
            if workoutVM.awaitingCooldownStart { cooldownGate }
            if workoutVM.showPausePrompt { pausePrompt }
            if showStopConfirm { stopConfirm }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: workoutVM.isWorkoutActive) { _, active in
            if !active, workoutVM.completedSession != nil { navigateToSummary = true }
        }
        .navigationDestination(isPresented: $navigateToSummary) {
            if let session = workoutVM.completedSession {
                WorkoutSummaryView(session: session, onFinish: onFinish)
            }
        }
    }

    // MARK: - Running (broadcast layout)

    private var runningContent: some View {
        VStack(spacing: 14) {
            scoreboardHeader

            if let proto = workoutVM.sessionProtocol {
                HRTraceView(
                    proto: proto,
                    zones: workoutVM.displayZones,
                    restingHR: workoutVM.displayRestingHR,
                    maxHR: workoutVM.displayMaxHR,
                    hrTrace: workoutVM.hrTrace,
                    currentSecond: Int(workoutVM.coachingState?.elapsedTime ?? 0),
                    currentZone: zone,
                    roundLabel: workoutVM.roundLabel,
                    remainingSec: workoutVM.remainingSessionSec)
            }

            if workoutVM.sensorDropout {
                Text("No heart-rate signal — safety checks paused. Check your Watch.")
                    .font(WT.body(13, .bold)).foregroundStyle(.black)
                    .frame(maxWidth: .infinity).padding(.vertical, 8).padding(.horizontal, 12)
                    .background(WT.warning)
            }

            Spacer(minLength: 0)
            hero
            ZoneGaugeView(currentHR: hr, currentZone: zone, targetZone: targetZone,
                          zones: workoutVM.displayZones, recoveryMode: recoveryMode)
            Spacer(minLength: 0)

            coachLowerThird
            statsRow
            controls
        }
        .padding(.top, 60).padding(.horizontal, 18).padding(.bottom, 30)
        .foregroundStyle(.white)
    }

    // MARK: Scoreboard header

    private var scoreboardHeader: some View {
        HStack(spacing: 0) {
            Text(phaseChip)
                .font(WT.cond(20, .heavy)).tracking(1).foregroundStyle(.white)
                .padding(.horizontal, 12).frame(height: 44).background(WT.red)
            Text(Int(workoutVM.coachingState?.elapsedTime ?? 0).msClock)
                .font(WT.cond(28, .bold)).monospacedDigit().foregroundStyle(.white)
                .padding(.horizontal, 12).frame(height: 44).background(WT.surface)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("PHASE ENDS").font(WT.body(10, .semibold)).tracking(1.6).foregroundStyle(WT.textSecondary)
                Text(Int(workoutVM.coachingState?.phaseTimeRemaining ?? 0).msClock)
                    .font(WT.cond(26, .bold)).monospacedDigit().foregroundStyle(.white)
            }
        }
        .frame(height: 44)
    }

    // MARK: Hero

    private var hero: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Text("Z\(zone)")
                    .font(WT.cond(18, .heavy)).foregroundStyle(.black)
                    .padding(.horizontal, 8).padding(.vertical, 5).background(WT.zoneColor(zone))
                Text(WT.zoneName(zone))
                    .font(WT.cond(18, .bold)).tracking(0.8).foregroundStyle(WT.zoneColor(zone))
            }
            .animation(.easeInOut(duration: 0.4), value: zone)

            Text(hr > 0 ? "\(hr)" : "--")
                .font(WT.cond(140, .heavy)).monospacedDigit()
                .foregroundStyle(hr > 0 ? .white : WT.textTertiary)
                .padding(.top, 6)
            Text("BPM").font(WT.cond(15, .bold)).tracking(5).foregroundStyle(WT.textSecondary)
        }
    }

    // MARK: Coach lower-third

    private var coachLowerThird: some View {
        ZStack {
            if let msg = workoutVM.coachingState?.coachingMessage, !msg.isEmpty {
                HStack(spacing: 0) {
                    Rectangle().fill(WT.red).frame(width: 10)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("COACH").font(WT.body(10.5, .bold)).tracking(1.8).foregroundStyle(WT.textTertiary)
                        Text(msg.uppercased())
                            .font(WT.cond(26, .heavy)).foregroundStyle(.black).lineLimit(1).truncationMode(.tail)
                    }
                    .padding(.horizontal, 14)
                    Spacer()
                }
                .background(WT.bannerPaper)
                .transition(.move(edge: .leading).combined(with: .opacity))
            } else {
                HStack {
                    Text(idleLine).font(WT.cond(15, .bold)).tracking(1.2).foregroundStyle(WT.textLight)
                        .lineLimit(1)
                    Spacer()
                }
                .padding(.horizontal, 14)
                .overlay(RoundedRectangle(cornerRadius: 0).strokeBorder(WT.divider, lineWidth: 1))
            }
        }
        .frame(height: 76).clipped()
        .animation(.easeOut(duration: 0.4), value: workoutVM.coachingState?.coachingMessage)
    }

    private var idleLine: String {
        if workoutVM.sensorDropout { return "NO SIGNAL — CHECK YOUR WATCH" }
        if let step = workoutVM.cooldownStepLabel, workoutVM.coachingState?.phase == .cooldown {
            return "STRETCH · \(step.uppercased())"
        }
        switch recoveryMode {
        case .walk: return "RECOVERY — WALK IT OUT"
        case .stretch: return "COOL DOWN — STRETCH"
        case .none: return "KEEP IT STEADY"
        }
    }

    // MARK: Stats row

    private var statsRow: some View {
        HStack(spacing: 0) {
            stat("AVG", "\(workoutVM.liveAvgHR)")
            Divider().frame(height: 30).overlay(WT.divider)
            stat("PEAK", "\(workoutVM.peakHR)")
            Divider().frame(height: 30).overlay(WT.divider)
            stat("IN TARGET", "\(workoutVM.inTargetPercent)%")
        }
        .padding(.vertical, 8)
        .overlay(alignment: .top) { Rectangle().fill(WT.divider).frame(height: 1) }
        .overlay(alignment: .bottom) { Rectangle().fill(WT.divider).frame(height: 1) }
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(label).font(WT.body(10, .semibold)).tracking(1.6).foregroundStyle(WT.textSecondary)
            Text(value).font(WT.cond(24, .bold)).monospacedDigit().foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Controls

    private var controls: some View {
        HStack(spacing: 10) {
            Button { workoutVM.pause() } label: {
                Text("PAUSE").font(WT.cond(21, .heavy)).tracking(1).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).frame(height: 56).background(WT.surface)
            }
            .accessibilityIdentifier("workout-pause-button")
            Button { showStopConfirm = true } label: {
                Text("STOP").font(WT.cond(21, .heavy)).tracking(1).foregroundStyle(WT.redText)
                    .frame(width: 120).frame(height: 56)
                    .overlay(Rectangle().strokeBorder(WT.red, lineWidth: 2))
            }
            .accessibilityIdentifier("emergency-stop-button")
        }
        .frame(height: 56)
    }

    // MARK: Derived

    private var hr: Int { workoutVM.sensorDropout ? 0 : (workoutVM.coachingState?.currentHR ?? 0) }
    private var zone: Int { workoutVM.sensorDropout ? 0 : (workoutVM.coachingState?.currentZone ?? 0) }
    private var targetZone: Int? { workoutVM.coachingState?.targetZone }
    private var phaseChip: String {
        switch workoutVM.coachingState?.phase {
        case .warmup: return "WARM UP"; case .exercise: return "EXERCISE"
        case .recovery: return "RECOVERY"; case .cooldown: return "COOL DOWN"; default: return "—"
        }
    }
    private var recoveryMode: ZoneGaugeView.RecoveryMode {
        switch workoutVM.coachingState?.phase {
        case .recovery: return .walk; case .cooldown: return .stretch; default: return .none
        }
    }

    // MARK: - Overlays

    private var pausedOverlay: some View {
        overlayScrim {
            VStack(spacing: 16) {
                Text("PAUSED").font(WT.cond(64, .heavy)).foregroundStyle(.white)
                Text("\(Int(workoutVM.coachingState?.elapsedTime ?? 0).msClock) in · \(workoutVM.remainingSessionSec.msClock) to go")
                    .font(WT.body(15)).foregroundStyle(WT.textLight)
                primaryButton("Resume") { workoutVM.resume() }.accessibilityIdentifier("workout-resume-button")
                secondaryButton("End workout") { workoutVM.end() }.accessibilityIdentifier("workout-end-button")
            }
        }
    }

    private var stopConfirm: some View {
        overlayScrim(alignment: .bottom) {
            VStack(spacing: 16) {
                Text("STOP NOW?").font(WT.cond(44, .heavy)).foregroundStyle(.white)
                Text("Feeling unwell — dizzy, chest pain, short of breath? Stop and rest. Your session so far will be saved.")
                    .font(WT.body(15)).foregroundStyle(WT.textLight).multilineTextAlignment(.center).padding(.horizontal, 20)
                primaryButton("Stop workout") {
                    showStopConfirm = false; workoutVM.end()
                }
                secondaryButton("Keep going") { showStopConfirm = false }
            }
            .padding(.bottom, 40)
        }
    }

    private var pausePrompt: some View {
        overlayScrim {
            VStack(spacing: 16) {
                Text("STILL THERE?").font(WT.cond(44, .heavy)).foregroundStyle(.white)
                Text("Your workout has been paused for a while.")
                    .font(WT.body(15)).foregroundStyle(WT.textLight).multilineTextAlignment(.center)
                primaryButton("Continue workout") { workoutVM.resume() }.accessibilityIdentifier("pause-continue")
                if workoutVM.canSnoozePause {
                    secondaryButton("Need more time") { workoutVM.snoozePause() }.accessibilityIdentifier("pause-more-time")
                }
                Button("Finish workout") { workoutVM.end() }
                    .font(WT.body(15, .semibold)).foregroundStyle(WT.redText)
                    .accessibilityIdentifier("pause-finish")
            }
        }
    }

    private var cooldownGate: some View {
        overlayScrim {
            VStack(spacing: 14) {
                Text("TRAINING COMPLETE").font(WT.body(12, .bold)).tracking(2).foregroundStyle(WT.success)
                Text("GREAT WORK!").font(WT.cond(56, .heavy)).foregroundStyle(.white)
                Text("Step off and get ready for a 2-minute stretch — it's part of the session and helps prevent injury.")
                    .font(WT.body(15)).foregroundStyle(WT.textLight).multilineTextAlignment(.center).padding(.horizontal, 24)
                primaryButton("Begin stretches") { workoutVM.beginCooldown() }.accessibilityIdentifier("cooldown-begin-button")
                secondaryButton("Skip") { workoutVM.end() }.accessibilityIdentifier("cooldown-skip-button")
            }
        }
    }

    private func startupView(big: String?, caption: String, showSpinner: Bool) -> some View {
        VStack(spacing: 24) {
            if let big {
                Text(big).font(WT.cond(220, .heavy)).monospacedDigit().foregroundStyle(.white)
                    .contentTransition(.numericText()).id(big)
            } else if showSpinner {
                ProgressView().controlSize(.large).tint(WT.red)
            }
            Text(caption).font(showSpinner ? WT.body(17, .semibold) : WT.body(16, .bold))
                .tracking(showSpinner ? 0 : 3)
                .foregroundStyle(showSpinner ? WT.textLight : WT.redText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.snappy, value: big)
    }

    // MARK: - Overlay building blocks

    private func overlayScrim<Content: View>(alignment: Alignment = .center,
                                             @ViewBuilder _ content: () -> Content) -> some View {
        ZStack(alignment: alignment) {
            Color.black.opacity(0.9).ignoresSafeArea()
            content().padding(.horizontal, 24)
        }
    }
    private func primaryButton(_ title: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).font(WT.cond(20, .heavy)).tracking(0.6).foregroundStyle(.white)
                .frame(maxWidth: .infinity).frame(height: 56)
                .background(RoundedRectangle(cornerRadius: 16).fill(WT.red))
        }
    }
    private func secondaryButton(_ title: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).font(WT.cond(20, .heavy)).tracking(0.6).foregroundStyle(.white)
                .frame(maxWidth: .infinity).frame(height: 56)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.10)))
        }
    }
}
