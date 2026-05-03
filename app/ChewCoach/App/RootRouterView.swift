import SwiftUI
import SwiftData

struct RootRouterView: View {
    @Environment(\.appEnvironment) private var env
    @Query private var preferencesList: [UserPreferences]
    @Environment(\.modelContext) private var modelContext

    @State private var didCompleteOnboarding = false
    @State private var pendingCalibration = false
    @State private var showCalibration = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                RootTabView()
                    .fullScreenCover(isPresented: $showCalibration) {
                        ActiveMealView(env: env, mode: .calibration) { _ in
                            showCalibration = false
                        }
                    }
                    .task {
                        if pendingCalibration {
                            pendingCalibration = false
                            showCalibration = true
                        }
                    }
            } else {
                OnboardingFlowView { selectedPersona, startCalibration in
                    completeOnboarding(persona: selectedPersona, startCalibration: startCalibration)
                }
            }
        }
    }

    private var hasCompletedOnboarding: Bool {
        if didCompleteOnboarding { return true }
        return preferencesList.first?.onboardingCompletedAt != nil
    }

    private func completeOnboarding(persona: Persona?, startCalibration: Bool) {
        let prefs = preferencesList.first ?? {
            let p = UserPreferences()
            modelContext.insert(p)
            return p
        }()
        prefs.personaRaw = persona?.rawValue
        prefs.onboardingCompletedAt = Date()
        try? modelContext.save()
        didCompleteOnboarding = true
        if startCalibration {
            pendingCalibration = true
            showCalibration = true
        }
    }
}

struct RootTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("홈", systemImage: "house.fill") }
            MealHistoryView()
                .tabItem { Label("기록", systemImage: "list.bullet") }
            SettingsView()
                .tabItem { Label("설정", systemImage: "gearshape") }
        }
    }
}

#Preview {
    RootTabView()
        .environment(\.appEnvironment, AppEnvironment.preview())
}
