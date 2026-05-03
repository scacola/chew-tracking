import Foundation

/// Daily / Weekly 인사이트 생성. 외부 BackgroundTasks와는 별도 — 호출자가 트리거.
@MainActor
public struct InsightGenerator {
    public let picker: MessagePicker
    public let renderer: MessageRenderer
    public let patternEngine: PatternEngine

    public init(picker: MessagePicker = .init(),
                renderer: MessageRenderer = .init(),
                patternEngine: PatternEngine = .init()) {
        self.picker = picker
        self.renderer = renderer
        self.patternEngine = patternEngine
    }

    public func generateDailyInsight(now: Date,
                                     todayMeals: [MealSummary],
                                     yesterdayMeals: [MealSummary],
                                     weekMeals: [MealSummary],
                                     calibration: CalibrationSummary?,
                                     comfortReports: [ComfortSummary],
                                     lastMeal: MealSummary?,
                                     isVideoMode: Bool = false,
                                     isCalibrationJustCompleted: Bool = false) -> RenderedInsight? {
        let pattern = patternEngine.extract(weekMeals: weekMeals, comfortReports: comfortReports)
        let context = CoachingContext(
            now: now,
            todayMeals: todayMeals,
            yesterdayMeals: yesterdayMeals,
            weekMeals: weekMeals,
            lastMeal: lastMeal,
            calibration: calibration,
            comfortReports: comfortReports,
            pattern: pattern,
            isVideoMode: isVideoMode,
            isCalibrationJustCompleted: isCalibrationJustCompleted
        )
        guard let message = picker.pickAny(context: context) else { return nil }
        let values = buildValues(for: message, context: context)
        guard let rendered = renderer.render(message, values: values) else { return nil }
        return RenderedInsight(messageId: message.id, rendered: rendered, category: message.category)
    }

    private func buildValues(for message: CoachingMessage,
                             context: CoachingContext) -> [String: any Sendable] {
        var values: [String: any Sendable] = [:]
        for spec in message.variables {
            switch spec.name {
            case "deltaSec":
                if let today = context.todayMeals.avgDurationSec,
                   let yest = context.yesterdayMeals.avgDurationSec, today > yest {
                    values[spec.name] = today - yest
                } else if let cal = context.calibration,
                          let today = context.todayMeals.avgDurationSec {
                    values[spec.name] = max(0, today - cal.calibrationDurationSec)
                } else {
                    values[spec.name] = 0
                }
            case "minutes":
                if let last = context.todayMeals.last {
                    values[spec.name] = last.durationSec / 60
                } else {
                    values[spec.name] = 0
                }
            case "deltaMin":
                if let pattern = context.pattern {
                    values[spec.name] = pattern.lunchVsDinnerDeltaMin
                        ?? pattern.videoModeFasterMin
                        ?? pattern.morningShorterMin
                        ?? 1
                } else if let today = context.todayMeals.avgDurationSec,
                          let yest = context.yesterdayMeals.avgDurationSec {
                    values[spec.name] = max(1, (today - yest) / 60)
                } else {
                    values[spec.name] = 1
                }
            case "deltaCPM":
                values[spec.name] = 5
            case "comfortDelta":
                values[spec.name] = context.pattern?.quickMealComfortDelta ?? 0.5
            case "weekday":
                values[spec.name] = context.pattern?.fastestWeekday?.name ?? "월요일"
            case "percent":
                values[spec.name] = context.pattern?.fastestWeekday?.percentFaster
                    ?? context.pattern?.lateDinnerPercentFaster
                    ?? 10
            case "thisWeek":
                let avg = context.weekMeals.avgDurationSec ?? 0
                values[spec.name] = String(format: "%d", avg / 60)
            case "fastestDay":
                values[spec.name] = context.pattern?.fastestWeekday?.name ?? "월요일"
            default:
                continue
            }
        }
        return values
    }
}

public struct RenderedInsight: Sendable {
    public let messageId: String
    public let rendered: String
    public let category: CoachingMessage.Category
}
