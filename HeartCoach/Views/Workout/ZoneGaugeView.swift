import SwiftUI
import HeartRateCoachCore

/// Broadcast-style zone gauge (Direction D) — 6 proportional blocks (below-Z1 … Z5),
/// a target bracket, a sliding HR marker, and a target/delta caption. Replaces ZoneRingView.
struct ZoneGaugeView: View {
    let currentHR: Int          // 0 = no signal
    let currentZone: Int        // 0 (below) … 5
    let targetZone: Int?        // nil during recovery/cooldown
    let zones: HRZones
    /// Suppresses the bracket and swaps the caption during walk/stretch phases.
    var recoveryMode: RecoveryMode = .none

    enum RecoveryMode { case none, walk, stretch }

    // Domain + block layout (units sum to 75).
    private let domainLo = 110.0, domainHi = 190.0
    private let units: [CGFloat] = [12, 13, 12, 13, 12, 13]   // index 0 = below-Z1
    private let spacing: CGFloat = 3

    var body: some View {
        VStack(spacing: 10) {
            GeometryReader { geo in
                let w = geo.size.width
                let widths = blockWidths(trackWidth: w)
                let xs = blockOrigins(widths)
                ZStack(alignment: .topLeading) {
                    // Blocks
                    HStack(spacing: spacing) {
                        ForEach(0..<6, id: \.self) { i in
                            ZStack {
                                Rectangle().fill(i == currentZone ? WT.zoneColor(i) : WT.zoneDim(i))
                                if i >= 1 {
                                    Text("Z\(i)")
                                        .font(WT.cond(13, .heavy)).tracking(0.5)
                                        .foregroundStyle(i == currentZone ? .black : WT.textSecondary)
                                }
                            }
                            .frame(width: widths[i], height: 30)
                        }
                    }
                    // Target bracket
                    if let tz = targetZone, recoveryMode == .none, tz >= 1, tz <= 5 {
                        Rectangle()
                            .strokeBorder(Color.white, lineWidth: 2)
                            .frame(width: widths[tz] + 6, height: 36)
                            .offset(x: xs[tz] - 3, y: -3)
                            .animation(.easeInOut(duration: 0.4), value: tz)
                    }
                    // Marker (downward triangle), tip 13pt above the track top
                    DownTriangle()
                        .fill(Color.white)
                        .frame(width: 14, height: 10)
                        .offset(x: markerX(w) - 7, y: -23)
                        .animation(.easeOut(duration: 0.5), value: currentHR)
                }
            }
            .frame(height: 30)

            captionRow
        }
        .padding(.top, 10)
    }

    // MARK: Caption

    private var captionRow: some View {
        HStack(spacing: 10) {
            if let tz = targetZone, let band = zones.zone(number: tz) {
                Text("TARGET Z\(tz) · \(band.min)–\(band.max)")
                    .foregroundStyle(WT.zoneColor(tz))
            } else {
                Text(recoveryMode == .stretch ? "COOL DOWN" : "RECOVERY")
                    .foregroundStyle(WT.textSecondary)
            }
            Spacer()
            Text(status.text).foregroundStyle(status.color)
        }
        .font(WT.body(12, .semibold)).tracking(1.2)
        .lineLimit(1)
    }

    private var status: (text: String, color: Color) {
        switch recoveryMode {
        case .walk: return ("WALK IT OUT", WT.textSecondary)
        case .stretch: return ("STRETCH", WT.textSecondary)
        case .none:
            guard currentHR > 0, let tz = targetZone, let band = zones.zone(number: tz) else {
                return ("—", WT.textSecondary)
            }
            if currentHR < band.min { return ("\(band.min - currentHR) BELOW", WT.msgSpeedUp) }
            if currentHR > band.max { return ("\(currentHR - band.max) ABOVE", WT.msgSlowDown) }
            return ("IN ZONE", WT.success)
        }
    }

    // MARK: Geometry

    private func blockWidths(trackWidth w: CGFloat) -> [CGFloat] {
        let avail = w - spacing * 5
        let total = units.reduce(0, +)
        return units.map { avail * $0 / total }
    }
    private func blockOrigins(_ widths: [CGFloat]) -> [CGFloat] {
        var xs: [CGFloat] = []; var x: CGFloat = 0
        for (i, wdt) in widths.enumerated() { xs.append(x); x += wdt + (i < 5 ? spacing : 0) }
        return xs
    }
    private func markerX(_ w: CGFloat) -> CGFloat {
        let f = min(0.99, max(0.01, (Double(currentHR) - domainLo) / (domainHi - domainLo)))
        return CGFloat(f) * w
    }
}

private struct DownTriangle: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        p.addLine(to: CGPoint(x: r.midX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}
