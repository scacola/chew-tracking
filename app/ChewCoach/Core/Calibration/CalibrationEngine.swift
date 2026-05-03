import Foundation

public struct CalibrationResult: Sendable {
    public let peakThresholdG: Double
    public let mealStartThreshold: Int
    public let calibrationDurationSec: Int
    public let calibrationCPM: Double
}

/// signal §4.1 — 캘리브레이션 엔진.
/// 첫 한 끼 magnitude 분포의 p70 기준으로 사용자별 peak threshold 추정 + clamp.
public struct CalibrationEngine: Sendable {
    public init() {}

    public func calibrate(samples: [PreprocessedSample]) -> CalibrationResult {
        let mags = samples.map(\.magnitude).sorted()
        guard mags.count >= 10 else {
            return CalibrationResult(
                peakThresholdG: DetectorConstants.DEFAULT_PEAK_THRESHOLD_G,
                mealStartThreshold: DetectorConstants.DEFAULT_MEAL_START_THRESHOLD,
                calibrationDurationSec: 0,
                calibrationCPM: 0
            )
        }

        let p50 = mags[mags.count / 2]
        let p90Index = min(mags.count - 1, Int(Double(mags.count) * 0.9))
        let p90 = mags[p90Index]

        var threshold = p50 + (p90 - p50) * DetectorConstants.CALIBRATION_PERCENTILE_FACTOR
        threshold = min(max(threshold, DetectorConstants.CALIBRATION_THRESHOLD_MIN),
                        DetectorConstants.CALIBRATION_THRESHOLD_MAX)

        let durationSec = (samples.last?.timestamp ?? 0) - (samples.first?.timestamp ?? 0)
        let estimatedChews = mags.filter { $0 >= threshold }.count
        let cpm = durationSec > 0 ? Double(estimatedChews) * 60.0 / durationSec : 0
        let mealStart = max(DetectorConstants.CALIBRATION_START_FLOOR,
                            Int(cpm * DetectorConstants.CALIBRATION_START_FACTOR))

        return CalibrationResult(
            peakThresholdG: threshold,
            mealStartThreshold: mealStart,
            calibrationDurationSec: Int(durationSec),
            calibrationCPM: cpm
        )
    }
}
