import SwiftUI
import UIKit
import HeartRateCoachCore

/// Home — Option 3a "Broadcast, one screen". Same content as before, restyled in the
/// Live Workout D language: square slabs, Barlow Condensed, zone colors. Content region
/// fills/scrolls; the action bar stays pinned above the tab bar.
struct HomeView: View {
    @Environment(HomeViewModel.self) private var vm
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(AppContainer.self) private var container
    @Environment(\.scenePhase) private var scenePhase
    @State private var workoutVM: WorkoutViewModel?
    @State private var showWorkout = false
    @State private var showMinimumWalk = false
    @State private var showLevelUpUnlock = false
    @State private var showShapeUnlock = false
    @State private var showShapeChoice = false
    @State private var weightText = ""
    @State private var didRequestNotifications = false
    @State private var zonesOpen = false
    @AppStorage("preferredVoiceId") private var preferredVoiceId = ""

    private let durationMin = 37

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                content
                actionBar
            }
            .background(WT.bg.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $showWorkout) {
                if let wvm = workoutVM {
                    WorkoutView(onFinish: { showWorkout = false; workoutVM = nil })
                        .environment(wvm)
                }
            }
            .navigationDestination(isPresented: $showMinimumWalk) {
                MinimumWalkView(voiceFeedback: container.voiceFeedbackService) {
                    if let userID = authViewModel.currentUserID { vm.recordMinimumWalk(userID: userID) }
                    showMinimumWalk = false
                }
            }
            .navigationDestination(isPresented: $showLevelUpUnlock) {
                LevelUpUnlockView(prefilledInjuredJoints: vm.prefilledInjuredJoints) { injured, comfortable, approved in
                    if let userID = authViewModel.currentUserID {
                        vm.completeLevelUpUnlock(injuredJoints: injured, comfortable: comfortable,
                                                 approvedExerciseIDs: approved, userID: userID)
                    }
                    showLevelUpUnlock = false
                }
            }
            .navigationDestination(isPresented: $showShapeUnlock) {
                ShapeUnlockView { equipment, focus, pain in
                    if let userID = authViewModel.currentUserID {
                        vm.completeShapeUnlock(equipmentPreference: equipment, focusAreas: focus,
                                               acknowledgedPain: pain, userID: userID)
                    }
                    showShapeUnlock = false
                }
            }
            .navigationDestination(isPresented: $showShapeChoice) {
                if let wvm = workoutVM, let a = vm.assignment {
                    ShapeChoiceView(assignedType: a.type,
                                    defaultOption: vm.profile?.shapeUnlock?.equipmentPreference ?? .weights,
                                    focusDefaults: Array(vm.profile?.shapeUnlock?.focusAreas ?? []),
                                    onFinish: { showShapeChoice = false; workoutVM = nil })
                    .environment(wvm)
                }
            }
        }
        .onAppear {
            container.voiceFeedbackService.voiceIdentifier = preferredVoiceId.isEmpty ? nil : preferredVoiceId
            if let userID = authViewModel.currentUserID { vm.loadData(userID: userID) }
            if !didRequestNotifications {
                didRequestNotifications = true
                Task { _ = await container.notificationService.requestAuthorization() }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { vm.recheckHealthKitStatus() }
        }
    }

    // MARK: - A. Content (fills viewport; scrolls only when it overflows)

    private var content: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    scoreboard
                    greeting
                    if vm.profile?.program != nil { progressTicks }
                    if let msg = vm.relapseMessage { relapseBanner(msg) }
                    if vm.isMilestoneDue { milestoneBanner }
                    if let a = vm.assignment { TodaysSessionPanel(assignment: a, zonesOpen: $zonesOpen,
                                                                 zones: vm.zones, maxHR: effectiveMaxHR,
                                                                 durationMin: durationMin) }
                    if let session = vm.lastSession { LastSessionCardView(session: session) }
                    Spacer(minLength: 0)
                }
                .padding(.top, 8).padding(.horizontal, 18).padding(.bottom, 4)
                .frame(minHeight: geo.size.height, alignment: .top)
            }
        }
    }

    // MARK: - A1. Scoreboard header

    private var scoreboard: some View {
        HStack(spacing: 0) {
            Text(stageName)
                .font(WT.cond(17, .heavy)).tracking(0.85).foregroundStyle(.white)
                .padding(.horizontal, 12).frame(height: 36).background(WT.red)
            Text("\(sessionNumber) / 60")
                .font(WT.cond(20, .bold)).monospacedDigit().foregroundStyle(.white)
                .padding(.horizontal, 12).frame(height: 36).background(WT.surface)
            Spacer(minLength: 8)
            Text(dateString)
                .font(WT.body(10, .semibold)).tracking(1.6).foregroundStyle(WT.textSecondary)
        }
        .frame(height: 36)
    }

    // MARK: - A2. Greeting

    private var greeting: some View {
        Text("GOOD \(timeOfDayGreeting().uppercased())")
            .font(WT.cond(30, .heavy)).tracking(-0.46).foregroundStyle(WT.textSecondary)
            .lineLimit(1).minimumScaleFactor(0.6)
    }

    // MARK: - A3. Foundation progress ticks

    private var progressTicks: some View {
        let completed = sessionsCompleted
        return HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { g in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 2) {
                        ForEach(0..<ProgressionEngine.sessionsPerSubPhase, id: \.self) { i in
                            Rectangle()
                                .fill(tickColor(g * ProgressionEngine.sessionsPerSubPhase + i, completed))
                                .frame(height: 18).frame(maxWidth: .infinity)
                        }
                    }
                    Text("SUB-PHASE \(g + 1)")
                        .font(WT.cond(11, .bold)).tracking(1.54)
                        .foregroundStyle(isCurrentSubPhase(g, completed) ? .white : WT.textTertiary)
                }
            }
        }
    }

    private func tickColor(_ index: Int, _ completed: Int) -> Color {
        if index < completed { return WT.red }
        if index == completed { return .white }
        return WT.divider
    }
    private func isCurrentSubPhase(_ group: Int, _ completed: Int) -> Bool {
        completed < ProgressionEngine.sessionsPerStage && group == completed / ProgressionEngine.sessionsPerSubPhase
    }

    // MARK: - A4. Banners

    private func relapseBanner(_ msg: String) -> some View {
        HStack(spacing: 0) {
            Rectangle().fill(WT.red).frame(width: 10)
            VStack(alignment: .leading, spacing: 2) {
                (Text("WELCOME BACK · ").font(WT.body(10.5, .bold)).tracking(1.89).foregroundStyle(WT.textTertiary)
                 + Text(msg).font(WT.body(14, .semibold)).foregroundStyle(.black))
                .lineSpacing(3)
            }
            .padding(.vertical, 8).padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(WT.bannerPaper)
        }
    }

    private var milestoneBanner: some View {
        HStack(spacing: 0) {
            HStack(spacing: 8) {
                Text("CHECK-IN").font(WT.body(10, .semibold)).tracking(1.6).foregroundStyle(WT.warning)
                TextField("Weight", text: $weightText)
                    .keyboardType(.decimalPad)
                    .font(WT.cond(22, .bold)).foregroundStyle(.white)
                    .accessibilityIdentifier("milestone-weight-field")
                Text("KG").font(WT.cond(14, .bold)).tracking(2.8).foregroundStyle(WT.textSecondary)
            }
            .padding(.horizontal, 12).frame(maxWidth: .infinity, maxHeight: .infinity).background(WT.surface)

            Button {
                if let uid = authViewModel.currentUserID {
                    vm.logMilestone(weightKg: Double(weightText), userID: uid)
                    weightText = ""
                }
            } label: {
                Text("LOG").font(WT.cond(18, .heavy)).tracking(1.8).foregroundStyle(.black)
                    .frame(maxHeight: .infinity).frame(width: 80).background(WT.warning)
            }
        }
        .frame(height: 44)
    }

    // MARK: - B. Action bar (pinned)

    private var actionBar: some View {
        VStack(spacing: 4) {
            if vm.isHealthKitAuthorized {
                startButton
            } else {
                noAccessBar
            }
            minimumButton
        }
        .padding(.top, 10).padding(.horizontal, 18).padding(.bottom, 10)
    }

    private var startButton: some View {
        Button { startAction() } label: {
            HStack(spacing: 0) {
                Text(startTitle)
                    .font(WT.cond(22, .heavy)).tracking(2.2).foregroundStyle(.white)
                    .padding(.leading, 18)
                    .lineLimit(1).minimumScaleFactor(0.6)
                Spacer(minLength: 8)
                if !isStageComplete {
                    Text(timeString)
                        .font(WT.cond(18, .bold)).tracking(1.44).foregroundStyle(.white)
                        .padding(.horizontal, 16).frame(maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
            }
        }
        .buttonStyle(BroadcastPrimaryButtonStyle())
        .opacity(startDisabled ? 0.4 : 1)
        .disabled(startDisabled)
        .accessibilityIdentifier("home-start-workout")
    }

    private var noAccessBar: some View {
        HStack(spacing: 0) {
            Text("No heart-rate access. HeartCoach can't coach you without it.")
                .font(WT.body(13, .bold)).foregroundStyle(.black)
                .padding(.leading, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button { vm.requestHealthKitAccess() } label: {
                Text("GRANT").font(WT.cond(15, .heavy)).tracking(1.5).foregroundStyle(WT.warning)
                    .frame(height: 44).padding(.horizontal, 16).background(Color.black)
            }
            .padding(.trailing, 8)
        }
        .frame(height: 60).background(WT.warning)
    }

    private var minimumButton: some View {
        Button { showMinimumWalk = true } label: {
            (Text("NOT FEELING IT?").foregroundStyle(WT.textSecondary)
             + Text(" DO THE 15-MIN MINIMUM").foregroundStyle(.white))
            .font(WT.cond(15, .bold)).tracking(1.8)
        }
        .buttonStyle(BroadcastSecondaryButtonStyle())
        .disabled(vm.zones == nil)
        .accessibilityIdentifier("home-minimum-walk")
    }

    // MARK: - Actions

    private func startAction() {
        if isStageComplete {
            switch vm.profile?.program?.currentStage {
            case .foundation: showLevelUpUnlock = true
            case .levelUp: showShapeUnlock = true
            default: break
            }
            return
        }
        guard let zones = vm.zones, let profile = vm.profile else { return }
        let wvm = container.makeWorkoutViewModel(
            zones: zones, restingHR: profile.restingHR, maxHR: profile.effectiveMaxHR,
            stage: profile.program?.currentStage ?? .foundation, levelUpUnlock: profile.levelUpUnlock)
        workoutVM = wvm
        if profile.program?.currentStage == .shape {
            showShapeChoice = true
        } else {
            wvm.start(program: Self.program(for: vm.assignment?.type))
            showWorkout = true
        }
    }

    // MARK: - Derived

    private var sessionsCompleted: Int { vm.profile?.program?.currentProgress.sessionsCompleted ?? 0 }
    private var sessionNumber: Int { vm.assignment?.sessionNumber ?? (sessionsCompleted + 1) }
    private var stageName: String { (vm.profile?.program?.currentStage.displayName ?? "Foundation").uppercased() }
    private var effectiveMaxHR: Int { vm.profile?.effectiveMaxHR ?? 0 }
    private var isStageComplete: Bool { vm.assignment?.isStageComplete ?? false }
    private var timeString: String { String(format: "%d:00", durationMin) }
    private var startDisabled: Bool {
        isStageComplete ? false : (!vm.isHealthKitAuthorized || vm.zones == nil || vm.isWorkoutBlockedForWeight)
    }

    private var startTitle: String {
        if isStageComplete {
            switch vm.profile?.program?.currentStage {
            case .foundation: return "UNLOCK LEVEL UP"
            case .levelUp: return "UNLOCK SHAPE"
            default: return "COMPLETE"
            }
        }
        return "START \((vm.assignment?.type.displayName ?? "WORKOUT").uppercased())"
    }

    private var dateString: String {
        let d = Date()
        let wd = d.formatted(.dateTime.weekday(.abbreviated)).uppercased()
        let mo = d.formatted(.dateTime.month(.abbreviated)).uppercased()
        let day = d.formatted(.dateTime.day())
        return "\(wd) · \(mo) \(day)"
    }

    private static func program(for type: WorkoutType?) -> WorkoutProgram {
        switch type {
        case .hiit: return .hiit
        case .fartlek: return .fartlek
        default: return .continuous
        }
    }

    private func timeOfDayGreeting() -> String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 0..<12: return "morning"
        case 12..<17: return "afternoon"
        default: return "evening"
        }
    }
}

// MARK: - A5. Today's session panel (flexible height)

private struct TodaysSessionPanel: View {
    let assignment: SessionAssignment
    @Binding var zonesOpen: Bool
    let zones: HRZones?
    let maxHR: Int
    let durationMin: Int

    var body: some View {
        VStack(spacing: 0) {
            if assignment.isStageComplete {
                completeContent
            } else {
                sessionContent
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .padding(.top, 12).padding(.bottom, 10)
        .background(WT.panel)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(WT.panelStroke, lineWidth: 1))
    }

    private var sessionContent: some View {
        VStack(spacing: 0) {
            HStack {
                Text("TODAY'S SESSION")
                    .font(WT.cond(20, .heavy)).tracking(1.6).foregroundStyle(.white)
                    .padding(.vertical, 4).padding(.horizontal, 8).background(WT.red)
                Spacer()
                Text("\(durationMin) MIN")
                    .font(WT.cond(18, .bold)).tracking(1.8).foregroundStyle(WT.textLight)
            }
            .padding(.horizontal, 14)

            VStack(alignment: .leading, spacing: 0) {
                let name = assignment.type.displayName.uppercased()
                Text(name)
                    .font(WT.cond(name.count > 6 ? 72 : 112, .heavy)).tracking(-1.4).foregroundStyle(.white)
                    .lineLimit(1).minimumScaleFactor(0.5)
                    .padding(.top, 8)
                Text(metaString)
                    .font(WT.cond(15, .bold)).tracking(1.8).foregroundStyle(WT.textLight)
                    .padding(.top, 6).padding(.bottom, 12)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)

            if zonesOpen, let zones { zoneStrip(zones).padding(.bottom, 2) }

            bottomRow
        }
    }

    private func zoneStrip(_ zones: HRZones) -> some View {
        HStack(spacing: 2) {
            ForEach([zones.zone1, zones.zone2, zones.zone3, zones.zone4, zones.zone5], id: \.number) { z in
                VStack(spacing: 0) {
                    Text("Z\(z.number)").font(WT.cond(15, .heavy)).foregroundStyle(.black)
                    Spacer(minLength: 2)
                    Text(WT.zoneName(z.number)).font(WT.body(9, .bold)).tracking(0.54).foregroundStyle(.black)
                    Text("\(z.min)–\(z.max)").font(WT.cond(14, .heavy)).monospacedDigit().foregroundStyle(.black)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(6)
                .background(WT.zoneColor(z.number))
            }
        }
        .frame(height: 70).padding(.horizontal, 14)
    }

    private var bottomRow: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) { zonesOpen.toggle() }
        } label: {
            HStack {
                Text("YOUR ZONES · MAX \(maxHR)")
                    .foregroundStyle(WT.textSecondary)
                Spacer()
                Text(zonesOpen ? "HIDE ZONES" : "SHOW ZONES")
                    .foregroundStyle(.white)
            }
            .font(WT.body(11, .semibold)).tracking(1.54)
            .padding(.top, 10).padding(.horizontal, 14)
            .overlay(alignment: .top) { Rectangle().fill(WT.panelStroke).frame(height: 1) }
        }
        .buttonStyle(.plain)
        .padding(.top, 10)
    }

    private var completeContent: some View {
        VStack(spacing: 8) {
            Spacer(minLength: 0)
            Text("STAGE COMPLETE")
                .font(WT.cond(32, .heavy)).tracking(1).foregroundStyle(WT.red)
            Text("Unlock your next stage to keep progressing.")
                .font(WT.body(14, .medium)).foregroundStyle(WT.textSecondary)
                .multilineTextAlignment(.center)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity).padding(.horizontal, 14)
    }

    private var metaString: String {
        switch assignment.type {
        case .hiit: return "15 ROUNDS · 1 MIN HARD / 1 MIN WALK"
        case .fartlek: return "VARIED PACES · PUSH / FLOAT INTERVALS"
        default: return "5 CYCLES · 5 MIN RUN / 1 MIN WALK"
        }
    }
}
