import Foundation

/// signal §부록 A — 매직 넘버 표.
/// v1.1 Patch (2026-05-03): "감지 살리기" 라운드 — magnitude 정류 결함 해결 + cold start 임계값 하향.
/// signal §v1.1-2 표 그대로 반영.
public enum DetectorConstants {
    public static let SAMPLE_RATE: Double = 25.0          // Hz, CMHeadphoneMotionManager
    public static let BAND_LOW_HZ: Double = 0.94          // Hz, 일반 저작 빈도 하한 (분당 56회) — v1.1 변경 없음
    public static let BAND_HIGH_HZ: Double = 2.0          // Hz, 일반 저작 빈도 상한 (분당 120회) — v1.1 변경 없음
    public static let MIN_PEAK_INTERVAL_SEC: Double = 0.3 // 분당 200회 생리 상한
    public static let DETECT_WINDOW_SEC: Double = 2.0     // 검출 슬라이딩 윈도우

    // === v1.1 갱신: cold start 검출 회복 ===
    /// signal §v1.1-2: detrended magnitude는 raw 대비 진폭 절반 + cold start 검출 회복 우선.
    /// v1: 0.05 → v1.1: 0.025 (IMChew 정상 진폭 0.04g 하한 대비 -38% 보수치)
    public static let DEFAULT_PEAK_THRESHOLD_G: Double = 0.025
    public static let MEAL_START_WINDOW_SEC: Double = 60.0
    /// signal §v1.1-2: CPM 18 = 매우 천천히 먹는 사용자도 첫 식사부터 인식.
    /// v1: 25 → v1.1: 18
    public static let DEFAULT_MEAL_START_THRESHOLD: Int = 18
    public static let MEAL_END_WINDOW_SEC: Double = 120.0
    /// signal §v1.1-2: DEFAULT_MEAL_START_THRESHOLD 25→18 하향에 정비례 (8 × 18/25 ≈ 5.76 → 5.0 보수치).
    /// v1: 8.0 → v1.1: 5.0
    public static let MEAL_END_THRESHOLD_CPM: Double = 5.0
    public static let END_GRACE_SEC: Double = 90.0
    public static let MIN_MEAL_DURATION_SEC: Double = 90.0
    public static let WALKING_AVG_THRESHOLD: Double = 0.15
    public static let IMPULSE_THRESHOLD: Double = 0.5
    public static let BUFFER_SECONDS: Double = 30.0

    // === v1.1 갱신: detrended 진폭 절반 보정 ===
    /// signal §v1.1-2: detrended 진폭 절반 보정. v1: 0.03 → v1.1: 0.015
    public static let CALIBRATION_THRESHOLD_MIN: Double = 0.015
    /// signal §v1.1-2: 동일 보정. v1: 0.12 → v1.1: 0.06
    public static let CALIBRATION_THRESHOLD_MAX: Double = 0.06
    public static let CALIBRATION_PERCENTILE_FACTOR: Double = 0.7   // p70 — 변경 없음
    public static let CALIBRATION_START_FACTOR: Double = 0.6        // 변경 없음
    /// signal §v1.1-2: DEFAULT 25→18 하향에 정비례. v1: 15 → v1.1: 10
    public static let CALIBRATION_START_FLOOR: Int = 10

    // === v1.1 신규: 감도 모드 (Sensitivity Mode) ===
    /// signal §v1.1-1.C: 감도 모드 — 첫 사용자 0건 방지 보장.
    /// false positive ↑ 감수 (사용자 카피로 기대치 사전 조정).
    public static let SENSITIVITY_PEAK_THRESHOLD_G: Double = 0.015
    /// signal §v1.1-1.C: 감도 모드 식사 시작 임계 (CPM 12).
    public static let SENSITIVITY_MEAL_START_THRESHOLD: Int = 12

    // === v1.1 신규: detrending 윈도우 ===
    /// signal §v1.1-1.A: running mean 윈도우 길이 [IMChew 2024 표준 2s detrending].
    /// magnitude(t) - mean(magnitude, last 2s) → zero-mean detrended signal로 정류 효과 제거.
    public static let DETREND_WINDOW_SEC: Double = 2.0
}

// MARK: - Effective threshold helpers (v1.1)
//
// signal §v1.1-1.C 의사코드 그대로:
// 우선순위: Calibrated > Sensitivity Mode > Default(cold start)
//
// `userCalibration`이 있으면 사용자별 보정값 사용 (v1 §4.1 그대로).
// 없으면 sensitivityModeEnabled 여부에 따라 Sensitivity / Default 분기.

/// signal §v1.1-1.C — 현재 활성 PEAK_THRESHOLD_G 결정.
/// - Parameters:
///   - sensitivityModeEnabled: UserPreferences.sensitivityModeEnabled
///   - calibration: 캘리브레이션 완료 시 nil 아님
func effectivePeakThreshold(
    sensitivityModeEnabled: Bool,
    calibration: UserCalibration?
) -> Double {
    if let cal = calibration {
        return cal.peakThresholdG
    }
    if sensitivityModeEnabled {
        return DetectorConstants.SENSITIVITY_PEAK_THRESHOLD_G
    }
    return DetectorConstants.DEFAULT_PEAK_THRESHOLD_G
}

/// signal §v1.1-1.C — 현재 활성 MEAL_START_THRESHOLD 결정.
func effectiveMealStartThreshold(
    sensitivityModeEnabled: Bool,
    calibration: UserCalibration?
) -> Int {
    if let cal = calibration {
        return cal.mealStartThreshold
    }
    if sensitivityModeEnabled {
        return DetectorConstants.SENSITIVITY_MEAL_START_THRESHOLD
    }
    return DetectorConstants.DEFAULT_MEAL_START_THRESHOLD
}

/// 현재 활성 임계값 tier 식별자 (디버그 패널·로깅용).
public enum ThresholdTier: String, Sendable {
    case calibrated = "Calibrated"
    case sensitivity = "Sensitivity"
    case `default` = "Default"
}

func currentThresholdTier(
    sensitivityModeEnabled: Bool,
    calibration: UserCalibration?
) -> ThresholdTier {
    if calibration != nil { return .calibrated }
    if sensitivityModeEnabled { return .sensitivity }
    return .default
}
