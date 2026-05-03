import SwiftUI
import Charts

struct MealDetailView: View {
    let meal: MealSession
    @Environment(\.appEnvironment) private var env

    /// signal §v1.2-6 — 옵트인 사용자만 IMU 내보내기 버튼 노출.
    @State private var imuOptedIn: Bool = false
    @State private var imuExportURL: URL?
    @State private var showImuShareSheet: Bool = false
    @State private var imuFrameCount: Int = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text((meal.durationSec ?? 0).formattedDurationKR)
                    .font(.timerDisplay)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("씹은 횟수 (추정)")
                            .font(.caption1R)
                            .foregroundStyle(.secondary)
                        Text("\(meal.chewCount)회")
                            .font(.title3R)
                    }
                    Spacer()
                    if let cpm = meal.avgCPM {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("평균 페이스")
                                .font(.caption1R)
                                .foregroundStyle(.secondary)
                            Text("분당 \(Int(cpm))회")
                                .font(.title3R)
                        }
                    }
                }
                .padding(Spacing.md)
                .background(Color(uiColor: .secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))

                if !meal.chewSamples.isEmpty {
                    Chart {
                        ForEach(meal.chewSamples.sorted(by: { $0.timestamp < $1.timestamp }), id: \.id) { sample in
                            LineMark(
                                x: .value("시간", sample.timestamp),
                                y: .value("강도", sample.magnitudePeak)
                            )
                            .foregroundStyle(Color.brandPrimary)
                        }
                    }
                    .frame(height: 200)
                    .accessibilityLabel("식사 중 씹기 강도 그래프")
                }

                HonestyDisclosureRow()

                ComfortSelfReportRow(current: meal.comfortReport?.score) { score in
                    try? env.mealRepository.attachComfort(mealId: meal.id, score: score)
                }
                .padding(Spacing.md)
                .background(Color(uiColor: .secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))

                // signal §v1.2-6 — 옵트인 사용자만 IMU CSV 내보내기 노출.
                if imuOptedIn && imuFrameCount > 0 {
                    imuExportRow
                }
            }
            .padding(Spacing.lg)
        }
        .navigationTitle(formattedDate)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            let prefs = env.mealRepository.loadOrCreatePreferences()
            imuOptedIn = prefs.imuDataCollectionOptedIn
            imuFrameCount = env.mealRepository.imuFrameCount(forMealId: meal.id)
        }
        .sheet(isPresented: $showImuShareSheet) {
            if let url = imuExportURL {
                IMUShareSheet(items: [url])
            }
        }
    }

    private var imuExportRow: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .top, spacing: Spacing.sm) {
                Image(systemName: "waveform.path.ecg")
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("이 식사의 IMU 데이터")
                        .font(.bodyR)
                    Text("frame \(imuFrameCount.formatted())개 · 약 \(estimatedMBString)")
                        .font(.caption1R)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            Button {
                exportIMU()
            } label: {
                Label("IMU 데이터 내보내기 (CSV)", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            Text("도움 주셔서 고마워요. 데이터는 본인이 명시적으로 보낼 때만 외부로 나갑니다.")
                .font(.caption1R)
                .foregroundStyle(.secondary)
        }
        .padding(Spacing.md)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
    }

    private var estimatedMBString: String {
        let mb = Double(imuFrameCount) * 120.0 / 1_048_576.0
        if mb < 0.1 { return "< 0.1 MB" }
        return String(format: "%.1f MB", mb)
    }

    private func exportIMU() {
        do {
            let url = try env.mealRepository.exportIMUFramesCSV(sessionID: meal.id)
            imuExportURL = url
            showImuShareSheet = true
        } catch {
            // export 실패 시 silent (사용자 알림은 후속 라운드에서 toast 추가).
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 a h:mm"
        return formatter.string(from: meal.startedAt)
    }
}

/// signal §v1.2-6 — IMU CSV 내보내기용 ShareSheet 래퍼.
private struct IMUShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct HonestyDisclosureRow: View {
    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: "hand.raised.fill")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text("추정 ±15%. 100% 정확하지 않아요.")
                .font(.caption1R)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(Color(uiColor: .tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
    }
}

#Preview {
    let meal = MealSession(startedAt: Date())
    meal.durationSec = 11 * 60 + 32
    meal.chewCount = 350
    meal.avgCPM = 30
    return NavigationStack {
        MealDetailView(meal: meal)
            .environment(\.appEnvironment, AppEnvironment.preview())
    }
}
