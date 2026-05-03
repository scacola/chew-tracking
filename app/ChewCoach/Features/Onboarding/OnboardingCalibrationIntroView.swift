import SwiftUI

struct OnboardingCalibrationIntroView: View {
    @Bindable var flow: OnboardingFlow
    let onFinish: (Bool) -> Void

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            Image(systemName: "fork.knife")
                .font(.system(size: 56))
                .foregroundStyle(Color.brandPrimary)
                .accessibilityHidden(true)

            VStack(spacing: Spacing.md) {
                Text("이 한 끼만 함께해요")
                    .font(.title2S)
                Text("평소처럼 드시면 됩니다.\nAirPods가 옆에서 한 번만\n당신의 페이스를 익혀요.")
                    .font(.bodyR)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            VStack(spacing: Spacing.sm) {
                Button("이번 끼니에 시작할게요") {
                    flow.didStartCalibration = true
                    onFinish(true)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)

                Button("나중에 할게요") {
                    flow.didStartCalibration = false
                    onFinish(false)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(Spacing.lg)
    }
}

#Preview {
    OnboardingCalibrationIntroView(flow: OnboardingFlow(), onFinish: { _ in })
}
