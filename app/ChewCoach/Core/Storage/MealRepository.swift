import Foundation
import SwiftData

@MainActor
final class MealRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func save(_ meal: MealSession) throws {
        context.insert(meal)
        try context.save()
    }

    /// signal §v1.1-4.E — ChewEvent 영속화. mealSession ID로 찾아서 chewSample 추가.
    /// 호출이 잦으므로 save는 호출자가 batch로 처리하거나, 단발이면 즉시 save.
    @discardableResult
    func appendChewSample(to mealId: UUID, sample: ChewSample, autoSave: Bool = false) throws -> ChewSample {
        guard let meal = self.meal(id: mealId) else {
            throw RepositoryError.notFound
        }
        sample.mealSession = meal
        meal.chewSamples.append(sample)
        context.insert(sample)
        if autoSave {
            try context.save()
        }
        return sample
    }

    /// signal §v1.1-1.C — 캘리브레이션 완료 시 감도 모드 자동 OFF.
    func markCalibrationCompleted(prefs: UserPreferences) throws {
        prefs.sensitivityModeEnabled = false
        prefs.calibrationCompletedAt = Date()
        try context.save()
    }

    /// 사용자가 Settings 토글에서 감도 모드 변경.
    func setSensitivityMode(prefs: UserPreferences, enabled: Bool) throws {
        prefs.sensitivityModeEnabled = enabled
        try context.save()
    }

    /// MealSession을 *insert만* 수행 (chewSample append를 누적하기 위해).
    func insertActiveMeal(_ meal: MealSession) {
        context.insert(meal)
    }

    /// 누적된 변경 일괄 저장 (식사 종료 시 1회 호출 권고).
    func flush() throws {
        try context.save()
    }

    func recentMeals(days: Int) -> [MealSession] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let descriptor = FetchDescriptor<MealSession>(
            predicate: #Predicate { $0.startedAt >= cutoff },
            sortBy: [SortDescriptor(\MealSession.startedAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func todayMeals() -> [MealSession] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        guard let end = cal.date(byAdding: .day, value: 1, to: start) else { return [] }
        let descriptor = FetchDescriptor<MealSession>(
            predicate: #Predicate { $0.startedAt >= start && $0.startedAt < end },
            sortBy: [SortDescriptor(\MealSession.startedAt)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func meal(id: UUID) -> MealSession? {
        let descriptor = FetchDescriptor<MealSession>(
            predicate: #Predicate { $0.id == id }
        )
        return (try? context.fetch(descriptor))?.first
    }

    func attachComfort(mealId: UUID, score: Int, note: String? = nil) throws {
        guard let meal = self.meal(id: mealId) else {
            throw RepositoryError.notFound
        }
        let report = ComfortReport(mealId: mealId, score: score, note: note)
        context.insert(report)
        meal.comfortReport = report
        try context.save()
    }

    func markSeen(mealId: UUID) throws {
        guard let meal = self.meal(id: mealId) else {
            throw RepositoryError.notFound
        }
        meal.seenInDashboard = true
        try context.save()
    }

    func deleteAll() throws {
        try context.delete(model: MealSession.self)
        try context.delete(model: ChewSample.self)
        try context.delete(model: IMUFrame.self)
        try context.delete(model: ComfortReport.self)
        try context.delete(model: DailyInsight.self)
        try context.delete(model: UserCalibration.self)
        try context.save()
    }

    // MARK: - v1.2 신규 (signal §v1.2-6, §v1.2-9)

    /// signal §v1.2-6 — IMUFrame batch insert.
    ///
    /// 옵트인 사용자의 1초마다 25 frame 묶음을 한 번에 ModelContext.insert + save.
    /// 식사 1회 약 22,500 row × ~120 byte ≈ 2.7 MB 디스크 부담.
    ///
    /// 옵트아웃이거나 빈 batch면 즉시 return — *no-op*. (privacy: 옵트아웃 시 0 frame 보장.)
    func appendIMUFrames(to mealId: UUID, batch: [PendingIMUFrame], autoSave: Bool = true) throws {
        guard !batch.isEmpty else { return }
        guard let meal = self.meal(id: mealId) else {
            throw RepositoryError.notFound
        }
        for pending in batch {
            let frame = IMUFrame(
                sessionId: meal.id,
                timestamp: pending.timestamp,
                accelX: pending.accelX,
                accelY: pending.accelY,
                accelZ: pending.accelZ,
                gyroX: pending.gyroX,
                gyroY: pending.gyroY,
                gyroZ: pending.gyroZ,
                magnitudeRaw: pending.magnitudeRaw,
                magnitudeDetrended: pending.magnitudeDetrended,
                mealSession: meal
            )
            context.insert(frame)
            meal.imuFrames.append(frame)
        }
        if autoSave {
            try context.save()
        }
    }

    /// signal §v1.2-6 — 특정 식사의 IMUFrame 개수.
    /// Settings에 "이 식사 데이터 X MB" 동적 표시용.
    func imuFrameCount(forMealId mealId: UUID) -> Int {
        guard let meal = self.meal(id: mealId) else { return 0 }
        return meal.imuFrames.count
    }

    /// signal §v1.2-6 — 전체 IMUFrame 개수 + 추정 디스크 사용량 (MB).
    /// 1 frame ≈ 120 bytes (SwiftData overhead 포함 추정).
    func imuFrameTotalStats() -> (count: Int, estimatedMB: Double) {
        let descriptor = FetchDescriptor<IMUFrame>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        let mb = Double(count) * 120.0 / 1_048_576.0
        return (count, mb)
    }

    /// signal §v1.2-6 — 특정 식사의 IMUFrame만 삭제 (MealSession은 보존).
    /// 사용자가 "이 데이터만 정리" 요청 시.
    func deleteIMUFrames(forMealId mealId: UUID) throws {
        guard let meal = self.meal(id: mealId) else {
            throw RepositoryError.notFound
        }
        for frame in meal.imuFrames {
            context.delete(frame)
        }
        meal.imuFrames.removeAll()
        try context.save()
    }

    /// signal §v1.2-6 — 전체 IMUFrame 삭제 (MealSession·ChewSample은 보존).
    /// Settings "수집된 IMU 데이터 모두 삭제" 버튼.
    func deleteAllIMUFrames() throws {
        try context.delete(model: IMUFrame.self)
        try context.save()
    }

    /// signal §v1.2-6.1 — CSV export.
    ///
    /// Header: `timestamp,accel_x,accel_y,accel_z,gyro_x,gyro_y,gyro_z,magnitude_raw,magnitude_detrended,is_chew_detected,chew_confidence,user_label,meta_session_id,meta_persona,meta_app_version`
    ///
    /// `is_chew_detected` / `chew_confidence`: ChewSample과 timestamp join (±20ms 매칭).
    /// `user_label`: v1.2-1단계 미수집 → 빈 문자열.
    /// 임시 파일로 작성 후 URL 반환. 호출자는 ShareSheet로 내보냄.
    func exportIMUFramesCSV(sessionID: UUID,
                            persona: String? = nil,
                            appVersion: String = "0.1.0-v1.2.1") throws -> URL {
        guard let meal = self.meal(id: sessionID) else {
            throw RepositoryError.notFound
        }
        let frames = meal.imuFrames.sorted { $0.timestamp < $1.timestamp }
        let chewSamples = meal.chewSamples.sorted { $0.timestamp < $1.timestamp }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        // Header
        var csv = "timestamp,accel_x,accel_y,accel_z,gyro_x,gyro_y,gyro_z,magnitude_raw,magnitude_detrended,is_chew_detected,chew_confidence,user_label,meta_session_id,meta_persona,meta_app_version\n"

        // ChewSample timestamps를 sorted 배열로 두고, 매 frame마다 binary search 대신
        // two-pointer 방식 (frames도 sorted) — N+M 선형.
        let matchToleranceSec: TimeInterval = 0.04   // 25Hz frame interval = 40ms
        var chewIdx = 0
        let metaSessionStr = sessionID.uuidString
        let metaPersona = csvEscape(persona ?? "")
        let metaAppVersion = csvEscape(appVersion)

        for frame in frames {
            let ts = formatter.string(from: frame.timestamp)
            // Match ChewSample within tolerance — frames sorted, chewSamples sorted, so advance chewIdx
            while chewIdx < chewSamples.count
                  && chewSamples[chewIdx].timestamp < frame.timestamp.addingTimeInterval(-matchToleranceSec) {
                chewIdx += 1
            }
            var detected = 0
            var confidence: Double? = nil
            if chewIdx < chewSamples.count {
                let cs = chewSamples[chewIdx]
                let delta = abs(cs.timestamp.timeIntervalSince(frame.timestamp))
                if delta <= matchToleranceSec {
                    detected = 1
                    confidence = cs.confidence
                }
            }
            let confidenceStr = confidence.map { String(format: "%.4f", $0) } ?? ""

            csv += "\(ts),\(fmt(frame.accelX)),\(fmt(frame.accelY)),\(fmt(frame.accelZ)),"
            csv += "\(fmt(frame.gyroX)),\(fmt(frame.gyroY)),\(fmt(frame.gyroZ)),"
            csv += "\(fmt(frame.magnitudeRaw)),\(fmt(frame.magnitudeDetrended)),"
            csv += "\(detected),\(confidenceStr),,"     // user_label은 v1.2-1단계 미수집
            csv += "\(metaSessionStr),\(metaPersona),\(metaAppVersion)\n"
        }

        let isoForName = ISO8601DateFormatter()
        isoForName.formatOptions = [.withInternetDateTime]
        let safeStart = isoForName.string(from: meal.startedAt)
            .replacingOccurrences(of: ":", with: "-")
        let filename = "chewcoach_meal_\(sessionID.uuidString)_\(safeStart).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private func fmt(_ v: Double) -> String {
        // 6자리 소수점 — IMU 신호 ~0.001g 분해능 보존.
        String(format: "%.6f", v)
    }

    private func csvEscape(_ s: String) -> String {
        if s.contains(",") || s.contains("\"") || s.contains("\n") {
            let escaped = s.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return s
    }

    func exportCSV() throws -> URL {
        let meals = recentMeals(days: 365)
        var csv = "id,startedAt,endedAt,durationSec,chewCount,avgCPM,source,comfortScore\n"
        let formatter = ISO8601DateFormatter()
        for meal in meals {
            let started = formatter.string(from: meal.startedAt)
            let ended = meal.endedAt.map(formatter.string(from:)) ?? ""
            let duration = meal.durationSec.map(String.init) ?? ""
            let cpm = meal.avgCPM.map { String(format: "%.2f", $0) } ?? ""
            let comfort = meal.comfortReport?.score.description ?? ""
            csv += "\(meal.id),\(started),\(ended),\(duration),\(meal.chewCount),\(cpm),\(meal.sourceRaw),\(comfort)\n"
        }
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("chewcoach_export_\(Int(Date().timeIntervalSince1970)).csv")
        try csv.write(to: tmp, atomically: true, encoding: .utf8)
        return tmp
    }

    func loadOrCreatePreferences() -> UserPreferences {
        let descriptor = FetchDescriptor<UserPreferences>()
        if let existing = (try? context.fetch(descriptor))?.first {
            return existing
        }
        let prefs = UserPreferences()
        context.insert(prefs)
        try? context.save()
        return prefs
    }

    func saveCalibration(_ calibration: UserCalibration) throws {
        context.insert(calibration)
        try context.save()
    }

    func latestCalibration() -> UserCalibration? {
        let descriptor = FetchDescriptor<UserCalibration>(
            sortBy: [SortDescriptor(\UserCalibration.calibratedAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor))?.first
    }
}

enum RepositoryError: Error {
    case notFound
}
