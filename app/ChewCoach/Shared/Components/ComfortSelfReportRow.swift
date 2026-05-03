import SwiftUI

struct ComfortSelfReportRow: View {
    let current: Int?
    let onSelect: (Int) -> Void

    @State private var showToast = false

    private let emojis = ["😞", "🙁", "😐", "🙂", "😊"]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("지금 위 컨디션 어떠세요?")
                .font(.calloutR)
                .foregroundStyle(.secondary)

            HStack(spacing: Spacing.md) {
                ForEach(Array(emojis.enumerated()), id: \.offset) { idx, emoji in
                    let score = idx + 1
                    Button {
                        onSelect(score)
                        showToast = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            showToast = false
                        }
                    } label: {
                        Text(emoji)
                            .font(.system(size: 32))
                            .opacity(current == score ? 1.0 : 0.6)
                            .frame(width: HitArea.min, height: HitArea.min)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(score)점, \(label(for: score))")
                }
            }

            if showToast {
                Text("기록했어요. 고마워요.")
                    .font(.caption1R)
                    .foregroundStyle(.secondary)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showToast)
    }

    private func label(for score: Int) -> String {
        ["매우 안 좋음", "안 좋음", "보통", "좋음", "매우 좋음"][score - 1]
    }
}

#Preview {
    ComfortSelfReportRow(current: 3, onSelect: { _ in })
        .padding()
}
