import Foundation
import SwiftData

@Model
final class UserCalibration {
    @Attribute(.unique) var id: UUID
    var calibratedAt: Date
    var peakThresholdG: Double
    var mealStartThreshold: Int
    var calibrationDurationSec: Int
    var calibrationCPM: Double
    var sourceMealId: UUID

    init(peakThresholdG: Double, mealStartThreshold: Int,
         calibrationDurationSec: Int, calibrationCPM: Double, sourceMealId: UUID) {
        self.id = UUID()
        self.calibratedAt = Date()
        self.peakThresholdG = peakThresholdG
        self.mealStartThreshold = mealStartThreshold
        self.calibrationDurationSec = calibrationDurationSec
        self.calibrationCPM = calibrationCPM
        self.sourceMealId = sourceMealId
    }
}
