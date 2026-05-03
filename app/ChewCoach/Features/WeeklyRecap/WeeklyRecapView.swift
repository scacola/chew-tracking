import SwiftUI

struct WeeklyRecapData: Sendable {
    let thisWeekAvgMin: Int
    let lastWeekAvgMin: Int?
    let fastestDay: String?
    let mealCount: Int
    let discoveryMessage: String?
}

struct WeeklyRecapView: View {
    let data: WeeklyRecapData
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack {
                Text("이번 주 회고")
                    .font(.title1S)
                Spacer()
                Button("닫기") { onDismiss() }
                    .buttonStyle(.bordered)
            }

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("평균 식사 시간")
                    .font(.calloutR)
                    .foregroundStyle(.secondary)
                Text("\(data.thisWeekAvgMin)분")
                    .font(.displayLarge)
                if let last = data.lastWeekAvgMin {
                    Text(comparison(last: last))
                        .font(.calloutR)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))

            if let message = data.discoveryMessage {
                InsightCard(title: "이번 주의 발견", message: message, category: .insight)
            }

            if let fastest = data.fastestDay {
                Text("가장 빠른 식사는 \(fastest)이었어요.")
                    .font(.calloutR)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(Spacing.lg)
    }

    private func comparison(last: Int) -> String {
        let delta = data.thisWeekAvgMin - last
        if delta == 0 { return "지난 주와 비슷한 페이스를 유지하셨어요." }
        if delta > 0 { return "지난 주보다 \(delta)분 더 차분해졌어요." }
        return "지난 주보다 \(-delta)분 더 빨라졌어요. 다음 주는 한 입씩만 천천히 가볼까요?"
    }
}

#Preview {
    WeeklyRecapView(
        data: WeeklyRecapData(
            thisWeekAvgMin: 11,
            lastWeekAvgMin: 9,
            fastestDay: "수요일",
            mealCount: 14,
            discoveryMessage: "5분 미만으로 드신 다음 위 컨디션이 평균 0.5점 낮아요."
        ),
        onDismiss: {}
    )
}
