import SwiftUI

struct OnboardingWelcomeView: View {
    @Bindable var flow: OnboardingFlow

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            Image(systemName: "ear.and.waveform")
                .font(.system(size: 64))
                .foregroundStyle(Color.brandPrimary)
                .accessibilityHidden(true)

            VStack(spacing: Spacing.md) {
                Text("AirPods로\n내 위 컨디션을\n살펴봐요")
                    .font(.displayLarge)
                    .multilineTextAlignment(.center)

                Text("의사가 \"천천히 드세요\"라고\n하셨다면, 1분이면 시작해요.")
                    .font(.bodyR)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            Button("시작하기") {
                flow.goNext()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(maxWidth: .infinity)
        }
        .padding(Spacing.lg)
    }
}

#Preview {
    OnboardingWelcomeView(flow: OnboardingFlow())
}
