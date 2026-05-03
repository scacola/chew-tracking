import Foundation
import SwiftData

@Model
final class DailyInsight {
    @Attribute(.unique) var date: Date
    var mealsCount: Int
    var totalDurationSec: Int
    var avgCPM: Double?
    var comfortAvg: Double?
    var generatedMessageId: String
    var generatedMessageRendered: String
    var generatedAt: Date

    init(date: Date, mealsCount: Int, totalDurationSec: Int, messageId: String, rendered: String) {
        self.date = date
        self.mealsCount = mealsCount
        self.totalDurationSec = totalDurationSec
        self.generatedMessageId = messageId
        self.generatedMessageRendered = rendered
        self.generatedAt = Date()
    }
}
