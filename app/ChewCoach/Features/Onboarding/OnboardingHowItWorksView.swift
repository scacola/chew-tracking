import SwiftUI

struct OnboardingHowItWorksView: View {
    @Bindable var flow: OnboardingFlow
    @State private var currentPage: Int = 0

    private let cards: [HowItWorksCard] = [
        .init(icon: "ear.fill",
              title: "AirPods를 끼고 식사하시면",
              body: "자동으로 식사 시간을\n살짝 기록해요."),
        .init(icon: "hand.tap.fill",
              title: "처음 한 끼만 직접 시작",
              body: "처음 한 끼만 직접 시작 버튼을 누르시면\n다음부터는 자동이에요."),
        .init(icon: "hand.raised.fill",
              title: "100% 정확하지 않아요. (추정 ±15%)",
              body: "치료가 아니라 *행동 변화 코칭*이에요.")
    ]

    var body: some View {
        VStack(spacing: Spacing.lg) {
            TabView(selection: $currentPage) {
                ForEach(cards.indices, id: \.self) { idx in
                    cardView(cards[idx])
                        .tag(idx)
                        .padding(.horizontal, Spacing.lg)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            Button(currentPage == cards.count - 1 ? "다음" : "계속") {
                if currentPage == cards.count - 1 {
                    flow.goNext()
                } else {
                    currentPage += 1
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.lg)
        }
    }

    @ViewBuilder
    private func cardView(_ card: HowItWorksCard) -> some View {
        VStack(spacing: Spacing.lg) {
            Spacer()
            Image(systemName: card.icon)
                .font(.system(size: 56))
                .foregroundStyle(Color.brandPrimary)
                .accessibilityHidden(true)
            Text(card.title)
                .font(.title2S)
                .multilineTextAlignment(.center)
            Text(card.body)
                .font(.bodyR)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }
}

private struct HowItWorksCard {
    let icon: String
    let title: String
    let body: String
}

#Preview {
    OnboardingHowItWorksView(flow: OnboardingFlow())
}
