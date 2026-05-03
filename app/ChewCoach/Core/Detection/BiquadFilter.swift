import Foundation

/// 0.94-2.0 Hz Butterworth bandpass, fs=25 Hz, order 4 → 4 SOS biquad sections.
///
/// 계수는 SciPy로 사전 계산 (오프라인):
///   from scipy.signal import iirfilter
///   sos = iirfilter(4, [0.94, 2.0], btype='band', fs=25, output='sos')
///
/// 구현은 pure-Swift Direct Form II Transposed cascade — vDSP 의존 없이 단위 테스트
/// 환경에서도 동일하게 동작. 필터 자체는 stateless 함수로 호출되며 호출 시마다 처음부터
/// 처리 (warm-up 영향은 짧은 윈도우에서 무시 가능).
///
/// 각 section: [b0, b1, b2, a1, a2]  (a0 = 1로 정규화)
public final class BiquadFilter {
    /// 4차 Butterworth bandpass [0.94 Hz – 2.0 Hz] @ fs=25 Hz, SOS 형식 (4 section).
    /// SciPy iirfilter(4, [0.94, 2.0], btype='band', fs=25, output='sos') 결과.
    private let sections: [[Double]] = [
        // Section 1
        [0.0002273445, 0.0004546890, 0.0002273445, -1.6097916778, 0.7512748003],
        // Section 2
        [1.0, 2.0, 1.0, -1.7321118977, 0.8102451204],
        // Section 3
        [1.0, -2.0, 1.0, -1.6531412474, 0.8745212681],
        // Section 4
        [1.0, -2.0, 1.0, -1.8777660964, 0.9341641997]
    ]

    public init() {}

    public func filter(_ input: [Double]) -> [Double] {
        var current = input
        for section in sections {
            current = applyBiquad(section: section, input: current)
        }
        return current
    }

    /// Direct Form II Transposed biquad — numerically stable.
    /// y[n] = b0 * x[n] + z1[n-1]
    /// z1[n] = b1 * x[n] - a1 * y[n] + z2[n-1]
    /// z2[n] = b2 * x[n] - a2 * y[n]
    private func applyBiquad(section: [Double], input: [Double]) -> [Double] {
        let b0 = section[0], b1 = section[1], b2 = section[2]
        let a1 = section[3], a2 = section[4]
        var z1: Double = 0
        var z2: Double = 0
        var output = [Double](repeating: 0, count: input.count)
        for i in 0..<input.count {
            let x = input[i]
            let y = b0 * x + z1
            z1 = b1 * x - a1 * y + z2
            z2 = b2 * x - a2 * y
            output[i] = y
        }
        return output
    }
}
