import Foundation

public struct CoachingMessage: Identifiable, Sendable {
    public let id: String
    public let category: Category
    public let trigger: TriggerCondition
    public let template: String
    public let variables: [VariableSpec]
    public let tone: Tone

    public enum Category: String, Sendable, CaseIterable {
        case encouragement, insight, awareness, celebration, weekly
    }

    public enum Tone: String, Sendable {
        case encouraging
        case gentle
        case curious
        case celebratory
        case authoritativeGentle
    }

    public init(id: String,
                category: Category,
                trigger: TriggerCondition,
                template: String,
                variables: [VariableSpec],
                tone: Tone) {
        self.id = id
        self.category = category
        self.trigger = trigger
        self.template = template
        self.variables = variables
        self.tone = tone
    }
}

public struct VariableSpec: Sendable {
    public let name: String
    public let kind: Kind

    public enum Kind: Sendable {
        case int, double, string
    }

    public init(name: String, kind: Kind) {
        self.name = name
        self.kind = kind
    }
}

/// UX §8.2 — 32개 trigger 조건. YAML 표현식을 enum case + Evaluator로 변환.
public enum TriggerCondition: Sendable {
    case avgDurationIncreased(byMinSec: Int)
    case steadyPace
    case firstLongMealToday(minSec: Int)
    case afterQuickMeal
    case consistencyDays(min: Int)
    case calibrationJustCompleted
    case videoModeSteady
    case breakfastLogged
    case recoveryAfterQuick
    case weekendCalm

    case patternFastestWeekday
    case patternLunchVsDinner
    case patternQuickMealToComfort
    case patternVideoModeFaster
    case patternMorningShorter
    case patternConsistency
    case patternLateDinnerQuick
    case cpmTrendImproved
    case firstPatternEmerging
    case calibrationDrift

    case duringMeal5min
    case quickMealJustEnded
    case videoContextQuick
    case streakBroken
    case noComfortRecently

    case streak7days
    case weeklyImproved
    case firstLongMealInWeek
    case comfortImprovedWeekly
    case journey30day

    case weeklyRecapImproved
    case weeklyRecapSteady
}
