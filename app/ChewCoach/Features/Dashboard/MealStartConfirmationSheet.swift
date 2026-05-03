import SwiftUI

struct MealStartConfirmationSheet: View {
    let onStart: (ActiveMealViewModel.Mode) -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Capsule()
                .fill(Color(uiColor: .tertiarySystemFill))
                .frame(width: 36, height: 5)
                .padding(.top, Spacing.sm)

            VStack(spacing: Spacing.sm) {
                Image(systemName: "ear.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.brandPrimary)
                    .accessibilityHidden(true)
                Text("식사를 시작할게요")
                    .font(.title2S)
                Text("AirPods를 끼고 평소처럼 드세요. 자동으로 살펴볼게요.")
                    .font(.calloutR)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            Button {
                onStart(.standard)
            } label: {
                Text("시작")
                    .frame(maxWidth: .infinity, minHeight: HitArea.min)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button("취소") {
                onCancel()
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .frame(maxWidth: .infinity)
        }
        .padding(Spacing.lg)
    }
}

#Preview {
    MealStartConfirmationSheet(onStart: { _ in }, onCancel: {})
}
