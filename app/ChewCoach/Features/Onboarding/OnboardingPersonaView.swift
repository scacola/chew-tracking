import SwiftUI

struct OnboardingPersonaView: View {
    @Bindable var flow: OnboardingFlow

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("어떤 게 가장 가까우세요?")
                    .font(.title2S)
                Text("맞춤 코칭에 활용해요. 언제든 바꿀 수 있어요.")
                    .font(.calloutR)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: Spacing.md) {
                ForEach(Persona.allCases) { persona in
                    PersonaCard(
                        persona: persona,
                        isSelected: flow.selectedPersona == persona,
                        onTap: { flow.selectedPersona = persona }
                    )
                }
            }

            Spacer(minLength: Spacing.lg)

            Button("다음") {
                flow.goNext()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(maxWidth: .infinity)
            .disabled(flow.selectedPersona == nil)
        }
        .padding(Spacing.lg)
    }
}

#Preview {
    OnboardingPersonaView(flow: OnboardingFlow())
}
