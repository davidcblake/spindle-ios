import PPDesign
import SwiftUI

/// The Liahona, shown while a study or a plan is being prepared: "a round ball
/// of curious workmanship … and within the ball were two spindles; and the one
/// pointed the way" (1 Nephi 16:10).
///
/// With no `progress` the pointing spindle searches — swings, overshoots, and
/// settles on a direction — and then starts again, which is honest when nobody
/// knows how long the wait will be. With a `progress` the brass ring fills and
/// the spindle points at the leading edge of it, for a wait that can say how
/// far along it is. The study server reports no progress today, so every
/// caller passes none; the second form is here so the screen does not have to
/// change when it does.
///
/// Still, not animated, when the person has asked for reduced motion.
struct Liahona: View {
    @Environment(\.ppTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// From 0 to 1, or nil while nobody knows.
    var progress: Double?
    var size: CGFloat = 96

    var body: some View {
        ZStack {
            Circle()
                .stroke(progress == nil ? AnyShapeStyle(selectionRing) : AnyShapeStyle(selectionRing.opacity(0.35)), lineWidth: lineWidth)
            if let progress {
                Circle()
                    .trim(from: 0, to: clamped(progress))
                    .stroke(theme.accent, style: StrokeStyle(lineWidth: lineWidth * 1.4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            drifting
            pointing
            Circle()
                .fill(selectionRing)
                .frame(width: size * 0.08, height: size * 0.08)
        }
        .padding(lineWidth)
        .frame(width: size, height: size)
        .accessibilityElement()
        .accessibilityLabel(accessibilityLabel)
    }

    private var lineWidth: CGFloat { max(1.5, size * 0.025) }

    /// The spindle that points the way.
    @ViewBuilder
    private var pointing: some View {
        if let progress {
            Needle(color: theme.accent)
                .rotationEffect(.degrees(clamped(progress) * 360))
                .animation(.easeInOut(duration: 0.4), value: progress)
        } else if reduceMotion {
            Needle(color: theme.accent)
                .rotationEffect(.degrees(32))
        } else {
            KeyframeAnimator(initialValue: -70.0, repeating: true) { angle in
                Needle(color: theme.accent)
                    .rotationEffect(.degrees(angle))
            } keyframes: { _ in
                KeyframeTrack {
                    CubicKeyframe(38, duration: 1.0)
                    CubicKeyframe(-24, duration: 0.85)
                    CubicKeyframe(14, duration: 0.85)
                    CubicKeyframe(-6, duration: 0.7)
                    CubicKeyframe(32, duration: 0.6)
                    // Holds on the way it found before searching again.
                    LinearKeyframe(32, duration: 2.5)
                    CubicKeyframe(-70, duration: 0.5)
                }
            }
        }
    }

    /// The second spindle, which drifts slowly and points nowhere in particular.
    @ViewBuilder
    private var drifting: some View {
        let line = Capsule()
            .fill(selectionRing.opacity(0.8))
            .frame(width: lineWidth, height: size * 0.24)
            .offset(y: -size * 0.12)
        if reduceMotion || progress != nil {
            line.rotationEffect(.degrees(160))
        } else {
            KeyframeAnimator(initialValue: 150.0, repeating: true) { angle in
                line.rotationEffect(.degrees(angle))
            } keyframes: { _ in
                KeyframeTrack {
                    CubicKeyframe(200, duration: 4.5)
                    CubicKeyframe(150, duration: 4.5)
                }
            }
        }
    }

    private var accessibilityLabel: String {
        if let progress {
            "Preparing, \(Int((clamped(progress) * 100).rounded())) percent done"
        } else {
            "Preparing"
        }
    }

    private func clamped(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}

/// The pointing spindle: a slim diamond from the centre to near the ring.
private struct Needle: View {
    let color: PPColor

    var body: some View {
        NeedleShape()
            .fill(color)
    }
}

private struct NeedleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY + height * 0.16))
        path.addLine(to: CGPoint(x: rect.midX + width * 0.04, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.midY + height * 0.06))
        path.addLine(to: CGPoint(x: rect.midX - width * 0.04, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

/// What the screen says while the Liahona turns: what is being prepared, and
/// the verse about how the pointers worked.
struct PreparingView: View {
    @Environment(\.ppTheme) private var theme
    /// The passage or plan being prepared.
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: PPSpacing.large) {
            Spacer()
            Liahona()
            VStack(spacing: PPSpacing.small) {
                Text(title)
                    .ppText(.scriptureTitle)
                    .foregroundStyle(theme.textPrimary)
                    .multilineTextAlignment(.center)
                Text(message)
                    .ppText(.body)
                    .foregroundStyle(theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .accessibilityElement(children: .combine)
            Spacer()
            VStack(alignment: .leading, spacing: PPSpacing.small) {
                Text("“The pointers which were in the ball … did work according to the faith and diligence and heed which we did give unto them.”")
                    .ppText(.scripture)
                    .italic()
                    .foregroundStyle(theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(GospelLibrary.linked("1 Nephi 16:28"))
                    .ppText(.caption)
                    .foregroundStyle(theme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(PPSpacing.large)
            .background(theme.surface, in: RoundedRectangle(cornerRadius: PPRadius.large))
            .overlay(RoundedRectangle(cornerRadius: PPRadius.large).strokeBorder(theme.separator))
        }
        .padding(PPSpacing.screenMargin)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.background)
    }
}
