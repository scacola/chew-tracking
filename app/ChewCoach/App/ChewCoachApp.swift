import SwiftUI
import SwiftData

@main
struct ChewCoachApp: App {
    let container: ModelContainer

    init() {
        // signal §v1.1-6: V1.1 마이그레이션 정책 — destructive OK (출시 전).
        // ModelContainer 생성 실패(스키마 불일치) 시 store 파일 제거 후 재생성.
        // signal §v1.2-9 — IMUFrame 추가. v1.2 destructive 마이그레이션 (출시 전이라 OK).
        let schemaModels: [any PersistentModel.Type] = [
            MealSession.self, ChewSample.self, IMUFrame.self, ComfortReport.self,
            DailyInsight.self, UserCalibration.self, UserPreferences.self
        ]
        do {
            container = try ModelContainer(
                for: MealSession.self, ChewSample.self, IMUFrame.self, ComfortReport.self,
                     DailyInsight.self, UserCalibration.self, UserPreferences.self
            )
        } catch {
            // V1 destructive migration: 기존 store 삭제 후 재시도.
            Self.purgeDefaultStore()
            do {
                container = try ModelContainer(
                    for: MealSession.self, ChewSample.self, IMUFrame.self, ComfortReport.self,
                         DailyInsight.self, UserCalibration.self, UserPreferences.self
                )
            } catch {
                fatalError("ModelContainer 생성 실패 (purge 후): \(error)")
            }
        }
        _ = schemaModels  // suppress warning for documentation list
    }

    private static func purgeDefaultStore() {
        guard let appSupport = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return }
        for ext in ["store", "store-shm", "store-wal"] {
            let url = appSupport.appendingPathComponent("default.\(ext)")
            try? FileManager.default.removeItem(at: url)
        }
    }

    var body: some Scene {
        WindowGroup {
            RootRouterView()
                .environment(\.appEnvironment, AppEnvironment.live(container: container))
        }
        .modelContainer(container)
    }
}
