import SwiftUI
import SwiftData

@MainActor
struct AppEnvironment {
    let motionStream: any MotionStream
    let permissionCoordinator: PermissionCoordinator
    let mealRepository: MealRepository
    let messagePicker: MessagePicker
    let messageRenderer: MessageRenderer
    let calibrationEngine: CalibrationEngine
    let audioMonitor: AudioSessionMonitor
    let insightGenerator: InsightGenerator
    let patternEngine: PatternEngine

    static func live(container: ModelContainer) -> AppEnvironment {
        let context = ModelContext(container)
        let repo = MealRepository(context: context)
        return AppEnvironment(
            motionStream: liveOrMock(),
            permissionCoordinator: PermissionCoordinator(),
            mealRepository: repo,
            messagePicker: MessagePicker(),
            messageRenderer: MessageRenderer(),
            calibrationEngine: CalibrationEngine(),
            audioMonitor: AudioSessionMonitor(),
            insightGenerator: InsightGenerator(),
            patternEngine: PatternEngine()
        )
    }

    static func preview() -> AppEnvironment {
        // Preview/Test에서는 in-memory container를 별도 생성 → AppEnvironment.live로 위임
        let schema = Schema([
            MealSession.self, ChewSample.self, IMUFrame.self, ComfortReport.self,
            DailyInsight.self, UserCalibration.self, UserPreferences.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        return live(container: container)
    }

    private static func liveOrMock() -> any MotionStream {
        #if targetEnvironment(simulator)
        return MockMotionStream()
        #else
        return LiveMotionStream()
        #endif
    }
}

// MARK: - SwiftUI Environment key

private struct AppEnvironmentKey: @preconcurrency EnvironmentKey {
    @MainActor
    static let defaultValue: AppEnvironment = AppEnvironment.preview()
}

extension EnvironmentValues {
    var appEnvironment: AppEnvironment {
        get { self[AppEnvironmentKey.self] }
        set { self[AppEnvironmentKey.self] = newValue }
    }
}
