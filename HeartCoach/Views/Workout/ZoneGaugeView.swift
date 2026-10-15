import SwiftUI
import HeartRateCoachCore

/// Broadcast-style zone gauge (Direction D) — 6 proportional blocks (below-Z1 … Z5),
/// a bracket + marker on the CURRENT zone (where you are), and a correction arrow
/// pointing to the target zone when you're off it. Target is named in the caption.
struct ZoneGaugeView: View {
    let currentHR: Int          // 0 = no signal
    let currentZone: Int        // 0 (below) … 5
    let targetZone: Int?        // nil during recovery/cooldown
    let zones: HRZones
    /// Suppresses the arrow and swaps the caption during walk/stretch phases.
    var recoveryMode: RecoveryMode = .none

    enum RecoveryMode { case none, walk, stretch }

    // Block layout (relative widths over the 110–190 bpm domain; index 0 = below-Z1).
    private let units: [CGFloat] = [12, 13, 12, 13, 12, 13]
    private let spacing: CGFloat = 3

    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                let widths = blockWidths(trackWidth: geo.size.width)
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
                    // Bracket on the CURRENT zone block (where you are). Hidden on no signal.
                    if currentHR > 0 {
                        let z = min(5, max(0, currentZone))
                        Rectangle()
                            .strokeBorder(Color.white, lineWidth: 2)
                            .frame(width: widths[z] + 6, height: 36)
                            .offset(x: xs[z] - 3, y: -3)
                            .animation(.easeInOut(duration: 0.4), value: currentZone)
                    }
                    // Marker — slides within the current block by HR position, tip above the track.
                    DownTriangle()
                        .fill(Color.white)
                        .frame(width: 14, height: 10)
                        .offset(x: markerX(widths, xs) - 7, y: -12)
                        .animation(.easeInOut(duration: 0.5), value: currentHR)
                }
            }
            .frame(height: 30)

            // Correction arrow: current block → target block (keeps its height when hidden).
            GeometryReader { geo in
                let widths = blockWidths(trackWidth: geo.size.width)
                let xs = blockOrigins(widths)
                if let a = arrowInfo(widths: widths, xs: xs) {
                    CorrectionArrow(from: a.from, to: a.to, color: a.color)
                        .transition(.opacity)
                }
            }
            .frame(height: 18)
            .animation(.easeInOut(duration: 0.2), value: currentZone)

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

    /// Marker x: within the current block, proportional to HR's position in that block's bpm span.
    private func markerX(_ widths: [CGFloat], _ xs: [CGFloat]) -> CGFloat {
        let z = min(5, max(0, currentZone))
        guard currentHR > 0 else { return xs[z] + widths[z] / 2 }
        let (lo, hi) = zoneDomain(z)
        let frac = min(0.94, max(0.06, (Double(currentHR) - lo) / max(1, hi - lo)))
        return xs[z] + widths[z] * CGFloat(frac)
    }

    /// bpm span of a block (below-Z1 uses 110…Z1.min).
    private func zoneDomain(_ z: Int) -> (lo: Double, hi: Double) {
        if z == 0 { return (110, Double(zones.zone(number: 1)?.min ?? 120)) }
        if let band = zones.zone(number: z) { return (Double(band.min), Double(band.max)) }
        return (110, 190)
    }

    private func arrowInfo(widths: [CGFloat], xs: [CGFloat]) -> (from: CGFloat, to: CGFloat, color: Color)? {
        guard recoveryMode == .none, currentHR > 0,
              let tz = targetZone, tz >= 1, tz <= 5, let band = zones.zone(number: tz),
              currentHR < band.min || currentHR > band.max else { return nil }
        let from = markerX(widths, xs)
        let to = xs[tz] + widths[tz] / 2
        let color = currentHR < band.min ? WT.msgSpeedUp : WT.msgSlowDown
        return (from, to, color)
    }
}

/// Flowing dashed arrow from the current block to the target block (Direction D v2).
struct CorrectionArrow: View {
    let from: CGFloat
    let to: CGFloat
    var scale: CGFloat = 1
    let color: Color

    var body: some View {
        TimelineView(.animation) { tl in
            Canvas { ctx, size in
                let t = tl.date.timeIntervalSinceReferenceDate
                let y = size.height / 2
                let dir: CGFloat = (to >= from) ? 1 : -1
                let dotR = 4 * scale, headLen = 11 * scale, headH = 12 * scale
                let nudge = CGFloat(sin(t / 0.9 * .pi)) * 3 * scale      // 3pt fwd/back
                let tipX = to + dir * nudge

                let dot = CGRect(x: from - dotR, y: y - dotR, width: dotR * 2, height: dotR * 2)
                ctx.fill(Path(ellipseIn: dot), with: .color(color))

                var shaft = Path()
                shaft.move(to: CGPoint(x: from + dir * 6 * scale, y: y))
                shaft.addLine(to: CGPoint(x: tipX - dir * headLen, y: y))
                let phase = -CGFloat(t.truncatingRemainder(dividingBy: 0.5) / 0.5) * 8 * scale * dir
                ctx.stroke(shaft, with: .color(color),
                           style: StrokeStyle(lineWidth: 2 * scale, lineCap: .round,
                                              dash: [4.4 * scale, 3.6 * scale], dashPhase: phase))

                var head = Path()
                head.move(to: CGPoint(x: tipX, y: y))
                head.addLine(to: CGPoint(x: tipX - dir * headLen, y: y - headH / 2))
                head.addLine(to: CGPoint(x: tipX - dir * headLen, y: y + headH / 2))
                head.closeSubpath()
                ctx.fill(head, with: .color(color))
            }
        }
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
