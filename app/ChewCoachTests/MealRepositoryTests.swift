import XCTest
import SwiftData
@testable import ChewCoach

@MainActor
final class MealRepositoryTests: XCTestCase {

    private func makeRepository() throws -> (MealRepository, ModelContainer) {
        let schema = Schema([
            MealSession.self, ChewSample.self, ComfortReport.self,
            DailyInsight.self, UserCalibration.self, UserPreferences.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)
        return (MealRepository(context: context), container)
    }

    func test_save_persistsMealSession() throws {
        let (repo, _) = try makeRepository()
        let meal = MealSession(startedAt: Date())
        meal.endedAt = Date()
        meal.durationSec = 600
        meal.chewCount = 200
        try repo.save(meal)

        let recent = repo.recentMeals(days: 1)
        XCTAssertEqual(recent.count, 1)
        XCTAssertEqual(recent.first?.chewCount, 200)
    }

    func test_recentMeals_filtersOldMeals() throws {
        let (repo, _) = try makeRepository()
        let cal = Calendar.current
        let now = Date()
        let oldDate = cal.date(byAdding: .day, value: -30, to: now)!

        let recent = MealSession(startedAt: now)
        recent.durationSec = 600
        try repo.save(recent)

        let old = MealSession(startedAt: oldDate)
        old.durationSec = 600
        try repo.save(old)

        XCTAssertEqual(repo.recentMeals(days: 7).count, 1, "7일 필터 통과 = 1개")
        XCTAssertEqual(repo.recentMeals(days: 60).count, 2, "60일 필터 통과 = 2개")
    }

    func test_attachComfort_linksReportToMeal() throws {
        let (repo, _) = try makeRepository()
        let meal = MealSession(startedAt: Date())
        try repo.save(meal)

        try repo.attachComfort(mealId: meal.id, score: 4)
        let saved = repo.meal(id: meal.id)
        XCTAssertNotNil(saved?.comfortReport)
        XCTAssertEqual(saved?.comfortReport?.score, 4)
    }

    func test_deleteAll_removesAllMeals() throws {
        let (repo, _) = try makeRepository()
        let meal1 = MealSession(startedAt: Date())
        let meal2 = MealSession(startedAt: Date())
        try repo.save(meal1)
        try repo.save(meal2)
        XCTAssertEqual(repo.recentMeals(days: 1).count, 2)

        try repo.deleteAll()
        XCTAssertEqual(repo.recentMeals(days: 1).count, 0)
    }

    func test_loadOrCreatePreferences_createsIfMissing() throws {
        let (repo, _) = try makeRepository()
        let prefs1 = repo.loadOrCreatePreferences()
        let prefs2 = repo.loadOrCreatePreferences()
        XCTAssertEqual(prefs1.id, prefs2.id, "두 번째 호출은 기존 preferences 반환")
    }
}
