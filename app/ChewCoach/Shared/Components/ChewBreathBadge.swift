import SwiftUI

struct ChewBreathBadge: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var scale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: Spacing.sm) {
            Circle()
                .fill(Color.brandPrimary.opacity(0.3))
                .frame(width: 80, height: 80)
                .scaleEffect(scale)
                .accessibilityHidden(true)

            Text("차분히 드시고 있어요")
                .font(.calloutR)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("차분히 드시고 있어요")
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                scale = 1.2
            }
        }
    }
}

#Preview {
    ChewBreathBadge()
        .padding()
}
