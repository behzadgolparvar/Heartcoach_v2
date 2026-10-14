import SwiftUI
import HeartRateCoachCore

/// Live HR-trace panel (Direction D): the whole session's target-zone bands with the
/// user's HR line drawn over them, a dashed HRmax line, and a "now" cursor + dot.
struct HRTraceView: View {
    let proto: FoundationProtocol
    let zones: HRZones
    let restingHR: Int
    let maxHR: Int
    let hrTrace: [(second: Int, hr: Int)]
    let currentSecond: Int
    let currentZone: Int
    /// Round label (e.g. "ROUND 4 / 15") and total time remaining.
    let roundLabel: String
    let remainingSec: Int

    private let yLo = 95.0, yHi = 195.0

    var body: some View {
        VStack(spacing: 0) {
            Canvas { ctx, size in draw(ctx, size) }
                .frame(height: 150)
                .padding(.top, 10)

            // Caption row
            HStack {
                Text(roundLabel).lineLimit(1).truncationMode(.tail)
                Spacer()
                Text("\(remainingSec.msClock) TO GO")
            }
            .font(WT.body(11, .semibold)).tracking(1.4)
            .foregroundStyle(WT.textSecondary)
            .padding(.horizontal, 12)
            .padding(.top, 6).padding(.bottom, 2)
        }
        .background(WT.panel)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(WT.panelStroke, lineWidth: 1))
    }

    // MARK: - Drawing

    private var total: Int { max(1, proto.phases.compactMap { $0.durationSec }.reduce(0, +)) }

    private func draw(_ ctx: GraphicsContext, _ size: CGSize) {
        let w = size.width, h = size.height
        func xFor(_ sec: Double) -> Double { Double(sec) / Double(total) * w }
        func yFor(_ bpm: Double) -> Double { h - (min(yHi, max(yLo, bpm)) - yLo) / (yHi - yLo) * h }

        // Zone / recovery bands per segment.
        var start = 0
        for phase in proto.phases {
            guard let dur = phase.durationSec, dur > 0 else { continue }
            let x0 = xFor(Double(start)), x1 = xFor(Double(start + dur))
            let rectW = max(0, x1 - x0 - 0.6)
            let completed = (start + dur) <= currentSecond
            if let target = phase.target, phase.kind.isScored {
                let band = target.bpmRange(restingHR: restingHR, maxHR: maxHR)
                let lo = Double(band.lowerBound), hi = Double(band.upperBound)
                let op = completed ? 0.22 : 0.45
                // Split the target box across the zone bands it spans, so a block that
                // reaches into Z4 shows orange up top (not a single midpoint color).
                for n in 1...5 {
                    guard let z = zones.zone(number: n) else { continue }
                    let oLo = max(lo, Double(z.min)), oHi = min(hi, Double(z.max))
                    guard oHi > oLo else { continue }
                    let r = CGRect(x: x0, y: yFor(oHi), width: rectW, height: yFor(oLo) - yFor(oHi))
                    ctx.fill(Path(r), with: .color(WT.zoneColor(n).opacity(op)))
                }
            } else {
                let yTop = yFor(135), yBot = yFor(110)
                let r = CGRect(x: x0, y: yTop, width: rectW, height: yBot - yTop)
                ctx.fill(Path(r), with: .color(Color.white.opacity(0.07)))
            }
            start += dur
        }

        // HRmax dashed line.
        let yMax = yFor(Double(maxHR))
        var maxPath = Path(); maxPath.move(to: CGPoint(x: 0, y: yMax)); maxPath.addLine(to: CGPoint(x: w, y: yMax))
        ctx.stroke(maxPath, with: .color(WT.redText), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
        ctx.draw(Text("MAX \(maxHR)").font(WT.cond(9, .semibold)).foregroundColor(WT.redText),
                 at: CGPoint(x: w - 6, y: yMax - 7), anchor: .topTrailing)

        // HR line.
        if hrTrace.count > 1 {
            var line = Path()
            for (i, p) in hrTrace.enumerated() {
                let pt = CGPoint(x: xFor(Double(p.second)), y: yFor(Double(p.hr)))
                if i == 0 { line.move(to: pt) } else { line.addLine(to: pt) }
            }
            ctx.stroke(line, with: .color(.white), style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
        }

        // Now cursor + dot.
        let nx = xFor(Double(currentSecond))
        var cursor = Path(); cursor.move(to: CGPoint(x: nx, y: 0)); cursor.addLine(to: CGPoint(x: nx, y: h))
        ctx.stroke(cursor, with: .color(Color.white.opacity(0.35)), lineWidth: 1)
        if let last = hrTrace.last {
            let dot = CGRect(x: nx - 4.5, y: yFor(Double(last.hr)) - 4.5, width: 9, height: 9)
            ctx.fill(Path(ellipseIn: dot), with: .color(WT.zoneColor(currentZone)))
            ctx.stroke(Path(ellipseIn: dot), with: .color(Color(hex: 0x08090A)), lineWidth: 2)
        }
    }
}
