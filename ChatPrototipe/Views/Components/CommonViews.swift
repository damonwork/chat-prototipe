import SwiftUI

struct ErrorBannerView: View {
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(text)
                .lineLimit(2)
        }
        .font(.caption)
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.14))
        .foregroundStyle(.red)
    }
}

struct EmptyStateView: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 34))
                .foregroundStyle(.secondary)
            Text(title).font(.headline)
            Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
        }
    }
}

struct AvatarView: View {
    var body: some View {
        Circle()
            .fill(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: 34, height: 34)
            .overlay(Image(systemName: "sparkles").foregroundStyle(.white))
    }
}

struct LoadingDotsView: View {
    @State private var animate = false

    var body: some View {
        HStack(spacing: 6) {
            dot(0)
            dot(0.2)
            dot(0.4)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }

    private func dot(_ delay: Double) -> some View {
        Circle()
            .fill(Color.secondary)
            .frame(width: 6, height: 6)
            .scaleEffect(animate ? 1 : 0.4)
            .opacity(animate ? 1 : 0.35)
            .animation(.easeInOut(duration: 0.6).repeatForever().delay(delay), value: animate)
    }
}
