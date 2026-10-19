import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

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
                    .font(WWT.cond(12, .heavy))
                    .tracking(0.5).foregroundStyle(.white)
                    .padding(.horizontal, 5).padding(.vertical, 3)
                    .background(WWT.red)
                    .lineLimit(1)
                Spacer(minLength: 0)
                if viewModel.phaseRemainingSec > 0 {
                    Text(viewModel.phaseRemainingSec.clock)
                        .font(WWT.cond(15, .bold))
                        .monospacedDigit().foregroundStyle(.white)
                }
            }

            Spacer(minLength: 0)

            // Beating heart + big HR numeral (heart mirrors the iPhone; balance spacer
            // keeps the number centered).
            HStack(spacing: 6) {
                PulsingHeart(bpm: viewModel.currentHR,
                             color: viewModel.currentZone >= 1 ? WWT.zoneColor(viewModel.currentZone) : WWT.red)
                    .frame(width: 28, height: 28)
                Text("\(viewModel.currentHR)")
                    .font(WWT.cond(88, .heavy))
                    .monospacedDigit()
                    // Zone color in Z1–Z5; white when below/above a zone (but HR present);
                    // gray only for no signal — matches the iPhone's always-visible numeral.
                    .foregroundStyle(viewModel.currentHR > 0 && !(1...5).contains(viewModel.currentZone)
                                     ? .white : WWT.zoneColor(viewModel.currentZone))
                    .lineLimit(1).minimumScaleFactor(0.5)
                    .accessibilityLabel("\(viewModel.currentHR) beats per minute")
                Spacer(minLength: 2)
                // Persistent status pill on the right (mirrors the iPhone).
                WatchStatusPill(stat: heroStat)
            }

            Text(zoneCaption)
                .font(WWT.cond(12, .bold))
                .tracking(1).foregroundStyle(WWT.secondary)
                .lineLimit(1)

            Spacer(minLength: 0)

            miniGauge

            // Message line (fresh coaching message in its type color, else blank).
            Text(viewModel.lastMessage?.uppercased() ?? "")
                .font(WWT.cond(15, .heavy))
                .foregroundStyle(messageColor)
                .lineLimit(1).minimumScaleFactor(0.7)
                .frame(height: 20)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        // Tick the phase countdown locally every second (the phone only pushes
        // state ~every 5s to spare WCSession); a fresh packet re-syncs the value.
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            if viewModel.isWorkoutActive, viewModel.phaseRemainingSec > 0 {
                viewModel.phaseRemainingSec -= 1
            }
        }
    }

    // MARK: - Mini zone gauge (6 blocks, dimming + target outline)
    // A caret above the current block shows "where you are"; the white box is the target.

    private var miniGauge: some View {
        VStack(spacing: 2) {
            // Caret slides WITHIN the current block by HR position (mirrors the iPhone),
            // using the zone bounds the phone sent at workout start. Hidden on no signal.
            GeometryReader { geo in
                if viewModel.currentHR > 0 {
                    let blockW = (geo.size.width - 2 * 5) / 6     // 6 equal blocks, spacing 2
                    let cz = min(5, max(0, viewModel.currentZone))
                    let x = CGFloat(cz) * (blockW + 2) + blockW * caretFrac()
                    DownCaret()
                        .fill(Color.white)
                        .frame(width: 9, height: 5)
                        .offset(x: x - 4.5)
                        .animation(.easeInOut(duration: 0.5), value: viewModel.currentHR)
                        .animation(.easeInOut(duration: 0.4), value: viewModel.currentZone)
                }
            }
            .frame(height: 5)
            // Blocks
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
    }

    /// Caret position within the current block (0.06…0.94), from live HR vs the
    /// current block's bpm span. Falls back to center until the zone table arrives.
    private func caretFrac() -> CGFloat {
        guard let (lo, hi) = viewModel.blockDomain(viewModel.currentZone), hi > lo else { return 0.5 }
        let f = Double(viewModel.currentHR - lo) / Double(hi - lo)
        return CGFloat(min(0.94, max(0.06, f)))
    }

    // MARK: - Derived

    private var zoneCaption: String {
        let target = viewModel.targetZone >= 1 ? " · TARGET Z\(viewModel.targetZone)" : ""
        let here: String
        if viewModel.currentHR <= 0 {
            here = "—"                              // no signal
        } else {
            switch viewModel.currentZone {
            case 1...5: here = "Z\(viewModel.currentZone)"
            case 6:     here = "ABOVE"              // over HRmax
            default:    here = "BELOW"              // under Zone 1
            }
        }
        return here + target
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

    /// At-a-glance status beside the HR number: below / in / above the target zone,
    /// plus muted REST / NO HR. `big` carries the bpm gap to close (uses the zone table).
    private var heroStat: WHStat {
        let mutedFill = WWT.surface, mutedFg = WWT.secondary
        if viewModel.currentHR <= 0 { return WHStat(big: nil, label: "NO\nHR", fill: mutedFill, fg: mutedFg) }
        let tz = viewModel.targetZone
        guard tz >= 1 else { return WHStat(big: nil, label: "REST", fill: mutedFill, fg: mutedFg) }
        guard let band = viewModel.blockDomain(tz) else {
            return WHStat(big: nil, label: "—", fill: mutedFill, fg: mutedFg)   // bounds not in yet
        }
        let tint = WWT.zoneColor(tz)   // match the target zone's gauge-box color
        let hr = viewModel.currentHR
        if hr < band.lo { return WHStat(big: "\(band.lo - hr)", label: "BELOW", fill: tint, fg: .black) }
        if hr > band.hi { return WHStat(big: "\(hr - band.hi)", label: "ABOVE", fill: tint, fg: .black) }
        return WHStat(big: nil, label: "IN\nZONE", fill: tint, fg: .black)
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
    /// Barlow Condensed (ExtraBold for heavy, else Bold) with a system-condensed fallback.
    static func cond(_ size: CGFloat, _ weight: Font.Weight) -> Font {
        let name = (weight == .heavy || weight == .black) ? "BarlowCondensed-ExtraBold" : "BarlowCondensed-Bold"
        #if canImport(UIKit)
        if UIFont(name: name, size: size) != nil { return .custom(name, size: size) }
        #endif
        return .system(size: size, weight: weight).width(.condensed)
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

/// Status shown beside the HR number: an optional bpm gap (`big`) + a short label,
/// on a colored fill. Mirrors the iPhone `HeroStat`.
private struct WHStat: Equatable {
    let big: String?
    let label: String
    let fill: Color
    let fg: Color
}

/// Compact vertical status pill (delta over word) beside the Watch HR numeral.
private struct WatchStatusPill: View {
    let stat: WHStat

    var body: some View {
        VStack(spacing: 0) {
            if let big = stat.big {
                Text(big).font(WWT.cond(19, .heavy)).monospacedDigit().lineLimit(1)
            }
            Text(stat.label)
                .font(WWT.cond(stat.big == nil ? 11 : 8.5, .heavy))
                .tracking(0.2).multilineTextAlignment(.center).lineLimit(2)
        }
        .foregroundStyle(stat.fg)
        .minimumScaleFactor(0.6)
        .frame(width: 32, height: 40)
        .background(RoundedRectangle(cornerRadius: 7).fill(stat.fill))
        .animation(.easeInOut(duration: 0.3), value: stat)
    }
}

/// A heart that "beats" once per heartbeat (period = 60/bpm), tinted by zone.
/// Dim and still when there's no signal. Mirrors the iPhone hero heart.
private struct PulsingHeart: View {
    let bpm: Int
    let color: Color
    @State private var beat = 0

    var body: some View {
        Image(systemName: "heart.fill")
            .resizable().scaledToFit()
            .foregroundStyle(bpm > 0 ? color : WWT.secondary)
            .symbolEffect(.bounce, value: beat)
            .task(id: bpm) {
                guard bpm > 0 else { return }
                let period = min(1.5, max(0.34, 60.0 / Double(bpm)))
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: UInt64(period * 1_000_000_000))
                    beat &+= 1
                }
            }
    }
}

/// Small downward triangle marking the current zone above the gauge.
private struct DownCaret: Shape {
    func path(in r: CGRect) -> Path {
        let w: CGFloat = 9
        let cx = r.midX
        var p = Path()
        p.move(to: CGPoint(x: cx - w / 2, y: r.minY))
        p.addLine(to: CGPoint(x: cx + w / 2, y: r.minY))
        p.addLine(to: CGPoint(x: cx, y: r.maxY))
        p.closeSubpath()
        return p
    }
}
