import SwiftUI

struct InsightCard: View {
    let title: String
    let message: String
    let category: CoachingMessage.Category

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: iconName)
                    .foregroundStyle(Color.brandPrimary)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.headlineS)
            }
            Text(message)
                .font(.bodyR)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
        .accessibilityElement(children: .combine)
    }

    private var iconName: String {
        switch category {
        case .encouragement: return "leaf.fill"
        case .insight: return "sparkles"
        case .awareness: return "hand.raised.fill"
        case .celebration: return "party.popper.fill"
        case .weekly: return "calendar"
        }
    }
}

#Preview {
    InsightCard(
        title: "오늘의 발견",
        message: "5분 미만으로 드신 다음 위 컨디션이 평균 0.5점 낮아요. 패턴이 보이기 시작했어요.",
        category: .insight
    )
    .padding()
}
