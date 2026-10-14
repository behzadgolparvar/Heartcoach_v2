import Foundation
import UIKit
import PDFKit
import HeartRateCoachCore

/// Renders the client session-plan PDF (§K / FR-11). Behind a protocol.
protocol SessionPlanRendering: AnyObject {
    /// Returns a temp file URL to the generated PDF, or nil on failure.
    func render(stage: TrainingStage, rows: [SessionPlanRow], completionNote: String) -> URL?
}

/// PDFKit on-device renderer (no dependency). Simple paginated table.
final class SessionPlanPDFRenderer: SessionPlanRendering {

    func render(stage: TrainingStage, rows: [SessionPlanRow], completionNote: String) -> URL? {
        let pageW: CGFloat = 612, pageH: CGFloat = 792, margin: CGFloat = 40
        let format = UIGraphicsPDFRendererFormat()
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageW, height: pageH), format: format)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("HeartCoach-\(stage.rawValue)-plan.pdf")

        let title = "\(stage.displayName) — Your Session Plan"
        let intro = completionNote
        let miss = "Missed a day? A 15-minute minimum walk (8 fast / 7 slow) keeps your momentum and prevents setbacks — it doesn't count toward your 60 sessions."
        let colKey = "Columns: Session # · Type · Focus / What to Expect · Intensity · Duration"

        do {
            try renderer.writePDF(to: url) { ctx in
                var y: CGFloat = margin
                func newPage() { ctx.beginPage(); y = margin }
                ctx.beginPage()

                y = draw(title, at: y, margin: margin, width: pageW - 2*margin, font: .boldSystemFont(ofSize: 20))
                y += 6
                y = draw(intro, at: y, margin: margin, width: pageW - 2*margin, font: .systemFont(ofSize: 12))
                y += 4
                y = draw(colKey, at: y, margin: margin, width: pageW - 2*margin, font: .systemFont(ofSize: 10))
                y += 2
                y = draw(miss, at: y, margin: margin, width: pageW - 2*margin, font: .italicSystemFont(ofSize: 10))
                y += 10

                for row in rows {
                    if y > pageH - margin - 16 { newPage() }
                    let line = "\(row.sessionNumber).  \(row.type.displayName)  ·  \(row.focus)  ·  \(row.intensity)  ·  \(row.durationMin) min"
                    y = draw(line, at: y, margin: margin, width: pageW - 2*margin, font: .systemFont(ofSize: 11))
                    y += 2
                }
            }
            return url
        } catch {
            return nil   // best-effort; no health values logged
        }
    }

    private func draw(_ text: String, at y: CGFloat, margin: CGFloat, width: CGFloat, font: UIFont) -> CGFloat {
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor.black]
        let rect = CGRect(x: margin, y: y, width: width, height: .greatestFiniteMagnitude)
        let bounding = (text as NSString).boundingRect(with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attrs, context: nil)
        (text as NSString).draw(with: CGRect(x: margin, y: y, width: width, height: bounding.height),
            options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attrs, context: nil)
        _ = rect
        return y + bounding.height
    }
}
