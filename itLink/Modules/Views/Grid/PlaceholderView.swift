import SwiftUI

struct PlaceholderView: View {
    enum Style {
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

            switch style {
            case .nonLink:
                VStack(spacing: 6) {
                    Image(systemName: "textformat")
                        .font(.title2)
                    Text("Не ссылка")
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                }
                .foregroundStyle(.secondary)
                .padding(4)

            case .nonImage:
                VStack(spacing: 6) {
                    Image(systemName: "link")
                        .font(.title2)
                    Text("Не изображение")
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                }
                .foregroundStyle(.secondary)
                .padding(4)

            case .loading:
                ArcSpinnerView(size: 22, lineWidth: 2)

            case .failed:
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title3)
                    if let onRetry {
                        Button("Повторить", action: onRetry)
                            .font(.caption)
                            .buttonStyle(.bordered)
                    }
                }
                .foregroundStyle(.secondary)
                .padding(4)
            }
        }
    }
}
