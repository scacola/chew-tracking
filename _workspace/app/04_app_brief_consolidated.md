# 04. Chew Coach iOS V1 — 통합 빌드 브리프 (구현자 단독 입력)

**작성일**: 2026-05-02
**작성**: `ios-app-architect`
**대상 독자**: `ios-app-implementer` — *이 한 파일만 보고* 빌드
**스코프**: 옵션 G "Chew & Calm Coach" V1 — 측정 엔진 + 사용자 대시보드 + 코칭 메시지 골격
**상위 산출물 합본**:
- `_workspace/app/_brief.md` (V1 스코프·환경)
- `_workspace/app/01_signal_processing.md` (신호 알고리즘·매직 넘버·12 단위 테스트)
- `_workspace/app/02_app_architecture.md` (기술 스택·프로젝트 구조·모듈 명세·데이터 모델·권한 흐름)
- `_workspace/app/03_app_ux_spec.md` (11화면·코칭 메시지 32개·디자인 토큰·접근성)

> **핵심 원칙 7가지**:
> 1. **외부 SPM 의존성 0** (V1)
> 2. **iOS 17+ 한정** (SwiftData·Observation·Charts·#Preview 매크로 활용)
> 3. **xcodegen 사용** — `project.yml`이 단일 진리, `.xcodeproj` 손편집 금지
> 4. **백그라운드 약속 0** — foreground + audio session active 우선
> 5. **권한 일괄 요청 0** — Motion은 첫 식사 직전·Notifications는 첫 인사이트 직후
> 6. **V1 햅틱 0** — 신호 latency 10초로 늦음, 사후 리포트가 더 정직 (signal §7.1)
> 7. **카피 정직성** — "100% 정확" / "치료" / "track" 영어 잔존 0건 (UX §8.3)

---

## 0. 개요

### 0.1 V1 스코프 (`_brief.md` §2)

옵션 G "Chew & Calm Coach"의 *측정 엔진 + 사용자 대시보드 + 코칭 메시지 골격*:

1. **AirPods IMU 자동 식사 검출** — `CMHeadphoneMotionManager`, 룰 기반 검출, F1 0.75-0.85 KPI
2. **식사 세션 SwiftData 저장 + 7일 추이 차트 (Swift Charts)** + Discoveries 카드 V1
3. **친근한 한국어 코칭 메시지 32개 라이브러리 (다노식 톤)** — 의료 약속 0건

### 0.2 V1 범위 외

- 28일 위 건강 회복 코스 콘텐츠 (별도 트랙 — KOL + 카피라이터)
- 임상 RCT 데이터 수집 (의료 자문 후)
- 안드로이드 / 비-AirPods
- App Store 등록·심사
- 백엔드·계정·동기화

### 0.3 환경 (`_brief.md` §5)

| 항목 | 상태 |
|------|------|
| Xcode | 26.4 (Build 17E192) |
| xcodegen | 2.45.3 (`/opt/homebrew/bin/xcodegen`) |
| 시뮬레이터 디바이스 | 0개 (`xcrun simctl list devices` 비어있음) — 빌드는 generic destination으로 OK |
| iOS 타겟 | iOS 17.0 |
| 빌드 결과 | `app/` (프로젝트 루트, Xcode 프로젝트) |

### 0.4 옵션 G 톤 (`discovery_report.md` §5.1)

- "씹기 트래커" ❌ → "위 컨디션 결과 코치" ✓
- 다노식 친근 + 임상 권위 균형
- 5초 룰: 첫 실행 5초 / 첫 식사 결과 5초
- Vessyl·Healbe 함정 회피 — 카피 모두 §8.3 lint 통과

### 0.5 1순위 페르소나 (`discovery_report.md` §3.3 / UX §1.1)

**한지원** — 32세 IT 개발자, 미혼, 서울. 위염 진단 (페인 8/10). 점심 12분, 영상 시청, AirPods 매일.
> "의사가 '천천히 드세요' 했지만 실천 안 됨. 월 2-3회 위장약."

UX 모든 카피·CTA가 한지원 컨텍스트로 검증.

---

## 1. 알고리즘 — Swift 변환 가이드

`01_signal_processing.md` §2 의사코드를 *그대로 컴파일되는* Swift 시그니처로 변환.

### 1.1 데이터 타입

```swift
import Foundation

public struct IMUSample: Sendable {
    public let timestamp: TimeInterval        // CACurrentMediaTime() 기준 초
    public let userAccel: SIMD3<Double>       // g 단위, gravity 제거 (CMDeviceMotion.userAcceleration)
    public let rotationRate: SIMD3<Double>    // rad/s (V1 무시, V1.5 활용 예정)
}

public struct PreprocessedSample: Sendable {
    public let timestamp: TimeInterval
    public let magnitude: Double              // sqrt(x^2 + y^2 + z^2), 단위 g
}

public struct ChewEvent: Sendable {
    public let timestamp: TimeInterval
    public let magnitudePeak: Double
    public let confidence: Double             // 0..1
}

public enum MealEvent: Sendable {
    case mealStarted(MealSessionDescriptor)
    case cpmUpdate(Double)
    case mealPaused
    case mealResumed
    case mealEnded(MealSessionDescriptor)
    case mealDiscardedAsNoise(reason: String)
}

public struct MealSessionDescriptor: Sendable {
    public let id: UUID
    public let startedAt: Date
    public let endedAt: Date?
    public let chewCount: Int
    public let avgCPM: Double?
    public let source: Source
    public enum Source: String, Sendable { case auto, manualTrigger, calibration }
}

public enum ManualTrigger: Sendable {
    case startMeal
    case endMeal
}
```

### 1.2 MotionStream 프로토콜 — Live / Mock 분기

```swift
import CoreMotion

public protocol MotionStream: AnyObject, Sendable {
    var samples: AsyncStream<IMUSample> { get }
    var isAvailable: Bool { get async }      // CMHeadphoneMotionManager.isDeviceMotionAvailable
    func start() async throws
    func stop() async
}

// MARK: - LiveMotionStream

public final class LiveMotionStream: MotionStream {
    private let manager = CMHeadphoneMotionManager()
    private var continuation: AsyncStream<IMUSample>.Continuation?
    public let samples: AsyncStream<IMUSample>

    public init() {
        var localContinuation: AsyncStream<IMUSample>.Continuation!
        self.samples = AsyncStream { localContinuation = $0 }
        self.continuation = localContinuation
    }

    public var isAvailable: Bool {
        get async { manager.isDeviceMotionAvailable }
    }

    public func start() async throws {
        guard manager.isDeviceMotionAvailable else {
            throw MotionStreamError.unavailable
        }
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self, let motion else { return }
            let sample = IMUSample(
                timestamp: motion.timestamp,
                userAccel: SIMD3(motion.userAcceleration.x, motion.userAcceleration.y, motion.userAcceleration.z),
                rotationRate: SIMD3(motion.rotationRate.x, motion.rotationRate.y, motion.rotationRate.z)
            )
            self.continuation?.yield(sample)
        }
    }

    public func stop() async {
        manager.stopDeviceMotionUpdates()
        continuation?.finish()
    }
}

public enum MotionStreamError: Error { case unavailable, permissionDenied }

// MARK: - MockMotionStream (테스트·시뮬레이터용)

public final class MockMotionStream: MotionStream {
    private var continuation: AsyncStream<IMUSample>.Continuation?
    public let samples: AsyncStream<IMUSample>
    public var isAvailable: Bool { get async { true } }

    public init() {
        var localContinuation: AsyncStream<IMUSample>.Continuation!
        self.samples = AsyncStream { localContinuation = $0 }
        self.continuation = localContinuation
    }

    public func start() async throws { /* 테스트가 yield(_:) 직접 호출 */ }
    public func stop() async { continuation?.finish() }

    /// 테스트가 synthetic IMU 패턴을 주입할 때 사용
    public func emit(_ sample: IMUSample) { continuation?.yield(sample) }

    /// 합성 sine wave 생성 helper (T1~T7용)
    public func emitSineWave(frequencyHz: Double, amplitudeG: Double, durationSec: Double, sampleRate: Double = 25.0) {
        let count = Int(durationSec * sampleRate)
        for i in 0..<count {
            let t = Double(i) / sampleRate
            let mag = amplitudeG * sin(2 * .pi * frequencyHz * t)
            // 단순화: y축에만 신호, x·z는 0
            emit(IMUSample(timestamp: t, userAccel: SIMD3(0, mag, 0), rotationRate: .zero))
        }
    }
}
```

### 1.3 Preprocessor (signal §2.2)

```swift
import Foundation
import Collections   // V1엔 Swift Collections 미도입 — Array deque로 대체

public final class Preprocessor {
    public private(set) var ringBuffer: [PreprocessedSample] = []
    private let bufferSeconds: Double = DetectorConstants.BUFFER_SECONDS

    public init() {}

    public func ingest(_ sample: IMUSample) {
        let m = sqrt(
            sample.userAccel.x * sample.userAccel.x +
            sample.userAccel.y * sample.userAccel.y +
            sample.userAccel.z * sample.userAccel.z
        )
        ringBuffer.append(PreprocessedSample(timestamp: sample.timestamp, magnitude: m))
        let cutoff = sample.timestamp - bufferSeconds
        while let first = ringBuffer.first, first.timestamp < cutoff {
            ringBuffer.removeFirst()
        }
    }

    public func reset() { ringBuffer.removeAll() }
}
```

### 1.4 BiquadFilter (Butterworth 4차 IIR — vDSP)

```swift
import Accelerate

/// 0.94-2.0 Hz Butterworth bandpass, fs=25 Hz
/// SOS 계수는 SciPy로 오프라인 사전 계산:
///   from scipy.signal import iirfilter
///   sos = iirfilter(4, [0.94, 2.0], btype='band', fs=25, output='sos')
public final class BiquadFilter {
    // 4차 = 2개 biquad section
    // 아래 계수는 *예시 — 실제 SciPy 출력으로 교체*
    private let sosCoeffs: [Float] = [
        // section 1: b0, b1, b2, a0(=1.0 normalized), a1, a2
        0.0151, 0.0, -0.0151, 1.0, -1.8654, 0.8927,
        // section 2
        1.0,    0.0, -1.0,    1.0, -1.9321, 0.9434
    ]
    private let sectionCount = 2

    public init() {}

    public func filter(_ input: [Double]) -> [Double] {
        // Float 변환 (vDSP_biquad는 Float·Double 양쪽 지원, V1은 Float 권장 — 신호 진폭 작아 정밀도 충분)
        let inputFloat = input.map { Float($0) }
        var output = [Float](repeating: 0, count: input.count)
        var delays = [Float](repeating: 0, count: 2 * sectionCount + 2)

        let setup = vDSP_biquad_CreateSetup(sosCoeffs.map(Double.init), vDSP_Length(sectionCount))
        defer { if let setup { vDSP_biquad_DestroySetup(setup) } }
        guard let setup else { return input }

        var doubleDelays = delays.map(Double.init)
        let inputDouble = inputFloat.map(Double.init)
        var outputDouble = [Double](repeating: 0, count: input.count)
        vDSP_biquadD(setup, &doubleDelays, inputDouble, 1, &outputDouble, 1, vDSP_Length(input.count))
        return outputDouble
    }
}
```

> **구현자 노트**: SOS 계수는 위 예시값을 *반드시* SciPy로 재계산해서 교체. 5분이면 됨. 단위 테스트 T1·T2·T3가 정확한 chew count를 검증하므로 잘못된 계수면 즉시 발견됨.

### 1.5 ArtifactFilter (signal §2.5)

```swift
public struct ArtifactFilter {
    public init() {}

    public func isLikelyNonChewing(window: [PreprocessedSample], peakIndex: Int) -> Bool {
        let mags = window.map(\.magnitude)
        guard !mags.isEmpty else { return true }
        let avg = mags.reduce(0, +) / Double(mags.count)
        let peak = window[peakIndex].magnitude

        // 1) 걷기
        if avg > DetectorConstants.WALKING_AVG_THRESHOLD { return true }

        // 2) AirPods 조작 임펄스
        if peak > DetectorConstants.IMPULSE_THRESHOLD { return true }

        // 3) 짧은 burst (말하기·웃음) — 0.3s 내 다중 피크
        let recentWindowSec = 0.3
        let recentSamples = window.suffix(Int(DetectorConstants.SAMPLE_RATE * recentWindowSec))
        let burstThreshold = DetectorConstants.DEFAULT_PEAK_THRESHOLD_G * 0.7
        let recentPeaks = recentSamples.filter { $0.magnitude >= burstThreshold }.count
        if recentPeaks >= 3 { return true }

        // 4) 머리 끄덕임은 bandpass 0.94Hz 하한이 이미 컷 (보수적으로 패스)
        return false
    }
}
```

### 1.6 ChewDetector (signal §2.3)

```swift
public final class ChewDetector {
    public var peakThresholdG: Double          // 캘리브레이션 가능
    private let bandpass: BiquadFilter
    private let artifactFilter: ArtifactFilter
    private var lastChewTimestamp: TimeInterval = 0

    public init(peakThresholdG: Double = DetectorConstants.DEFAULT_PEAK_THRESHOLD_G,
                bandpass: BiquadFilter = .init(),
                artifactFilter: ArtifactFilter = .init()) {
        self.peakThresholdG = peakThresholdG
        self.bandpass = bandpass
        self.artifactFilter = artifactFilter
    }

    /// signal §2.3 의사코드 그대로
    public func detectChew(buffer: [PreprocessedSample], now: TimeInterval) -> ChewEvent? {
        // 1) 최근 2초 윈도우
        let windowSec = DetectorConstants.DETECT_WINDOW_SEC
        let window = buffer.filter { $0.timestamp >= now - windowSec && $0.timestamp <= now }
        let minSamples = Int(DetectorConstants.SAMPLE_RATE * windowSec * 0.8)
        guard window.count >= minSamples else { return nil }

        // 2) bandpass 필터
        let filtered = bandpass.filter(window.map(\.magnitude))

        // 3) 최근 0.5초 내 피크 후보
        let recentCount = Int(DetectorConstants.SAMPLE_RATE * 0.5)
        let sliceStart = max(0, filtered.count - recentCount)
        let recentSlice = Array(filtered[sliceStart...])
        guard let (peakIdxLocal, peakValue) = recentSlice.enumerated().max(by: { $0.element < $1.element }) else { return nil }
        guard peakValue >= peakThresholdG else { return nil }
        guard isLocalMaximum(recentSlice, index: peakIdxLocal) else { return nil }

        // 4) 인접 저작 간격
        let absoluteIdx = sliceStart + peakIdxLocal
        let peakTimestamp = window[absoluteIdx].timestamp
        guard peakTimestamp - lastChewTimestamp >= DetectorConstants.MIN_PEAK_INTERVAL_SEC else { return nil }

        // 5) 식사 외 활동 필터
        guard !artifactFilter.isLikelyNonChewing(window: window, peakIndex: absoluteIdx) else { return nil }

        // 6) 신뢰도 계산 (간단: 진폭/threshold 비율 + clamp)
        let confidence = min(1.0, peakValue / (peakThresholdG * 2.0))

        lastChewTimestamp = peakTimestamp
        return ChewEvent(timestamp: peakTimestamp, magnitudePeak: peakValue, confidence: confidence)
    }

    private func isLocalMaximum(_ values: [Double], index: Int) -> Bool {
        guard index > 0, index < values.count - 1 else { return true }
        return values[index] >= values[index - 1] && values[index] >= values[index + 1]
    }

    public func reset() { lastChewTimestamp = 0 }
}
```

### 1.7 MealSessionTracker (signal §2.4)

```swift
public actor MealSessionTracker {
    public enum State: Sendable {
        case idle
        case calibrating
        case awaitingMeal
        case inMeal(descriptor: MealSessionDescriptor, startedAt: Date)
        case ending(descriptor: MealSessionDescriptor, sinceTimestamp: TimeInterval)
    }

    public private(set) var state: State = .idle
    private var recentChews: [ChewEvent] = []      // 최근 5분 (300s)
    private var sessionChewCount: Int = 0
    private var eventsContinuation: AsyncStream<MealEvent>.Continuation?
    public let events: AsyncStream<MealEvent>

    public init() {
        var local: AsyncStream<MealEvent>.Continuation!
        self.events = AsyncStream { local = $0 }
        self.eventsContinuation = local
    }

    public func setCalibrating() { state = .calibrating }
    public func setAwaitingMeal() { state = .awaitingMeal }

    public func ingest(chew: ChewEvent?, manualTrigger: ManualTrigger? = nil, now: TimeInterval) {
        if let chew { recentChews.append(chew) }
        let cutoff = now - 300
        recentChews.removeAll { $0.timestamp < cutoff }

        switch state {
        case .calibrating:
            handleCalibration(chew: chew, manualTrigger: manualTrigger, now: now)

        case .idle, .awaitingMeal:
            if manualTrigger == .startMeal {
                let descriptor = MealSessionDescriptor(
                    id: UUID(), startedAt: Date(),
                    endedAt: nil, chewCount: 0, avgCPM: nil, source: .manualTrigger
                )
                state = .inMeal(descriptor: descriptor, startedAt: Date())
                sessionChewCount = 0
                eventsContinuation?.yield(.mealStarted(descriptor))
                return
            }
            let inWindow = recentChews.filter { now - $0.timestamp <= DetectorConstants.MEAL_START_WINDOW_SEC }
            if inWindow.count >= DetectorConstants.DEFAULT_MEAL_START_THRESHOLD,
               let first = inWindow.first {
                let descriptor = MealSessionDescriptor(
                    id: UUID(), startedAt: Date(timeIntervalSinceReferenceDate: first.timestamp),
                    endedAt: nil, chewCount: inWindow.count, avgCPM: nil, source: .auto
                )
                state = .inMeal(descriptor: descriptor, startedAt: Date())
                sessionChewCount = inWindow.count
                eventsContinuation?.yield(.mealStarted(descriptor))
            }

        case .inMeal(let descriptor, let startedAt):
            if let _ = chew { sessionChewCount += 1 }
            let cpm = computeCPM(now: now, windowSec: 60)
            eventsContinuation?.yield(.cpmUpdate(cpm))

            if manualTrigger == .endMeal {
                finalize(descriptor: descriptor, startedAt: startedAt, now: now)
                return
            }

            let endCPM = computeCPM(now: now, windowSec: DetectorConstants.MEAL_END_WINDOW_SEC)
            if endCPM < DetectorConstants.MEAL_END_THRESHOLD_CPM {
                state = .ending(descriptor: descriptor, sinceTimestamp: now)
            }

        case .ending(let descriptor, let since):
            let recentCPM = computeCPM(now: now, windowSec: 60)
            if recentCPM >= DetectorConstants.MEAL_END_THRESHOLD_CPM * 1.5 {
                state = .inMeal(descriptor: descriptor, startedAt: descriptor.startedAt)
            } else if now - since >= DetectorConstants.END_GRACE_SEC {
                finalize(descriptor: descriptor, startedAt: descriptor.startedAt, now: now)
            }
        }
    }

    private func computeCPM(now: TimeInterval, windowSec: Double) -> Double {
        let count = recentChews.filter { now - $0.timestamp <= windowSec }.count
        return Double(count) * (60.0 / windowSec)
    }

    private func finalize(descriptor: MealSessionDescriptor, startedAt: Date, now: TimeInterval) {
        let endTime = Date(timeIntervalSinceReferenceDate: now - DetectorConstants.END_GRACE_SEC)
        let duration = endTime.timeIntervalSince(descriptor.startedAt)
        if duration < DetectorConstants.MIN_MEAL_DURATION_SEC {
            state = .awaitingMeal
            eventsContinuation?.yield(.mealDiscardedAsNoise(reason: "duration<\(Int(DetectorConstants.MIN_MEAL_DURATION_SEC))s"))
            return
        }
        let avgCPM = duration > 0 ? Double(sessionChewCount) * 60.0 / duration : nil
        let final = MealSessionDescriptor(
            id: descriptor.id, startedAt: descriptor.startedAt, endedAt: endTime,
            chewCount: sessionChewCount, avgCPM: avgCPM, source: descriptor.source
        )
        state = .awaitingMeal
        sessionChewCount = 0
        eventsContinuation?.yield(.mealEnded(final))
    }

    private func handleCalibration(chew: ChewEvent?, manualTrigger: ManualTrigger?, now: TimeInterval) {
        // 캘리브레이션은 사용자 명시 트리거로만 종료
        if manualTrigger == .endMeal {
            // CalibrationEngine에 IMU magnitude 분포 전달은 별도 path
            state = .awaitingMeal
        }
    }
}
```

### 1.8 CalibrationEngine (signal §4.1)

```swift
public struct CalibrationResult: Sendable {
    public let peakThresholdG: Double
    public let mealStartThreshold: Int
    public let calibrationDurationSec: Int
    public let calibrationCPM: Double
}

public struct CalibrationEngine {
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
        let p90 = mags[Int(Double(mags.count) * 0.9)]

        var threshold = p50 + (p90 - p50) * DetectorConstants.CALIBRATION_PERCENTILE_FACTOR
        threshold = min(max(threshold, DetectorConstants.CALIBRATION_THRESHOLD_MIN), DetectorConstants.CALIBRATION_THRESHOLD_MAX)

        let durationSec = samples.last.map { $0.timestamp - (samples.first?.timestamp ?? 0) } ?? 0
        // 사용자별 CPM 추정 — 단순화: peak count / duration
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
```

### 1.9 단위 테스트 12개 (signal §3.4 — `ChewCoachTests/`)

| # | 케이스 | 입력 | 기대 출력 |
|---|--------|------|---------|
| T1 | 이상적 저작 | 1.5 Hz sine, 0.08g, 60s | ChewEvent 90 ±5 |
| T2 | 저작 빈도 하한 | 1.0 Hz, 0.06g, 60s | ChewEvent 60 ±5 |
| T3 | 저작 빈도 상한 | 1.95 Hz, 0.07g, 60s | ChewEvent 117 ±5 |
| T4 | 대역 외 (말하기) | 3.5 Hz, 0.05g, 60s | ChewEvent 0 (bandpass reject) |
| T5 | 대역 외 (끄덕임) | 0.6 Hz, 0.05g, 60s | ChewEvent 0 (bandpass reject) |
| T6 | 걷기 시뮬 | 2.0 Hz, 0.30g, 60s | ChewEvent 0 (avgMag>0.15g reject) |
| T7 | AirPods 임펄스 | 0.8g spike + 무신호 | ChewEvent 0 (peakMag>0.5g reject) |
| T8 | 식사 시작 검출 | 1.5 Hz, 0.08g, 90s | MealStartedEvent emit, source=.auto |
| T9 | 명시 트리거 | manualTrigger=.startMeal + 무신호 60s | MealStartedEvent emit, source=.manualTrigger |
| T10 | 종료 grace | 1.5Hz 60s → 무신호 60s → 1.5Hz 30s → 무신호 120s | 단일 MealSession (270s), 중간 60s 흡수 |
| T11 | 짧은 false positive 폐기 | 1.5 Hz, 0.08g, 60s 단일 | finalize에서 폐기, .mealDiscardedAsNoise emit |
| T12 | 검출 latency | 1.5Hz pulse train 시작 후 첫 ChewEvent 시간 | ≤ 2.5초 |

각 테스트 구현 골격:

```swift
import XCTest
@testable import ChewCoach

final class ChewDetectorTests: XCTestCase {
    func test_T1_idealChewing_emits90ChewsIn60s() {
        let preprocessor = Preprocessor()
        let detector = ChewDetector()
        let mock = MockMotionStream()
        // mock.emitSineWave(frequencyHz: 1.5, amplitudeG: 0.08, durationSec: 60)
        // ... (각 sample을 preprocessor.ingest → detector.detectChew 루프)
        var chewCount = 0
        for _ in 0..<Int(60 * 25) { /* synthetic generation */ }
        XCTAssertGreaterThanOrEqual(chewCount, 85)
        XCTAssertLessThanOrEqual(chewCount, 95)
    }
    // T2~T7 동일 패턴
}
```

---

## 2. 화면 인벤토리 + 컴포넌트 트리

UX §3 11화면 + 모달 3개 + Custom 컴포넌트 7개. 각 화면 props·상태·이벤트.

### 2.1 RootTabView (탭 구조)

```swift
struct RootTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("홈", systemImage: "house.fill") }
            MealHistoryView()
                .tabItem { Label("기록", systemImage: "list.bullet") }
            SettingsView()
                .tabItem { Label("설정", systemImage: "gearshape") }
        }
    }
}
```

Onboarding 미완료 시 `OnboardingFlow`가 root 대신 노출.

### 2.2 화면별 명세 (요약 — 자세한 와이어는 UX §3)

| # | 화면 | Props (주입) | State | 주요 이벤트 |
|---|------|------------|-------|----------|
| 1 | OnboardingWelcomeView | `flow: OnboardingFlow` | idle | `onTapStart` |
| 2 | OnboardingPersonaView | `flow` | `selected: Persona?` | `onSelect(persona)` |
| 3 | OnboardingHowItWorksView | `flow` | `currentPage: 0..2` | `onComplete` |
| 4 | OnboardingMotionPermissionView | `flow`, `coordinator: PermissionCoordinator` | `phase: idle/requesting/granted/denied` | `onAllow`, `onLater` |
| 5 | OnboardingCalibrationIntroView | `flow` | idle | `onStart`, `onLater` |
| 6 | ActiveMealView | `vm: ActiveMealViewModel` | (vm: phase/duration/cpm/videoMode) | `onAppear`, `onTapEnd` |
| 7 | DashboardView | `vm: DashboardViewModel`, `coordinator` | (vm: state/today/week/insight) | `onAppear`, `onTapStartMeal`, `onComfortReported` |
| 8 | MealHistoryView | `repo: MealRepository` | `state: empty/loaded/error` | `onTapMeal` → MealDetail |
| 9 | MealDetailView | `meal: MealSession`, `repo` | — | `onComfortReported` |
| 10 | WeeklyRecapView | `recap: WeeklyRecapData` | `state: loading/loaded/noData` | `onTapNextWeekToggle` |
| 11 | SettingsView | `coordinator`, `prefs: UserPreferences`, `repo` | (각 toggle binding) | `onExportCSV`, `onDeleteAll` |

### 2.3 Custom 컴포넌트 7개

#### MealResultCard (UX §6)

```swift
struct MealResultCard: View {
    let meal: MealSession
    let calibrationDuration: Int?
    let coachingMessage: CoachingMessage?
    let onTapDetail: () -> Void
    let onComfortReported: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(headerTitle)              // "오늘 점심 결과"
                .font(.title3)
            Text(durationText)             // "11분 32초"
                .font(.system(size: 56, weight: .semibold, design: .monospaced))
            if let caliText = calibrationComparisonText {
                Text(caliText)              // "캘리브레이션 +2분"
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            if let msg = coachingMessage {
                Text(msg.rendered)
                    .font(.body)
            }
            Divider()
            ComfortSelfReportRow(current: meal.comfortReport?.score, onSelect: onComfortReported)
            Button("자세히 보기", action: onTapDetail)
                .buttonStyle(.bordered)
        }
        .padding(Spacing.lg)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(voiceOverLabel)
    }
}
```

#### ChewBreathBadge (UX §3.6)

```swift
struct ChewBreathBadge: View {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var scale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: Spacing.sm) {
            Circle()
                .fill(Color.brandPrimary.opacity(0.3))
                .frame(width: 80, height: 80)
                .scaleEffect(scale)
                .onAppear {
                    guard !reduceMotion else { return }
                    withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                        scale = 1.2
                    }
                }
            Text("차분히 드시고 있어요")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .accessibilityLabel("차분히 드시고 있어요")
    }
}
```

#### ComfortSelfReportRow (UX §5.5)

```swift
struct ComfortSelfReportRow: View {
    let current: Int?
    let onSelect: (Int) -> Void
    @State private var showToast = false

    private let emojis = ["😞", "🙁", "😐", "🙂", "😊"]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("지금 위 컨디션 어떠세요?")
                .font(.callout)
            HStack(spacing: 16) {
                ForEach(Array(emojis.enumerated()), id: \.offset) { idx, emoji in
                    let score = idx + 1
                    Button {
                        onSelect(score)
                        showToast = true
                    } label: {
                        Text(emoji).font(.system(size: 32))
                            .opacity(current == score ? 1.0 : 0.7)
                    }
                    .frame(width: 44, height: 44)
                    .accessibilityLabel("\(score)점, \(label(for: score))")
                }
            }
        }
    }

    private func label(for score: Int) -> String {
        ["매우 안 좋음", "안 좋음", "보통", "좋음", "매우 좋음"][score - 1]
    }
}
```

#### InsightCard / MealTrendChartCard / PersonaCard / TodayHeaderCard

각 컴포넌트 자세한 구조는 UX §5.2·§5.3·§5.4·§3.2 그대로. 위 패턴으로 구현.

### 2.4 SwiftUI 표준 컴포넌트 매핑 (UX §12.1)

- `TabView(selection:).tabViewStyle(.page)` → OnboardingHowItWorksView
- `Form` + `Toggle` → SettingsView
- `Charts` (BarMark, RuleMark, AnnotationMark) → MealTrendChart
- `@Environment(\.accessibilityReduceMotion)` → ChewBreathBadge
- `.sheet(detents: [.medium, .large])` → ComfortDetailSheet, WeeklyRecapView, NotificationPermissionPromptSheet
- `NavigationStack` → 모든 Feature root

---

## 3. 코칭 메시지 라이브러리 — Swift 변환 (UX §8)

UX §8.2 YAML 32개를 *그대로 컴파일되는* Swift struct 배열로.

### 3.1 데이터 타입

```swift
public struct CoachingMessage: Identifiable, Sendable {
    public let id: String
    public let category: Category
    public let trigger: TriggerCondition
    public let template: String
    public let variables: [VariableSpec]
    public let tone: Tone

    public enum Category: String, Sendable {
        case encouragement, insight, awareness, celebration, weekly
    }
    public enum Tone: String, Sendable {
        case encouraging, gentle, curious, celebratory, authoritativeGentle
    }
}

public struct VariableSpec: Sendable {
    public let name: String
    public let kind: Kind
    public enum Kind: Sendable { case int, double, string }
}

/// Trigger는 enum case로 — YAML 표현식을 컴파일된 closure로
public enum TriggerCondition: Sendable {
    case avgDurationIncreased(byMinSec: Int)        // enc_slowed_down_d2d
    case steadyPace                                  // enc_steady_pace
    case firstLongMealToday(minSec: Int)            // enc_first_long_meal
    case afterQuickMeal                             // enc_after_quick_meal
    case consistencyDays(min: Int)                  // enc_consistency_3day
    case calibrationJustCompleted                   // enc_after_calibration
    case videoModeSteady                            // enc_video_mode_steady
    case breakfastLogged                            // enc_breakfast_logged
    case recoveryAfterQuick                         // enc_recovery_after_quick
    case weekendCalm                                // enc_weekend_calm
    case patternFastestWeekday                      // insight_fastest_weekday
    case patternLunchVsDinner                       // insight_lunch_vs_dinner
    case patternQuickMealToComfort                  // insight_quick_meal_to_comfort
    case patternVideoModeFaster                     // insight_video_mode_pattern
    case patternMorningShorter                      // insight_morning_shorter
    case patternConsistency                         // insight_consistency_pattern
    case patternLateDinnerQuick                     // insight_evening_late_quick
    case cpmTrendImproved                           // insight_cpm_trend
    case firstPatternEmerging                       // insight_first_pattern_emerging
    case calibrationDrift                           // insight_calibration_drift
    case duringMeal5min                             // aware_during_meal_5min
    case quickMealJustEnded                         // aware_after_quick_meal
    case videoContextQuick                          // aware_video_context
    case streakBroken                               // aware_streak_break
    case noComfortRecently                          // aware_no_comfort_reported
    case streak7days                                // celeb_7day_streak
    case weeklyImproved                             // celeb_weekly_improvement
    case firstLongMealInWeek                        // celeb_first_long_meal_in_week
    case comfortImprovedWeekly                      // celeb_comfort_improved
    case journey30day                               // celeb_30day_journey
    case weeklyRecapImproved                        // weekly_recap_improved
    case weeklyRecapSteady                          // weekly_recap_steady
}
```

### 3.2 MessageLibrary (32개 — 코드 스케치)

```swift
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
              variables: [.init(name: "weekday", kind: .string), .init(name: "percent", kind: .int)],
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
              variables: [.init(name: "deltaMin", kind: .int), .init(name: "percent", kind: .int)],
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
              tone: .gentle),
    ]
}
```

### 3.3 TriggerEvaluator + MessagePicker

```swift
public struct CoachingContext {
    public let now: Date
    public let todayMeals: [MealSession]
    public let yesterdayMeals: [MealSession]
    public let weekMeals: [MealSession]
    public let lastMeal: MealSession?
    public let calibration: UserCalibration?
    public let comfortReports: [ComfortReport]
    public let pattern: PatternResult?
    public let isVideoMode: Bool
    // ... 필요 시 확장
}

public struct TriggerEvaluator {
    public func evaluate(_ trigger: TriggerCondition, context: CoachingContext) -> Bool {
        switch trigger {
        case .avgDurationIncreased(let minSec):
            let todayAvg = context.todayMeals.avgDurationSec ?? 0
            let yAvg = context.yesterdayMeals.avgDurationSec ?? 0
            return todayAvg > yAvg + minSec
        case .steadyPace:
            guard let cal = context.calibration, !context.todayMeals.isEmpty else { return false }
            let avg = context.todayMeals.avgDurationSec ?? 0
            return abs(avg - cal.calibrationDurationSec) <= 60
        // ... 32개 case 모두 평가 로직 (UX §8.2 trigger 표현식 그대로)
        default: return false
        }
    }
}

public struct MessagePicker {
    let evaluator: TriggerEvaluator
    public func pick(category: CoachingMessage.Category, context: CoachingContext) -> CoachingMessage? {
        MessageLibrary.library
            .filter { $0.category == category }
            .first { evaluator.evaluate($0.trigger, context: context) }
    }
}
```

### 3.4 변수 치환 + 한국어 조사 helper (UX §8.4)

```swift
public struct MessageRenderer {
    public func render(_ message: CoachingMessage, values: [String: Any]) -> String? {
        var output = message.template
        for spec in message.variables {
            guard let value = values[spec.name] else { return nil }   // nil → 메시지 폐기
            output = output.replacingOccurrences(of: "{{\(spec.name)}}", with: format(value, kind: spec.kind))
        }
        return output
    }

    private func format(_ value: Any, kind: VariableSpec.Kind) -> String {
        switch kind {
        case .int: return "\(value as? Int ?? 0)"
        case .double: return String(format: "%.1f", value as? Double ?? 0)
        case .string: return "\(value as? String ?? "")"
        }
    }
}

// MARK: - Korean particle

public enum KoreanParticle {
    /// 받침 유무로 자동 분기
    public static func append(_ noun: String, _ withBatchim: String, _ withoutBatchim: String) -> String {
        guard let last = noun.last else { return noun + withoutBatchim }
        let scalar = last.unicodeScalars.first!.value
        guard scalar >= 0xAC00, scalar <= 0xD7A3 else { return noun + withoutBatchim }
        let hasBatchim = ((Int(scalar) - 0xAC00) % 28) != 0
        return noun + (hasBatchim ? withBatchim : withoutBatchim)
    }

    public static func eulReul(_ noun: String) -> String { append(noun, "을", "를") }
    public static func iGa(_ noun: String) -> String { append(noun, "이", "가") }
    public static func eunNeun(_ noun: String) -> String { append(noun, "은", "는") }
}
```

### 3.5 카피 lint (`MessageLibraryTests`)

```swift
final class MessageLibraryTests: XCTestCase {
    private static let forbiddenSubstrings: [String] = [
        "치료", "회복 보장", "완치", "100%", "정확하게 측정",
        "체중 ", "다이어트 보장", "왜 또", "안 좋아요", "실패",
        "track", "data", "stats", "monitor", "score",
        "환자", "회원님"
    ]

    func test_allMessages_haveNoForbiddenExpressions() {
        for msg in MessageLibrary.library {
            for f in Self.forbiddenSubstrings {
                XCTAssertFalse(msg.template.contains(f), "\(msg.id) contains forbidden: \(f)")
            }
        }
    }

    func test_allMessages_endWithHaeyoForm() {
        // "요." / "요!" / "요?" 로 끝
        for msg in MessageLibrary.library {
            let trimmed = msg.template.trimmingCharacters(in: .whitespaces)
            XCTAssertTrue(trimmed.hasSuffix("요.") || trimmed.hasSuffix("요!") || trimmed.hasSuffix("요?"),
                          "\(msg.id) does not end with 해요체")
        }
    }

    func test_libraryHas32Messages() {
        XCTAssertEqual(MessageLibrary.library.count, 32)
    }

    func test_categoryDistribution() {
        let counts = Dictionary(grouping: MessageLibrary.library, by: \.category).mapValues(\.count)
        XCTAssertEqual(counts[.encouragement], 10)
        XCTAssertEqual(counts[.insight], 10)
        XCTAssertEqual(counts[.awareness], 5)
        XCTAssertEqual(counts[.celebration], 5)
        XCTAssertEqual(counts[.weekly], 2)
    }
}
```

---

## 4. 데이터 모델 (SwiftData @Model — 그대로 컴파일 가능)

`Core/Storage/`에 다음 5개 파일. 02_app_architecture.md §4.1 그대로 인용 + 보강.

```swift
import SwiftData
import Foundation

// MealSession.swift
@Model
final class MealSession {
    @Attribute(.unique) var id: UUID
    var startedAt: Date
    var endedAt: Date?
    var durationSec: Int?
    var chewCount: Int
    var avgCPM: Double?
    var detectionConfidence: Double?
    var sourceRaw: String           // "auto" | "manualTrigger" | "calibration"
    var notes: String?
    var seenInDashboard: Bool
    @Relationship(deleteRule: .cascade) var samples: [ChewSample] = []
    @Relationship(deleteRule: .cascade) var comfortReport: ComfortReport?

    init(startedAt: Date, source: MealSource = .auto) {
        self.id = UUID()
        self.startedAt = startedAt
        self.chewCount = 0
        self.sourceRaw = source.rawValue
        self.seenInDashboard = false
    }

    enum MealSource: String { case auto, manualTrigger, calibration }
    var source: MealSource { MealSource(rawValue: sourceRaw) ?? .auto }
}

// ChewSample.swift
@Model
final class ChewSample {
    var sessionId: UUID
    var timestamp: Date
    var intensity: Double
    var confidence: Double

    init(sessionId: UUID, timestamp: Date, intensity: Double, confidence: Double) {
        self.sessionId = sessionId
        self.timestamp = timestamp
        self.intensity = intensity
        self.confidence = confidence
    }
}

// ComfortReport.swift
@Model
final class ComfortReport {
    @Attribute(.unique) var id: UUID
    var mealId: UUID?
    var reportedAt: Date
    var score: Int
    var note: String?

    init(mealId: UUID?, score: Int, note: String? = nil) {
        self.id = UUID()
        self.mealId = mealId
        self.reportedAt = Date()
        self.score = score
        self.note = note
    }
}

// DailyInsight.swift
@Model
final class DailyInsight {
    @Attribute(.unique) var date: Date
    var mealsCount: Int
    var totalDurationSec: Int
    var avgCPM: Double?
    var comfortAvg: Double?
    var generatedMessageId: String
    var generatedMessageRendered: String
    var generatedAt: Date

    init(date: Date, mealsCount: Int, totalDurationSec: Int, messageId: String, rendered: String) {
        self.date = date
        self.mealsCount = mealsCount
        self.totalDurationSec = totalDurationSec
        self.generatedMessageId = messageId
        self.generatedMessageRendered = rendered
        self.generatedAt = Date()
    }
}

// UserCalibration.swift
@Model
final class UserCalibration {
    @Attribute(.unique) var id: UUID
    var calibratedAt: Date
    var peakThresholdG: Double
    var mealStartThreshold: Int
    var calibrationDurationSec: Int
    var calibrationCPM: Double
    var sourceMealId: UUID

    init(peakThresholdG: Double, mealStartThreshold: Int,
         calibrationDurationSec: Int, calibrationCPM: Double, sourceMealId: UUID) {
        self.id = UUID()
        self.calibratedAt = Date()
        self.peakThresholdG = peakThresholdG
        self.mealStartThreshold = mealStartThreshold
        self.calibrationDurationSec = calibrationDurationSec
        self.calibrationCPM = calibrationCPM
        self.sourceMealId = sourceMealId
    }
}

// UserPreferences.swift
@Model
final class UserPreferences {
    @Attribute(.unique) var id: UUID
    var personaRaw: String?         // "gastric" | "diet" | "curious"
    var honestyAcknowledgedAt: Date?
    var notificationsAllowedAt: Date?
    var dailyInsightTime: Date
    var weeklyRecapDayOfWeek: Int
    var weeklyRecapTime: Date
    var pacingToastLevel: String    // "off" | "light" | "standard"
    var endNotifLevel: String       // "off" | "light" | "standard"
    var onboardingCompletedAt: Date?

    init() {
        self.id = UUID()
        self.dailyInsightTime = Calendar.current.date(bySettingHour: 9, minute: 30, second: 0, of: Date())!
        self.weeklyRecapDayOfWeek = 1   // 일요일
        self.weeklyRecapTime = Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: Date())!
        self.pacingToastLevel = "light"
        self.endNotifLevel = "standard"
    }
}
```

### 4.1 ModelContainer 구성 (`ChewCoachApp.swift`)

```swift
import SwiftUI
import SwiftData

@main
struct ChewCoachApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(
                for: MealSession.self, ChewSample.self, ComfortReport.self,
                     DailyInsight.self, UserCalibration.self, UserPreferences.self
            )
        } catch {
            fatalError("ModelContainer 생성 실패: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootRouterView()
                .environment(\.appEnvironment, AppEnvironment.live(container: container))
        }
        .modelContainer(container)
    }
}
```

### 4.2 AppEnvironment (DI)

```swift
struct AppEnvironment {
    let motionStream: MotionStream
    let permissionCoordinator: PermissionCoordinator
    let mealRepository: MealRepository
    let messagePicker: MessagePicker
    let messageRenderer: MessageRenderer
    let calibrationEngine: CalibrationEngine
    let audioMonitor: AudioSessionMonitor

    static func live(container: ModelContainer) -> AppEnvironment {
        let context = ModelContext(container)
        let repo = MealRepository(context: context)
        return AppEnvironment(
            motionStream: liveOrMock(),
            permissionCoordinator: PermissionCoordinator(),
            mealRepository: repo,
            messagePicker: MessagePicker(evaluator: TriggerEvaluator()),
            messageRenderer: MessageRenderer(),
            calibrationEngine: CalibrationEngine(),
            audioMonitor: AudioSessionMonitor()
        )
    }

    private static func liveOrMock() -> MotionStream {
        #if targetEnvironment(simulator)
        return MockMotionStream()
        #else
        return LiveMotionStream()
        #endif
    }
}
```

---

## 5. CMHeadphoneMotionManager 통합 패턴

### 5.1 Live / Mock 분기

위 §1.2 코드 그대로. 시뮬레이터는 자동으로 Mock, 실기기는 Live (`#if targetEnvironment(simulator)`).

### 5.2 권한 요청 (Motion)

```swift
import CoreMotion

@Observable
final class PermissionCoordinator {
    enum MotionState { case notDetermined, authorized, denied }

    var motionState: MotionState = .notDetermined

    func requestMotion() async {
        // CMHeadphoneMotionManager 자체는 별도 권한 X — 그러나 startDeviceMotionUpdates 시도 시
        // iOS가 NSMotionUsageDescription 기반 권한 다이얼로그 노출
        let manager = CMHeadphoneMotionManager()
        if !manager.isDeviceMotionAvailable {
            motionState = .denied
            return
        }
        // start 시도 → 시스템 다이얼로그 → 콜백으로 상태 추론
        manager.startDeviceMotionUpdates(to: .main) { motion, error in
            if let error = error as NSError?, error.code == CMErrorMotionActivityNotAuthorized.rawValue {
                self.motionState = .denied
            } else if motion != nil {
                self.motionState = .authorized
            }
            manager.stopDeviceMotionUpdates()
        }
    }

    func requestNotifications(reason: String) async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch { return false }
    }
}
```

### 5.3 Info.plist 한국어 카피 (UX §3.4)

`project.yml`에 박힌 키:

```yaml
NSMotionUsageDescription: "AirPods 모션으로 식사 시작·끝을 자동으로 살펴봐요. 데이터는 기기 내에서만 처리됩니다."
```

권한 요청 직전 *시스템 prompt 위*에 추가 컨텍스트 카피 (UX §3.4):

> "AirPods 모션 데이터로 식사 시간을 자동으로 살펴봐요. 데이터는 기기에서만 처리되고 7일 후 자동 삭제돼요."

### 5.4 Audio Session (영상 시청 컨텍스트 — UX §4.3)

```swift
import AVFoundation
import Combine

@Observable
final class AudioSessionMonitor {
    var isVideoPlaying: Bool = false
    private var timer: Timer?

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.isVideoPlaying = AVAudioSession.sharedInstance().isOtherAudioPlaying
        }
    }

    func stop() { timer?.invalidate() }
}
```

`UIBackgroundModes: audio`(`project.yml`)와 결합 → 영상 시청 중 IMU 수신 유지 (signal §5.6).

### 5.5 AirPods 분리·재연결 (signal §2.5 mitigation 4)

```swift
// CMHeadphoneMotionManager는 connect/disconnect 콜백 미제공 — AVAudioSession route change로 감지
NotificationCenter.default.addObserver(
    forName: AVAudioSession.routeChangeNotification, object: nil, queue: .main
) { notification in
    guard let reason = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
          let changeReason = AVAudioSession.RouteChangeReason(rawValue: reason) else { return }
    switch changeReason {
    case .oldDeviceUnavailable: tracker.markDisconnected()
    case .newDeviceAvailable: tracker.markReconnected()
    default: break
    }
}
```

UX §3.6 `paused` 상태 → 5분 내 재연결 시 자동 재개, 5분 초과 시 부분 데이터로 자동 종료.

---

## 6. 디자인 토큰 (UX §9 — Swift extension)

### 6.1 색 (`Shared/DesignSystem/Color+Tokens.swift`)

```swift
import SwiftUI

extension Color {
    // Brand
    static let brandPrimary = Color("BrandPrimary")    // Assets.xcassets 등록: light=#5B7CFF dark=adapted
    static let brandAccent  = Color("BrandAccent")     // #FFB54A (light) / dark adapted

    // Semantic 알리아스 (Apple 시스템 우선)
    static let positive = Color(uiColor: .systemGreen)
    static let warning  = Color(uiColor: .systemOrange)
    static let critical = Color(uiColor: .systemRed)
}
```

`Assets.xcassets`에 `BrandPrimary` (Universal + Dark Appearance) / `BrandAccent` ColorSet 등록.

### 6.2 폰트 (`Shared/DesignSystem/Font+Tokens.swift`)

```swift
import SwiftUI

extension Font {
    static let displayLarge = Font.largeTitle.weight(.bold)
    static let title1S = Font.title.weight(.semibold)
    static let title2S = Font.title2.weight(.semibold)
    static let title3R = Font.title3
    static let headlineS = Font.headline
    static let bodyR = Font.body
    static let calloutR = Font.callout
    static let caption1R = Font.caption
    static let caption2R = Font.caption2
    static let timerDisplay = Font.system(size: 56, weight: .semibold, design: .monospaced)
}
```

모든 텍스트는 시맨틱 토큰 사용 → Dynamic Type 자동 스케일.

### 6.3 간격·layout (`Shared/DesignSystem/Spacing.swift`)

```swift
enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

enum CornerRadius {
    static let card: CGFloat = 16
    static let button: CGFloat = 12
    static let pill: CGFloat = 999
    static let small: CGFloat = 8
}

enum HitArea {
    static let min: CGFloat = 44
}
```

### 6.4 모션 (`Shared/DesignSystem/Motion.swift`)

```swift
import SwiftUI

enum AppMotion {
    static let defaultDuration: Double = 0.3
    static let longDuration: Double = 0.6
    static let spring = Animation.spring(response: 0.4, dampingFraction: 0.8)

    /// reduce_motion 환경 시 즉시 전환
    static func adaptive(_ reduceMotion: Bool, default: Animation = .easeInOut(duration: 0.3)) -> Animation {
        reduceMotion ? .linear(duration: 0) : `default`
    }
}
```

---

## 7. 권한 흐름 시퀀스 (UX §7 정확 반영)

### 7.1 Onboarding 5 단계 (시점 분리)

```
Step 1: OnboardingWelcomeView
   └─ "시작하기" 탭
Step 2: OnboardingPersonaView  
   └─ 페르소나 1개 선택 → "다음"
Step 3: OnboardingHowItWorksView  
   └─ 3 카드 (정직성 카드 = card 3 = 정확도 ±15% 노출 — Vessyl 함정 회피 신호)
   └─ "다음"
Step 4: OnboardingMotionPermissionView
   ├─ "AirPods로 자동 인식 켜기" 탭
   │     → PermissionCoordinator.requestMotion() → 시스템 prompt
   │        ├─ 허용 → motionState=.authorized → "다음" 자동 활성
   │        └─ 거부 → motionState=.denied → fallback 카피
   │              "괜찮아요. 식사할 때 *시작* 버튼을 직접 누르셔도 똑같이 작동해요."
   │              → "다음" 자동 활성
   └─ "나중에" 탭 → motionState 유지 → fallback 카피 + "다음"
Step 5: OnboardingCalibrationIntroView
   ├─ "이번 끼니에 시작할게요" 탭
   │     → ActiveMealView(mode: .calibrating)
   │        └─ 식사 종료 시 CalibrationEngine.calibrate() → UserCalibration 저장
   │           → DashboardView 진입
   └─ "나중에 할게요" 탭
         → DashboardView 진입 (캘리브레이션은 Settings에서 재시도 가능)
```

### 7.2 Notifications 권한 — 첫 인사이트 카드 노출 직후

```
Day 1 또는 Day 2: DashboardView 진입 시
   ├─ 첫 InsightCard 노출 가능 조건 충족 (식사 ≥ 1)
   │     → NotificationPermissionPromptSheet 노출
   │        └─ "다음 식사 결과를 살짝 알려드릴까요? 하루 1번 정도예요."
   │           ├─ "켤게요" → coordinator.requestNotifications() → 시스템 prompt
   │           └─ "나중에" → in-app 카드만 노출, 다음 진입 시 배너로 재요청 옵션
```

### 7.3 거부 시 fallback (UX §7.3)

| 권한 | 거부 시 동작 |
|------|----------|
| Motion | 자동 검출 비활성. 수동 시작 트리거만으로 V1 정상 작동. Settings에서 재요청 가능 안내. |
| Notifications | in-app 카드만 노출. 푸시 없음. Dashboard 재방문 배너로 재요청. |
| Live Activity (V1.5) | 식사 중 화면 표준 모드만. |

### 7.4 정직성 카드 선노출 (UX §3.3 card 3)

OnboardingHowItWorksView card 3 = *권한 요청 전*에 정확도 ±15% / "치료가 아니라 행동 변화 코칭" 명시. 사용자가 약속받지 않은 것을 명확히 한 후 권한 요청 → 신뢰 빌드.

```
Card 3/3
[hand.raised.fill icon]

100% 정확하지 않아요. (추정 ±15%)
치료가 아니라 *행동 변화 코칭*이에요.
```

---

## 8. 빌드 단계 + 단계별 검증 체크리스트

`02_app_architecture.md` §6 6단계와 정합. 각 단계에 *xcodebuild 명령*과 *체크리스트* 포함.

### Step 1 — 데이터 모델·스토리지 (1~1.5일)

#### 작업

```bash
mkdir -p app/ChewCoach/{App,Features,Core,Shared,Resources,Preview\ Content}
mkdir -p app/ChewCoach/Core/{Sensing,Detection,Calibration,Storage,Coaching,Permissions,AudioContext}
mkdir -p app/ChewCoach/Shared/{DesignSystem,Components}
mkdir -p app/ChewCoachTests app/ChewCoachUITests
# project.yml 작성 (§2.2 골격 참고)
cd app && xcodegen generate
```

- `App/ChewCoachApp.swift` (위 §4.1 코드 그대로)
- `App/AppEnvironment.swift` (§4.2)
- `Core/Storage/` 6개 `@Model` 파일 (§4 코드 그대로)
- `Core/Storage/MealRepository.swift` (`02_app_architecture.md` §4.3 API 그대로)
- `Resources/Info.plist` (`project.yml`이 자동 생성 — 또는 properties로 인라인)
- `Resources/Assets.xcassets` (`BrandPrimary`, `BrandAccent` ColorSet, `AppIcon` 빈 placeholder)

#### 검증

```bash
xcodebuild -project app/ChewCoach.xcodeproj -scheme ChewCoach \
  -destination 'generic/platform=iOS Simulator' \
  -skipPackagePluginValidation build
```

- [ ] 빌드 통과
- [ ] 빌드 워닝 0건
- [ ] `MealRepositoryTests` CRUD 4개 (save / recentMeals / attachComfort / deleteAll) 통과 (Mock context로)
- [ ] `ModelContainer` 생성 성공 — fatalError 없이 init 완료

### Step 2 — 코어 알고리즘 (3~4일)

#### 작업

- `Core/Sensing/MotionStream.swift` (protocol)
- `Core/Sensing/MockMotionStream.swift` (synthetic generator — §1.2)
- `Core/Detection/DetectorConstants.swift` (`02_app_architecture.md` 부록 A 그대로)
- `Core/Detection/Preprocessor.swift` (§1.3)
- `Core/Detection/BiquadFilter.swift` (§1.4 — **SOS 계수 SciPy로 재계산해서 교체**)
- `Core/Detection/ArtifactFilter.swift` (§1.5)
- `Core/Detection/ChewDetector.swift` (§1.6)
- `Core/Detection/MealSessionTracker.swift` (§1.7)
- `Core/Calibration/CalibrationEngine.swift` (§1.8)

#### 검증

```bash
xcodebuild -project app/ChewCoach.xcodeproj -scheme ChewCoach \
  -destination 'generic/platform=iOS Simulator' build
# 시뮬 다운로드 후
xcodebuild -project app/ChewCoach.xcodeproj -scheme ChewCoach \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=17.0' test
```

- [ ] 빌드 통과
- [ ] signal §3.4 단위 테스트 12개 통과 (T1~T12)
- [ ] `CalibrationEngineTests` 통과 (p70 + clamp 검증)
- [ ] Mock 분기 시뮬레이터에서 sine wave → ChewEvent emit 확인

### Step 3 — UI 화면 (3~4일)

#### 작업

- `Shared/DesignSystem/` (Color/Font/Spacing/Motion — §6)
- `Shared/Components/` (Custom 7개 — §2.3)
- `Features/Onboarding/` (5개 View + Flow — §2.2)
- `Features/Dashboard/` (Dashboard / MealHistory / MealDetail / WeeklyRecap)
- `Features/Settings/` (SettingsView / HonestyPledgeView)
- `Features/ActiveMeal/` (ActiveMealView + ViewModel + Sheet)
- `App/RootRouterView.swift` (Onboarding 미완료 → OnboardingFlow / 완료 → RootTabView)

#### 검증

- [ ] 빌드 통과
- [ ] 시뮬레이터에서 11화면 + 모달 3개 모두 도달 가능 (네비게이션 끊김 0건)
- [ ] SwiftUI `#Preview` 모든 화면 렌더링 OK (Mock 데이터)
- [ ] 빈 상태 카피 모두 정의됨 (Dashboard / MealHistory / 차트)

### Step 4 — 라이브 모션 통합 (1.5~2일)

#### 작업

- `Core/Sensing/LiveMotionStream.swift` (§1.2)
- `Core/Permissions/PermissionCoordinator.swift` (§5.2)
- `Core/AudioContext/AudioSessionMonitor.swift` (§5.4)
- `AppEnvironment.live` 분기 적용 (§4.2)
- `project.yml` `Info.plist` properties 검증 (`NSMotionUsageDescription`, `UIBackgroundModes: audio`)

#### 검증

- [ ] 빌드 통과 + 워닝 0건
- [ ] 시뮬레이터에서 `MockMotionStream` 자동 분기, 식사 시뮬 동작
- [ ] (실기기) 권한 요청 다이얼로그 노출 — 사용자 별도 검증 필요
- [ ] 권한 거부 시 fallback UI 정상 + Settings 딥링크 동작

### Step 5 — 코칭 메시지 엔진 (2일)

#### 작업

- `Core/Coaching/CoachingMessage.swift` (§3.1)
- `Core/Coaching/MessageLibrary.swift` (§3.2 — 32개 static let)
- `Core/Coaching/TriggerEvaluator.swift` (§3.3)
- `Core/Coaching/MessagePicker.swift`
- `Core/Coaching/MessageRenderer.swift` (§3.4)
- `Core/Coaching/KoreanParticle.swift` (§3.4)
- `Core/Coaching/PatternEngine.swift` (UX §5.3 V1 패턴 — fastest weekday / lunch vs dinner / quick → comfort)
- `Core/Coaching/InsightGenerator.swift` (BackgroundTasks API — `BGAppRefreshTask` 등록, Daily 09:30 트리거)

#### 검증

- [ ] 빌드 통과
- [ ] `MessageLibraryTests` 4개 모두 통과 (32개 / 카테고리 분포 / 금지 표현 / 해요체 종결)
- [ ] `TriggerEvaluatorTests` 컨텍스트 dictionary 입력 → 카테고리별 1개 선택
- [ ] 7일 시뮬 데이터 입력 → DailyInsight 7개 생성 + WeeklyRecap 시드 1개

### Step 6 — 폴리시·접근성 (1.5~2일)

#### 작업

- Dynamic Type AX1~AX5 모든 화면 깨짐 점검 (`ViewThatFits`로 AX3+ 세로 fallback)
- VoiceOver 라벨 (UX §10.1) — Custom 컴포넌트 모두
- 다크 모드 — `Color.label` / `.systemBackground` 100% 사용 검증
- prefers-reduced-motion (UX §10.4)
- 빌드 워닝 모두 0건으로
- 5초 룰 시나리오 5개 (UX §11.1) self-audit

#### 검증

- [ ] `xcodebuild build` 워닝 0건
- [ ] 시뮬레이터 다크 모드 토글 시 모든 화면 적응
- [ ] VoiceOver 흐름 5개 (UX §10.5) 완주 가능
  - 온보딩 → 캘리브레이션 시작
  - 수동 식사 시작 → 종료
  - Comfort 셀프리포트 입력
  - 주간 회고 진입
  - 알림 설정 끄기/켜기
- [ ] AX5에서 모든 화면 overflow 0건 (`ViewThatFits` 작동 확인)
- [ ] `MessageLibraryTests` 영어 잔존 lint 통과
- [ ] 안티-함정 체크리스트 (UX §11.2) 15개 모두 ✓

---

## 9. 성공 기준 (QA 인계 전 체크리스트)

`ios-app-qa`에 인계하기 전 *구현자 단독으로 확인 가능*한 시나리오·정량 기준.

### 9.1 빌드 정량 기준

- [ ] `xcodebuild ... build` 통과 (generic destination)
- [ ] 빌드 워닝 0건
- [ ] 외부 SPM 의존성 0개 (project.yml `dependencies: []`)
- [ ] 단위 테스트 12개(T1~T12) + α(`MessageLibraryTests` 4개 + `CalibrationEngineTests` + `MealRepositoryTests` 4개 + `KoreanParticleTests`) 모두 통과

### 9.2 시뮬레이터 검증 시나리오 5개

각 시나리오는 시뮬레이터에서 *Mock 모션 분기*로 완주 가능.

| # | 시나리오 | 통과 기준 |
|---|---------|--------|
| 1 | **첫 실행 → 캘리브레이션 식사** | OnboardingFlow 5단계 진입 → ActiveMealView (calibrating) 도달 → 종료 → CalibrationResult 저장 → DashboardView 진입 (UserPreferences.onboardingCompletedAt set) |
| 2 | **수동 식사 시작 → 종료 → MealResultCard** | DashboardView FAB 탭 → MealStartConfirmationSheet → 시작 → ActiveMealView (active) → "식사 끝났어요" → MealResultCard 노출 (5초 룰: 시각·시간·코칭 메시지·Comfort row 모두 인지) |
| 3 | **Comfort 셀프리포트 입력** | MealResultCard 또는 Dashboard ComfortSelfReportRow 이모지 1탭 → ComfortReport 저장 + 1초 toast |
| 4 | **MealHistoryView → MealDetailView** | 탭바 2 진입 → 누적 세션 리스트 → row 탭 → MealDetailView 진입 (Swift Charts 라인 차트 + 코칭 메시지) |
| 5 | **WeeklyRecap (Day 7+ 시뮬)** | UserPreferences 강제로 7일 전 진입 + 7일 시뮬 데이터 → DashboardView 진입 시 WeeklyRecapSheet 자동 노출 → 평균 비교 + Discovery 1개 |

### 9.3 5초 룰 self-audit (UX §11.1)

- [ ] OnboardingWelcomeView — "AirPods + 위 건강" 키워드 인지 < 5초
- [ ] DashboardView (Day 2+) — "오늘 N분", "어제보다 차분" 인지 < 5초
- [ ] MealResultCard — "오늘 점심 결과", "11분 32초", Comfort row 진입 인지 < 5초
- [ ] ActiveMealView — "지금 식사 중", 타이머, 종료 버튼 인지 < 5초
- [ ] WeeklyRecapSheet — "이번 주 회고", 평균 비교, Discovery 1개 인지 < 5초

### 9.4 안티-함정 체크리스트 (UX §11.2 — 출시 전 self-audit)

- [ ] 화면 헤드/CTA에 "씹기 횟수" / "트래킹" 0건
- [ ] 모든 카피 "치료" / "회복 보장" / "위염 회복" 0건 (`MessageLibraryTests` 통과)
- [ ] "정확하게" / "100%" 0건. "추정 ±15%" 표시 ≥ 3곳 (HowItWorks card 3, Settings 정직성, MealDetail)
- [ ] Motion·Notifications 권한 일괄 요청 0건 (시점 분리 검증)
- [ ] 식사 중 햅틱·소리 알림 0건 (V1 햅틱 자체 비활성)
- [ ] 다크 모드: `.systemBackground` / `Color.label` 사용 100%, 하드코딩 white/black 0건
- [ ] `.font(.body)` 등 시맨틱 토큰 사용. 하드코딩 `.font(.system(size: 16))` 0건
- [ ] VoiceOver 흐름 5개 모두 완주 가능
- [ ] UI 카피에 "track" / "data" / "stats" / "monitor" / "score" (영문) 0건
- [ ] 모든 코칭 메시지 해요체 종결 (`MessageLibraryTests` 통과)
- [ ] 사용자 이름·환자·회원 호칭 0건
- [ ] 메시지 본문 이모지 0건. UI 카드 이모지는 Comfort row + persona card만
- [ ] 모든 버튼·이모지·차트 막대 탭 영역 ≥ 44×44pt
- [ ] brand_accent 본문 텍스트 사용 0건 (배경/아이콘만 — 대비 1.97:1로 AA 미달)
- [ ] 빈 상태 카피 모두 정의됨 (Dashboard·MealHistory·차트)

### 9.5 알려진 한계 사용자 노출 검증

- [ ] OnboardingHowItWorksView card 3 — "100% 정확하지 않아요. (추정 ±15%)" 노출
- [ ] Settings → "정직성 약속" — `02_app_architecture.md` §8.2 카피 노출 ("우리는 약속해요" / "약속하지 않아요")
- [ ] Settings → 디바이스 — AirPods 호환성 안내
- [ ] OnboardingMotionPermissionView 거부 시 — 수동 모드 fallback 카피 노출

---

## 부록 A. xcodebuild 명령 모음

```bash
# 빌드 (시뮬 미설치 환경)
xcodebuild -project app/ChewCoach.xcodeproj -scheme ChewCoach \
  -destination 'generic/platform=iOS Simulator' \
  -skipPackagePluginValidation build

# 클린 빌드
xcodebuild -project app/ChewCoach.xcodeproj -scheme ChewCoach \
  -destination 'generic/platform=iOS Simulator' \
  clean build

# 단위 테스트 (시뮬 1개 다운로드 후)
xcodebuild -project app/ChewCoach.xcodeproj -scheme ChewCoach \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=17.0' test

# project.yml 변경 후 재생성
cd app && xcodegen generate

# 시뮬 다운로드
xcodebuild -downloadPlatform iOS
```

---

## 부록 B. 매직 넘버 표 (signal 부록 A — DetectorConstants.swift 그대로)

| 상수 | 값 | 단위 | 근거 |
|------|----|----|----|
| SAMPLE_RATE | 25.0 | Hz | CMHeadphoneMotionManager 추정 |
| BAND_LOW_HZ | 0.94 | Hz | 일반 저작 빈도 하한 (분당 56회) |
| BAND_HIGH_HZ | 2.0 | Hz | 일반 저작 빈도 상한 (분당 120회) |
| MIN_PEAK_INTERVAL_SEC | 0.3 | 초 | 분당 200회 생리 상한 |
| DETECT_WINDOW_SEC | 2.0 | 초 | 2-4회 저작 포함 (학술 표준) |
| DEFAULT_PEAK_THRESHOLD_G | 0.05 | g | IMChew 2024 §3 (캘리브 가능) |
| MEAL_START_WINDOW_SEC | 60 | 초 | 식사 첫 1분 |
| DEFAULT_MEAL_START_THRESHOLD | 25 | 회 | CPM 30 × 60s × 0.83 (캘리브 가능) |
| MEAL_END_WINDOW_SEC | 120 | 초 | 한식 식사 평균 12-20분 |
| MEAL_END_THRESHOLD_CPM | 8.0 | CPM | 식사 종료 후 잔류 컷오프 |
| END_GRACE_SEC | 90 | 초 | 식사 중간 잠시 멈춤 흡수 |
| MIN_MEAL_DURATION_SEC | 90 | 초 | 짧은 false positive 폐기 |
| WALKING_AVG_THRESHOLD | 0.15 | g | 보행 통상 0.2-0.5g 보수적 컷오프 |
| IMPULSE_THRESHOLD | 0.5 | g | 일반 저작 상한 3-5배 |
| BUFFER_SECONDS | 30 | 초 | 60s 윈도우의 절반 + 여유 |
| CALIBRATION_THRESHOLD_MIN | 0.03 | g | 안전 하한 |
| CALIBRATION_THRESHOLD_MAX | 0.12 | g | 안전 상한 |
| CALIBRATION_PERCENTILE_FACTOR | 0.7 | — | p70 |
| CALIBRATION_START_FACTOR | 0.6 | — | 평소 CPM의 60% |
| CALIBRATION_START_FLOOR | 15 | 회 | 매우 천천히 먹는 사람 fallback |

---

## 부록 C. UX 카피 빠른 참조 (구현자 그대로 복붙 가능)

### 온보딩

- Welcome 헤드라인: `"AirPods로\n내 위 컨디션을\n살펴봐요"`
- Welcome 본문: `"의사가 \"천천히 드세요\"라고\n하셨다면, 1분이면 시작해요."`
- Welcome CTA: `"시작하기"`
- HowItWorks Card 1: `"AirPods를 끼고 식사하시면\n자동으로 식사 시간을\n살짝 기록해요."`
- HowItWorks Card 2: `"처음 한 끼만 직접 시작 버튼을 누르시면\n다음부터는 자동이에요."`
- HowItWorks Card 3: `"100% 정확하지 않아요. (추정 ±15%)\n치료가 아니라 *행동 변화 코칭*이에요."`
- MotionPermission CTA: `"AirPods로 자동 인식 켜기"` / `"나중에"`
- MotionPermission 컨텍스트: `"AirPods 모션 데이터로 식사 시간을 자동으로 살펴봐요. 데이터는 기기에서만 처리되고 7일 후 자동 삭제돼요."`
- MotionPermission 거부 fallback: `"괜찮아요. 식사할 때 *시작* 버튼을 직접 누르셔도 똑같이 작동해요."`
- Calibration 헤드: `"이 한 끼만 함께해요"`
- Calibration 본문: `"평소처럼 드시면 됩니다.\nAirPods가 옆에서 한 번만\n당신의 페이스를 익혀요."`
- Calibration CTA: `"이번 끼니에 시작할게요"` / `"나중에 할게요"`

### Persona 카드

| 키 | 제목 | 부제 |
|---|---|---|
| gastric | 위 건강 (위염·소화불량) | 더부룩함이 줄어드는 게 목표예요 |
| diet | 다이어트 정체기 | 천천히 드시면서 회복하고 싶어요 |
| curious | 그냥 궁금해서 | 내 식습관 패턴을 보고 싶어요 |

### ActiveMealView

- idle (calibrating): `"준비됐어요. 한 입 드셔보세요."`
- breath 라벨: `"차분히 드시고 있어요"`
- 부속 정보: `"추정 약 {n}회 씹으셨어요"`
- 종료 CTA: `"식사 끝났어요"`
- paused 헤드: `"잠시 멈춤"` / 본문: `"AirPods가\n잠깐 끊겼어요"` / 안내: `"다시 끼시면 이어 가요"` / CTA: `"수동으로 종료"`
- ending CTA: `"계속"` / `"종료"`

### Dashboard

- empty (Day 0): `"첫 식사를 함께해 주세요. 시작 버튼은 우하단에 있어요."`
- calibration done: `"캘리브레이션 완료! 다음 식사부터 자동으로 살펴봐요."`
- 비교 텍스트: `"+2분"` / `"-3분"` / `"비슷한 페이스"`
- error: `"잠시 정보를 불러오지 못했어요. 다시 시도"`

### MealHistory empty: `"아직 기록이 없어요. 첫 식사를 함께해 주세요."`

### Settings — 정직성 약속

```
우리는 약속해요:
- 식사 시간을 추정으로 보여드려요 (정확도 ±15%)
- 패턴 인사이트를 제공해요
- 행동 변화를 도와드려요

우리는 약속하지 않아요:
- 위염 치료 / 의료적 효과
- 칼로리·음식 종류 자동 인식
- 100% 정확한 측정
```

### 알림 권한 sheet

- 카피: `"다음 식사 결과를 살짝 알려드릴까요? 하루 1번 정도예요."`
- CTA: `"켤게요"` / `"나중에"`

---

## 업데이트 이력

- **2026-05-02**: 초안. 9개 섹션 모두 작성. 알고리즘 Swift 변환 (Detector·Tracker·MotionStream protocol·Calibration), 11화면 + Custom 7개 컴포넌트 명세, 32개 코칭 메시지 Swift struct 배열 코드 스케치, SwiftData 6 entity (그대로 컴파일 수준), CMHeadphoneMotionManager Live/Mock 분기 + AudioSessionMonitor + AirPods route change, 디자인 토큰 Swift extension, 권한 흐름 5단계 + Notifications 시점 분리, 6단계 빌드 + 단계별 xcodebuild 명령 + 체크리스트, 9.1~9.5 성공 기준 시뮬 시나리오 5개 + 5초 룰 + 안티-함정 체크리스트. 부록 A xcodebuild 명령 / 부록 B 매직 넘버 / 부록 C 카피 복붙 라이브러리. 외부 의존성 0건, V1 햅틱 0건, 권한 일괄 요청 0건 원칙 명시.
