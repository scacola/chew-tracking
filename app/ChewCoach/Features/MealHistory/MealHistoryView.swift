import SwiftUI
import SwiftData

struct MealHistoryView: View {
    @Environment(\.appEnvironment) private var env
    @State private var meals: [MealSession] = []

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("기록")
                .task {
                    reload()
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if meals.isEmpty {
            VStack(spacing: Spacing.md) {
                Image(systemName: "tray")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                Text("아직 기록이 없어요. 첫 식사를 함께해 주세요.")
                    .font(.bodyR)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                ForEach(grouped, id: \.0) { day, dayMeals in
                    Section(header: Text(formatDay(day))) {
                        ForEach(dayMeals, id: \.id) { meal in
                            NavigationLink {
                                MealDetailView(meal: meal)
                            } label: {
                                MealHistoryRow(meal: meal)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }

    private var grouped: [(Date, [MealSession])] {
        let cal = Calendar.current
        let dict = Dictionary(grouping: meals) { cal.startOfDay(for: $0.startedAt) }
        return dict
            .map { ($0.key, $0.value.sorted(by: { $0.startedAt > $1.startedAt })) }
            .sorted(by: { $0.0 > $1.0 })
    }

    private func reload() {
        meals = env.mealRepository.recentMeals(days: 365)
    }

    private func formatDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 (E)"
        return formatter.string(from: date)
    }
}

private struct MealHistoryRow: View {
    let meal: MealSession

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(timeText)
                    .font(.bodyR)
                Text((meal.durationSec ?? 0).formattedDurationKR)
                    .font(.calloutR)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let comfort = meal.comfortReport {
                Text(emoji(for: comfort.score))
                    .font(.system(size: 24))
                    .accessibilityLabel("위 컨디션 \(comfort.score)점")
            }
        }
        .padding(.vertical, Spacing.xs)
    }

    private var timeText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "a h:mm"
        return formatter.string(from: meal.startedAt)
    }

    private func emoji(for score: Int) -> String {
        ["😞", "🙁", "😐", "🙂", "😊"][max(0, min(4, score - 1))]
    }
}

#Preview {
    MealHistoryView()
        .environment(\.appEnvironment, AppEnvironment.preview())
}
