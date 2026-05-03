import SwiftUI

struct HonestyPledgeView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.brandPrimary)
                    .accessibilityHidden(true)

                Text("정직성 약속")
                    .font(.title1S)

                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text("우리는 약속해요:")
                        .font(.headlineS)
                    pledgeRow("식사 시간을 추정으로 보여드려요 (정확도 ±15%)")
                    pledgeRow("패턴 인사이트를 제공해요")
                    pledgeRow("행동 변화를 도와드려요")
                }
                .padding(Spacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(uiColor: .secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))

                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text("우리는 약속하지 않아요:")
                        .font(.headlineS)
                    notPledgeRow("위염 치료 / 의료적 효과")
                    notPledgeRow("칼로리·음식 종류 자동 인식")
                    notPledgeRow("100% 정확한 측정")
                }
                .padding(Spacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(uiColor: .secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))

                Text("데이터는 모두 기기 안에서만 처리되고, 7일 후 자동으로 정리해요.")
                    .font(.calloutR)
                    .foregroundStyle(.secondary)
            }
            .padding(Spacing.lg)
        }
    }

    private func pledgeRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.positive)
                .accessibilityHidden(true)
            Text(text)
                .font(.bodyR)
        }
    }

    private func notPledgeRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text(text)
                .font(.bodyR)
        }
    }
}

#Preview {
    HonestyPledgeView()
}
