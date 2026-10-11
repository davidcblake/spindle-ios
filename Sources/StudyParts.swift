import PPDesign
import SwiftUI

// The pieces of a study, as separate views so the same layout draws on the
// screen and onto the pages of a PDF (`StudyPDF`).

/// The top of a study: which volume and when, then the passage in scripture's
/// serif, over a hairline. Plain ink on the page, so it prints as it shows.
struct StudyPlate: View {
    @Environment(\.ppTheme) private var theme
    let reference: String
    let volume: String
    let date: Date

    var body: some View {
        VStack(alignment: .leading, spacing: PPSpacing.small) {
            Text("\(volume) · \(date.formatted(date: .long, time: .omitted))")
                .ppText(.caption)
                .fontWeight(.semibold)
                .textCase(.uppercase)
                .tracking(0.8)
                .foregroundStyle(theme.textSecondary)
            Text(reference)
                .ppText(.scriptureTitle)
                .foregroundStyle(theme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, PPSpacing.medium)
        .overlay(alignment: .bottom) {
            Rectangle().fill(theme.separator).frame(height: 1)
        }
        .accessibilityElement(children: .combine)
    }
}

/// One of the eleven sections, laid out as the web app lays it out.
struct StudySectionView: View {
    @Environment(\.ppTheme) private var theme
    let section: StudySection
    let study: Study

    var body: some View {
        switch section {
        case .placement:
            titled(section) { paragraph(study.placement) }
        case .background:
            titled(section) { paragraph(study.background) }
        case .people:
            titled(section) {
                ForEach(study.people, id: \.self) { person in
                    item(name: person.name, detail: person.who, elsewhereLabel: "Elsewhere in scripture", elsewhere: person.elsewhere)
                }
            }
        case .principles:
            titled(section) {
                ForEach(study.principles, id: \.self) { principle in
                    item(name: principle.principle, detail: principle.explanation, elsewhereLabel: "Also taught in", elsewhere: principle.elsewhere)
                }
            }
        case .patterns:
            titled(section) {
                ForEach(study.patterns, id: \.self) { pattern in
                    item(name: pattern.pattern, detail: pattern.meaning, elsewhereLabel: "Echoes", elsewhere: pattern.echoes)
                }
            }
        case .christ:
            titled(section) {
                paragraph(study.christ)
                    .padding(PPSpacing.medium)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(theme.accentSoft, in: RoundedRectangle(cornerRadius: PPRadius.medium))
            }
        case .conference:
            // Studies prepared before this section existed have no talks; the
            // web app leaves the section out rather than showing it empty.
            if !study.conference.isEmpty {
                titled(section) {
                    ForEach(study.conference, id: \.self) { talk in
                        VStack(alignment: .leading, spacing: PPSpacing.extraSmall) {
                            Text(talk.speaker).ppText(.cardTitle)
                            paragraph(talk.point)
                            Link("“\(talk.talk)” · \(talk.session)", destination: GospelLibrary.searchURL(speaker: talk.speaker, talk: talk.talk))
                                .ppText(.caption)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
        case .crossRefs:
            titled(section) {
                ForEach(study.crossRefs, id: \.self) { crossReference in
                    VStack(alignment: .leading, spacing: PPSpacing.extraSmall) {
                        Text(GospelLibrary.linked(crossReference.ref))
                            .ppText(.cardTitle)
                        paragraph(crossReference.note)
                    }
                }
            }
        case .reflection:
            titled(section) {
                ForEach(Array(study.reflection.enumerated()), id: \.offset) { number, question in
                    HStack(alignment: .firstTextBaseline, spacing: PPSpacing.small) {
                        Text("\(number + 1).")
                            .ppText(.body)
                            .monospacedDigit()
                            .foregroundStyle(theme.textSecondary)
                        paragraph(question)
                    }
                }
            }
        case .invitation:
            titled(section) { paragraph(study.invitation) }
        case .anchor:
            titled(section) {
                VStack(spacing: PPSpacing.small) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(selectionRing)
                        .accessibilityHidden(true)
                    Text(GospelLibrary.linked(study.anchor))
                        .ppText(.scripture)
                        .multilineTextAlignment(.center)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(PPSpacing.large)
                .background(verseBlock, in: RoundedRectangle(cornerRadius: PPRadius.large))
            }
        }
    }

    private func titled<Content: View>(_ section: StudySection, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: PPSpacing.small) {
            Text(section.title.uppercased())
                .ppText(.caption)
                .fontWeight(.bold)
                .tracking(0.8)
                .foregroundStyle(theme.accent)
                .accessibilityAddTraits(.isHeader)
            content()
        }
    }

    private func paragraph(_ text: String) -> some View {
        Text(GospelLibrary.linked(text))
            .ppText(.body)
            .foregroundStyle(theme.textPrimary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func item(name: String, detail: String, elsewhereLabel: String, elsewhere: String) -> some View {
        VStack(alignment: .leading, spacing: PPSpacing.extraSmall) {
            Text(name).ppText(.cardTitle)
            paragraph(detail)
            VStack(alignment: .leading, spacing: 2) {
                Text(elsewhereLabel)
                    .ppText(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(theme.textSecondary)
                Text(GospelLibrary.linked(elsewhere))
                    .ppText(.caption)
                    .foregroundStyle(theme.textSecondary)
            }
        }
    }
}

/// The verse the web app puts at the foot of every page.
struct StudyFooter: View {
    @Environment(\.ppTheme) private var theme

    var body: some View {
        VStack(spacing: PPSpacing.extraSmall) {
            Text("“And we talk of Christ, we rejoice in Christ, we preach of Christ, we prophesy of Christ… that our children may know to what source they may look for a remission of their sins.”")
                .italic()
            Text(GospelLibrary.linked("2 Nephi 25:26"))
        }
        .ppText(.caption)
        .foregroundStyle(theme.textSecondary)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.top, PPSpacing.medium)
    }
}
