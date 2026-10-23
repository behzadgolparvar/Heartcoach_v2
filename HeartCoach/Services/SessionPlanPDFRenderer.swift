import Foundation
import UIKit
import PDFKit
import HeartRateCoachCore

/// Renders the client session-plan PDF (§K / FR-11). Behind a protocol.
protocol SessionPlanRendering: AnyObject {
    /// Returns a temp file URL to the generated PDF, or nil on failure.
    func render(stage: TrainingStage, blocks: [SessionPlanBlock], completionNote: String) -> URL?
}

/// On-device renderer (no dependency). Draws a branded, paginated session-plan table.
final class SessionPlanPDFRenderer: SessionPlanRendering {

    private let pageW: CGFloat = 612, pageH: CGFloat = 792, margin: CGFloat = 40
    private let pad: CGFloat = 7
    private let brand = UIColor(red: 0xFF/255, green: 0x3B/255, blue: 0x30/255, alpha: 1)   // #FF3B30
    private let altRow = UIColor(white: 0.965, alpha: 1)
    private let border = UIColor(white: 0.86, alpha: 1)

    /// Table columns: (header, width). Widths sum to the content width (pageW − 2·margin).
    private let columns: [(title: String, width: CGFloat)] = [
        ("Sessions", 64), ("Type", 82), ("Focus / What to Expect", 178), ("Intensity", 130), ("Duration", 78)
    ]

    func render(stage: TrainingStage, blocks: [SessionPlanBlock], completionNote: String) -> URL? {
        let contentW = pageW - 2 * margin
        var colX: [CGFloat] = []
        var cx = margin
        for col in columns { colX.append(cx); cx += col.width }

        let format = UIGraphicsPDFRendererFormat()
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageW, height: pageH), format: format)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("HeartCoach-\(stage.rawValue)-plan.pdf")

        let title = "\(stage.displayName) — Your Session Plan"
        let miss = "Missed a day? A 15-minute minimum walk (8 fast / 7 slow) keeps your momentum and prevents setbacks — it doesn't count toward your 60 sessions."

        do {
            try renderer.writePDF(to: url) { ctx in
                let cg = ctx.cgContext
                var y: CGFloat = margin

                func drawHeaderRow() {
                    let h: CGFloat = 26
                    cg.setFillColor(brand.cgColor)
                    cg.fill(CGRect(x: margin, y: y, width: contentW, height: h))
                    for (i, col) in columns.enumerated() {
                        drawCell(col.title,
                                 in: CGRect(x: colX[i] + pad, y: y + 7, width: col.width - 2 * pad, height: h - 10),
                                 font: .boldSystemFont(ofSize: 10.5), color: .white)
                    }
                    y += h
                }

                func newPage() { ctx.beginPage(); y = margin; drawHeaderRow() }

                ctx.beginPage()
                // Intro block
                y = draw(title, at: y, width: contentW, font: .boldSystemFont(ofSize: 22), color: brand)
                y += 8
                y = draw(completionNote, at: y, width: contentW, font: .systemFont(ofSize: 11), color: .black)
                y += 4
                y = draw(miss, at: y, width: contentW, font: .italicSystemFont(ofSize: 9.5), color: UIColor(white: 0.4, alpha: 1))
                y += 16

                drawHeaderRow()

                for (idx, block) in blocks.enumerated() {
                    let range = block.startSession == block.endSession
                        ? "\(block.startSession)" : "\(block.startSession)–\(block.endSession)"
                    let cells = [range, block.type.displayName, block.focus, block.intensity, "\(block.durationMin) min"]

                    // Row height = tallest wrapped cell + vertical padding.
                    var bodyH: CGFloat = 0
                    for (i, text) in cells.enumerated() {
                        bodyH = max(bodyH, textHeight(text, width: columns[i].width - 2 * pad, font: .systemFont(ofSize: 10.5)))
                    }
                    let rowH = bodyH + 12

                    if y + rowH > pageH - margin { newPage() }

                    if idx % 2 == 1 {
                        cg.setFillColor(altRow.cgColor)
                        cg.fill(CGRect(x: margin, y: y, width: contentW, height: rowH))
                    }
                    for (i, text) in cells.enumerated() {
                        drawCell(text,
                                 in: CGRect(x: colX[i] + pad, y: y + 6, width: columns[i].width - 2 * pad, height: bodyH),
                                 font: i == 0 ? .boldSystemFont(ofSize: 10.5) : .systemFont(ofSize: 10.5),
                                 color: .black)
                    }
                    cg.setStrokeColor(border.cgColor)
                    cg.setLineWidth(0.5)
                    cg.move(to: CGPoint(x: margin, y: y + rowH))
                    cg.addLine(to: CGPoint(x: margin + contentW, y: y + rowH))
                    cg.strokePath()
                    y += rowH
                }
            }
            return url
        } catch {
            return nil   // best-effort; no health values logged
        }
    }

    // MARK: - Drawing helpers

    /// Draws full-width left-aligned text at `y`, returns the new y.
    private func draw(_ text: String, at y: CGFloat, width: CGFloat, font: UIFont, color: UIColor) -> CGFloat {
        let h = textHeight(text, width: width, font: font)
        drawCell(text, in: CGRect(x: margin, y: y, width: width, height: h), font: font, color: color)
        return y + h
    }

    private func drawCell(_ text: String, in rect: CGRect, font: UIFont, color: UIColor) {
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        (text as NSString).draw(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attrs, context: nil)
    }

    private func textHeight(_ text: String, width: CGFloat, font: UIFont) -> CGFloat {
        let b = (text as NSString).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font], context: nil)
        return ceil(b.height)
    }
}
