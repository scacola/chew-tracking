import SwiftUI

struct MealResultCard: View {
    let meal: MealSession
    let calibrationDurationSec: Int?
    let coachingMessage: String?
    let onTapDetail: () -> Void
    let onComfortReported: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(headerTitle)
                .font(.title3R)
                .foregroundStyle(.secondary)

            Text((meal.durationSec ?? 0).formattedDurationKR)
                .font(.timerDisplay)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .accessibilityLabel("식사 시간 \((meal.durationSec ?? 0).formattedDurationKR)")

            if let comparison = calibrationComparisonText {
                Text(comparison)
                    .font(.calloutR)
                    .foregroundStyle(.secondary)
            }

            if let message = coachingMessage {
                Text(message)
                    .font(.bodyR)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()

            ComfortSelfReportRow(current: meal.comfortReport?.score, onSelect: onComfortReported)

            Button("자세히 보기", action: onTapDetail)
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
        }
        .padding(Spacing.lg)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.card)
                .strokeBorder(Color(uiColor: .separator), lineWidth: 0.5)
        )
        .accessibilityElement(children: .contain)
    }

    private var headerTitle: String {
        let hour = Calendar.current.component(.hour, from: meal.startedAt)
        let when: String
        if hour < 5 { when = "새벽 식사 결과" }
        else if hour < 11 { when = "오늘 아침 결과" }
        else if hour < 15 { when = "오늘 점심 결과" }
        else if hour < 18 { when = "오늘 오후 결과" }
        else if hour < 21 { when = "오늘 저녁 결과" }
        else { when = "오늘 야식 결과" }
        return when
    }

    private var calibrationComparisonText: String? {
        guard let cal = calibrationDurationSec, let dur = meal.durationSec else { return nil }
        let delta = dur - cal
        if abs(delta) < 30 { return "캘리브레이션과 비슷한 페이스" }
        let minutes = abs(delta) / 60
        let seconds = abs(delta) % 60
        // 부호 의미를 결과 언어로 표현: + → 더 천천히 (차분), - → 더 빨리 (급함)
        let amount: String = minutes > 0 ? "\(minutes)분" : "\(seconds)초"
        return delta > 0
            ? "캘리브레이션보다 \(amount) 더 차분히"
            : "캘리브레이션보다 \(amount) 더 빨리"
    }
}

#Preview {
    let meal = MealSession(startedAt: Date())
    meal.durationSec = 11 * 60 + 32
    meal.chewCount = 350
    meal.avgCPM = 30
    return MealResultCard(
        meal: meal,
        calibrationDurationSec: 9 * 60,
        coachingMessage: "어제보다 60초 차분해졌어요. 잘하고 계세요.",
        onTapDetail: {},
        onComfortReported: { _ in }
    )
    .padding()
}
