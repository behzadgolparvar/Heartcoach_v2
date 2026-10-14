import SwiftUI

/// Apple Watch live workout — Direction D "Broadcast + Trace" (mirrors the iPhone).
/// Phase chip + countdown, big zone-colored HR, zone/target caption, mini zone gauge,
/// and a fresh-message line. Fed by `WorkoutWatchViewModel` over WCSession.
struct WorkoutWatchView: View {
    @Environment(WorkoutWatchViewModel.self) private var viewModel

    var body: some View {
        VStack(spacing: 4) {
            // Phase chip + phase-remaining countdown.
            HStack(spacing: 4) {
                Text(viewModel.phaseName.uppercased())
                    .font(.system(size: 12, weight: .heavy).width(.condensed))
                    .tracking(0.5).foregroundStyle(.white)
                    .padding(.horizontal, 5).padding(.vertical, 3)
                    .background(WWT.red)
                    .lineLimit(1)
                Spacer(minLength: 0)
                if viewModel.phaseRemainingSec > 0 {
                    Text(viewModel.phaseRemainingSec.clock)
                        .font(.system(size: 15, weight: .bold).width(.condensed))
                        .monospacedDigit().foregroundStyle(.white)
                }
            }

            Spacer(minLength: 0)

            // Big HR numeral, colored by current zone.
            Text("\(viewModel.currentHR)")
                .font(.system(size: 88, weight: .heavy).width(.condensed))
                .monospacedDigit()
                .foregroundStyle(WWT.zoneColor(viewModel.currentZone))
                .lineLimit(1).minimumScaleFactor(0.5)
                .accessibilityLabel("\(viewModel.currentHR) beats per minute")

            Text(zoneCaption)
                .font(.system(size: 12, weight: .bold).width(.condensed))
                .tracking(1).foregroundStyle(WWT.secondary)
                .lineLimit(1)

            Spacer(minLength: 0)

            miniGauge

            // Message line (fresh coaching message in its type color, else blank).
            Text(viewModel.lastMessage?.uppercased() ?? "")
                .font(.system(size: 15, weight: .heavy).width(.condensed))
                .foregroundStyle(messageColor)
                .lineLimit(1).minimumScaleFactor(0.7)
                .frame(height: 20)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }

    // MARK: - Mini zone gauge (6 blocks, dimming + target outline)

    private var miniGauge: some View {
        HStack(spacing: 2) {
            ForEach(0..<6, id: \.self) { i in
                RoundedRectangle(cornerRadius: 1)
                    .fill(i == viewModel.currentZone ? WWT.zoneColor(i) : WWT.zoneDim(i))
                    .frame(height: 8)
                    .overlay {
                        if i == viewModel.targetZone, i >= 1 {
                            RoundedRectangle(cornerRadius: 1).strokeBorder(.white, lineWidth: 1.5)
                        }
                    }
            }
        }
    }

    // MARK: - Derived

    private var zoneCaption: String {
        let cz = viewModel.currentZone
        let czStr = (cz >= 1 && cz <= 5) ? "Z\(cz)" : "—"
        if viewModel.targetZone >= 1 { return "\(czStr) · TARGET Z\(viewModel.targetZone)" }
        return czStr
    }

    private var messageColor: Color {
        guard let msg = viewModel.lastMessage else { return .clear }
        let t = msg.lowercased()
        if t.contains("stretch") { return WWT.msgStretch }
        if t.contains("slow") { return WWT.msgSlowDown }
        if t.contains("speed up") || t.contains("faster") || t.contains("push") || t.contains("quicker") { return WWT.msgSpeedUp }
        if t.contains("good") || t.contains("great") || t.contains("keep") || t.contains("steady") { return WWT.msgGood }
        return WWT.red
    }
}

// MARK: - Watch theme (Direction D tokens, local to the Watch target)

private enum WWT {
    static let red       = Color(hex: 0xFF3B30)
    static let secondary = Color(hex: 0x8E8E93)
    static let surface   = Color(hex: 0x1C1C1E)
    static let msgSpeedUp  = Color(hex: 0xFF9F0A)
    static let msgSlowDown = Color(hex: 0x4DACF6)
    static let msgGood     = Color(hex: 0x56D57B)
    static let msgStretch  = Color(hex: 0xC7C7CC)

    private static let surfaceHex: UInt32 = 0x1C1C1E
    private static func zoneHex(_ zone: Int) -> UInt32 {
        switch zone {
        case 1: return 0x46A6EF
        case 2: return 0x56D57B
        case 3: return 0xF2D42D
        case 4: return 0xFF8B00
        case 5: return 0xF93534
        default: return 0x48484A
        }
    }
    static func zoneColor(_ zone: Int) -> Color { Color(hex: zoneHex(zone)) }
    /// Dimmed block = zone color mixed 32% into surface (blend raw hex, no UIColor).
    static func zoneDim(_ zone: Int) -> Color {
        Color(hex: mixHex(zoneHex(zone), surfaceHex, by: 0.68))
    }

    private static func mixHex(_ a: UInt32, _ b: UInt32, by t: Double) -> UInt32 {
        func chan(_ v: UInt32, _ s: UInt32) -> UInt32 {
            let x = Double((v >> s) & 0xFF), y = Double((b >> s) & 0xFF)
            return UInt32((x + (y - x) * t).rounded()) & 0xFF
        }
        return (chan(a, 16) << 16) | (chan(a, 8) << 8) | chan(a, 0)
    }
}

private extension Color {
    init(hex: UInt32) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: 1)
    }
}

private extension Int {
    var clock: String { String(format: "%d:%02d", self / 60, self % 60) }
}
