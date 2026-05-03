import XCTest
import SwiftData
import simd
@testable import ChewCoach

/// signal §v1.2-6, §v1.2-9 — 1단계 데이터 수집 인프라 신규 테스트 T19~T22.
///
/// - T19: IMUFrame batch flush — buffer accumulator 검증
/// - T20: CSV export header + row 검증
/// - T21: 옵트아웃 시 0 frame 보장 + 옵트인 토글 후 다음 식사부터 저장
/// - T22: PostHocAnalyzer stub 인터페이스 — RuleBasedAnalyzer가 v1.1 결과와 동일 PostHocResult 반환
@MainActor
final class IMUDataCollectionTests: XCTestCase {

    private func makeRepository() throws -> (MealRepository, ModelContainer) {
        let schema = Schema([
            MealSession.self, ChewSample.self, IMUFrame.self, ComfortReport.self,
            DailyInsight.self, UserCalibration.self, UserPreferences.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)
        return (MealRepository(context: context), container)
    }

    // MARK: - T19: IMUFrame batch flush

    /// signal §v1.2-6, §v1.2-9 — 1초 동안 25 frame을 buffer에 emit → drain → 1개 batch insert 확인.
    func test_T19_imuFrameBuffer_drainsBatchOf25Frames() throws {
        let (repo, _) = try makeRepository()
        let meal = MealSession(startedAt: Date())
        try repo.save(meal)

        let buffer = IMUFrameBuffer(sessionId: meal.id)
        let bootOffset: TimeInterval = 1_700_000_000

        // 1초 동안 25Hz × 1s = 25 frame emit.
        for i in 0..<25 {
            let t = Double(i) / 25.0
            let sample = IMUSample(
                timestamp: t,
                userAccel: SIMD3(0, 0.05 * sin(2 * .pi * 1.2 * t), 0),
                rotationRate: SIMD3(0, 0, 0.01)
            )
            buffer.append(sample: sample,
                          magnitudeRaw: 0.05,
                          magnitudeDetrended: 0.03,
                          bootOffset: bootOffset)
        }
        XCTAssertEqual(buffer.pendingCount, 25, "T19: buffer는 25 frame 누적")

        // drain → 1개 batch (25 frame) 반환, buffer는 비워짐.
        let batch = buffer.drain()
        XCTAssertEqual(batch.count, 25, "T19: 1초 batch = 25 frame")
        XCTAssertEqual(buffer.pendingCount, 0, "T19: drain 후 buffer 비워짐")

        // Repository batch insert.
        try repo.appendIMUFrames(to: meal.id, batch: batch, autoSave: true)
        XCTAssertEqual(repo.imuFrameCount(forMealId: meal.id), 25,
                       "T19: 25 frame이 MealSession에 영속화")

        // 두 번째 drain — 빈 batch.
        let empty = buffer.drain()
        XCTAssertTrue(empty.isEmpty, "T19: 빈 buffer drain은 빈 배열")

        // 빈 batch insert는 no-op.
        XCTAssertNoThrow(try repo.appendIMUFrames(to: meal.id, batch: [], autoSave: true))
        XCTAssertEqual(repo.imuFrameCount(forMealId: meal.id), 25, "T19: 빈 batch insert는 no-op")
    }

    // MARK: - T20: CSV export header + row 검증

    /// signal §v1.2-6.1 — CSV header + 1식사 분량 row 검증.
    func test_T20_csvExport_headerAndRowFormat() throws {
        let (repo, _) = try makeRepository()
        let meal = MealSession(startedAt: Date(timeIntervalSince1970: 1_700_000_000))
        try repo.save(meal)

        // 5초 분량 (125 frame) IMUFrame + 중간에 chew event 1개 (timestamp 매칭용).
        let buffer = IMUFrameBuffer(sessionId: meal.id)
        let bootOffset: TimeInterval = 0   // monotonic timestamp = wall-clock (테스트 단순화)
        for i in 0..<125 {
            let t = 1_700_000_000.0 + Double(i) / 25.0
            let sample = IMUSample(
                timestamp: t,
                userAccel: SIMD3(0.001 * Double(i % 3),
                                 0.06 * sin(2 * .pi * 1.2 * Double(i) / 25.0),
                                 -0.002),
                rotationRate: SIMD3(0.01, 0.005, -0.001)
            )
            buffer.append(sample: sample,
                          magnitudeRaw: 0.06,
                          magnitudeDetrended: 0.04,
                          bootOffset: bootOffset)
        }
        let batch = buffer.drain()
        try repo.appendIMUFrames(to: meal.id, batch: batch, autoSave: true)

        // ChewSample 1개 — 60번째 frame과 timestamp 매칭 (60/25 = 2.4s).
        let chewT = 1_700_000_000.0 + 60.0 / 25.0
        let event = ChewEvent(timestamp: chewT, magnitudePeak: 0.05, confidence: 0.82)
        let sample = ChewSample(from: event, mealSession: meal, bootOffset: 0)
        try repo.appendChewSample(to: meal.id, sample: sample, autoSave: true)

        let url = try repo.exportIMUFramesCSV(sessionID: meal.id, persona: "gastric")
        defer { try? FileManager.default.removeItem(at: url) }
        let csv = try String(contentsOf: url, encoding: .utf8)
        let lines = csv.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)

        // Header 검증.
        let expectedHeader = "timestamp,accel_x,accel_y,accel_z,gyro_x,gyro_y,gyro_z,magnitude_raw,magnitude_detrended,is_chew_detected,chew_confidence,user_label,meta_session_id,meta_persona,meta_app_version"
        XCTAssertEqual(lines.first, expectedHeader, "T20: CSV header 정확")

        // Row 개수: header 1 + 125 frame + 끝에 빈 line 가능.
        let dataLines = lines.dropFirst().filter { !$0.isEmpty }
        XCTAssertEqual(dataLines.count, 125, "T20: 125 frame = 125 data row")

        // 첫 row 컬럼 개수 = 15.
        let firstRowCols = dataLines.first?.split(separator: ",", omittingEmptySubsequences: false) ?? []
        XCTAssertEqual(firstRowCols.count, 15, "T20: 첫 row는 15 column")

        // 60번째 frame에 chew detected = 1, confidence는 0.82±tolerance로 채워져야 함.
        let chewMatchedRows = dataLines.filter { row in
            row.split(separator: ",", omittingEmptySubsequences: false).dropFirst(9).first == "1"
        }
        XCTAssertGreaterThanOrEqual(chewMatchedRows.count, 1,
                                    "T20: 최소 1개 row에 is_chew_detected=1")

        // meta_persona 컬럼에 "gastric" 포함.
        XCTAssertTrue(csv.contains("gastric"), "T20: meta_persona 'gastric' 포함")
        // meta_app_version 컬럼에 v1.2 식별자 포함.
        XCTAssertTrue(csv.contains("v1.2"), "T20: meta_app_version에 v1.2 포함")
    }

    // MARK: - T21: 옵트아웃 시 0 frame + 옵트인 토글 후 저장

    /// signal §v1.2-6 — privacy 보장: 옵트아웃 시 IMUFrame 미저장.
    /// 1단계 구현은 ActiveMealViewModel이 prefs 읽고 buffer를 nil로 두는 분기를 사용한다.
    /// 본 테스트는 이를 *분리해서* 검증: 옵트아웃 = buffer 인스턴스 미생성 가정 → 0 frame.
    func test_T21_optOut_storesZeroFrames_optIn_storesFrames() throws {
        let (repo, _) = try makeRepository()

        // === 시나리오 A: 옵트아웃 ===
        let prefsA = repo.loadOrCreatePreferences()
        prefsA.imuDataCollectionOptedIn = false
        try repo.flush()
        XCTAssertFalse(prefsA.imuDataCollectionOptedIn, "T21-A: 옵트아웃 default")

        let mealA = MealSession(startedAt: Date())
        try repo.save(mealA)

        // 옵트아웃 → ActiveMealViewModel은 imuFrameBuffer = nil → append 호출 자체가 발생 안 함.
        // 시뮬레이션: buffer 인스턴스 자체를 만들지 않은 채 식사 진행.
        let bufferA: IMUFrameBuffer? = prefsA.imuDataCollectionOptedIn
            ? IMUFrameBuffer(sessionId: mealA.id) : nil
        XCTAssertNil(bufferA, "T21-A: 옵트아웃이면 buffer 인스턴스 nil")

        // 식사 종료 시 flush 시도 — buffer가 nil이라 batch 자체가 비어있음.
        let batchA = bufferA?.drain() ?? []
        try repo.appendIMUFrames(to: mealA.id, batch: batchA, autoSave: true)
        XCTAssertEqual(repo.imuFrameCount(forMealId: mealA.id), 0,
                       "T21-A: 옵트아웃 식사는 0 frame (privacy 보장)")

        // === 시나리오 B: 옵트인 토글 후 새 식사 ===
        prefsA.imuDataCollectionOptedIn = true
        try repo.flush()
        XCTAssertTrue(prefsA.imuDataCollectionOptedIn, "T21-B: 옵트인 ON")

        let mealB = MealSession(startedAt: Date())
        try repo.save(mealB)

        let bufferB: IMUFrameBuffer? = prefsA.imuDataCollectionOptedIn
            ? IMUFrameBuffer(sessionId: mealB.id) : nil
        XCTAssertNotNil(bufferB, "T21-B: 옵트인이면 buffer 인스턴스 생성")

        // 25 frame emit → flush
        for i in 0..<25 {
            let t = Double(i) / 25.0
            let s = IMUSample(timestamp: t,
                              userAccel: SIMD3(0, 0.05, 0),
                              rotationRate: .zero)
            bufferB?.append(sample: s, magnitudeRaw: 0.05, magnitudeDetrended: 0.03, bootOffset: 0)
        }
        let batchB = bufferB?.drain() ?? []
        try repo.appendIMUFrames(to: mealB.id, batch: batchB, autoSave: true)
        XCTAssertEqual(repo.imuFrameCount(forMealId: mealB.id), 25,
                       "T21-B: 옵트인 후 식사는 25 frame 저장")

        // 이전 옵트아웃 식사는 여전히 0 frame (혼재 검증).
        XCTAssertEqual(repo.imuFrameCount(forMealId: mealA.id), 0,
                       "T21-B: 옵트아웃 식사는 변동 없이 0 frame 유지")
    }

    // MARK: - T22: PostHocAnalyzer stub interface — RuleBasedAnalyzer 동치 확인

    /// signal §v1.2-9 — RuleBasedAnalyzer는 v1.1 룰 기반 결과를 그대로 wrap (no-op).
    /// 인터페이스 정합성 검증.
    func test_T22_ruleBasedAnalyzer_returnsV11Result() async throws {
        let (repo, _) = try makeRepository()
        let started = Date()
        let meal = MealSession(startedAt: started)
        meal.endedAt = started.addingTimeInterval(600)
        meal.durationSec = 600
        meal.chewCount = 412
        meal.avgCPM = 41.2
        try repo.save(meal)

        // 3개 ChewSample 추가 (confidence 0.6 / 0.8 / 0.7 → 평균 0.7).
        let bootOffset: TimeInterval = 0
        let confidences: [Double] = [0.6, 0.8, 0.7]
        for (i, conf) in confidences.enumerated() {
            let event = ChewEvent(timestamp: Double(i),
                                  magnitudePeak: 0.04 + Double(i) * 0.01,
                                  confidence: conf)
            let sample = ChewSample(from: event, mealSession: meal, bootOffset: bootOffset)
            try repo.appendChewSample(to: meal.id, sample: sample, autoSave: true)
        }

        let analyzer = RuleBasedAnalyzer()
        let result = await analyzer.analyze(session: meal)

        XCTAssertEqual(result.chewCount, 412, "T22: chewCount는 v1.1 결과와 동일")
        XCTAssertEqual(result.avgCPM ?? -1, 41.2, accuracy: 0.001, "T22: avgCPM 동일")
        XCTAssertEqual(result.confidence, 0.7, accuracy: 0.001, "T22: confidence는 ChewSample 평균")
        XCTAssertEqual(result.method, "v1.1-rule-based", "T22: stub method 식별자")

        // ChewSample이 없는 식사도 정상 동작 (confidence default 0.5).
        let mealEmpty = MealSession(startedAt: Date())
        mealEmpty.chewCount = 0
        mealEmpty.avgCPM = nil
        try repo.save(mealEmpty)
        let resultEmpty = await analyzer.analyze(session: mealEmpty)
        XCTAssertEqual(resultEmpty.chewCount, 0)
        XCTAssertNil(resultEmpty.avgCPM)
        XCTAssertEqual(resultEmpty.confidence, 0.5, "T22: ChewSample 없으면 default 0.5")
    }
}
