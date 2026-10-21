import SwiftUI

struct ArcSpinnerView: View {
    var size: CGFloat = 24
    var lineWidth: CGFloat = 2.5
    var color: Color = .secondary
    var duration: TimeInterval = 0.9
    var arcFraction: CGFloat = 0.28

    var body: some View {
        TimelineView(.animation) { context in
            let elapsed = context.date.timeIntervalSinceReferenceDate
            let progress = elapsed.truncatingRemainder(dividingBy: duration) / duration
            let degrees = progress * 360

            Circle()
                .trim(from: 0, to: arcFraction)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(degrees))
        }
        .accessibilityLabel("Загрузка")
    }
}

#Preview {
    ZStack {
        Color(.secondarySystemBackground)
        ArcSpinnerView()
    }
    .frame(width: 80, height: 80)
    .preferredColorScheme(.dark)
}
