import SwiftUI

struct OnboardingMotionPermissionView: View {
    @Bindable var flow: OnboardingFlow
    @Environment(\.appEnvironment) private var env
    @State private var phase: Phase = .idle
    @State private var motionStateLocal: PermissionCoordinator.MotionState = .notDetermined

    enum Phase {
        case idle, requesting, granted, deniedFallback
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("AirPods로 자동 인식")
                    .font(.title2S)
                Text("AirPods 모션 데이터로 식사 시간을 자동으로 살펴봐요. 데이터는 기기에서만 처리되고 7일 후 자동 삭제돼요.")
                    .font(.calloutR)
                    .foregroundStyle(.secondary)
            }

            Image(systemName: "airpodspro")
                .font(.system(size: 64))
                .foregroundStyle(Color.brandPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.lg)
                .accessibilityHidden(true)

            if phase == .deniedFallback {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("괜찮아요. 식사할 때 *시작* 버튼을 직접 누르셔도 똑같이 작동해요.")
                        .font(.calloutR)
                        .foregroundStyle(.secondary)
                    Text("자동 인식은 설정에서 언제든 다시 켤 수 있어요.")
                        .font(.caption1R)
                        .foregroundStyle(.tertiary)
                }
                .padding(Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(uiColor: .secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Spacer()

            Button {
                Task { await requestMotion() }
            } label: {
                HStack {
                    if phase == .requesting { ProgressView().controlSize(.small) }
                    Text(phase == .deniedFallback ? "다시 시도" : "AirPods로 자동 인식 켜기")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(phase == .requesting || phase == .granted)

            Button(phase == .deniedFallback ? "확인했어요, 다음" : "나중에") {
                if phase == .deniedFallback {
                    flow.goNext()
                } else {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        phase = .deniedFallback
                    }
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .frame(maxWidth: .infinity)
        }
        .padding(Spacing.lg)
        .animation(.easeInOut(duration: 0.25), value: phase)
    }

    private func requestMotion() async {
        phase = .requesting
        await env.permissionCoordinator.requestMotion()
        motionStateLocal = env.permissionCoordinator.motionState
        switch motionStateLocal {
        case .authorized:
            phase = .granted
            flow.goNext()
        case .denied, .notDetermined:
            withAnimation(.easeInOut(duration: 0.25)) {
                phase = .deniedFallback
            }
            // fallback 카피 노출 후 사용자 확인을 기다림 — 자동 진행하지 않음
        }
    }
}

#Preview {
    OnboardingMotionPermissionView(flow: OnboardingFlow())
}
