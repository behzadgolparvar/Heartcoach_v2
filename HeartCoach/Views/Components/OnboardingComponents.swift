import SwiftUI

/// Numeric field with a metric/imperial unit toggle (weight, height).
struct MeasurementField: View {
    let label: String
    @Binding var text: String
    @Binding var imperial: Bool
    let metricUnit: String
    let imperialUnit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.subheadline).foregroundStyle(.secondary)
            HStack(spacing: 10) {
                TextField("", text: $text)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                Picker("", selection: $imperial) {
                    Text(metricUnit).tag(false)
                    Text(imperialUnit).tag(true)
                }
                .pickerStyle(.segmented)
                .frame(width: 120)
            }
        }
    }
}

/// Small progress dots for the onboarding pager.
struct ProgressDots: View {
    let current: Int
    let total: Int
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { i in
                Circle()
                    .fill(i <= current ? Color.red : Color.gray.opacity(0.4))
                    .frame(width: 8, height: 8)
            }
        }
    }
}

/// Single-select option row.
struct SelectRow<T: Hashable>: View {
    let title: String
    let value: T
    @Binding var selection: T?
    var body: some View {
        Button {
            selection = value
        } label: {
            HStack {
                Text(title).foregroundStyle(.white)
                Spacer()
                if selection == value {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.red)
                }
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 10)
                .fill(selection == value ? Color.red.opacity(0.15) : Color.white.opacity(0.06)))
        }
        .buttonStyle(.plain)
    }
}

/// Multi-select option row (toggles membership in a Set).
struct MultiSelectRow<T: Hashable>: View {
    let title: String
    let value: T
    @Binding var selection: Set<T>
    var body: some View {
        Button {
            if selection.contains(value) { selection.remove(value) } else { selection.insert(value) }
        } label: {
            HStack {
                Text(title).foregroundStyle(.white)
                Spacer()
                Image(systemName: selection.contains(value) ? "checkmark.square.fill" : "square")
                    .foregroundStyle(selection.contains(value) ? .red : .secondary)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 10)
                .fill(selection.contains(value) ? Color.red.opacity(0.15) : Color.white.opacity(0.06)))
        }
        .buttonStyle(.plain)
    }
}

/// Section scaffold: title + scrollable content + a bottom Next/primary button.
struct OnboardingSection<Content: View>: View {
    let title: String
    let subtitle: String?
    let primaryTitle: String
    let primaryEnabled: Bool
    let onPrimary: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(title).font(.title.bold()).foregroundStyle(.white)
                    if let subtitle {
                        Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
                    }
                    content()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)
                .hideKeyboardOnTap()
            }
            .dismissableKeyboard()
            Button(primaryTitle, action: onPrimary)
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!primaryEnabled)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
        }
        .background(Color.black)
    }
}
