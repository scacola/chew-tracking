import Foundation
import SwiftUI
import Observation

@MainActor
@Observable
final class DashboardViewModel {
    enum State: Equatable {
        case loading
        case empty
        case loaded
        case error
    }

    var state: State = .loading
    var todayMeals: [MealSession] = []
    var weekMeals: [MealSession] = []
    var lastMeal: MealSession?
    var calibration: UserCalibration?
    var insightCard: RenderedInsight?

    private let repository: MealRepository
    private let insightGenerator: InsightGenerator

    init(env: AppEnvironment) {
        self.repository = env.mealRepository
        self.insightGenerator = env.insightGenerator
    }

    func reload() {
        let today = repository.todayMeals()
        let week = repository.recentMeals(days: 7)
        let cal = repository.latestCalibration()
        self.todayMeals = today
        self.weekMeals = week
        self.calibration = cal
        self.lastMeal = today.last ?? week.first
        if today.isEmpty && week.isEmpty {
            state = .empty
        } else {
            state = .loaded
        }
        regenerateInsight()
    }

    var todayTotalSec: Int {
        todayMeals.compactMap(\.durationSec).reduce(0, +)
    }

    var weekTrendPoints: [MealTrendDataPoint] {
        let cal = Calendar.current
        let byDay = Dictionary(grouping: weekMeals) { cal.startOfDay(for: $0.startedAt) }
        let today = cal.startOfDay(for: Date())
        return (0..<7).reversed().compactMap { offset in
            guard let day = cal.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let meals = byDay[day] ?? []
            let total = meals.compactMap(\.durationSec).reduce(0, +)
            return MealTrendDataPoint(date: day, durationSec: total)
        }
    }

    func attachComfort(mealId: UUID, score: Int) {
        try? repository.attachComfort(mealId: mealId, score: score)
        reload()
    }

    func comparisonText() -> String? {
        guard let cal = calibration, let avg = todayMeals.compactMap(\.durationSec).avg else { return nil }
        let delta = avg - cal.calibrationDurationSec
        if abs(delta) < 60 { return "캘리브레이션과 비슷한 페이스" }
        let minutes = abs(delta) / 60
        // 부호 의미를 결과 언어로 표현
        return delta > 0
            ? "캘리브레이션보다 \(minutes)분 더 차분히"
            : "캘리브레이션보다 \(minutes)분 더 빨리"
    }

    private func regenerateInsight() {
        let now = Date()
        let calendar = Calendar.current
        let yStart = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: now)) ?? now
        let yEnd = calendar.startOfDay(for: now)
        let yMeals = weekMeals.filter { $0.startedAt >= yStart && $0.startedAt < yEnd }

        let todaySummaries = todayMeals.map(summary(for:))
        let yesterdaySummaries = yMeals.map(summary(for:))
        let weekSummaries = weekMeals.map(summary(for:))
        let comforts: [ComfortSummary] = weekMeals.compactMap { meal in
            guard let report = meal.comfortReport else { return nil }
            return ComfortSummary(mealId: meal.id, score: report.score, reportedAt: report.reportedAt)
        }
        let calSummary: CalibrationSummary? = calibration.map { c in
            CalibrationSummary(calibrationDurationSec: c.calibrationDurationSec,
                               calibrationCPM: c.calibrationCPM,
                               calibratedAt: c.calibratedAt)
        }
        insightCard = insightGenerator.generateDailyInsight(
            now: now,
            todayMeals: todaySummaries,
            yesterdayMeals: yesterdaySummaries,
            weekMeals: weekSummaries,
            calibration: calSummary,
            comfortReports: comforts,
            lastMeal: todaySummaries.last ?? weekSummaries.first
        )
    }

    private func summary(for meal: MealSession) -> MealSummary {
        MealSummary(
            id: meal.id,
            startedAt: meal.startedAt,
            durationSec: meal.durationSec ?? 0,
            chewCount: meal.chewCount,
            avgCPM: meal.avgCPM,
            comfortScore: meal.comfortReport?.score,
            isVideoMode: false
        )
    }
}

private extension Array where Element == Int {
    var avg: Int? {
        guard !isEmpty else { return nil }
        return reduce(0, +) / count
    }
}
