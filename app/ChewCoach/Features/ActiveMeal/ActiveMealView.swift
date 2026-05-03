import SwiftUI

struct ActiveMealView: View {
    @State var viewModel: ActiveMealViewModel
    let mode: ActiveMealViewModel.Mode
    let onFinish: (MealSession?) -> Void

    @State private var showEndConfirmation = false

    /// signal §v1.1-4.F — 개발자 모드 디버그 패널 토글.
    /// Settings에서 ON/OFF, 기본 OFF (production 사용자에게 노출 안 함).
    @AppStorage("developerMode") private var developerMode: Bool = false

    @State private var debugRefreshTick: Int = 0
    @State private var debugTimer: Timer?

    init(env: AppEnvironment,
         mode: ActiveMealViewModel.Mode,
         onFinish: @escaping (MealSession?) -> Void) {
        self._viewModel = State(initialValue: ActiveMealViewModel(env: env))
        self.mode = mode
        self.onFinish = onFinish
    }

    var body: some View {
        VStack(spacing: Spacing.xl) {
            header

            // signal §v1.1-1.C — 감도 모드 활성 시 작은 노란색 배지
            if viewModel.sensitivityModeOn && viewModel.activeThresholdTier == .sensitivity {
                sensitivityBadge
            }

            Spacer()

            ChewBreathBadge()

            Text(viewModel.currentDurationSec.formattedTimerKR)
                .font(.timerDisplay)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .accessibilityLabel("식사 시간 \(viewModel.currentDurationSec.formattedDurationKR)")

            if viewModel.currentChewCount > 0 {
                Text("추정 약 \(viewModel.currentChewCount)회 씹으셨어요")
                    .font(.calloutR)
                    .foregroundStyle(.secondary)
            } else if mode == .calibration {
                Text("준비됐어요. 한 입 드셔보세요.")
                    .font(.calloutR)
                    .foregroundStyle(.secondary)
            }

            if viewModel.phase == .paused {
                pausedView
            }

            Spacer()

            Button {
                showEndConfirmation = true
            } label: {
                Text("식사 끝났어요")
                    .frame(maxWidth: .infinity, minHeight: HitArea.min)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            // signal §v1.1-4.F — 개발자 모드 디버그 패널 (폴드 이하)
            if developerMode {
                debugPanel
            }
        }
        .padding(Spacing.lg)
        .task {
            await viewModel.start(mode: mode)
        }
        .onAppear {
            if developerMode {
                debugTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                    Task { @MainActor in
                        debugRefreshTick &+= 1
                    }
                }
            }
        }
        .onDisappear {
            debugTimer?.invalidate()
            debugTimer = nil
        }
        .onChange(of: viewModel.phase) { _, newValue in
            if case .finished(let meal) = newValue {
                onFinish(meal)
            }
        }
        .confirmationDialog("식사를 마칠까요?", isPresented: $showEndConfirmation) {
            Button("종료", role: .destructive) {
                Task { await viewModel.end() }
            }
            Button("계속", role: .cancel) {}
        }
    }

    private var header: some View {
        HStack {
            Text(mode == .calibration ? "캘리브레이션 식사" : "지금 식사 중")
                .font(.headlineS)
                .foregroundStyle(.secondary)
            Spacer()
            if viewModel.isVideoMode {
                Label("영상 시청 중", systemImage: "play.tv")
                    .font(.caption1R)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var sensitivityBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "wand.and.stars")
                .font(.caption2)
                .accessibilityHidden(true)
            Text("감도 높임 모드 켜짐")
                .font(.caption2R)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color.yellow.opacity(0.18))
        .foregroundStyle(Color.orange)
        .clipShape(Capsule())
        .accessibilityLabel("감도 높임 모드 켜짐. 평소보다 더 잘 잡히지만 가끔 잘못 잡을 수 있어요.")
    }

    private var pausedView: some View {
        VStack(spacing: Spacing.sm) {
            Text("잠시 멈춤")
                .font(.title2S)
            Text("AirPods가\n잠깐 끊겼어요")
                .font(.bodyR)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Text("다시 끼시면 이어 가요")
                .font(.calloutR)
                .foregroundStyle(.secondary)
        }
        .padding(Spacing.lg)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
    }

    /// signal §v1.1-4.F — 9개 디버그 정보 표시. 작은 글자, 폴드 이하.
    private var debugPanel: some View {
        // debugRefreshTick은 0.5s 폴링 트리거 (값 자체는 무시)
        let _ = debugRefreshTick
        return VStack(alignment: .leading, spacing: 4) {
            Text("개발자 모드 — 디버그")
                .font(.caption2R)
                .foregroundStyle(.tertiary)
            debugRow("마지막 검출", value: lastChewElapsedText)
            debugRow("누적 씹기 / 페이스", value: "\(viewModel.currentChewCount)회 / \(viewModel.currentCPM.map { String(format: "%.0f", $0) } ?? "-") CPM")
            debugRow("최근 5초 강도 최댓값 (원본)", value: String(format: "%.4fg", viewModel.recentMagMax5s))
            debugRow("최근 5초 강도 최댓값 (보정)", value: String(format: "%.4fg", viewModel.recentDetrendedMax5s))
            debugRow("검출 임계값", value: String(format: "%.4fg (%@)",
                                              viewModel.activePeakThreshold,
                                              viewModel.activeThresholdTier.rawValue))
            debugRow("모션 소스", value: viewModel.motionStreamKind)
            debugRow("감도 모드", value: viewModel.sensitivityModeOn ? "켜짐" : "꺼짐")
            debugRow("마지막 신뢰도", value: viewModel.lastChewConfidence.map { String(format: "%.2f", $0) } ?? "-")
            debugRow("식사 모드", value: mode == .calibration ? "캘리브레이션" : "일반")
        }
        .padding(Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
    }

    @ViewBuilder
    private func debugRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption2R)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption2R.monospacedDigit())
                .foregroundStyle(.primary)
        }
    }

    private var lastChewElapsedText: String {
        #if canImport(QuartzCore)
        guard let ts = viewModel.lastChewMonotonicTs else { return "—" }
        let elapsed = CACurrentMediaTime() - ts
        if elapsed < 0 { return "방금" }
        if elapsed < 60 { return String(format: "%.1f초 전", elapsed) }
        return String(format: "%.0f분 전", elapsed / 60)
        #else
        return "—"
        #endif
    }
}

#Preview {
    ActiveMealView(env: AppEnvironment.preview(), mode: .standard, onFinish: { _ in })
}
