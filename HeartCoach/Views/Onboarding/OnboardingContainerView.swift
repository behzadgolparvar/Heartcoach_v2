import SwiftUI
import HeartRateCoachCore

struct OnboardingContainerView: View {
    @Environment(OnboardingViewModel.self) private var vm

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                if vm.section != .consent {
                    Button("Back") { vm.back() }.foregroundStyle(.white)
                } else {
                    Color.clear.frame(width: 44, height: 1)
                }
                Spacer()
                ProgressDots(current: vm.section.rawValue, total: OnboardingViewModel.Section.allCases.count)
                Spacer()
                Color.clear.frame(width: 44, height: 1)
            }
            .padding(.horizontal, 16).padding(.top, 10)

            Group {
                switch vm.section {
                case .consent:      ConsentSectionView()
                case .demographics: DemographicsSectionView()
                case .scheduling:   SchedulingSectionView()
                case .mentality:    MentalitySectionView()
                case .equipment:    EquipmentSectionView()
                case .goals:        GoalsSectionView()
                case .device:       DeviceSectionView()
                case .zones:        ZonesSectionView()
                }
            }

            if let err = vm.fieldError {
                Text(err).font(.caption).foregroundStyle(.red).padding(.bottom, 6)
            }
        }
        .background(Color.black.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .onAppear { vm.prefillRestingHR() }
    }
}

// MARK: - 1 Consent

private struct ConsentSectionView: View {
    @Environment(OnboardingViewModel.self) private var vm
    var body: some View {
        @Bindable var vm = vm
        OnboardingSection(title: "Before we start", subtitle: "Please review and accept to continue.",
                          primaryTitle: "Agree & Continue", primaryEnabled: vm.isValid(.consent),
                          onPrimary: { vm.advance() }) {
            Toggle("I consent to HeartCoach collecting and using my health data to personalize my training.",
                   isOn: $vm.healthDataConsent).tint(.red).foregroundStyle(.white)
            Toggle("I consent to receiving workout reminders.",
                   isOn: $vm.remindersConsent).tint(.red).foregroundStyle(.white)
            Text("Your data is stored securely, and only you can access it. HeartCoach is for healthy individuals; it is not medical advice.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }
}

// MARK: - 2 Demographics / Health

private struct DemographicsSectionView: View {
    @Environment(OnboardingViewModel.self) private var vm
    var body: some View {
        @Bindable var vm = vm
        OnboardingSection(title: "About you", subtitle: "Used to personalize your heart-rate zones.",
                          primaryTitle: "Next", primaryEnabled: vm.isValid(.demographics),
                          onPrimary: { vm.advance() }) {
            labeledNumber("Age", $vm.ageText)
            picker("Gender", Gender.allCases, \.displayName, $vm.gender)
            MeasurementField(label: "Weight (optional)", text: $vm.weightText, imperial: $vm.weightImperial,
                             metricUnit: "kg", imperialUnit: "lb")
            MeasurementField(label: "Height (optional)", text: $vm.heightText, imperial: $vm.heightImperial,
                             metricUnit: "cm", imperialUnit: "in")
            if let bmi = vm.bmi {
                Text(String(format: "BMI: %.1f", bmi)).font(.subheadline).foregroundStyle(.secondary)
            }
            labeledNumber("Resting HR (bpm)", $vm.rhrText)
            if let w = vm.rhrWarning {
                Text(w == .belowTypicalRange ? "That's below the typical 40–100 range — please confirm."
                                             : "That's above the typical 40–100 range — please confirm.")
                    .font(.caption).foregroundStyle(.orange)
            }
            labeledNumber("Max HR (optional)", $vm.maxHRText)
            picker("Occupation activity (optional)", OccupationActivity.allCases, \.displayName, $vm.occupation)
            picker("Fitness experience", FitnessExperience.allCases, \.displayName, $vm.fitnessExperience)

            DisclosureGroup("Optional health background") {
                VStack(alignment: .leading, spacing: 12) {
                    multiPicker("Chronic conditions", ChronicCondition.allCases, \.displayName, $vm.chronicConditions)
                    multiPicker("HR-affecting medications", HRMedication.allCases, \.displayName, $vm.hrMedications)
                    Toggle("On Ozempic / anti-obesity therapy", isOn: $vm.onAntiObesityTherapy).tint(.red).foregroundStyle(.white)
                    picker("Smoking status", SmokingStatus.allCases, \.displayName, $vm.smokingStatus)
                    multiPicker("Joint / orthopedic issues", JointIssue.allCases, \.displayName, $vm.jointIssues)
                }.padding(.top, 8)
            }
            .tint(.white).foregroundStyle(.white)
        }
    }
}

// MARK: - 3 Scheduling

private struct SchedulingSectionView: View {
    @Environment(OnboardingViewModel.self) private var vm
    var body: some View {
        @Bindable var vm = vm
        OnboardingSection(title: "Your schedule", subtitle: "When and how often you'll train.",
                          primaryTitle: "Next", primaryEnabled: vm.isValid(.scheduling),
                          onPrimary: { vm.advance() }) {
            labeledNumber("Session length (minutes)", $vm.sessionLengthText)
            labeledNumber("Sessions per week", $vm.frequencyText)
            multiPicker("Preferred days (optional)", Weekday.allCases, \.displayName, $vm.preferredDays)
            picker("Preferred time of day (optional)", TimeOfDay.allCases, \.displayName, $vm.timeOfDay)
            picker("Reminder method (optional)", ReminderMethod.allCases, \.displayName, $vm.reminderMethod)
        }
    }
}

// MARK: - 4 Mentality

private struct MentalitySectionView: View {
    @Environment(OnboardingViewModel.self) private var vm
    var body: some View {
        @Bindable var vm = vm
        OnboardingSection(title: "What drives you", subtitle: "Helps us tailor your coaching.",
                          primaryTitle: "Next", primaryEnabled: vm.isValid(.mentality),
                          onPrimary: { vm.advance() }) {
            group("What motivates you?") {
                SelectRow(title: "I enjoy the process / workout itself", value: MotivationDriver.process, selection: $vm.motivationDriver)
                SelectRow(title: "I care most about seeing results", value: MotivationDriver.outcome, selection: $vm.motivationDriver)
            }
            group("When you miss a workout, you feel…") {
                SelectRow(title: "Like I broke a habit", value: MissedResponse.habit, selection: $vm.missedResponse)
                SelectRow(title: "Like I'm losing progress", value: MissedResponse.goal, selection: $vm.missedResponse)
            }
            group("Your routine preference") {
                SelectRow(title: "I prefer a fixed routine", value: RoutinePreference.fixed, selection: $vm.routinePreference)
                SelectRow(title: "I prefer variety", value: RoutinePreference.variety, selection: $vm.routinePreference)
            }
        }
    }
}

// MARK: - 5 Equipment

private struct EquipmentSectionView: View {
    @Environment(OnboardingViewModel.self) private var vm
    var body: some View {
        @Bindable var vm = vm
        OnboardingSection(title: "Equipment & facility", subtitle: "Optional — helps future recommendations.",
                          primaryTitle: "Next", primaryEnabled: true, onPrimary: { vm.advance() }) {
            multiPicker("Available equipment", Equipment.allCases, \.displayName, $vm.equipment)
            picker("Indoor / outdoor preference", LocationPreference.allCases, \.displayName, $vm.locationPreference)
        }
    }
}

// MARK: - 6 Goals

private struct GoalsSectionView: View {
    @Environment(OnboardingViewModel.self) private var vm
    var body: some View {
        @Bindable var vm = vm
        OnboardingSection(title: "Your goals", subtitle: "Pick one or more.",
                          primaryTitle: "Next", primaryEnabled: vm.isValid(.goals),
                          onPrimary: { vm.advance() }) {
            multiPicker("Goals", TrainingGoal.allCases, \.displayName, $vm.goals)
        }
    }
}

// MARK: - 7 Device

private struct DeviceSectionView: View {
    @Environment(OnboardingViewModel.self) private var vm
    var body: some View {
        @Bindable var vm = vm
        OnboardingSection(title: "Your devices", subtitle: "Optional.",
                          primaryTitle: "Next", primaryEnabled: true, onPrimary: { vm.advance() }) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Wearable").font(.subheadline).foregroundStyle(.secondary)
                Picker("", selection: $vm.wearable) {
                    ForEach(Wearable.allCases, id: \.self) { Text($0.displayName).tag($0) }
                }.pickerStyle(.segmented)
            }
            multiPicker("Existing tracking apps", TrackingApp.allCases, \.displayName, $vm.trackingApps)
        }
    }
}

// MARK: - 8 Zones preview + Save

private struct ZonesSectionView: View {
    @Environment(OnboardingViewModel.self) private var vm
    @Environment(AuthViewModel.self) private var authVM
    var body: some View {
        OnboardingSection(title: "Your personalized zones",
                          subtitle: "Based on your age and resting heart rate.",
                          primaryTitle: vm.isSaving ? "Saving…" : "Start Training",
                          primaryEnabled: vm.computedZones != nil && !vm.isSaving,
                          onPrimary: { vm.save(userID: authVM.currentUserID ?? "") }) {
            if let z = vm.computedZones {
                VStack(spacing: 0) {
                    ForEach([z.zone1, z.zone2, z.zone3, z.zone4, z.zone5], id: \.number) { zone in
                        ZoneRowView(zone: zone)
                        if zone.number < 5 { Divider().background(Color.white.opacity(0.1)) }
                    }
                }
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

// MARK: - Local helpers

@ViewBuilder
private func labeledNumber(_ label: String, _ text: Binding<String>) -> some View {
    VStack(alignment: .leading, spacing: 6) {
        Text(label).font(.subheadline).foregroundStyle(.secondary)
        TextField("", text: text).keyboardType(.numberPad).textFieldStyle(.roundedBorder)
    }
}

@ViewBuilder
private func group<C: View>(_ title: String, @ViewBuilder _ content: () -> C) -> some View {
    VStack(alignment: .leading, spacing: 8) {
        Text(title).font(.subheadline).foregroundStyle(.secondary)
        content()
    }
}

@ViewBuilder
private func picker<T: Hashable & CaseIterable>(_ title: String, _ cases: [T],
                                                _ name: KeyPath<T, String>, _ sel: Binding<T?>) -> some View {
    VStack(alignment: .leading, spacing: 8) {
        Text(title).font(.subheadline).foregroundStyle(.secondary)
        ForEach(cases, id: \.self) { c in
            SelectRow(title: c[keyPath: name], value: c, selection: sel)
        }
    }
}

@ViewBuilder
private func multiPicker<T: Hashable & CaseIterable>(_ title: String, _ cases: [T],
                                                     _ name: KeyPath<T, String>, _ sel: Binding<Set<T>>) -> some View {
    VStack(alignment: .leading, spacing: 8) {
        Text(title).font(.subheadline).foregroundStyle(.secondary)
        ForEach(cases, id: \.self) { c in
            MultiSelectRow(title: c[keyPath: name], value: c, selection: sel)
        }
    }
}
