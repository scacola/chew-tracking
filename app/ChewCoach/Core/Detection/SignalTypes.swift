import Foundation
import simd

public struct IMUSample: Sendable {
    public let timestamp: TimeInterval        // CACurrentMediaTime() 기준 초
    public let userAccel: SIMD3<Double>       // g 단위, gravity 제거
    public let rotationRate: SIMD3<Double>    // rad/s

    public init(timestamp: TimeInterval, userAccel: SIMD3<Double>, rotationRate: SIMD3<Double>) {
        self.timestamp = timestamp
        self.userAccel = userAccel
        self.rotationRate = rotationRate
    }
}

public struct PreprocessedSample: Sendable {
    public let timestamp: TimeInterval
    public let magnitude: Double
}

public struct ChewEvent: Sendable {
    public let timestamp: TimeInterval
    public let magnitudePeak: Double
    public let confidence: Double
}

public struct MealSessionDescriptor: Sendable, Identifiable {
    public let id: UUID
    public let startedAt: Date
    public let endedAt: Date?
    public let chewCount: Int
    public let avgCPM: Double?
    public let source: Source

    public enum Source: String, Sendable, Codable {
        case auto, manualTrigger, calibration
    }

    public init(id: UUID, startedAt: Date, endedAt: Date?, chewCount: Int,
                avgCPM: Double?, source: Source) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.chewCount = chewCount
        self.avgCPM = avgCPM
        self.source = source
    }
}

public enum MealEvent: Sendable {
    case mealStarted(MealSessionDescriptor)
    case cpmUpdate(Double)
    case mealPaused
    case mealResumed
    case mealEnded(MealSessionDescriptor)
    case mealDiscardedAsNoise(reason: String)
}

public enum ManualTrigger: Sendable {
    case startMeal
    case endMeal
}

public enum MotionStreamError: Error, Sendable {
    case unavailable
    case permissionDenied
}
