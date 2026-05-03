import Foundation
import SwiftData

/// signal §v1.1-4.E — ChewEvent → ChewSample @Model 매핑.
/// MealSession.chewSamples 관계로 영속화.
@Model
final class ChewSample {
    @Attribute(.unique) var id: UUID
    var sessionId: UUID
    var timestamp: Date           // wall-clock (ChewEvent.timestamp + bootOffset)
    var magnitudePeak: Double     // ChewEvent.magnitudePeak
    var confidence: Double        // ChewEvent.confidence
    /// 부모 MealSession 역참조. signal §v1.1-4.E.
    var mealSession: MealSession?

    init(sessionId: UUID,
         timestamp: Date,
         magnitudePeak: Double,
         confidence: Double,
         mealSession: MealSession? = nil) {
        self.id = UUID()
        self.sessionId = sessionId
        self.timestamp = timestamp
        self.magnitudePeak = magnitudePeak
        self.confidence = confidence
        self.mealSession = mealSession
    }

    /// signal §v1.1-4.E — ChewEvent에서 생성. bootOffset으로 wall-clock 변환.
    /// `event.timestamp`는 CACurrentMediaTime() 기반 monotonic.
    convenience init(from event: ChewEvent,
                     mealSession: MealSession,
                     bootOffset: TimeInterval) {
        self.init(
            sessionId: mealSession.id,
            timestamp: Date(timeIntervalSince1970: event.timestamp + bootOffset),
            magnitudePeak: event.magnitudePeak,
            confidence: event.confidence,
            mealSession: mealSession
        )
    }
}
