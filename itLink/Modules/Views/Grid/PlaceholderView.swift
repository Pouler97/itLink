import SwiftUI

struct PlaceholderView: View {
    enum Style: Equatable {
        case nonLink
        case nonImage
        case loading
        case failed
    }

    let style: Style
    var onRetry: (() -> Void)?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.secondarySystemBackground))

            ZStack {
                switch style {
                case .nonLink:
                    caption(icon: "textformat", title: "Не ссылка")
                case .nonImage:
                    caption(icon: "link", title: "Не изображение")
                case .loading:
                    ArcSpinnerView(size: 22, lineWidth: 2)
                        .transition(contentTransition)
                case .failed:
                    caption(icon: "arrow.clockwise", title: "Повторить")
                        .transition(contentTransition)
                }
            }
        }
        .animation(.easeInOut(duration: 0.32), value: style)
        .contentShape(Rectangle())
        .onTapGesture {
            if style == .failed {
                onRetry?()
            }
        }
    }

    private var contentTransition: AnyTransition {
        .opacity.combined(with: .scale(scale: 0.86))
    }

    private func caption(icon: String, title: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
            Text(title)
                .font(.caption2)
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(.secondary)
        .padding(4)
    }
}
