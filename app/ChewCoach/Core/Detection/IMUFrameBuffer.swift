import Foundation

/// signal §v1.2-6, §v1.2-9 — IMU frame batch buffer.
///
/// **목적**: 25Hz × 식사 15분 = ~22,500 frame을 매 frame 즉시 저장하면 SwiftData I/O 비효율.
/// 메모리 buffer에 1초 분량(25 frame) 누적 후 batch flush.
///
/// 사용 흐름:
/// 1. 옵트인 ON일 때만 사용. 옵트아웃이면 인스턴스 미생성.
/// 2. `MotionStream` sample stream에서 매 sample마다 `append(...)` 호출.
/// 3. 1초마다 (또는 buffer가 25개 도달 시) `drain()` → `[PendingIMUFrame]` 반환.
/// 4. caller (ActiveMealViewModel)가 ModelContext.insert(batch) + save.
///
/// **의도적으로 actor가 아닌 thread-safe class**: AsyncStream consumer Task가 background에서 호출,
/// 주기적 flush는 MainActor Timer에서 trigger. NSLock으로 가벼운 보호.
///
/// 옵트아웃 시 *완전히* 0 frame — caller가 `imuFrameBuffer = nil`로 두면 append 호출 자체가 없음.
public final class IMUFrameBuffer: @unchecked Sendable {
    /// 메모리 임시 frame (아직 flush 전).
    private var pending: [PendingIMUFrame] = []
    private let lock = NSLock()
    /// session id를 holder가 결정 (활성 MealSession.id 매핑).
    private let sessionId: UUID

    public init(sessionId: UUID) {
        self.sessionId = sessionId
    }

    /// IMUSample + Preprocessor 출력 + bootOffset → PendingIMUFrame 누적.
    /// `monotonicTimestamp`는 CACurrentMediaTime() 기반, `bootOffset`을 더해 wall-clock UTC로 변환.
    public func append(sample: IMUSample,
                       magnitudeRaw: Double,
                       magnitudeDetrended: Double,
                       bootOffset: TimeInterval) {
        let frame = PendingIMUFrame(
            sessionId: sessionId,
            timestamp: Date(timeIntervalSince1970: sample.timestamp + bootOffset),
            accelX: sample.userAccel.x,
            accelY: sample.userAccel.y,
            accelZ: sample.userAccel.z,
            gyroX: sample.rotationRate.x,
            gyroY: sample.rotationRate.y,
            gyroZ: sample.rotationRate.z,
            magnitudeRaw: magnitudeRaw,
            magnitudeDetrended: magnitudeDetrended
        )
        lock.lock()
        pending.append(frame)
        lock.unlock()
    }

    /// 누적된 frame을 모두 가져오고 buffer 비움. caller가 ModelContext에 insert.
    /// 빈 배열이면 SwiftData I/O 미수행.
    public func drain() -> [PendingIMUFrame] {
        lock.lock()
        defer { lock.unlock() }
        guard !pending.isEmpty else { return [] }
        let snapshot = pending
        pending.removeAll(keepingCapacity: true)
        return snapshot
    }

    /// 현재 buffer 크기 (테스트·디버그용).
    public var pendingCount: Int {
        lock.lock(); defer { lock.unlock() }
        return pending.count
    }
}

/// SwiftData @Model 의존성 없는 순수 값 타입 (background에서 안전하게 전달 가능).
/// MainActor에서 `IMUFrame(...)` @Model로 변환되어 ModelContext에 insert.
public struct PendingIMUFrame: Sendable {
    public let sessionId: UUID
    public let timestamp: Date
    public let accelX: Double
    public let accelY: Double
    public let accelZ: Double
    public let gyroX: Double
    public let gyroY: Double
    public let gyroZ: Double
    public let magnitudeRaw: Double
    public let magnitudeDetrended: Double
}
