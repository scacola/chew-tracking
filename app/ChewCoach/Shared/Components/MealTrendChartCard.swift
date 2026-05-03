import SwiftUI
import Charts

struct MealTrendDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let durationSec: Int
}

struct MealTrendChartCard: View {
    let points: [MealTrendDataPoint]
    let calibrationDurationSec: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("최근 7일 추이")
                .font(.headlineS)

            if points.isEmpty {
                Text("아직 일주일치 데이터가 모이지 않았어요. 더 함께해 주세요.")
                    .font(.calloutR)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 120, alignment: .center)
            } else {
                Chart {
                    ForEach(points) { point in
                        BarMark(
                            x: .value("날짜", point.date, unit: .day),
                            y: .value("분", Double(point.durationSec) / 60.0)
                        )
                        .foregroundStyle(Color.brandPrimary)
                        .cornerRadius(4)
                    }
                    if let cal = calibrationDurationSec {
                        RuleMark(y: .value("캘리브레이션", Double(cal) / 60.0))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                            .foregroundStyle(.secondary)
                            .annotation(position: .top, alignment: .leading) {
                                Text("캘리브 \(cal / 60)분")
                                    .font(.caption2R)
                                    .foregroundStyle(.secondary)
                            }
                    }
                }
                .frame(height: 160)
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisValueLabel()
                        AxisGridLine()
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisValueLabel(format: .dateTime.weekday(.narrow))
                        AxisTick()
                    }
                }
                .accessibilityLabel("최근 7일 식사 시간 추이")
            }
        }
        .padding(Spacing.lg)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
    }
}

#Preview {
    let cal = Calendar.current
    let points = (0..<7).map { i in
        MealTrendDataPoint(
            date: cal.date(byAdding: .day, value: -i, to: Date()) ?? Date(),
            durationSec: 8 * 60 + Int.random(in: -120...300)
        )
    }
    return MealTrendChartCard(points: points, calibrationDurationSec: 9 * 60)
        .padding()
}
