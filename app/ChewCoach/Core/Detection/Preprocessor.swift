import Foundation

/// signal §2.2 — Preprocessor: IMU magnitude 계산 + ring buffer 유지.
///
/// v1.1 Patch (signal §v1.1-1.A): magnitude 정류 결함 해결.
/// - 기존 raw `ringBuffer`는 그대로 유지 (캘리브레이션·디버그용)
/// - 신규 `detrendedRing`: `magnitude(t) - runningMean(magnitude, last 2s)` 형태로 zero-mean 신호.
///   → ChewDetector는 *detrendedRing*을 입력으로 사용해 1.0–1.5Hz 저작 주파수가 그대로 보존되어
///     bandpass 0.94–2.0Hz를 통과한다.
public final class Preprocessor {
    /// 원본 magnitude (raw, 항상 양수). 캘리브레이션·디버그·DC level 계산용.
    public private(set) var ringBuffer: [PreprocessedSample] = []
    /// Detrended magnitude (zero-mean). ChewDetector가 입력으로 사용 (signal §v1.1-1.A).
    public private(set) var detrendedRing: [PreprocessedSample] = []
    private let bufferSeconds: Double
    private let detrendWindowSec: Double

    public init(bufferSeconds: Double = DetectorConstants.BUFFER_SECONDS,
                detrendWindowSec: Double = DetectorConstants.DETREND_WINDOW_SEC) {
        self.bufferSeconds = bufferSeconds
        self.detrendWindowSec = detrendWindowSec
    }

    public func ingest(_ sample: IMUSample) {
        // 1) Raw magnitude (signal §2.2)
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

        // 2) Detrending — running mean 차감 (signal §v1.1-1.A 의사코드 그대로)
        //
        // detrended = magnitude(t) - mean(magnitude, last DETREND_WINDOW_SEC)
        // → zero-mean 신호로 음·양 진동 복원, 정류 효과 제거.
        let detrendCutoff = sample.timestamp - detrendWindowSec
        var sum: Double = 0
        var count: Int = 0
        for s in ringBuffer.reversed() {
            if s.timestamp < detrendCutoff { break }
            sum += s.magnitude
            count += 1
        }
        let dcLevel = count > 0 ? sum / Double(count) : 0
        let detrended = m - dcLevel
        detrendedRing.append(PreprocessedSample(timestamp: sample.timestamp, magnitude: detrended))
        while let first = detrendedRing.first, first.timestamp < cutoff {
            detrendedRing.removeFirst()
        }
    }

    public func reset() {
        ringBuffer.removeAll()
        detrendedRing.removeAll()
    }
}
