import Foundation

/// signal §2.4 — 식사 세션 상태 머신.
public actor MealSessionTracker {
    public enum State: Sendable {
        case idle
        case calibrating
        case awaitingMeal
        case inMeal(descriptor: MealSessionDescriptor, startedAt: Date)
        case ending(descriptor: MealSessionDescriptor, sinceTimestamp: TimeInterval)
    }

    public private(set) var state: State = .awaitingMeal
    private var recentChews: [ChewEvent] = []      // 최근 5분 (300s)
    private var sessionChewCount: Int = 0
    private var mealStartThreshold: Int = DetectorConstants.DEFAULT_MEAL_START_THRESHOLD

    private var eventsContinuation: AsyncStream<MealEvent>.Continuation?
    public nonisolated let events: AsyncStream<MealEvent>

    public init() {
        var local: AsyncStream<MealEvent>.Continuation!
        self.events = AsyncStream { local = $0 }
        self.eventsContinuation = local
    }

    public func setCalibrating() {
        state = .calibrating
        sessionChewCount = 0
    }

    public func setAwaitingMeal() {
        state = .awaitingMeal
    }

    public func setMealStartThreshold(_ value: Int) {
        mealStartThreshold = max(5, value)
    }

    /// signal §2.4 — chew 또는 manual trigger 입력 → 상태 전이.
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
                    endedAt: nil, chewCount: 0, avgCPM: nil,
                    source: .manualTrigger
                )
                state = .inMeal(descriptor: descriptor, startedAt: Date())
                sessionChewCount = 0
                eventsContinuation?.yield(.mealStarted(descriptor))
                return
            }
            // 자동 검출
            let inWindow = recentChews.filter { now - $0.timestamp <= DetectorConstants.MEAL_START_WINDOW_SEC }
            if inWindow.count >= mealStartThreshold,
               let first = inWindow.first {
                let startedDate = Date(timeIntervalSinceReferenceDate: first.timestamp)
                let descriptor = MealSessionDescriptor(
                    id: UUID(), startedAt: startedDate,
                    endedAt: nil, chewCount: inWindow.count, avgCPM: nil,
                    source: .auto
                )
                state = .inMeal(descriptor: descriptor, startedAt: startedDate)
                sessionChewCount = inWindow.count
                eventsContinuation?.yield(.mealStarted(descriptor))
            }

        case .inMeal(let descriptor, let startedAt):
            if chew != nil { sessionChewCount += 1 }
            let cpm = computeCPM(now: now, windowSec: 60)
            eventsContinuation?.yield(.cpmUpdate(cpm))

            if manualTrigger == .endMeal {
                finalize(descriptor: descriptor, startedAt: startedAt, now: now, isManual: true)
                return
            }

            let endCPM = computeCPM(now: now, windowSec: DetectorConstants.MEAL_END_WINDOW_SEC)
            if endCPM < DetectorConstants.MEAL_END_THRESHOLD_CPM {
                state = .ending(descriptor: descriptor, sinceTimestamp: now)
            }

        case .ending(let descriptor, let since):
            if chew != nil { sessionChewCount += 1 }
            if manualTrigger == .endMeal {
                finalize(descriptor: descriptor, startedAt: descriptor.startedAt, now: now, isManual: true)
                return
            }
            let recentCPM = computeCPM(now: now, windowSec: 60)
            if recentCPM >= DetectorConstants.MEAL_END_THRESHOLD_CPM * 1.5 {
                state = .inMeal(descriptor: descriptor, startedAt: descriptor.startedAt)
                eventsContinuation?.yield(.mealResumed)
            } else if now - since >= DetectorConstants.END_GRACE_SEC {
                finalize(descriptor: descriptor, startedAt: descriptor.startedAt, now: now, isManual: false)
            }
        }
    }

    public func markPaused() {
        eventsContinuation?.yield(.mealPaused)
    }

    public func markResumed() {
        eventsContinuation?.yield(.mealResumed)
    }

    private func computeCPM(now: TimeInterval, windowSec: Double) -> Double {
        let count = recentChews.filter { now - $0.timestamp <= windowSec }.count
        return Double(count) * (60.0 / windowSec)
    }

    private func finalize(descriptor: MealSessionDescriptor,
                          startedAt: Date,
                          now: TimeInterval,
                          isManual: Bool) {
        // 자동 종료는 grace 만큼 시간을 빼서 실제 종료 시점 추정
        let endTimestamp: TimeInterval = isManual ? now : (now - DetectorConstants.END_GRACE_SEC)
        let endTime = Date(timeIntervalSinceReferenceDate: endTimestamp)
        let duration = endTime.timeIntervalSince(descriptor.startedAt)
        if duration < DetectorConstants.MIN_MEAL_DURATION_SEC {
            state = .awaitingMeal
            sessionChewCount = 0
            eventsContinuation?.yield(.mealDiscardedAsNoise(reason: "duration<\(Int(DetectorConstants.MIN_MEAL_DURATION_SEC))s"))
            return
        }
        let avgCPM: Double? = duration > 0 ? Double(sessionChewCount) * 60.0 / duration : nil
        let final = MealSessionDescriptor(
            id: descriptor.id, startedAt: descriptor.startedAt, endedAt: endTime,
            chewCount: sessionChewCount, avgCPM: avgCPM, source: descriptor.source
        )
        state = .awaitingMeal
        sessionChewCount = 0
        eventsContinuation?.yield(.mealEnded(final))
    }

    private func handleCalibration(chew: ChewEvent?, manualTrigger: ManualTrigger?, now: TimeInterval) {
        if chew != nil { sessionChewCount += 1 }
        if manualTrigger == .endMeal {
            // CalibrationEngine은 별도 path에서 magnitude 분포를 받음
            state = .awaitingMeal
            sessionChewCount = 0
        }
    }
}
