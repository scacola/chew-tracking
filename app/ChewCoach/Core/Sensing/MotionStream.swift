import Foundation

public protocol MotionStream: AnyObject, Sendable {
    var samples: AsyncStream<IMUSample> { get }
    var isAvailable: Bool { get async }
    func start() async throws
    func stop() async
}
