import Foundation
import SwiftData

@Model
final class MealSession {
    @Attribute(.unique) var id: UUID
    var startedAt: Date
    var endedAt: Date?
    var durationSec: Int?
    var chewCount: Int
    var avgCPM: Double?
    var detectionConfidence: Double?
    var sourceRaw: String           // "auto" | "manualTrigger" | "calibration"
    var notes: String?
    var seenInDashboard: Bool
    var partialData: Bool
    /// signal §v1.1-4.E — 검출된 ChewEvent 영속화. ChewSample.mealSession이 역방향.
    @Relationship(deleteRule: .cascade, inverse: \ChewSample.mealSession)
    var chewSamples: [ChewSample] = []
    /// signal §v1.2-6, §v1.2-9.2 — raw IMU frame 영속화 (사용자 옵트인 시에만 채워짐).
    @Relationship(deleteRule: .cascade, inverse: \IMUFrame.mealSession)
    var imuFrames: [IMUFrame] = []
    @Relationship(deleteRule: .cascade) var comfortReport: ComfortReport?

    init(startedAt: Date, source: MealSource = .auto) {
        self.id = UUID()
        self.startedAt = startedAt
        self.chewCount = 0
        self.sourceRaw = source.rawValue
        self.seenInDashboard = false
        self.partialData = false
    }

    enum MealSource: String, Codable {
        case auto, manualTrigger, calibration
    }

    var source: MealSource {
        MealSource(rawValue: sourceRaw) ?? .auto
    }
}
