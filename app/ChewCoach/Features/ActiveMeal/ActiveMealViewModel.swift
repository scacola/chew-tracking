import Foundation
import SwiftUI
import Observation
#if canImport(QuartzCore)
import QuartzCore
#endif

@MainActor
@Observable
final class ActiveMealViewModel {
    enum Phase: Equatable {
        case idle
        case calibrating
        case active
        case paused
        case ending
        case finished(MealSession)
    }

    enum Mode: Equatable {
        case calibration
        case standard
    }

    var phase: Phase = .idle
    var mode: Mode = .standard
    var currentDurationSec: Int = 0
    var currentChewCount: Int = 0
    var currentCPM: Double?
    var isVideoMode: Bool = false

    // === v1.1 디버그 패널 노출 데이터 (signal §v1.1-4.F) ===
    /// 마지막 검출 timestamp (CACurrentMediaTime monotonic). nil = 아직 없음.
    var lastChewMonotonicTs: TimeInterval?
    /// 마지막 검출 confidence.
    var lastChewConfidence: Double?
    /// 최근 5초 raw magnitude max (디버그용).
    var recentMagMax5s: Double = 0
    /// 최근 5초 detrended magnitude max (디버그용).
    var recentDetrendedMax5s: Double = 0
    /// 현재 활성 PEAK_THRESHOLD_G.
    var activePeakThreshold: Double = DetectorConstants.DEFAULT_PEAK_THRESHOLD_G
    /// 현재 활성 임계값 tier.
    var activeThresholdTier: ThresholdTier = .default
    /// MotionStream 종류 ("Live" | "Mock" | "Mock-synthetic").
    var motionStreamKind: String = "Mock"
    /// 감도 모드 ON 여부 (UI 배지·안내 표시).
    var sensitivityModeOn: Bool = true

    private let tracker: MealSessionTracker
    private let motion: any MotionStream
    private let preprocessor: Preprocessor
    private let detector: ChewDetector
    private let calibrationEngine: CalibrationEngine
    private let repository: MealRepository
    private let audioMonitor: AudioSessionMonitor

    /// CACurrentMediaTime() → wall-clock 변환 offset. 앱 시작 시 1회 계산.
    private let bootOffset: TimeInterval

    private var timer: Timer?
    /// signal §v1.2-6, §v1.2-9 — IMUFrame batch flush 1초 타이머. 옵트인 ON일 때만 작동.
    private var imuFlushTimer: Timer?
    private var samplesTask: Task<Void, Never>?
    private var eventsTask: Task<Void, Never>?
    private var startTime: Date = Date()
    private var lastDescriptor: MealSessionDescriptor?

    /// 현재 활성 MealSession (chewSample 누적 대상). nil = 아직 영속화 안 함.
    private var activeMeal: MealSession?

    /// signal §v1.2-6, §v1.2-9 — IMUFrame buffer (옵트인 ON일 때만 nil 아님).
    /// 옵트아웃 시 이 값은 nil → append 호출 자체가 발생 안 함 (privacy 보장).
    private var imuFrameBuffer: IMUFrameBuffer?
    /// 옵트인 여부 캐시 (start 시점에 prefs 읽어 fix; 식사 중 변경되지 않음).
    private var imuOptedInForCurrentSession: Bool = false

    init(env: AppEnvironment,
         tracker: MealSessionTracker = MealSessionTracker(),
         preprocessor: Preprocessor = Preprocessor(),
         detector: ChewDetector? = nil) {
        self.tracker = tracker
        self.motion = env.motionStream
        self.preprocessor = preprocessor

        let prefs = env.mealRepository.loadOrCreatePreferences()
        let cal = env.mealRepository.latestCalibration()
        self.sensitivityModeOn = prefs.sensitivityModeEnabled
        let activeThresh = effectivePeakThreshold(
            sensitivityModeEnabled: prefs.sensitivityModeEnabled,
            calibration: cal
        )
        self.activePeakThreshold = activeThresh
        self.activeThresholdTier = currentThresholdTier(
            sensitivityModeEnabled: prefs.sensitivityModeEnabled,
            calibration: cal
        )
        if let d = detector {
            self.detector = d
        } else {
            self.detector = ChewDetector(peakThresholdG: activeThresh)
        }
        self.calibrationEngine = env.calibrationEngine
        self.repository = env.mealRepository
        self.audioMonitor = env.audioMonitor

        #if canImport(QuartzCore)
        self.bootOffset = Date().timeIntervalSince1970 - CACurrentMediaTime()
        #else
        self.bootOffset = 0
        #endif

        // MotionStream 종류 판별 (디버그 패널용).
        if env.motionStream is MockMotionStream {
            self.motionStreamKind = "Mock"
        } else {
            self.motionStreamKind = "Live"
        }
    }

    func start(mode: Mode) async {
        self.mode = mode
        self.phase = mode == .calibration ? .calibrating : .active
        self.currentDurationSec = 0
        self.currentChewCount = 0
        self.currentCPM = nil
        self.startTime = Date()
        self.lastChewMonotonicTs = nil
        self.lastChewConfidence = nil
        self.recentMagMax5s = 0
        self.recentDetrendedMax5s = 0

        // 임계값 동기화 (Settings 토글 후 식사 시작 케이스)
        let prefs = repository.loadOrCreatePreferences()
        let cal = repository.latestCalibration()
        let thresh = effectivePeakThreshold(
            sensitivityModeEnabled: prefs.sensitivityModeEnabled,
            calibration: cal
        )
        let mealStart = effectiveMealStartThreshold(
            sensitivityModeEnabled: prefs.sensitivityModeEnabled,
            calibration: cal
        )
        detector.peakThresholdG = thresh
        activePeakThreshold = thresh
        activeThresholdTier = currentThresholdTier(
            sensitivityModeEnabled: prefs.sensitivityModeEnabled,
            calibration: cal
        )
        sensitivityModeOn = prefs.sensitivityModeEnabled

        // signal §v1.2-6 — 옵트인 여부를 식사 시작 시점에 fix. 옵트인 ON이면 buffer 생성.
        // (캘리브레이션 식사는 IMU 수집 제외 — 짧고 분석 가치 낮음.)
        imuOptedInForCurrentSession = (mode == .standard) && prefs.imuDataCollectionOptedIn
        imuFrameBuffer = nil   // 새 식사 시작 시 reset (실제 buffer는 mealStarted 이벤트에서 생성)

        await tracker.setMealStartThreshold(mealStart)
        await tracker.setAwaitingMeal()
        if mode == .calibration {
            await tracker.setCalibrating()
        }
        try? await motion.start()
        audioMonitor.start()
        startTimer()
        if imuOptedInForCurrentSession {
            startIMUFlushTimer()
        }
        observeAudio()
        observeSamples()
        observeEvents()

        if mode == .standard {
            await tracker.ingest(chew: nil, manualTrigger: .startMeal, now: relativeTime())
        }

        // === v1.1: 시뮬레이터 + developerMode ON일 때 자동 합성 식사 emission ===
        // signal §v1.1-4.D 권고. 실기기에선 절대 트리거되지 않음 (#if 분기).
        #if targetEnvironment(simulator)
        if let mock = motion as? MockMotionStream,
           UserDefaults.standard.bool(forKey: "developerMode") {
            mock.startSyntheticMealEmission(durationSec: 900)
            motionStreamKind = "Mock-synthetic"
        }
        #endif
    }

    func end() async {
        phase = .ending
        await tracker.ingest(chew: nil, manualTrigger: .endMeal, now: relativeTime())
        await stopAll()
        if mode == .calibration {
            await persistCalibration()
        }
        if let descriptor = lastDescriptor {
            await persistMeal(from: descriptor)
        } else {
            let now = Date()
            let descriptor = MealSessionDescriptor(
                id: UUID(),
                startedAt: startTime,
                endedAt: now,
                chewCount: currentChewCount,
                avgCPM: currentCPM,
                source: mode == .calibration ? .calibration : .manualTrigger
            )
            await persistMeal(from: descriptor)
        }
    }

    func cancel() async {
        await stopAll()
        phase = .idle
    }

    private func observeSamples() {
        samplesTask?.cancel()
        let stream = motion.samples
        let preprocessor = self.preprocessor
        let detector = self.detector
        let tracker = self.tracker
        let bootOffset = self.bootOffset
        samplesTask = Task { [weak self] in
            for await sample in stream {
                preprocessor.ingest(sample)
                let now = sample.timestamp
                // signal §v1.2-6 — 옵트인 ON 시 IMUFrame buffer에 append (1초마다 batch flush).
                // 옵트아웃이면 imuFrameBuffer == nil → append 호출 없음 → 0 frame.
                let rawMag = preprocessor.ringBuffer.last?.magnitude ?? 0
                let detrendedMag = preprocessor.detrendedRing.last?.magnitude ?? 0
                let bufferOpt: IMUFrameBuffer? = await MainActor.run { self?.imuFrameBuffer }
                if let buffer = bufferOpt {
                    buffer.append(
                        sample: sample,
                        magnitudeRaw: rawMag,
                        magnitudeDetrended: detrendedMag,
                        bootOffset: bootOffset
                    )
                }

                // signal §v1.1-1.A: detrended ring을 detector 입력으로 사용
                if let chew = detector.detectChew(buffer: preprocessor.detrendedRing, now: now) {
                    await tracker.ingest(chew: chew, manualTrigger: nil, now: now)
                    await MainActor.run {
                        self?.currentChewCount += 1
                        self?.lastChewMonotonicTs = chew.timestamp
                        self?.lastChewConfidence = chew.confidence
                        self?.persistChewSample(event: chew, bootOffset: bootOffset)
                    }
                }
                // 디버그용 magnitude 업데이트 (5s sliding max).
                let recentRaw = preprocessor.ringBuffer.suffix(Int(DetectorConstants.SAMPLE_RATE * 5)).map(\.magnitude)
                let recentDet = preprocessor.detrendedRing.suffix(Int(DetectorConstants.SAMPLE_RATE * 5)).map(\.magnitude)
                let rawMax = recentRaw.max() ?? 0
                let detMax = recentDet.map(abs).max() ?? 0
                await MainActor.run {
                    self?.recentMagMax5s = rawMax
                    self?.recentDetrendedMax5s = detMax
                }
            }
        }
    }

    private func observeEvents() {
        eventsTask?.cancel()
        let events = tracker.events
        eventsTask = Task { [weak self] in
            for await event in events {
                await MainActor.run {
                    self?.handle(event: event)
                }
            }
        }
    }

    private func observeAudio() {
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 500_000_000)
            self?.isVideoMode = self?.audioMonitor.isVideoPlaying ?? false
        }
    }

    private func handle(event: MealEvent) {
        switch event {
        case .mealStarted(let descriptor):
            lastDescriptor = descriptor
            startTime = descriptor.startedAt
            // 식사 시작 → MealSession 즉시 영속화하여 chewSample append 가능하게.
            if activeMeal == nil {
                let meal = MealSession(startedAt: descriptor.startedAt,
                                       source: meal_source(from: descriptor.source))
                meal.id = descriptor.id
                repository.insertActiveMeal(meal)
                activeMeal = meal
                // signal §v1.2-6 — 옵트인 시 IMUFrame buffer 생성 (식사 id 결정 후).
                if imuOptedInForCurrentSession {
                    imuFrameBuffer = IMUFrameBuffer(sessionId: meal.id)
                }
            }
        case .cpmUpdate(let cpm):
            currentCPM = cpm
        case .mealPaused:
            phase = .paused
        case .mealResumed:
            phase = .active
        case .mealEnded(let descriptor):
            lastDescriptor = descriptor
            phase = .ending
        case .mealDiscardedAsNoise:
            phase = .idle
        }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.currentDurationSec = Int(Date().timeIntervalSince(self.startTime))
            }
        }
    }

    /// signal §v1.2-6 — IMUFrame buffer를 1초마다 batch flush.
    /// 옵트인 ON일 때만 호출됨.
    private func startIMUFlushTimer() {
        imuFlushTimer?.invalidate()
        imuFlushTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.flushIMUFrameBuffer()
            }
        }
    }

    /// 누적된 PendingIMUFrame을 ModelContext에 batch insert.
    /// 옵트아웃이거나 buffer가 비었으면 즉시 return — *no-op*.
    private func flushIMUFrameBuffer() {
        guard let buffer = imuFrameBuffer, let meal = activeMeal else { return }
        let batch = buffer.drain()
        guard !batch.isEmpty else { return }
        do {
            try repository.appendIMUFrames(to: meal.id, batch: batch, autoSave: true)
        } catch {
            // 영속화 실패해도 검출 흐름은 계속 (사용자 입장 영향 없음).
        }
    }

    private func stopAll() async {
        timer?.invalidate()
        timer = nil
        imuFlushTimer?.invalidate()
        imuFlushTimer = nil
        // signal §v1.2-6 — 식사 종료 시 마지막 batch flush (≤1초 분량 잔존 frame).
        flushIMUFrameBuffer()
        imuFrameBuffer = nil
        samplesTask?.cancel()
        samplesTask = nil
        eventsTask?.cancel()
        eventsTask = nil
        await motion.stop()
        audioMonitor.stop()
    }

    /// signal §v1.1-4.E — ChewEvent → ChewSample 영속화.
    private func persistChewSample(event: ChewEvent, bootOffset: TimeInterval) {
        guard let meal = activeMeal else { return }
        let sample = ChewSample(from: event, mealSession: meal, bootOffset: bootOffset)
        // append만 — flush는 식사 종료 시 batch save.
        do {
            try repository.appendChewSample(to: meal.id, sample: sample, autoSave: false)
        } catch {
            // 실패해도 검출 흐름은 계속 (영속화 실패가 검출을 막지 않음)
        }
    }

    private func persistMeal(from descriptor: MealSessionDescriptor) async {
        let endedAt = descriptor.endedAt ?? Date()
        let duration = Int(endedAt.timeIntervalSince(descriptor.startedAt))
        let chewCountFinal = max(currentChewCount, descriptor.chewCount)
        let avgCPMFinal = descriptor.avgCPM ?? currentCPM

        if let meal = activeMeal {
            // 이미 inserted — 메타만 갱신 후 flush
            meal.endedAt = endedAt
            meal.durationSec = duration
            meal.chewCount = chewCountFinal
            meal.avgCPM = avgCPMFinal
            do {
                try repository.flush()
                phase = .finished(meal)
            } catch {
                phase = .idle
            }
            activeMeal = nil
            return
        }

        // 자동 시작이 안 됐을 경우 (manual end 직전) — 즉시 생성 후 save
        let meal = MealSession(startedAt: descriptor.startedAt,
                               source: meal_source(from: descriptor.source))
        meal.endedAt = endedAt
        meal.durationSec = duration
        meal.chewCount = chewCountFinal
        meal.avgCPM = avgCPMFinal
        do {
            try repository.save(meal)
            phase = .finished(meal)
        } catch {
            phase = .idle
        }
    }

    private func persistCalibration() async {
        // raw magnitude (식사 강도 분포) 기반으로 캘리브레이션
        let result = calibrationEngine.calibrate(samples: preprocessor.ringBuffer)
        let mealId = lastDescriptor?.id ?? UUID()
        let calibration = UserCalibration(
            peakThresholdG: result.peakThresholdG,
            mealStartThreshold: result.mealStartThreshold,
            calibrationDurationSec: max(result.calibrationDurationSec, currentDurationSec),
            calibrationCPM: result.calibrationCPM,
            sourceMealId: mealId
        )
        try? repository.saveCalibration(calibration)
        // signal §v1.1-1.C — 캘리브레이션 완료 시 감도 모드 자동 OFF
        let prefs = repository.loadOrCreatePreferences()
        try? repository.markCalibrationCompleted(prefs: prefs)
    }

    private func relativeTime() -> TimeInterval {
        Date().timeIntervalSince(startTime)
    }

    private func meal_source(from source: MealSessionDescriptor.Source) -> MealSession.MealSource {
        switch source {
        case .auto: return .auto
        case .manualTrigger: return .manualTrigger
        case .calibration: return .calibration
        }
    }
}
