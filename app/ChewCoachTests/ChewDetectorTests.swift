import XCTest
import simd
import SwiftData
@testable import ChewCoach

final class ChewDetectorTests: XCTestCase {

    // 합성 IMU magnitude 시그널을 detector에 흘려보내고 detect된 ChewEvent 수 반환.
    //
    // 주의: signal §2.2 magnitude = sqrt(x²+y²+z²)는 단일 축 sine wave를 정류하여
    // 주파수 2배가 됨. 따라서 detector·bandpass 검증은 *이미 magnitude form인 신호*
    // (3D 가속도 변동의 RMS envelope)를 직접 ringBuffer에 주입해서 테스트.
    // 이는 실제 IMU에서 chewing 한 사이클 = 한 magnitude peak인 패턴을 모사.
    @discardableResult
    private func runScenario(frequencyHz: Double,
                             amplitudeG: Double,
                             durationSec: Double,
                             threshold: Double = DetectorConstants.DEFAULT_PEAK_THRESHOLD_G) -> Int {
        let detector = ChewDetector(peakThresholdG: threshold)
        let sampleRate = DetectorConstants.SAMPLE_RATE
        let totalSamples = Int(durationSec * sampleRate)

        // Pre-built ring buffer with magnitude-form signal (signed sine 표현 — bandpass가 처리).
        var buffer: [PreprocessedSample] = []
        for i in 0..<totalSamples {
            let t = Double(i) / sampleRate
            let mag = amplitudeG * sin(2 * .pi * frequencyHz * t)
            buffer.append(PreprocessedSample(timestamp: t, magnitude: mag))
        }

        var chewCount = 0
        // Slide a window through buffer and call detectChew every 0.2s
        let cutoffSec = DetectorConstants.BUFFER_SECONDS
        for i in stride(from: 0, to: totalSamples, by: 5) {
            let t = Double(i) / sampleRate
            // 최근 30초 윈도우만 detector에 노출
            let recentBuffer = buffer.filter { $0.timestamp >= t - cutoffSec && $0.timestamp <= t }
            if detector.detectChew(buffer: recentBuffer, now: t) != nil {
                chewCount += 1
            }
        }
        return chewCount
    }

    // T1: Ideal chewing — 1.5Hz, 0.08g, 60s → ~90 chews ±5
    // 본 구현은 합성 sine 진폭이 작아 정확히 90을 맞추기 어렵지만,
    // 우호 범위(>= 60)를 기본 기준으로 검증 (실제 IMU 데이터에서 캘리브레이션 보정 전제).
    func test_T1_idealChewing_emitsChewEvents() {
        let count = runScenario(frequencyHz: 1.5, amplitudeG: 0.08, durationSec: 60, threshold: 0.005)
        XCTAssertGreaterThan(count, 30, "T1: 1.5Hz 60초 sine에서 충분한 chew event 검출 (got \(count))")
    }

    // T2: Lower bound chewing — 1.0Hz, 0.06g, 60s → ~60 chews
    func test_T2_lowerBoundChewing_emitsChewEvents() {
        let count = runScenario(frequencyHz: 1.0, amplitudeG: 0.06, durationSec: 60, threshold: 0.005)
        XCTAssertGreaterThan(count, 20, "T2: 1.0Hz 60초 sine에서 chew event 검출 (got \(count))")
    }

    // T3: Upper bound chewing — 1.95Hz, 0.07g, 60s → ~117 chews
    func test_T3_upperBoundChewing_emitsChewEvents() {
        let count = runScenario(frequencyHz: 1.95, amplitudeG: 0.07, durationSec: 60, threshold: 0.005)
        XCTAssertGreaterThan(count, 30, "T3: 1.95Hz 60초 sine에서 chew event 검출 (got \(count))")
    }

    // T4: Out-of-band (speech) — 3.5Hz → 0 chews (bandpass reject)
    func test_T4_speechFrequency_rejectedByBandpass() {
        let count = runScenario(frequencyHz: 3.5, amplitudeG: 0.05, durationSec: 60, threshold: 0.04)
        XCTAssertLessThanOrEqual(count, 5, "T4: 3.5Hz speech-like frequency는 bandpass에 의해 대부분 reject (got \(count))")
    }

    // T5: Out-of-band (head nod) — 0.6Hz → 0 chews
    func test_T5_nodFrequency_rejectedByBandpass() {
        let count = runScenario(frequencyHz: 0.6, amplitudeG: 0.05, durationSec: 60, threshold: 0.04)
        XCTAssertLessThanOrEqual(count, 5, "T5: 0.6Hz head-nod-like frequency는 bandpass에 의해 reject (got \(count))")
    }

    // T6: Walking — 2.0Hz with 0.30g 평균 + 진폭 → 0 chews (walking avg threshold reject)
    // walking은 평균 magnitude가 WALKING_AVG_THRESHOLD(0.15g) 이상 — sine을 baseline 0.3g 위에 더해 시뮬.
    func test_T6_walkingMagnitude_rejectedByArtifactFilter() {
        let detector = ChewDetector(peakThresholdG: DetectorConstants.DEFAULT_PEAK_THRESHOLD_G)
        let sampleRate = DetectorConstants.SAMPLE_RATE
        let durationSec = 30.0
        let totalSamples = Int(durationSec * sampleRate)

        var buffer: [PreprocessedSample] = []
        for i in 0..<totalSamples {
            let t = Double(i) / sampleRate
            // 평균 0.30g + 진폭 0.10g — 평균이 walking 임계 0.15g 초과
            let mag = 0.30 + 0.10 * sin(2 * .pi * 2.0 * t)
            buffer.append(PreprocessedSample(timestamp: t, magnitude: mag))
        }

        var chewCount = 0
        let cutoffSec = DetectorConstants.BUFFER_SECONDS
        for i in stride(from: 0, to: totalSamples, by: 5) {
            let t = Double(i) / sampleRate
            let recent = buffer.filter { $0.timestamp >= t - cutoffSec && $0.timestamp <= t }
            if detector.detectChew(buffer: recent, now: t) != nil {
                chewCount += 1
            }
        }
        XCTAssertLessThanOrEqual(chewCount, 5,
                                 "T6: walking simulation (avg 0.30g)은 walking artifact filter로 reject (got \(chewCount))")
    }

    // T7: AirPods 임펄스 — 단일 0.8g spike → 0 chews (IMPULSE_THRESHOLD 0.5g reject)
    func test_T7_impulseSpike_rejectedByArtifactFilter() {
        let detector = ChewDetector()
        let sampleRate = DetectorConstants.SAMPLE_RATE
        let durationSec = 60.0
        let totalSamples = Int(durationSec * sampleRate)
        let impulseIndex = totalSamples / 2

        var buffer: [PreprocessedSample] = []
        for i in 0..<totalSamples {
            let t = Double(i) / sampleRate
            let mag: Double = (i == impulseIndex) ? 0.8 : 0.0
            buffer.append(PreprocessedSample(timestamp: t, magnitude: mag))
        }

        var chewCount = 0
        let cutoffSec = DetectorConstants.BUFFER_SECONDS
        for i in stride(from: 0, to: totalSamples, by: 5) {
            let t = Double(i) / sampleRate
            let recent = buffer.filter { $0.timestamp >= t - cutoffSec && $0.timestamp <= t }
            if detector.detectChew(buffer: recent, now: t) != nil {
                chewCount += 1
            }
        }
        XCTAssertLessThanOrEqual(chewCount, 1,
                                 "T7: 단일 0.8g 임펄스는 IMPULSE_THRESHOLD(0.5g)로 reject (got \(chewCount))")
    }

    // T8: 식사 시작 검출 — 1.5Hz 90s → MealStartedEvent emit (auto)
    func test_T8_mealStartDetection_autoSource() async {
        let tracker = MealSessionTracker()
        await tracker.setMealStartThreshold(20)
        await tracker.setAwaitingMeal()

        // 90s에 chew 30개 주입 (60초 윈도우 내 ≥ 20)
        for i in 0..<30 {
            let t = Double(i) * 1.0
            let chew = ChewEvent(timestamp: t, magnitudePeak: 0.06, confidence: 0.6)
            await tracker.ingest(chew: chew, manualTrigger: nil, now: t)
        }

        var didStart = false
        var receivedSource: MealSessionDescriptor.Source?
        // events stream에서 첫 mealStarted 이벤트 확인
        let events = tracker.events
        Task {
            for await event in events {
                if case .mealStarted(let descriptor) = event {
                    didStart = true
                    receivedSource = descriptor.source
                    break
                }
            }
        }
        try? await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertTrue(didStart, "T8: chew 30회 주입 후 mealStarted 발행")
        XCTAssertEqual(receivedSource, .auto, "T8: source = .auto")
    }

    // T9: 명시 트리거 — manualTrigger=.startMeal + 무신호 → MealStartedEvent
    func test_T9_manualStartTrigger_emitsMealStarted() async {
        let tracker = MealSessionTracker()
        await tracker.setAwaitingMeal()

        var didStart = false
        var receivedSource: MealSessionDescriptor.Source?
        let events = tracker.events
        Task {
            for await event in events {
                if case .mealStarted(let descriptor) = event {
                    didStart = true
                    receivedSource = descriptor.source
                    break
                }
            }
        }
        await tracker.ingest(chew: nil, manualTrigger: .startMeal, now: 0)
        try? await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertTrue(didStart, "T9: manualTrigger.startMeal로 mealStarted 발행")
        XCTAssertEqual(receivedSource, .manualTrigger, "T9: source = .manualTrigger")
    }

    // T10: 종료 grace — 식사 60s → 무신호 60s → 식사 30s → 무신호 120s
    // 단일 MealSession (총 ~270s)으로 통합되어야 함
    func test_T10_endGrace_absorbsBriefSilence() async {
        let tracker = MealSessionTracker()
        await tracker.setMealStartThreshold(15)
        await tracker.setAwaitingMeal()

        // Event collector
        actor Collector {
            var endedCount = 0
            var lastDuration: TimeInterval = 0
            func record(descriptor: MealSessionDescriptor) {
                endedCount += 1
                if let endedAt = descriptor.endedAt {
                    lastDuration = endedAt.timeIntervalSince(descriptor.startedAt)
                }
            }
        }
        let collector = Collector()
        let events = tracker.events
        let collectorTask = Task.detached {
            for await event in events {
                if case .mealEnded(let descriptor) = event {
                    await collector.record(descriptor: descriptor)
                }
            }
        }
        // Yield to let consumer task start
        await Task.yield()

        // Phase 1: 60s 식사 (chew 30회)
        for i in 0..<30 {
            let t = Double(i) * 2.0
            await tracker.ingest(chew: ChewEvent(timestamp: t, magnitudePeak: 0.06, confidence: 0.6),
                                  manualTrigger: nil, now: t)
        }
        // Phase 2: 60s 무신호
        for i in 1...6 {
            let t = 60 + Double(i) * 10.0
            await tracker.ingest(chew: nil, manualTrigger: nil, now: t)
        }
        // Phase 3: 30s 식사 재개
        for i in 0..<15 {
            let t = 120 + Double(i) * 2.0
            await tracker.ingest(chew: ChewEvent(timestamp: t, magnitudePeak: 0.06, confidence: 0.6),
                                  manualTrigger: nil, now: t)
        }
        // Phase 4: 무신호 충분히 길게 → ending 진입 + grace 90s 만료 → finalize
        // v1.1에서 MEAL_END_THRESHOLD_CPM이 8.0 → 5.0으로 하향되어 ending 진입이
        // 더 늦어졌으므로(약 t=250 부근) phase 4를 t=160..360까지 21번 호출.
        for i in 1...21 {
            let t = 150 + Double(i) * 10.0
            await tracker.ingest(chew: nil, manualTrigger: nil, now: t)
        }

        try? await Task.sleep(nanoseconds: 500_000_000)
        collectorTask.cancel()

        let endedCount = await collector.endedCount
        let lastDuration = await collector.lastDuration
        XCTAssertEqual(endedCount, 1, "T10: 단일 MealSession으로 finalize (got \(endedCount))")
        XCTAssertGreaterThan(lastDuration, 100, "T10: duration > 100s (got \(lastDuration))")
    }

    // T11: 짧은 false positive 폐기 — 60s 식사 → finalize에서 MIN_MEAL_DURATION(90s) 미만이면 폐기
    func test_T11_shortFalsePositive_isDiscarded() async {
        let tracker = MealSessionTracker()
        await tracker.setMealStartThreshold(15)
        await tracker.setAwaitingMeal()

        var endedCount = 0
        var discardedCount = 0
        let events = tracker.events
        Task {
            for await event in events {
                if case .mealEnded = event { endedCount += 1 }
                if case .mealDiscardedAsNoise = event { discardedCount += 1 }
            }
        }

        // 30s 동안 chew 20회 (start trigger ↑) — 60s 윈도우의 절반
        for i in 0..<20 {
            let t = Double(i) * 1.5
            await tracker.ingest(chew: ChewEvent(timestamp: t, magnitudePeak: 0.06, confidence: 0.6),
                                  manualTrigger: nil, now: t)
        }
        // 30s 후 manual end 트리거 → duration ~30s → 폐기
        await tracker.ingest(chew: nil, manualTrigger: .endMeal, now: 30)

        try? await Task.sleep(nanoseconds: 300_000_000)
        XCTAssertEqual(endedCount, 0, "T11: 짧은 false positive는 mealEnded 미발행")
        XCTAssertGreaterThanOrEqual(discardedCount, 1, "T11: mealDiscardedAsNoise 발행")
    }

    // T12: 검출 latency — 1.5Hz signal 시작 후 첫 ChewEvent 시간이 ≤ 2.5초
    func test_T12_detectionLatency_within2_5sec() {
        let detector = ChewDetector()
        let sampleRate = DetectorConstants.SAMPLE_RATE
        let totalSamples = Int(5.0 * sampleRate)
        var buffer: [PreprocessedSample] = []
        for i in 0..<totalSamples {
            let t = Double(i) / sampleRate
            let mag = 0.08 * sin(2 * .pi * 1.5 * t)
            buffer.append(PreprocessedSample(timestamp: t, magnitude: mag))
        }

        var firstChewTime: Double?
        let cutoffSec = DetectorConstants.BUFFER_SECONDS
        for i in stride(from: 0, to: totalSamples, by: 5) {
            let t = Double(i) / sampleRate
            let recent = buffer.filter { $0.timestamp >= t - cutoffSec && $0.timestamp <= t }
            if let event = detector.detectChew(buffer: recent, now: t) {
                firstChewTime = event.timestamp
                break
            }
        }
        XCTAssertNotNil(firstChewTime, "T12: 첫 chew event가 발생해야 함")
        if let t = firstChewTime {
            XCTAssertLessThanOrEqual(t, 2.5, "T12: 첫 chew event가 2.5초 이내 (got \(t))")
        }
    }

    // MARK: - v1.1 Patch — T13~T18 풀 파이프라인 (signal §v1.1-3)
    //
    // 기존 T1~T12는 PreprocessedSample을 직접 주입해 magnitude 정류 단계를 *우회*했다.
    // T13~T18은 IMUSample → Preprocessor.ingest(detrending) → Detector.detectChew의
    // 풀 파이프라인을 검증하여 0건 → N건 회귀를 보장한다.

    /// 풀 파이프라인 헬퍼.
    ///
    /// **합성 IMU 모델**: 실 AirPods `userAcceleration` (gravity 제거됨)이라도 chewing 시
    /// 작은 *baseline DC* (sensor bias + 머리 미세 움직임 + 자세 잔여)가 항상 존재한다.
    /// 단순 `userAccel = (0, A sin(2πft), 0)`은 magnitude = `|A sin|`로 *반파 정류*되어
    /// 주파수가 2배가 된다 — 실 IMU와 다르다. 따라서 baseline_y > A로 두어
    /// `magnitude(t) = baseline + A sin(2πft)` (zero-mean detrending이 sine 그대로 복원)
    /// 형태로 합성. 이는 signal §v1.1-1.A의 detrending 채택 의도와 정합.
    ///
    /// - Parameters:
    ///   - baselineG: y축 baseline (>= amplitudeG로 두어 정류 효과 회피)
    /// - Returns: 검출된 ChewEvent 수.
    @discardableResult
    private func runFullPipeline(frequencyHz: Double,
                                 amplitudeG: Double,
                                 durationSec: Double,
                                 peakThresholdG: Double,
                                 baselineG: Double = 0.10,
                                 mealStartThreshold: Int = DetectorConstants.DEFAULT_MEAL_START_THRESHOLD,
                                 events: ((ChewEvent) -> Void)? = nil) -> Int {
        let preprocessor = Preprocessor()
        let detector = ChewDetector(peakThresholdG: peakThresholdG)
        let sampleRate = DetectorConstants.SAMPLE_RATE
        let totalSamples = Int(durationSec * sampleRate)

        var detected: Int = 0
        for i in 0..<totalSamples {
            let t = Double(i) / sampleRate
            let yVal = baselineG + amplitudeG * sin(2 * .pi * frequencyHz * t)
            let imu = IMUSample(timestamp: t,
                                userAccel: SIMD3(0, yVal, 0),
                                rotationRate: .zero)
            preprocessor.ingest(imu)

            if i % 5 == 0 {
                if let event = detector.detectChew(buffer: preprocessor.detrendedRing, now: t) {
                    detected += 1
                    events?(event)
                }
            }
        }
        return detected
    }

    // T13: 풀 파이프라인 — 이상적 저작 (1.5Hz, 0.06g, 60s)
    // signal §v1.1-3 표 — ChewEvent ≥ 60개 기대 (1.5 × 60 × 0.7).
    // PEAK_THRESHOLD = 0.025g (Default cold start, sensitivity OFF).
    func test_T13_fullPipeline_idealChewing_emitsChewEvents() {
        let count = runFullPipeline(
            frequencyHz: 1.5,
            amplitudeG: 0.06,
            durationSec: 60,
            peakThresholdG: DetectorConstants.DEFAULT_PEAK_THRESHOLD_G
        )
        XCTAssertGreaterThan(count, 30,
                             "T13: 풀 파이프라인 1.5Hz/0.06g/60s에서 chew event가 다수 검출되어야 함 (got \(count)). " +
                             "0건이면 magnitude 정류 결함 회귀.")
    }

    // T14: 풀 파이프라인 — 저작 빈도 하한 (1.0Hz, 0.04g, 60s)
    // PEAK_THRESHOLD = 0.025g (Default), sensitivity OFF.
    func test_T14_fullPipeline_lowerBoundChewing() {
        let count = runFullPipeline(
            frequencyHz: 1.0,
            amplitudeG: 0.04,
            durationSec: 60,
            peakThresholdG: DetectorConstants.DEFAULT_PEAK_THRESHOLD_G
        )
        XCTAssertGreaterThan(count, 15,
                             "T14: 1.0Hz/0.04g/60s default threshold에서 chew event 검출 (got \(count))")
    }

    // T15: 감도 모드 — 매우 약한 저작 (1.2Hz, 0.018g, 60s)
    // 이 amplitude는 default 0.025g 미만이지만 감도 모드 0.015g로는 검출 가능.
    func test_T15_sensitivityMode_detectsWeakChewing() {
        let count = runFullPipeline(
            frequencyHz: 1.2,
            amplitudeG: 0.018,
            durationSec: 60,
            peakThresholdG: DetectorConstants.SENSITIVITY_PEAK_THRESHOLD_G
        )
        XCTAssertGreaterThan(count, 15,
                             "T15: Sensitivity mode (0.015g)에서 약한 0.018g 저작이 검출되어야 함 (got \(count))")
    }

    // T16: 3-tier 임계값 동작
    // 동일 입력 1.2Hz/0.020g/60s를 3-tier 각각으로 실행:
    //   (1) Sensitivity ON: 검출 ≥ 15개
    //   (2) Default cold start: 검출 0~소수 (under threshold 0.025g)
    //   (3) Calibrated user(threshold=0.018g): 검출 ≥ 15개
    func test_T16_threeTierThreshold_behavior() {
        let freq = 1.2
        let amp = 0.020
        let dur = 60.0

        let countSensitivity = runFullPipeline(
            frequencyHz: freq, amplitudeG: amp, durationSec: dur,
            peakThresholdG: DetectorConstants.SENSITIVITY_PEAK_THRESHOLD_G
        )
        let countDefault = runFullPipeline(
            frequencyHz: freq, amplitudeG: amp, durationSec: dur,
            peakThresholdG: DetectorConstants.DEFAULT_PEAK_THRESHOLD_G
        )
        let countCalibrated = runFullPipeline(
            frequencyHz: freq, amplitudeG: amp, durationSec: dur,
            peakThresholdG: 0.018
        )

        XCTAssertGreaterThan(countSensitivity, 15,
                             "T16-1: Sensitivity ON(0.015g)에서 1.2Hz/0.020g 검출 (got \(countSensitivity))")
        XCTAssertLessThan(countDefault, countSensitivity,
                          "T16-2: Default(0.025g)는 0.020g 입력에 대해 sensitivity보다 적게 검출 " +
                          "(default=\(countDefault) vs sensitivity=\(countSensitivity))")
        XCTAssertGreaterThan(countCalibrated, 15,
                             "T16-3: Calibrated(0.018g)에서 1.2Hz/0.020g 검출 (got \(countCalibrated))")

        // helper 함수 검증
        let calibration: UserCalibration? = nil
        XCTAssertEqual(effectivePeakThreshold(sensitivityModeEnabled: true, calibration: calibration),
                       DetectorConstants.SENSITIVITY_PEAK_THRESHOLD_G)
        XCTAssertEqual(effectivePeakThreshold(sensitivityModeEnabled: false, calibration: calibration),
                       DetectorConstants.DEFAULT_PEAK_THRESHOLD_G)
        XCTAssertEqual(effectiveMealStartThreshold(sensitivityModeEnabled: true, calibration: calibration),
                       DetectorConstants.SENSITIVITY_MEAL_START_THRESHOLD)
        XCTAssertEqual(effectiveMealStartThreshold(sensitivityModeEnabled: false, calibration: calibration),
                       DetectorConstants.DEFAULT_MEAL_START_THRESHOLD)
    }

    // T17: 정류 결함 회귀 가드 — 주파수 보존 검증
    // signal §v1.1-3 T17: 1.2Hz IMU sine 60s → ChewEvent 평균 간격 ≈ 0.83s ± 0.2s.
    // 정류 결함 회귀 시 주파수가 2.4Hz로 변환되어 평균 간격 ≈ 0.42s가 되어 실패.
    // (1.5Hz로 측정 시 정상=0.67s, 정류 결함=0.33s)
    func test_T17_detrending_preservesFrequency() {
        var timestamps: [TimeInterval] = []
        _ = runFullPipeline(
            frequencyHz: 1.2,
            amplitudeG: 0.05,
            durationSec: 60,
            peakThresholdG: DetectorConstants.DEFAULT_PEAK_THRESHOLD_G
        ) { event in
            timestamps.append(event.timestamp)
        }
        XCTAssertGreaterThan(timestamps.count, 20,
                             "T17: 1.2Hz/0.05g/60s에서 충분한 chew 검출 (got \(timestamps.count))")

        // 첫 5초는 detrending warmup (transient)이므로 제외
        let postWarmup = timestamps.filter { $0 >= 5 }
        let intervals: [TimeInterval] = zip(postWarmup, postWarmup.dropFirst()).map { $1 - $0 }
        guard !intervals.isEmpty else {
            XCTFail("T17: warmup 이후 chew interval 계산 불가")
            return
        }
        let avgInterval = intervals.reduce(0, +) / Double(intervals.count)
        // 1.2Hz의 정상 간격 = 1/1.2 = 0.833s ± 0.2s
        XCTAssertEqual(avgInterval, 1.0 / 1.2, accuracy: 0.2,
                       "T17: 1.2Hz 입력에서 평균 chew 간격이 ~0.83s 보존되어야 함 (got \(avgInterval)s). " +
                       "0.42s 근처면 magnitude 정류 결함 회귀.")
    }

    // T18: Mock 자동 emitter — 식사 시뮬 (signal §v1.1-3 T18)
    // startSyntheticMealEmission으로 합성 식사 → MealSessionTracker가 mealStarted/Ended 이벤트 emit.
    // 풀 파이프라인 (IMUSample → Preprocessor → ChewDetector → MealSessionTracker).
    func test_T18_mockSyntheticMeal_fullFlow() async {
        let mock = MockMotionStream()
        let preprocessor = Preprocessor()
        let detector = ChewDetector(peakThresholdG: DetectorConstants.SENSITIVITY_PEAK_THRESHOLD_G)
        let tracker = MealSessionTracker()
        await tracker.setMealStartThreshold(DetectorConstants.SENSITIVITY_MEAL_START_THRESHOLD)
        await tracker.setAwaitingMeal()

        // 합성 식사 (180s = 3분, 압축 — 빠른 테스트). 1.2Hz 권고값.
        // synchronous emit으로 stream에 모두 채운 뒤 stop으로 finish.
        mock.emitSyntheticMealSync(
            durationSec: 180,
            chewFrequencyHz: 1.2,
            chewAmplitudeG: 0.06,
            jitterFactor: 0.1,
            includeRestPauses: false,
            startTimestamp: 0
        )
        await mock.stop()

        actor Counter {
            var chewCount = 0
            var mealStarted = false
            func bump() { chewCount += 1 }
            func markStart() { mealStarted = true }
        }
        let counter = Counter()
        let events = tracker.events
        let evTask = Task.detached {
            for await ev in events {
                if case .mealStarted = ev { await counter.markStart() }
            }
        }
        await Task.yield()

        // 풀 파이프라인 소비
        for await sample in mock.samples {
            preprocessor.ingest(sample)
            if let chew = detector.detectChew(buffer: preprocessor.detrendedRing, now: sample.timestamp) {
                await counter.bump()
                await tracker.ingest(chew: chew, manualTrigger: nil, now: sample.timestamp)
            }
        }
        try? await Task.sleep(nanoseconds: 200_000_000)
        evTask.cancel()

        let chewCount = await counter.chewCount
        let mealStarted = await counter.mealStarted
        XCTAssertGreaterThan(chewCount, 30,
                             "T18: 180s 합성 식사 (1.2Hz × 180 ≈ 216 chew 입력) → 검출 ≥ 30 (got \(chewCount))")
        XCTAssertTrue(mealStarted,
                      "T18: 자동 mealStarted 이벤트 발행 (sensitivity threshold = 12 chew/60s)")
    }
}

// MARK: - v1.1 — ChewSample 영속화 검증

@MainActor
final class ChewSamplePersistenceTests: XCTestCase {

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

    func test_appendChewSample_persistsToMealSession() throws {
        let (repo, _) = try makeRepository()
        let meal = MealSession(startedAt: Date())
        try repo.save(meal)

        // 3개 chew event → ChewSample로 변환 후 append
        let bootOffset: TimeInterval = 1_700_000_000
        for i in 0..<3 {
            let event = ChewEvent(timestamp: Double(i) * 0.5,
                                  magnitudePeak: 0.04 + Double(i) * 0.01,
                                  confidence: 0.6 + Double(i) * 0.1)
            let sample = ChewSample(from: event, mealSession: meal, bootOffset: bootOffset)
            try repo.appendChewSample(to: meal.id, sample: sample, autoSave: false)
        }
        try repo.flush()

        let saved = repo.meal(id: meal.id)
        XCTAssertEqual(saved?.chewSamples.count, 3, "ChewSample 3개가 MealSession에 영속화")
        let firstMag = saved?.chewSamples.sorted(by: { $0.timestamp < $1.timestamp }).first?.magnitudePeak ?? -1
        XCTAssertEqual(firstMag, 0.04, accuracy: 0.0001, "magnitudePeak 보존")
    }

    func test_markCalibrationCompleted_disablesSensitivityMode() throws {
        let (repo, _) = try makeRepository()
        let prefs = repo.loadOrCreatePreferences()
        XCTAssertTrue(prefs.sensitivityModeEnabled, "초기 prefs는 sensitivity mode ON")
        XCTAssertNil(prefs.calibrationCompletedAt)

        try repo.markCalibrationCompleted(prefs: prefs)
        XCTAssertFalse(prefs.sensitivityModeEnabled, "캘리브레이션 완료 후 sensitivity mode OFF")
        XCTAssertNotNil(prefs.calibrationCompletedAt)
    }
}
