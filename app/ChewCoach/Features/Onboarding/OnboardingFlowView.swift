import SwiftUI

struct OnboardingFlowView: View {
    @State private var flow = OnboardingFlow()
    let onComplete: (Persona?, Bool) -> Void

    var body: some View {
        NavigationStack {
            content
                .animation(.easeInOut(duration: 0.25), value: flow.step)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch flow.step {
        case .welcome:
            OnboardingWelcomeView(flow: flow)
        case .persona:
            OnboardingPersonaView(flow: flow)
        case .howItWorks:
            OnboardingHowItWorksView(flow: flow)
        case .motionPermission:
            OnboardingMotionPermissionView(flow: flow)
        case .calibrationIntro:
            OnboardingCalibrationIntroView(
                flow: flow,
                onFinish: { startCalibration in
                    onComplete(flow.selectedPersona, startCalibration)
                }
            )
        }
    }
}

#Preview {
    OnboardingFlowView(onComplete: { _, _ in })
}
