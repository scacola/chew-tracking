import Foundation
import SwiftData

@Model
final class ComfortReport {
    @Attribute(.unique) var id: UUID
    var mealId: UUID?
    var reportedAt: Date
    var score: Int
    var note: String?

    init(mealId: UUID?, score: Int, note: String? = nil) {
        self.id = UUID()
        self.mealId = mealId
        self.reportedAt = Date()
        self.score = score
        self.note = note
    }
}
