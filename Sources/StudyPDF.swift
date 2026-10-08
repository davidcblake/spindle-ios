import CoreTransferable
import PPCore
import PPDesign
import SwiftUI
import UniformTypeIdentifiers

/// A study as a PDF, for the share sheet's Print and Save to Files.
///
/// The web app's Print / Save PDF opens the browser's print dialog. The
/// iPhone's share sheet offers both printing and saving a PDF, so handing it a
/// PDF covers the same ground with nothing but SwiftUI and Core Graphics.
///
/// Made only when somebody taps Share, not every time the screen draws.
struct StudyDocument: Transferable, Sendable {
    let reference: String
    let volume: String
    let date: Date
    let study: Study
    let hidden: Set<StudySection>

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .pdf) { document in
            SentTransferredFile(try await document.pdf())
        }
    }

    /// Lays the study onto US Letter pages, the way the web app's print styles
    /// do: no section is split across two pages unless it is taller than a page.
    @MainActor
    func pdf() throws -> URL {
        let page = CGSize(width: 612, height: 792)
        let margin: CGFloat = 48
        let width = page.width - margin * 2
        let name = reference.replacingOccurrences(of: "/", with: "-")
        let url = URL.temporaryDirectory.appending(path: "\(name).pdf")

        var mediaBox = CGRect(origin: .zero, size: page)
        guard let pdf = CGContext(url as CFURL, mediaBox: &mediaBox, nil) else {
            throw CouldNotMakeThePDF(logMessage: "Core Graphics would not open a PDF at \(url.path())")
        }

        var top = margin
        pdf.beginPDFPage(nil)
        for block in blocks {
            let renderer = ImageRenderer(
                content: block
                    .frame(width: width)
                    .ppTheme(.spindle)
                    .environment(\.colorScheme, .light)
            )
            renderer.render { size, draw in
                if top + size.height > page.height - margin, top > margin {
                    pdf.endPDFPage()
                    pdf.beginPDFPage(nil)
                    top = margin
                }
                pdf.saveGState()
                // PDF pages count up from the bottom; the layout counts down.
                pdf.translateBy(x: margin, y: page.height - top - size.height)
                draw(pdf)
                pdf.restoreGState()
                top += size.height + PPSpacing.medium
            }
        }
        pdf.endPDFPage()
        pdf.closePDF()
        return url
    }

    @MainActor
    private var blocks: [AnyView] {
        [AnyView(StudyPlate(reference: reference, volume: volume, date: date))]
            + StudySection.allCases
                .filter { !hidden.contains($0) }
                .map { AnyView(StudySectionView(section: $0, study: study)) }
            + [AnyView(StudyFooter())]
    }
}

struct CouldNotMakeThePDF: PPError {
    var userMessage: String {
        "Spindle couldn't make a PDF of this study."
    }

    let logMessage: String
}
