import Foundation
import simd
#if canImport(CoreMotion)
import CoreMotion
#endif

/// 실기기에서만 동작 — 시뮬레이터에서는 MockMotionStream을 사용.
/// CMHeadphoneMotionManager는 simulator에서 isDeviceMotionAvailable=false.
public final class LiveMotionStream: MotionStream, @unchecked Sendable {
    #if canImport(CoreMotion)
    private let manager = CMHeadphoneMotionManager()
    #endif

    private let continuation: AsyncStream<IMUSample>.Continuation
    public let samples: AsyncStream<IMUSample>

    public init() {
        var localContinuation: AsyncStream<IMUSample>.Continuation!
        self.samples = AsyncStream { localContinuation = $0 }
        self.continuation = localContinuation
    }

    public var isAvailable: Bool {
        get async {
            #if canImport(CoreMotion)
            return manager.isDeviceMotionAvailable
            #else
            return false
            #endif
        }
    }

    public func start() async throws {
        #if canImport(CoreMotion)
        guard manager.isDeviceMotionAvailable else {
            throw MotionStreamError.unavailable
        }
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            let sample = IMUSample(
                timestamp: motion.timestamp,
                userAccel: SIMD3(motion.userAcceleration.x,
                                  motion.userAcceleration.y,
                                  motion.userAcceleration.z),
                rotationRate: SIMD3(motion.rotationRate.x,
                                    motion.rotationRate.y,
                                    motion.rotationRate.z)
            )
            self.continuation.yield(sample)
        }
        #else
        throw MotionStreamError.unavailable
        #endif
    }

    public func stop() async {
        #if canImport(CoreMotion)
        manager.stopDeviceMotionUpdates()
        #endif
        continuation.finish()
    }
}
