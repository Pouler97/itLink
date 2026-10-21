import SwiftUI

struct LiquidGlassCircle: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular.interactive(), in: .circle)
        } else {
            content.background(.ultraThinMaterial, in: Circle())
        }
    }
}

struct GlassCircleIcon: View {
    let systemName: String
    var opticalOffset: CGSize = .zero

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.primary)
            .offset(x: opticalOffset.width, y: opticalOffset.height)
            .frame(width: 44, height: 44)
            .contentShape(Circle())
            .modifier(LiquidGlassCircle())
    }
}

struct GlassIconButton: View {
    let systemName: String
    var accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            GlassCircleIcon(systemName: systemName)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}
