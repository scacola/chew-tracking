import Foundation

/// signal §v1.2-9 — 사후 분석기 인터페이스 (1단계 *stub*).
///
/// **현재 (v1.2-1단계)**: 인터페이스만 정의. `RuleBasedAnalyzer`는 v1.1 룰 기반 결과
/// (이미 `MealSession.chewCount` / `avgCPM`)를 그대로 wrap만 함 (no-op).
///
/// **다음 라운드 (v1.2 본구현)**: `EnsembleAnalyzer` — 신호 §v1.2-3 옵션 D
/// (FFT-peak counting / ACF / gyro veto / 3-of-N voting). 베타 사용자 IMU CSV 수집·튜닝 후 구현.
///
/// 1단계의 목적은 *interface 정합성 검증* — 데이터 수집 인프라가 PostHoc과 잘 연결될지 미리 검증.
///
/// **Concurrency**: SwiftData @Model (MealSession·ChewSample)은 Sendable 아님. MainActor에서만
/// 접근. analyze는 async지만 본문은 MainActor에서 수행.
@MainActor
protocol PostHocAnalyzer {
    /// 식사 세션 → 사후 분석 결과.
    ///
    /// - Parameter session: 분석 대상 MealSession (chewSamples + imuFrames 포함).
    /// - Returns: 분석 결과 (chew count + 평균 CPM + 신뢰도 + 알고리즘 식별자).
    func analyze(session: MealSession) async -> PostHocResult
}

/// signal §v1.2-9 — 사후 분석 결과 (1단계).
///
/// v1.2 본구현 시 episode breakdown (`[EpisodeWindow]`), per-axis gyro veto stats 등
/// 더 풍부한 필드 추가 예정.
public struct PostHocResult: Sendable, Equatable {
    /// 분석된 총 chew count. v1.1 룰 기반(`MealSession.chewCount`) 또는 v1.2 ensemble 결과.
    public let chewCount: Int
    /// 평균 chews-per-minute. nil = 산출 불가 (duration 0 등).
    public let avgCPM: Double?
    /// 결과 신뢰도 0..1. 1단계 stub은 ChewSample.confidence 평균을 그대로 사용.
    public let confidence: Double
    /// 알고리즘 식별자. v1.2-1단계는 `"v1.1-rule-based"`, 본구현 후 `"v1.2-D-ensemble"`.
    public let method: String

    public init(chewCount: Int, avgCPM: Double?, confidence: Double, method: String) {
        self.chewCount = chewCount
        self.avgCPM = avgCPM
        self.confidence = confidence
        self.method = method
    }
}

/// signal §v1.2-9 — v1.1 룰 기반 결과를 PostHocResult로 wrap만 하는 *no-op* stub.
///
/// **인터페이스 정합성 검증용**: 실 식사 종료 후 `analyze(session:)` 호출 path를 미리 만들어둠.
/// 미래에 `EnsembleAnalyzer`로 교체 시 호출처 변경 없이 swap 가능.
///
/// 동작:
/// - `chewCount` = `session.chewCount` (v1.1 실시간 누적값)
/// - `avgCPM` = `session.avgCPM`
/// - `confidence` = `session.chewSamples` 평균 confidence (없으면 0.5 기본)
/// - `method` = `"v1.1-rule-based"`
@MainActor
struct RuleBasedAnalyzer: PostHocAnalyzer {
    init() {}

    func analyze(session: MealSession) async -> PostHocResult {
        let samples = session.chewSamples
        let chewCount = session.chewCount
        let avgCPM = session.avgCPM
        let confidence: Double
        if samples.isEmpty {
            confidence = 0.5
        } else {
            let total = samples.reduce(0.0) { $0 + $1.confidence }
            confidence = total / Double(samples.count)
        }
        return PostHocResult(
            chewCount: chewCount,
            avgCPM: avgCPM,
            confidence: confidence,
            method: "v1.1-rule-based"
        )
    }
}
