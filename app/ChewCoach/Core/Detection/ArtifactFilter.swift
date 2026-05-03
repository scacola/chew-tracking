import Foundation

/// signal §2.5 — 식사 외 활동(걷기·말하기·AirPods 조작·끄덕임) 필터.
public struct ArtifactFilter: Sendable {
    public init() {}

    public func isLikelyNonChewing(window: [PreprocessedSample], peakIndex: Int) -> Bool {
        let mags = window.map { abs($0.magnitude) }
        guard !mags.isEmpty, peakIndex >= 0, peakIndex < window.count else { return true }
        let avg = mags.reduce(0, +) / Double(mags.count)

        // 1) 걷기 — 평균 magnitude가 보행 임계 이상이면 reject
        if avg > DetectorConstants.WALKING_AVG_THRESHOLD { return true }

        // 2) AirPods 조작 임펄스 — bandpass 필터로 진폭이 spread되므로
        //    *원본 window 내 어떤 sample이라도* IMPULSE_THRESHOLD를 넘으면 reject.
        if mags.contains(where: { $0 > DetectorConstants.IMPULSE_THRESHOLD }) { return true }

        // 3) 짧은 burst (말하기·웃음) — 0.3s 윈도우에 *상향 zero-crossing 피크*가 다중이면 reject.
        //    (저작은 보통 0.5-1.0s 한 사이클 → 0.3s에 한 피크 미만)
        let recentWindowSec: Double = 0.3
        let recentCount = max(1, Int(DetectorConstants.SAMPLE_RATE * recentWindowSec))
        let recentSamples = Array(window.suffix(recentCount))
        let burstThreshold = DetectorConstants.DEFAULT_PEAK_THRESHOLD_G * 1.5
        var burstPeakCount = 0
        for i in 1..<(recentSamples.count - 1) {
            let prev = recentSamples[i - 1].magnitude
            let cur = recentSamples[i].magnitude
            let next = recentSamples[i + 1].magnitude
            if cur > burstThreshold && cur >= prev && cur >= next {
                burstPeakCount += 1
            }
        }
        if burstPeakCount >= 3 { return true }

        // 4) 머리 끄덕임은 bandpass 0.94 Hz 하한이 이미 컷
        return false
    }
}
