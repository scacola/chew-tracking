import Foundation
import SwiftData

/// signal §v1.2-6, §v1.2-9.2 — 사후 분석·CSV 내보내기를 위한 raw IMU frame 영속화 entity.
///
/// **사용자 옵트인 시에만 누적됨** (`UserPreferences.imuDataCollectionOptedIn`).
/// 옵트아웃 default. 옵트인 시 식사 1회 약 22,500 row × ~120 byte ≈ 2.7 MB 저장.
///
/// 1단계 (v1.2-1)에서는 *수집·내보내기*만 구현. 본격적인 PostHoc 분석은 별도 라운드.
@Model
final class IMUFrame {
    @Attribute(.unique) var id: UUID
    /// 부모 MealSession FK (관계 역방향).
    var sessionId: UUID
    /// wall-clock UTC timestamp (CSV·분석용).
    var timestamp: Date
    /// userAcceleration (gravity 제거, g 단위).
    var accelX: Double
    var accelY: Double
    var accelZ: Double
    /// rotationRate (rad/s).
    var gyroX: Double
    var gyroY: Double
    var gyroZ: Double
    /// signal §2.2 — sqrt(x²+y²+z²) raw magnitude.
    var magnitudeRaw: Double
    /// signal §v1.1-1.A — running mean 차감된 zero-mean signal.
    var magnitudeDetrended: Double
    /// 부모 MealSession 역참조 (cascade delete용).
    var mealSession: MealSession?

    init(sessionId: UUID,
         timestamp: Date,
         accelX: Double,
         accelY: Double,
         accelZ: Double,
         gyroX: Double,
         gyroY: Double,
         gyroZ: Double,
         magnitudeRaw: Double,
         magnitudeDetrended: Double,
         mealSession: MealSession? = nil) {
        self.id = UUID()
        self.sessionId = sessionId
        self.timestamp = timestamp
        self.accelX = accelX
        self.accelY = accelY
        self.accelZ = accelZ
        self.gyroX = gyroX
        self.gyroY = gyroY
        self.gyroZ = gyroZ
        self.magnitudeRaw = magnitudeRaw
        self.magnitudeDetrended = magnitudeDetrended
        self.mealSession = mealSession
    }
}
