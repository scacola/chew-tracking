import XCTest
@testable import ChewCoach

final class CalibrationEngineTests: XCTestCase {

    func test_calibrate_withTooFewSamples_returnsDefaults() {
        let engine = CalibrationEngine()
        let samples = (0..<5).map {
            PreprocessedSample(timestamp: Double($0), magnitude: 0.05)
        }
        let result = engine.calibrate(samples: samples)
        XCTAssertEqual(result.peakThresholdG, DetectorConstants.DEFAULT_PEAK_THRESHOLD_G)
        XCTAssertEqual(result.mealStartThreshold, DetectorConstants.DEFAULT_MEAL_START_THRESHOLD)
    }

    func test_calibrate_clampsThresholdToMaxBound() {
        let engine = CalibrationEngine()
        // 매우 큰 magnitude 분포 → threshold 상한(0.12g) clamp
        let samples = (0..<100).map {
            PreprocessedSample(timestamp: Double($0) * 0.04, magnitude: 0.5)
        }
        let result = engine.calibrate(samples: samples)
        XCTAssertLessThanOrEqual(result.peakThresholdG, DetectorConstants.CALIBRATION_THRESHOLD_MAX,
                                 "p70 threshold는 max bound clamp")
    }

    func test_calibrate_clampsThresholdToMinBound() {
        let engine = CalibrationEngine()
        // 매우 작은 magnitude → threshold 하한(0.03g) clamp
        let samples = (0..<100).map {
            PreprocessedSample(timestamp: Double($0) * 0.04, magnitude: 0.001)
        }
        let result = engine.calibrate(samples: samples)
        XCTAssertGreaterThanOrEqual(result.peakThresholdG, DetectorConstants.CALIBRATION_THRESHOLD_MIN,
                                    "p70 threshold는 min bound clamp")
    }

    func test_calibrate_returnsFloorMealStartThreshold() {
        let engine = CalibrationEngine()
        let samples = (0..<100).map {
            PreprocessedSample(timestamp: Double($0) * 0.04, magnitude: 0.001)
        }
        let result = engine.calibrate(samples: samples)
        XCTAssertGreaterThanOrEqual(result.mealStartThreshold,
                                    DetectorConstants.CALIBRATION_START_FLOOR,
                                    "mealStartThreshold는 floor 이상")
    }
}
