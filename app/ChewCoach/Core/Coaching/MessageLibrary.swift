import Foundation

/// UX §8.2 — 32개 코칭 메시지 라이브러리.
/// 카테고리: encouragement(10) + insight(10) + awareness(5) + celebration(5) + weekly(2)
public enum MessageLibrary {
    public static let library: [CoachingMessage] = [
        // MARK: - Encouragement (10)
        .init(id: "enc_slowed_down_d2d", category: .encouragement,
              trigger: .avgDurationIncreased(byMinSec: 60),
              template: "어제보다 {{deltaSec}}초 차분해졌어요. 잘하고 계세요.",
              variables: [.init(name: "deltaSec", kind: .int)],
              tone: .encouraging),

        .init(id: "enc_steady_pace", category: .encouragement,
              trigger: .steadyPace,
              template: "캘리브레이션과 비슷한 페이스예요. 안정적이세요.",
              variables: [],
              tone: .gentle),

        .init(id: "enc_first_long_meal", category: .encouragement,
              trigger: .firstLongMealToday(minSec: 600),
              template: "오늘 첫 식사를 {{minutes}}분에 드셨어요. 좋은 시작이에요.",
              variables: [.init(name: "minutes", kind: .int)],
              tone: .encouraging),

        .init(id: "enc_after_quick_meal", category: .encouragement,
              trigger: .afterQuickMeal,
              template: "이번엔 짧았네요. 다음 식사를 1분만 더 가볼까요?",
              variables: [],
              tone: .gentle),

        .init(id: "enc_consistency_3day", category: .encouragement,
              trigger: .consistencyDays(min: 3),
              template: "3일 연속 8분 넘게 드셨어요. 꾸준함이 보여요.",
              variables: [],
              tone: .encouraging),

        .init(id: "enc_after_calibration", category: .encouragement,
              trigger: .calibrationJustCompleted,
              template: "캘리브레이션 완료! 다음 식사부터 자동으로 살펴봐요.",
              variables: [],
              tone: .gentle),

        .init(id: "enc_video_mode_steady", category: .encouragement,
              trigger: .videoModeSteady,
              template: "영상 보시면서도 차분하게 드셨어요.",
              variables: [],
              tone: .encouraging),

        .init(id: "enc_breakfast_logged", category: .encouragement,
              trigger: .breakfastLogged,
              template: "아침을 챙기셨네요. 위장이 천천히 깨어나요.",
              variables: [],
              tone: .gentle),

        .init(id: "enc_recovery_after_quick", category: .encouragement,
              trigger: .recoveryAfterQuick,
              template: "직전 식사보다 {{deltaMin}}분 더 천천히 드셨어요. 회복하셨네요.",
              variables: [.init(name: "deltaMin", kind: .int)],
              tone: .encouraging),

        .init(id: "enc_weekend_calm", category: .encouragement,
              trigger: .weekendCalm,
              template: "주말이라 그런가, 평일보다 차분히 드시고 계세요.",
              variables: [],
              tone: .gentle),

        // MARK: - Insight (10)
        .init(id: "insight_fastest_weekday", category: .insight,
              trigger: .patternFastestWeekday,
              template: "{{weekday}} 점심이 평소보다 {{percent}}% 빨라요. 회의 후라 그럴까요?",
              variables: [.init(name: "weekday", kind: .string),
                          .init(name: "percent", kind: .int)],
              tone: .curious),

        .init(id: "insight_lunch_vs_dinner", category: .insight,
              trigger: .patternLunchVsDinner,
              template: "저녁이 점심보다 평균 {{deltaMin}}분 더 천천히세요. 환경 차이가 있는 것 같아요.",
              variables: [.init(name: "deltaMin", kind: .int)],
              tone: .curious),

        .init(id: "insight_quick_meal_to_comfort", category: .insight,
              trigger: .patternQuickMealToComfort,
              template: "5분 미만으로 드신 다음 위 컨디션이 평균 {{comfortDelta}}점 낮아요. 패턴이 보이기 시작했어요.",
              variables: [.init(name: "comfortDelta", kind: .double)],
              tone: .authoritativeGentle),

        .init(id: "insight_video_mode_pattern", category: .insight,
              trigger: .patternVideoModeFaster,
              template: "영상 보시면서 드실 때 평균 {{deltaMin}}분 더 빠르세요. 한 입씩 의식해 보실래요?",
              variables: [.init(name: "deltaMin", kind: .int)],
              tone: .curious),

        .init(id: "insight_morning_shorter", category: .insight,
              trigger: .patternMorningShorter,
              template: "아침 식사가 다른 시간대보다 평균 {{deltaMin}}분 짧으세요. 시간이 부족하셨나 봐요.",
              variables: [.init(name: "deltaMin", kind: .int)],
              tone: .gentle),

        .init(id: "insight_consistency_pattern", category: .insight,
              trigger: .patternConsistency,
              template: "이번 주 식사 시간 편차가 줄어들었어요. 패턴이 안정적으로 자리 잡고 있어요.",
              variables: [],
              tone: .encouraging),

        .init(id: "insight_evening_late_quick", category: .insight,
              trigger: .patternLateDinnerQuick,
              template: "21시 이후 저녁이 평소보다 {{percent}}% 빠르세요. 야식은 천천히가 위에 좋아요.",
              variables: [.init(name: "percent", kind: .int)],
              tone: .authoritativeGentle),

        .init(id: "insight_cpm_trend", category: .insight,
              trigger: .cpmTrendImproved,
              template: "이번 주 씹는 페이스가 분당 {{deltaCPM}}회 차분해졌어요.",
              variables: [.init(name: "deltaCPM", kind: .int)],
              tone: .encouraging),

        .init(id: "insight_first_pattern_emerging", category: .insight,
              trigger: .firstPatternEmerging,
              template: "데이터가 모이고 있어요. 일주일 정도 함께하면 처음 패턴이 보여요.",
              variables: [],
              tone: .gentle),

        .init(id: "insight_calibration_drift", category: .insight,
              trigger: .calibrationDrift,
              template: "처음과 비교해 평균 {{deltaSec}}초 변화가 있어요. 새 캘리브레이션을 시도해 보실래요?",
              variables: [.init(name: "deltaSec", kind: .int)],
              tone: .gentle),

        // MARK: - Awareness (5)
        .init(id: "aware_during_meal_5min", category: .awareness,
              trigger: .duringMeal5min,
              template: "지금 5분 지났어요. 한 입 더 천천히 음미해 보세요.",
              variables: [],
              tone: .gentle),

        .init(id: "aware_after_quick_meal", category: .awareness,
              trigger: .quickMealJustEnded,
              template: "오늘은 {{minutes}}분 만에 드셨어요. 위가 따라잡을 시간이 부족했을 수 있어요.",
              variables: [.init(name: "minutes", kind: .int)],
              tone: .gentle),

        .init(id: "aware_video_context", category: .awareness,
              trigger: .videoContextQuick,
              template: "영상 보시면서 드실 때 평소보다 빠르세요. 한 손은 영상, 한 손은 천천히.",
              variables: [],
              tone: .curious),

        .init(id: "aware_streak_break", category: .awareness,
              trigger: .streakBroken,
              template: "어제까진 8분 넘게 드셨는데 오늘은 짧으셨네요. 바쁜 하루였나요?",
              variables: [],
              tone: .gentle),

        .init(id: "aware_no_comfort_reported", category: .awareness,
              trigger: .noComfortRecently,
              template: "최근 며칠간 위 컨디션이 어떠셨어요? 한 번만 알려주시면 패턴이 더 잘 보여요.",
              variables: [],
              tone: .gentle),

        // MARK: - Celebration (5)
        .init(id: "celeb_7day_streak", category: .celebration,
              trigger: .streak7days,
              template: "7일 연속 8분 넘게 드셨어요. 큰 변화가 시작되고 있어요.",
              variables: [],
              tone: .celebratory),

        .init(id: "celeb_weekly_improvement", category: .celebration,
              trigger: .weeklyImproved,
              template: "이번 주 평균 {{deltaMin}}분 더 차분해졌어요. 지난 주보다 {{percent}}% 개선했어요.",
              variables: [.init(name: "deltaMin", kind: .int),
                          .init(name: "percent", kind: .int)],
              tone: .celebratory),

        .init(id: "celeb_first_long_meal_in_week", category: .celebration,
              trigger: .firstLongMealInWeek,
              template: "이번 주 처음으로 15분 넘게 드셨어요. 페이스 잘 잡으셨네요.",
              variables: [],
              tone: .celebratory),

        .init(id: "celeb_comfort_improved", category: .celebration,
              trigger: .comfortImprovedWeekly,
              template: "이번 주 위 컨디션 평균이 살짝 좋아졌어요. 천천히 드신 효과가 보여요.",
              variables: [],
              tone: .celebratory),

        .init(id: "celeb_30day_journey", category: .celebration,
              trigger: .journey30day,
              template: "함께한 지 30일이에요. 처음과 비교해 평균 {{deltaMin}}분 차분해졌어요.",
              variables: [.init(name: "deltaMin", kind: .int)],
              tone: .celebratory),

        // MARK: - Weekly (2)
        .init(id: "weekly_recap_improved", category: .weekly,
              trigger: .weeklyRecapImproved,
              template: "이번 주는 평균 {{thisWeek}}분 — 지난 주보다 {{deltaMin}}분 차분해졌어요. 가장 빠른 식사는 {{fastestDay}}이었어요.",
              variables: [.init(name: "thisWeek", kind: .string),
                          .init(name: "deltaMin", kind: .int),
                          .init(name: "fastestDay", kind: .string)],
              tone: .celebratory),

        .init(id: "weekly_recap_steady", category: .weekly,
              trigger: .weeklyRecapSteady,
              template: "이번 주는 평균 {{thisWeek}}분 — 지난 주와 비슷한 페이스를 유지하셨어요. 꾸준함이 진짜 변화를 만들어요.",
              variables: [.init(name: "thisWeek", kind: .string)],
              tone: .gentle)
    ]
}
