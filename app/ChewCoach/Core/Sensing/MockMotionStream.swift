import Foundation
import simd
#if canImport(QuartzCore)
import QuartzCore
#endif

/// 테스트·시뮬레이터에서 사용하는 합성 모션 스트림.
/// AsyncStream.Continuation 자체가 thread-safe — 별도 락 불필요.
public final class MockMotionStream: MotionStream, @unchecked Sendable {
    private let continuation: AsyncStream<IMUSample>.Continuation
    public let samples: AsyncStream<IMUSample>
    public var isAvailable: Bool { get async { true } }

    private var syntheticTask: Task<Void, Never>?

    public init() {
        var localContinuation: AsyncStream<IMUSample>.Continuation!
        self.samples = AsyncStream { localContinuation = $0 }
        self.continuation = localContinuation
    }

    public func start() async throws {
        // 합성 데이터는 emit/emitSineWave/startSyntheticMealEmission를 호출자가 직접 호출
    }

    public func stop() async {
        syntheticTask?.cancel()
        syntheticTask = nil
        continuation.finish()
    }

    /// 단일 샘플 주입.
    public func emit(_ sample: IMUSample) {
        continuation.yield(sample)
    }

    // MARK: - Legacy synchronous helpers (T1~T12 단위 테스트 보존용)

    /// 합성 sine wave 생성 helper.
    /// y축에만 신호, x·z는 0. timestamp는 startTimestamp부터 1/sampleRate 간격.
    public func emitSineWave(frequencyHz: Double,
                             amplitudeG: Double,
                             durationSec: Double,
                             sampleRate: Double = DetectorConstants.SAMPLE_RATE,
                             startTimestamp: TimeInterval = 0) {
        let count = Int(durationSec * sampleRate)
        for i in 0..<count {
            let t = startTimestamp + Double(i) / sampleRate
            let mag = amplitudeG * sin(2 * .pi * frequencyHz * (Double(i) / sampleRate))
            emit(IMUSample(
                timestamp: t,
                userAccel: SIMD3(0, mag, 0),
                rotationRate: .zero
            ))
        }
    }

    /// 무신호 (0g) 구간 주입.
    public func emitSilence(durationSec: Double,
                            sampleRate: Double = DetectorConstants.SAMPLE_RATE,
                            startTimestamp: TimeInterval = 0) {
        let count = Int(durationSec * sampleRate)
        for i in 0..<count {
            let t = startTimestamp + Double(i) / sampleRate
            emit(IMUSample(
                timestamp: t,
                userAccel: SIMD3(0, 0, 0),
                rotationRate: .zero
            ))
        }
    }

    /// 단일 임펄스 (AirPods 조작 시뮬).
    public func emitImpulse(at timestamp: TimeInterval, magnitudeG: Double) {
        emit(IMUSample(
            timestamp: timestamp,
            userAccel: SIMD3(0, magnitudeG, 0),
            rotationRate: .zero
        ))
    }

    // MARK: - v1.1: 자동 합성 식사 emission (signal §v1.1-4.D)

    /// signal §v1.1-4.D — 시뮬레이터·Preview용 자동 합성 식사 emission.
    ///
    /// 한국인 평균 저작 빈도 1.2 Hz ± 20% jitter, IMChew 정상 진폭 0.06g ± 15% jitter,
    /// 자연 휴식 (30–60초마다 5–15초, p=0.3), 12–18분 분량.
    ///
    /// 별도 Task로 백그라운드 실행 (호출 즉시 반환). `stop()` 호출 시 cancel.
    /// timestamp는 CACurrentMediaTime() 기반 (실제 detector와 동일한 시간축).
    public func startSyntheticMealEmission(
        durationSec: Double = 900,
        chewFrequencyHz: Double = 1.2,
        chewAmplitudeG: Double = 0.06,
        jitterFactor: Double = 0.2,
        includeRestPauses: Bool = true,
        startTimestamp: TimeInterval? = nil
    ) {
        syntheticTask?.cancel()
        let start = startTimestamp ?? Self.nowMonotonic()
        let end = start + durationSec
        let freq = chewFrequencyHz
        let amp = chewAmplitudeG
        let jitter = jitterFactor
        let withRests = includeRestPauses
        let cont = self.continuation

        syntheticTask = Task { [weak self] in
            guard let self else { return }
            var t = start
            // Ramp-up 5s
            await self.emitChewSegment(continuation: cont,
                                       from: t, durationSec: 5,
                                       freqHz: freq,
                                       amplitudeG: amp * 0.5,
                                       jitter: jitter)
            t += 5
            var nextRestAt = t + Double.random(in: 30...60)

            while t < end - 10 {
                if Task.isCancelled { return }
                if withRests && t >= nextRestAt {
                    let restDur = Double.random(in: 5...15)
                    await self.emitSilenceSegment(continuation: cont,
                                                  from: t, durationSec: restDur)
                    t += restDur
                    nextRestAt = t + Double.random(in: 30...60)
                    continue
                }
                let interval = (1.0 / freq) * Double.random(in: 1.0 - jitter ... 1.0 + jitter)
                let amplitude = amp * Double.random(in: 0.85...1.15)
                await self.emitSingleChew(continuation: cont,
                                          at: t,
                                          amplitudeG: amplitude)
                t += interval
            }

            // Ramp-down 10s
            if !Task.isCancelled {
                await self.emitChewSegment(continuation: cont,
                                           from: t, durationSec: 10,
                                           freqHz: freq,
                                           amplitudeG: amp * 0.5,
                                           jitter: jitter)
            }
        }
    }

    /// 동기 버전 — 단위 테스트 (T18) 용. Task.sleep 없이 즉시 emit.
    /// 실 시간 기반 sleep을 빼고 timestamp만 진행시켜 짧은 시간에 합성 식사 시퀀스 검증.
    /// T18 회귀 가드는 *연속 1.2Hz sine* (실 chew와 가장 가까운 신호)을 흘려 검출 흐름이
    /// 작동하는지 검증한다. async 버전은 단일 chew pulse + 자연 휴식으로 더 사실적이지만
    /// 단위 테스트 목적엔 연속 sine이 신호 무결성 검증에 더 유리.
    public func emitSyntheticMealSync(
        durationSec: Double,
        chewFrequencyHz: Double = 1.2,
        chewAmplitudeG: Double = 0.06,
        jitterFactor: Double = 0.2,
        includeRestPauses: Bool = false,
        startTimestamp: TimeInterval = 0
    ) {
        var t = startTimestamp
        // Ramp-up
        emitChewSegmentSync(from: t, durationSec: 5,
                            freqHz: chewFrequencyHz,
                            amplitudeG: chewAmplitudeG * 0.5,
                            jitter: jitterFactor)
        t += 5

        let end = startTimestamp + durationSec
        var nextRestAt = t + 45
        while t < end - 10 {
            if includeRestPauses && t >= nextRestAt {
                emitSilenceSegmentSync(from: t, durationSec: 8)
                t += 8
                nextRestAt = t + 45
                continue
            }
            // 30초 단위로 끊어 emit (chew와 chew 사이 끊김 없는 연속 sine)
            let segmentDur = min(30.0, end - 10 - t)
            if segmentDur <= 0 { break }
            emitChewSegmentSync(from: t, durationSec: segmentDur,
                                freqHz: chewFrequencyHz,
                                amplitudeG: chewAmplitudeG,
                                jitter: jitterFactor)
            t += segmentDur
        }
        emitChewSegmentSync(from: t, durationSec: 10,
                            freqHz: chewFrequencyHz,
                            amplitudeG: chewAmplitudeG * 0.5,
                            jitter: jitterFactor)
    }

    // MARK: - Private emit helpers

    /// signal §v1.1-4.D: 합성 IMU는 실 AirPods userAcceleration의
    /// 잔여 baseline DC(센서 bias + 머리 미세 움직임)를 모방하기 위해 y축에
    /// 작은 baseline을 깔고 그 위에 sine 변동을 얹는다. 이렇게 해야 magnitude가
    /// `baseline + sine`으로 양·음 진동을 보존하고, detrending 후 정상 주파수로 복원된다.
    /// (단순 `(0, A sin, 0)`은 magnitude = `|A sin|`로 반파 정류되어 주파수 2배.)
    private static let SYNTHETIC_BASELINE_G: Double = 0.10

    /// 단일 chew = y축 sine wave 1주기 (≈ 0.4초 동안 amplitude g 펄스).
    private func emitSingleChew(continuation: AsyncStream<IMUSample>.Continuation,
                                at t: TimeInterval,
                                amplitudeG: Double) async {
        let pulseDur = 0.4
        let samples = Int(pulseDur * DetectorConstants.SAMPLE_RATE)
        for i in 0..<samples {
            let dt = Double(i) / DetectorConstants.SAMPLE_RATE
            let mag = Self.SYNTHETIC_BASELINE_G + amplitudeG * sin(2 * .pi * (1 / pulseDur) * dt)
            let noiseX = Double.random(in: -0.005...0.005)
            let noiseZ = Double.random(in: -0.005...0.005)
            continuation.yield(IMUSample(
                timestamp: t + dt,
                userAccel: SIMD3(noiseX, mag, noiseZ),
                rotationRate: .zero
            ))
        }
        try? await Task.sleep(nanoseconds: UInt64(pulseDur * 1_000_000_000))
    }

    private func emitSilenceSegment(continuation: AsyncStream<IMUSample>.Continuation,
                                    from t: TimeInterval,
                                    durationSec: Double) async {
        let samples = Int(durationSec * DetectorConstants.SAMPLE_RATE)
        for i in 0..<samples {
            let dt = Double(i) / DetectorConstants.SAMPLE_RATE
            let noiseX = Double.random(in: -0.005...0.005)
            let noiseZ = Double.random(in: -0.005...0.005)
            // baseline은 silence에도 유지 (자세 잔여)
            continuation.yield(IMUSample(
                timestamp: t + dt,
                userAccel: SIMD3(noiseX, Self.SYNTHETIC_BASELINE_G, noiseZ),
                rotationRate: .zero
            ))
        }
        try? await Task.sleep(nanoseconds: UInt64(durationSec * 1_000_000_000))
    }

    /// 연속 chew sine — ramp-up/down 구간용 (sleep 1회로 묶음).
    private func emitChewSegment(continuation: AsyncStream<IMUSample>.Continuation,
                                 from t: TimeInterval,
                                 durationSec: Double,
                                 freqHz: Double,
                                 amplitudeG: Double,
                                 jitter: Double) async {
        let samples = Int(durationSec * DetectorConstants.SAMPLE_RATE)
        for i in 0..<samples {
            let dt = Double(i) / DetectorConstants.SAMPLE_RATE
            let mag = Self.SYNTHETIC_BASELINE_G + amplitudeG * sin(2 * .pi * freqHz * dt)
            let noiseX = Double.random(in: -0.005...0.005)
            let noiseZ = Double.random(in: -0.005...0.005)
            continuation.yield(IMUSample(
                timestamp: t + dt,
                userAccel: SIMD3(noiseX, mag, noiseZ),
                rotationRate: .zero
            ))
        }
        try? await Task.sleep(nanoseconds: UInt64(durationSec * 1_000_000_000))
    }

    // MARK: - Sync helpers (no Task.sleep) — 단위 테스트 전용

    private func emitSingleChewSync(at t: TimeInterval, amplitudeG: Double) {
        let pulseDur = 0.4
        let samples = Int(pulseDur * DetectorConstants.SAMPLE_RATE)
        for i in 0..<samples {
            let dt = Double(i) / DetectorConstants.SAMPLE_RATE
            let mag = Self.SYNTHETIC_BASELINE_G + amplitudeG * sin(2 * .pi * (1 / pulseDur) * dt)
            emit(IMUSample(
                timestamp: t + dt,
                userAccel: SIMD3(0, mag, 0),
                rotationRate: .zero
            ))
        }
    }

    private func emitSilenceSegmentSync(from t: TimeInterval, durationSec: Double) {
        let samples = Int(durationSec * DetectorConstants.SAMPLE_RATE)
        for i in 0..<samples {
            let dt = Double(i) / DetectorConstants.SAMPLE_RATE
            emit(IMUSample(
                timestamp: t + dt,
                userAccel: SIMD3(0, Self.SYNTHETIC_BASELINE_G, 0),
                rotationRate: .zero
            ))
        }
    }

    private func emitChewSegmentSync(from t: TimeInterval,
                                     durationSec: Double,
                                     freqHz: Double,
                                     amplitudeG: Double,
                                     jitter: Double) {
        let samples = Int(durationSec * DetectorConstants.SAMPLE_RATE)
        for i in 0..<samples {
            let dt = Double(i) / DetectorConstants.SAMPLE_RATE
            let mag = Self.SYNTHETIC_BASELINE_G + amplitudeG * sin(2 * .pi * freqHz * dt)
            emit(IMUSample(
                timestamp: t + dt,
                userAccel: SIMD3(0, mag, 0),
                rotationRate: .zero
            ))
        }
    }

    private static func nowMonotonic() -> TimeInterval {
        #if canImport(QuartzCore)
        return CACurrentMediaTime()
        #else
        return Date().timeIntervalSince1970
        #endif
    }
}
