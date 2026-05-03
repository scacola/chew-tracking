import Foundation

public struct TriggerEvaluator: Sendable {
    public init() {}

    public func evaluate(_ trigger: TriggerCondition, context: CoachingContext) -> Bool {
        switch trigger {
        case .avgDurationIncreased(let minSec):
            guard let today = context.todayMeals.avgDurationSec,
                  let yest = context.yesterdayMeals.avgDurationSec else { return false }
            return today >= yest + minSec

        case .steadyPace:
            guard let cal = context.calibration,
                  let avg = context.todayMeals.avgDurationSec else { return false }
            return abs(avg - cal.calibrationDurationSec) <= 60

        case .firstLongMealToday(let minSec):
            return context.todayMeals.contains { $0.durationSec >= minSec }

        case .afterQuickMeal:
            guard let last = context.lastMeal else { return false }
            return last.durationSec < 300   // <5분

        case .consistencyDays(let min):
            // 최근 n일 모두 식사 1+ 회 + 평균 8분 이상
            return consecutiveLongDays(weekMeals: context.weekMeals, now: context.now) >= min

        case .calibrationJustCompleted:
            return context.isCalibrationJustCompleted

        case .videoModeSteady:
            // 오늘 비디오 모드 식사가 평균과 비슷하거나 길게
            let videoMeals = context.todayMeals.filter(\.isVideoMode)
            guard let videoAvg = videoMeals.avgDurationSec,
                  let totalAvg = context.todayMeals.avgDurationSec else { return false }
            return videoAvg >= totalAvg

        case .breakfastLogged:
            return context.todayMeals.contains { isMorning(date: $0.startedAt) }

        case .recoveryAfterQuick:
            // 오늘 마지막 식사가 직전 식사보다 +60s 이상
            guard context.todayMeals.count >= 2 else { return false }
            let sorted = context.todayMeals.sorted { $0.startedAt < $1.startedAt }
            let last = sorted[sorted.count - 1]
            let prev = sorted[sorted.count - 2]
            return last.durationSec >= prev.durationSec + 60 && prev.durationSec < 300

        case .weekendCalm:
            let cal = Calendar.current
            let weekday = cal.component(.weekday, from: context.now)
            guard weekday == 1 || weekday == 7 else { return false } // 일/토
            guard let weekendAvg = context.todayMeals.avgDurationSec else { return false }
            let weekdayMeals = context.weekMeals.filter {
                let w = cal.component(.weekday, from: $0.startedAt)
                return w >= 2 && w <= 6
            }
            guard let weekdayAvg = weekdayMeals.avgDurationSec else { return false }
            return weekendAvg > weekdayAvg

        case .patternFastestWeekday:
            return context.pattern?.fastestWeekday != nil

        case .patternLunchVsDinner:
            return context.pattern?.lunchVsDinnerDeltaMin != nil

        case .patternQuickMealToComfort:
            return context.pattern?.quickMealComfortDelta != nil

        case .patternVideoModeFaster:
            return context.pattern?.videoModeFasterMin != nil

        case .patternMorningShorter:
            return context.pattern?.morningShorterMin != nil

        case .patternConsistency:
            return context.pattern?.consistencyImproving == true

        case .patternLateDinnerQuick:
            return context.pattern?.lateDinnerPercentFaster != nil

        case .cpmTrendImproved:
            // 이번 주 평균 cpm < 전주 cpm (느려졌으면 차분해진 것)
            let cpms = context.weekMeals.compactMap(\.avgCPM)
            return cpms.count >= 5 // 데이터 충분 시만 트리거 (실제 비교는 InsightGenerator)

        case .firstPatternEmerging:
            return context.weekMeals.count >= 3 && context.pattern == nil

        case .calibrationDrift:
            guard let cal = context.calibration,
                  let weekAvg = context.weekMeals.avgDurationSec else { return false }
            return abs(weekAvg - cal.calibrationDurationSec) >= 60

        case .duringMeal5min:
            return context.isDuringMealAt5min

        case .quickMealJustEnded:
            guard let last = context.lastMeal else { return false }
            return last.durationSec < 300 && context.now.timeIntervalSince(last.startedAt) < 600

        case .videoContextQuick:
            guard let last = context.lastMeal else { return false }
            return last.isVideoMode && last.durationSec < 600

        case .streakBroken:
            // 어제 8분 이상 + 오늘 짧음
            guard let yAvg = context.yesterdayMeals.avgDurationSec,
                  let tAvg = context.todayMeals.avgDurationSec else { return false }
            return yAvg >= 480 && tAvg < 300

        case .noComfortRecently:
            return context.comfortReports.isEmpty && context.weekMeals.count >= 3

        case .streak7days:
            return consecutiveLongDays(weekMeals: context.weekMeals, now: context.now) >= 7

        case .weeklyImproved:
            return context.pattern?.consistencyImproving == true && context.weekMeals.count >= 5

        case .firstLongMealInWeek:
            return context.weekMeals.contains { $0.durationSec >= 900 }

        case .comfortImprovedWeekly:
            let scores = context.comfortReports.map(\.score)
            guard scores.count >= 3 else { return false }
            let half = scores.count / 2
            let early = Array(scores.prefix(half))
            let late = Array(scores.suffix(half))
            let earlyAvg = early.reduce(0, +) / early.count
            let lateAvg = late.reduce(0, +) / late.count
            return lateAvg > earlyAvg

        case .journey30day:
            // 첫 식사 30일 전 이상
            guard let earliest = context.weekMeals.min(by: { $0.startedAt < $1.startedAt }) else { return false }
            return context.now.timeIntervalSince(earliest.startedAt) >= 30 * 86400

        case .weeklyRecapImproved:
            return context.weekMeals.count >= 5

        case .weeklyRecapSteady:
            return context.weekMeals.count >= 3
        }
    }

    private func consecutiveLongDays(weekMeals: [MealSummary], now: Date) -> Int {
        let cal = Calendar.current
        let byDay = Dictionary(grouping: weekMeals) { cal.startOfDay(for: $0.startedAt) }
        var count = 0
        for offset in 0..<7 {
            guard let day = cal.date(byAdding: .day, value: -offset, to: cal.startOfDay(for: now)) else { break }
            if let meals = byDay[day], let avg = meals.avgDurationSec, avg >= 480 {
                count += 1
            } else if offset > 0 {
                break
            }
        }
        return count
    }

    private func isMorning(date: Date) -> Bool {
        let hour = Calendar.current.component(.hour, from: date)
        return hour >= 5 && hour < 11
    }
}
