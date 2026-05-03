import Foundation
import Observation
import UserNotifications
#if canImport(CoreMotion)
import CoreMotion
#endif

@MainActor
@Observable
final class PermissionCoordinator {
    enum MotionState: Equatable, Sendable {
        case notDetermined
        case authorized
        case denied
    }

    enum NotificationsState: Equatable, Sendable {
        case notDetermined
        case authorized
        case denied
    }

    var motionState: MotionState = .notDetermined
    var notificationsState: NotificationsState = .notDetermined

    func requestMotion() async {
        #if canImport(CoreMotion)
        let manager = CMHeadphoneMotionManager()
        guard manager.isDeviceMotionAvailable else {
            motionState = .denied
            return
        }
        // 시뮬레이터에선 isDeviceMotionAvailable이 false이므로 위에서 .denied 처리됨.
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            var didResume = false
            manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
                guard !didResume else { return }
                Task { @MainActor in
                    if let nsError = error as NSError?, nsError.domain == CMErrorDomain {
                        self?.motionState = .denied
                    } else if motion != nil {
                        self?.motionState = .authorized
                    }
                    manager.stopDeviceMotionUpdates()
                    didResume = true
                    continuation.resume()
                }
            }
            // Fallback: 다이얼로그가 닫히기 전 콜백이 호출되지 않을 가능성 → 짧은 timeout.
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                guard !didResume else { return }
                manager.stopDeviceMotionUpdates()
                didResume = true
                continuation.resume()
            }
        }
        #else
        motionState = .denied
        #endif
    }

    @discardableResult
    func requestNotifications() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            notificationsState = granted ? .authorized : .denied
            return granted
        } catch {
            notificationsState = .denied
            return false
        }
    }

    func refreshNotificationsState() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined: notificationsState = .notDetermined
        case .denied: notificationsState = .denied
        case .authorized, .provisional, .ephemeral: notificationsState = .authorized
        @unknown default: notificationsState = .notDetermined
        }
    }
}
