import Foundation

/// signal §2.3 — Chew detector.
/// 슬라이딩 윈도우(2s) 내에서 bandpass 필터 → 피크 탐지 → artifact 필터 → ChewEvent 발행.
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

    /// signal §2.3 의사코드. v1.1 patch (signal §v1.1-1.A): 입력은 *detrended* (zero-mean) 신호.
    /// abs 정류를 *하지 않고* positive peak만 검출 — 정류 시 주파수 2배가 되는 결함 회피.
    /// (양·음 두 peak는 같은 chew의 양면이므로 양만 잡아도 빈도 정합.)
    public func detectChew(buffer: [PreprocessedSample], now: TimeInterval) -> ChewEvent? {
        // 1) 최근 windowSec(2s) 윈도우 추출
        let windowSec = DetectorConstants.DETECT_WINDOW_SEC
        let window = buffer.filter { $0.timestamp >= now - windowSec && $0.timestamp <= now }
        let minSamples = Int(DetectorConstants.SAMPLE_RATE * windowSec * 0.8)
        guard window.count >= minSamples else { return nil }

        // 2) bandpass 필터 (입력은 detrended zero-mean)
        let filtered = bandpass.filter(window.map(\.magnitude))

        // 3) 최근 0.5초 내 positive peak 후보
        let recentCount = Int(DetectorConstants.SAMPLE_RATE * 0.5)
        let sliceStart = max(0, filtered.count - recentCount)
        guard sliceStart < filtered.count else { return nil }
        let recentSlice = Array(filtered[sliceStart...])
        guard !recentSlice.isEmpty,
              let peakIdxLocal = recentSlice.indices.max(by: { recentSlice[$0] < recentSlice[$1] }) else {
            return nil
        }
        let peakValue = recentSlice[peakIdxLocal]
        // signal §v1.1-1.A: positive peak만. zero-mean 신호이므로 음수 peak는 반대 방향.
        guard peakValue >= peakThresholdG else { return nil }
        guard isLocalMaximum(recentSlice, index: peakIdxLocal) else { return nil }

        // 4) 인접 저작 간격
        let absoluteIdx = sliceStart + peakIdxLocal
        guard absoluteIdx >= 0, absoluteIdx < window.count else { return nil }
        let peakTimestamp = window[absoluteIdx].timestamp
        guard peakTimestamp - lastChewTimestamp >= DetectorConstants.MIN_PEAK_INTERVAL_SEC else { return nil }

        // 5) artifact 필터
        guard !artifactFilter.isLikelyNonChewing(window: window, peakIndex: absoluteIdx) else { return nil }

        // 6) 신뢰도 (진폭/threshold 비율, 0..1 clamp)
        let confidence = min(1.0, peakValue / (peakThresholdG * 2.0))

        lastChewTimestamp = peakTimestamp
        return ChewEvent(timestamp: peakTimestamp, magnitudePeak: peakValue, confidence: confidence)
    }

    private func isLocalMaximum(_ values: [Double], index: Int) -> Bool {
        guard index > 0, index < values.count - 1 else { return true }
        return values[index] >= values[index - 1] && values[index] >= values[index + 1]
    }

    public func reset() {
        lastChewTimestamp = 0
    }
}
