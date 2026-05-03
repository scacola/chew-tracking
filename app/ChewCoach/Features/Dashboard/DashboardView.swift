import SwiftUI

struct DashboardView: View {
    @Environment(\.appEnvironment) private var env
    @State private var viewModel: DashboardViewModel?
    @State private var showStartSheet = false
    @State private var showActiveMeal = false
    @State private var startMealMode: ActiveMealViewModel.Mode = .standard
    @State private var detailMeal: MealSession?

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Chew Coach")
                .toolbarBackground(.visible, for: .navigationBar)
                .overlay(alignment: .bottomTrailing) {
                    Button {
                        showStartSheet = true
                    } label: {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.brandPrimary)
                            .clipShape(Circle())
                            .shadow(radius: 4, y: 2)
                    }
                    .padding(Spacing.lg)
                    .accessibilityLabel("식사 시작")
                }
                .navigationDestination(item: $detailMeal) { meal in
                    MealDetailView(meal: meal)
                }
        }
        .task {
            if viewModel == nil {
                viewModel = DashboardViewModel(env: env)
            }
            viewModel?.reload()
        }
        .sheet(isPresented: $showStartSheet) {
            MealStartConfirmationSheet(onStart: { mode in
                startMealMode = mode
                showStartSheet = false
                showActiveMeal = true
            }, onCancel: {
                showStartSheet = false
            })
            .presentationDetents([.medium])
        }
        .fullScreenCover(isPresented: $showActiveMeal) {
            ActiveMealView(env: env, mode: startMealMode) { _ in
                showActiveMeal = false
                viewModel?.reload()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if let vm = viewModel {
            switch vm.state {
            case .loading:
                ProgressView()
            case .empty:
                emptyView
            case .loaded:
                loadedView(vm)
            case .error:
                errorView
            }
        } else {
            ProgressView()
        }
    }

    private var emptyView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text("첫 식사를 함께해 주세요. 시작 버튼은 우하단에 있어요.")
                .font(.bodyR)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.lg)
        }
    }

    private var errorView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text("잠시 정보를 불러오지 못했어요.")
                .font(.bodyR)
                .multilineTextAlignment(.center)
            Button("다시 시도") {
                viewModel?.reload()
            }
            .buttonStyle(.bordered)
        }
        .padding(Spacing.lg)
    }

    private func loadedView(_ vm: DashboardViewModel) -> some View {
        // 마지막 식사 카드와 InsightCard에 같은 메시지가 동시에 노출되지 않도록 조정.
        // 결과 카드에는 "오늘 결과" 컨텍스트만, 패턴 인사이트는 별도 InsightCard로.
        let resultMessage: String? = {
            guard let insight = vm.insightCard else { return nil }
            // encouragement 카테고리만 결과 카드에 함께 — insight/awareness/celebration/weekly는 별도 카드로.
            return insight.category == .encouragement ? insight.rendered : nil
        }()
        let showSeparateInsight: Bool = {
            guard let insight = vm.insightCard else { return false }
            return insight.category != .encouragement
        }()

        return ScrollView {
            VStack(spacing: Spacing.md) {
                TodayHeaderCard(
                    totalDurationSec: vm.todayTotalSec,
                    mealsCount: vm.todayMeals.count,
                    comparisonText: vm.comparisonText()
                )

                if let last = vm.lastMeal {
                    MealResultCard(
                        meal: last,
                        calibrationDurationSec: vm.calibration?.calibrationDurationSec,
                        coachingMessage: resultMessage,
                        onTapDetail: { detailMeal = last },
                        onComfortReported: { score in
                            vm.attachComfort(mealId: last.id, score: score)
                        }
                    )
                }

                if showSeparateInsight, let insight = vm.insightCard {
                    InsightCard(title: title(for: insight.category),
                                message: insight.rendered,
                                category: insight.category)
                }

                MealTrendChartCard(
                    points: vm.weekTrendPoints,
                    calibrationDurationSec: vm.calibration?.calibrationDurationSec
                )
            }
            .padding(Spacing.lg)
            .padding(.bottom, 80)
        }
    }

    private func title(for category: CoachingMessage.Category) -> String {
        switch category {
        case .encouragement: return "오늘의 한마디"
        case .insight: return "오늘의 발견"
        case .awareness: return "잠깐, 한마디"
        case .celebration: return "축하해요"
        case .weekly: return "이번 주 회고"
        }
    }
}

#Preview {
    DashboardView()
        .environment(\.appEnvironment, AppEnvironment.preview())
}
