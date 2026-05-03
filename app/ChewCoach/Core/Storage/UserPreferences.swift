import Foundation
import SwiftData

@Model
final class UserPreferences {
    @Attribute(.unique) var id: UUID
    var personaRaw: String?         // "gastric" | "diet" | "curious"
    var honestyAcknowledgedAt: Date?
    var notificationsAllowedAt: Date?
    var dailyInsightTime: Date
    var weeklyRecapDayOfWeek: Int
    var weeklyRecapTime: Date
    var pacingToastLevel: String    // "off" | "light" | "standard"
    var endNotifLevel: String       // "off" | "light" | "standard"
    var onboardingCompletedAt: Date?

    // === v1.1 신규 (signal §v1.1-1.C) ===
    /// 감도 모드 (Sensitivity Mode) — 첫 사용자 0건 방지 보장.
    /// 기본 ON, 캘리브레이션 1식사 완료 후 자동 OFF.
    var sensitivityModeEnabled: Bool
    /// 캘리브레이션 완료 일시 (nil = cold start).
    var calibrationCompletedAt: Date?

    // === v1.2 신규 1단계 (signal §v1.2-6) ===
    /// 옵트인 raw IMU 데이터 수집 동의. 기본 OFF — privacy first.
    /// ON일 때만 IMUFrame이 SwiftData에 누적됨. OFF일 땐 0 frame 저장.
    var imuDataCollectionOptedIn: Bool

    init() {
        self.id = UUID()
        self.dailyInsightTime = Calendar.current.date(bySettingHour: 9, minute: 30, second: 0, of: Date()) ?? Date()
        self.weeklyRecapDayOfWeek = 1
        self.weeklyRecapTime = Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: Date()) ?? Date()
        self.pacingToastLevel = "light"
        self.endNotifLevel = "standard"
        // signal §v1.1-1.C: 첫 사용자는 감도 모드 ON으로 시작
        self.sensitivityModeEnabled = true
        self.calibrationCompletedAt = nil
        // signal §v1.2-6: 데이터 수집 default OFF (사용자 명시 동의 필요)
        self.imuDataCollectionOptedIn = false
    }
}

enum Persona: String, CaseIterable, Identifiable, Sendable {
    case gastric, diet, curious

    var id: String { rawValue }

    var title: String {
        switch self {
        case .gastric: return "위가 자주 더부룩해요"
        case .diet: return "체중이 잘 안 빠져요"
        case .curious: return "그냥 궁금해서"
        }
    }

    var subtitle: String {
        switch self {
        case .gastric: return "천천히 드시는 습관이 도움이 될 수 있어요"
        case .diet: return "천천히 드시면 포만감이 자연스럽게 와요"
        case .curious: return "내 식습관 패턴을 살펴보고 싶어요"
        }
    }

    var emoji: String {
        switch self {
        case .gastric: return "🫶"
        case .diet: return "🌱"
        case .curious: return "🔎"
        }
    }
}
