import Foundation

public struct CoachingContext: Sendable {
    public let now: Date
    public let todayMeals: [MealSummary]
    public let yesterdayMeals: [MealSummary]
    public let weekMeals: [MealSummary]
    public let lastMeal: MealSummary?
    public let calibration: CalibrationSummary?
    public let comfortReports: [ComfortSummary]
    public let pattern: PatternResult?
    public let isVideoMode: Bool
    public let isCalibrationJustCompleted: Bool
    public let isDuringMealAt5min: Bool

    public init(now: Date,
                todayMeals: [MealSummary],
                yesterdayMeals: [MealSummary],
                weekMeals: [MealSummary],
                lastMeal: MealSummary?,
                calibration: CalibrationSummary?,
                comfortReports: [ComfortSummary],
                pattern: PatternResult?,
                isVideoMode: Bool,
                isCalibrationJustCompleted: Bool = false,
                isDuringMealAt5min: Bool = false) {
        self.now = now
        self.todayMeals = todayMeals
        self.yesterdayMeals = yesterdayMeals
        self.weekMeals = weekMeals
        self.lastMeal = lastMeal
        self.calibration = calibration
        self.comfortReports = comfortReports
        self.pattern = pattern
        self.isVideoMode = isVideoMode
        self.isCalibrationJustCompleted = isCalibrationJustCompleted
        self.isDuringMealAt5min = isDuringMealAt5min
    }
}

public struct MealSummary: Sendable, Identifiable {
    public let id: UUID
    public let startedAt: Date
    public let durationSec: Int
    public let chewCount: Int
    public let avgCPM: Double?
    public let comfortScore: Int?
    public let isVideoMode: Bool

    public init(id: UUID, startedAt: Date, durationSec: Int, chewCount: Int,
                avgCPM: Double?, comfortScore: Int?, isVideoMode: Bool) {
        self.id = id
        self.startedAt = startedAt
        self.durationSec = durationSec
        self.chewCount = chewCount
        self.avgCPM = avgCPM
        self.comfortScore = comfortScore
        self.isVideoMode = isVideoMode
    }
}

public struct CalibrationSummary: Sendable {
    public let calibrationDurationSec: Int
    public let calibrationCPM: Double
    public let calibratedAt: Date

    public init(calibrationDurationSec: Int, calibrationCPM: Double, calibratedAt: Date) {
        self.calibrationDurationSec = calibrationDurationSec
        self.calibrationCPM = calibrationCPM
        self.calibratedAt = calibratedAt
    }
}

public struct ComfortSummary: Sendable {
    public let mealId: UUID?
    public let score: Int
    public let reportedAt: Date

    public init(mealId: UUID?, score: Int, reportedAt: Date) {
        self.mealId = mealId
        self.score = score
        self.reportedAt = reportedAt
    }
}

public struct PatternResult: Sendable {
    public var fastestWeekday: (name: String, percentFaster: Int)?
    public var lunchVsDinnerDeltaMin: Int?
    public var quickMealComfortDelta: Double?
    public var videoModeFasterMin: Int?
    public var morningShorterMin: Int?
    public var consistencyImproving: Bool
    public var lateDinnerPercentFaster: Int?

    public init(fastestWeekday: (name: String, percentFaster: Int)? = nil,
                lunchVsDinnerDeltaMin: Int? = nil,
                quickMealComfortDelta: Double? = nil,
                videoModeFasterMin: Int? = nil,
                morningShorterMin: Int? = nil,
                consistencyImproving: Bool = false,
                lateDinnerPercentFaster: Int? = nil) {
        self.fastestWeekday = fastestWeekday
        self.lunchVsDinnerDeltaMin = lunchVsDinnerDeltaMin
        self.quickMealComfortDelta = quickMealComfortDelta
        self.videoModeFasterMin = videoModeFasterMin
        self.morningShorterMin = morningShorterMin
        self.consistencyImproving = consistencyImproving
        self.lateDinnerPercentFaster = lateDinnerPercentFaster
    }
}

extension Array where Element == MealSummary {
    public var avgDurationSec: Int? {
        guard !isEmpty else { return nil }
        let total = reduce(0) { $0 + $1.durationSec }
        return total / count
    }
}
