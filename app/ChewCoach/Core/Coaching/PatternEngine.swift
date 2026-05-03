import Foundation

/// UX §5.3 — V1 패턴 추출 (fastest weekday / lunch vs dinner / quick → comfort).
public struct PatternEngine: Sendable {
    public init() {}

    public func extract(weekMeals: [MealSummary], comfortReports: [ComfortSummary]) -> PatternResult? {
        guard weekMeals.count >= 5 else { return nil }
        var result = PatternResult()
        let cal = Calendar.current

        // Fastest weekday — 평균이 전체보다 20% 짧은 요일
        let byWeekday = Dictionary(grouping: weekMeals) { cal.component(.weekday, from: $0.startedAt) }
        let totalAvg = weekMeals.avgDurationSec ?? 0
        if totalAvg > 0 {
            for (weekday, meals) in byWeekday {
                guard let avg = meals.avgDurationSec, avg < totalAvg else { continue }
                let percent = Int(Double(totalAvg - avg) / Double(totalAvg) * 100)
                if percent >= 20 {
                    result.fastestWeekday = (name: weekdayName(weekday), percentFaster: percent)
                    break
                }
            }
        }

        // Lunch vs dinner
        let lunch = weekMeals.filter { hour(of: $0.startedAt) >= 11 && hour(of: $0.startedAt) < 15 }
        let dinner = weekMeals.filter { hour(of: $0.startedAt) >= 17 && hour(of: $0.startedAt) < 22 }
        if let lunchAvg = lunch.avgDurationSec, let dinnerAvg = dinner.avgDurationSec, dinnerAvg > lunchAvg + 60 {
            result.lunchVsDinnerDeltaMin = (dinnerAvg - lunchAvg) / 60
        }

        // Quick meal → comfort
        let comfortByMeal = Dictionary(uniqueKeysWithValues: comfortReports.compactMap { r -> (UUID, Int)? in
            guard let id = r.mealId else { return nil }
            return (id, r.score)
        })
        let quickMealComforts = weekMeals.filter { $0.durationSec < 300 }.compactMap { comfortByMeal[$0.id] }
        let allComforts = weekMeals.compactMap { comfortByMeal[$0.id] }
        if !quickMealComforts.isEmpty && !allComforts.isEmpty {
            let qAvg = Double(quickMealComforts.reduce(0, +)) / Double(quickMealComforts.count)
            let aAvg = Double(allComforts.reduce(0, +)) / Double(allComforts.count)
            let delta = aAvg - qAvg
            if delta >= 0.5 {
                result.quickMealComfortDelta = (delta * 10).rounded() / 10
            }
        }

        // Video mode faster
        let videoMeals = weekMeals.filter(\.isVideoMode)
        let nonVideoMeals = weekMeals.filter { !$0.isVideoMode }
        if let videoAvg = videoMeals.avgDurationSec,
           let nonAvg = nonVideoMeals.avgDurationSec,
           nonAvg > videoAvg + 60 {
            result.videoModeFasterMin = (nonAvg - videoAvg) / 60
        }

        // Morning shorter
        let morning = weekMeals.filter { hour(of: $0.startedAt) >= 5 && hour(of: $0.startedAt) < 11 }
        let other = weekMeals.filter { hour(of: $0.startedAt) >= 11 }
        if let morningAvg = morning.avgDurationSec,
           let otherAvg = other.avgDurationSec,
           otherAvg > morningAvg + 60 {
            result.morningShorterMin = (otherAvg - morningAvg) / 60
        }

        // Consistency improving — 표준편차 감소 (단순화: 직전 3일 vs 그 전 3일)
        let durations = weekMeals.sorted { $0.startedAt < $1.startedAt }.map { Double($0.durationSec) }
        if durations.count >= 6 {
            let half = durations.count / 2
            let first = Array(durations.prefix(half))
            let last = Array(durations.suffix(half))
            let firstStd = standardDeviation(first)
            let lastStd = standardDeviation(last)
            if lastStd < firstStd - 30 {
                result.consistencyImproving = true
            }
        }

        // Late dinner quick
        let lateDinner = weekMeals.filter { hour(of: $0.startedAt) >= 21 }
        let normalDinner = weekMeals.filter { hour(of: $0.startedAt) >= 17 && hour(of: $0.startedAt) < 21 }
        if let lateAvg = lateDinner.avgDurationSec,
           let normalAvg = normalDinner.avgDurationSec, normalAvg > 0,
           lateAvg < normalAvg {
            let percent = Int(Double(normalAvg - lateAvg) / Double(normalAvg) * 100)
            if percent >= 15 {
                result.lateDinnerPercentFaster = percent
            }
        }

        return result
    }

    private func hour(of date: Date) -> Int {
        Calendar.current.component(.hour, from: date)
    }

    private func weekdayName(_ index: Int) -> String {
        // Calendar.weekday: 1=Sunday
        let names = ["일요일", "월요일", "화요일", "수요일", "목요일", "금요일", "토요일"]
        let normalized = max(1, min(7, index)) - 1
        return names[normalized]
    }

    private func standardDeviation(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        return sqrt(variance)
    }
}
