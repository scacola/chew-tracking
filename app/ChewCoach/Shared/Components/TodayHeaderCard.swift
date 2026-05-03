import SwiftUI

struct TodayHeaderCard: View {
    let totalDurationSec: Int
    let mealsCount: Int
    let comparisonText: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("오늘")
                .font(.caption1R)
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                Text("\(totalDurationSec / 60)분")
                    .font(.title1S)
                Text("· 식사 \(mealsCount)회")
                    .font(.calloutR)
                    .foregroundStyle(.secondary)
            }
            if let comparisonText {
                Text(comparisonText)
                    .font(.calloutR)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    TodayHeaderCard(totalDurationSec: 11 * 60 + 32, mealsCount: 1, comparisonText: "+2분")
        .padding()
}
