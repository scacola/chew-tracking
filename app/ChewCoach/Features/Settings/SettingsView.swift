import SwiftUI

struct SettingsView: View {
    @Environment(\.appEnvironment) private var env
    @State private var notificationsEnabled = true
    @State private var pacingToastEnabled = true
    @State private var endNotifEnabled = true
    @State private var showHonestyPledge = false
    @State private var showResetConfirm = false
    @State private var exportURL: URL?
    @State private var showShareSheet = false

    /// signal §v1.1-1.C — 감도 모드 토글 상태 (UserPreferences와 양방향 동기화).
    @State private var sensitivityModeOn: Bool = true

    /// signal §v1.2-6 — IMU 데이터 수집 옵트인 토글.
    @State private var imuOptedIn: Bool = false
    /// 현재 누적된 IMU 데이터 통계 (count + 추정 MB).
    @State private var imuFrameStats: (count: Int, mb: Double) = (0, 0)
    @State private var showImuDeleteConfirm = false

    /// signal §v1.1-4.F — 개발자 모드 토글 (디버그 패널 + 시뮬 자동 합성 식사).
    @AppStorage("developerMode") private var developerMode: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section("알림") {
                    Toggle("일일 인사이트 알림", isOn: $notificationsEnabled)
                    Toggle("식사 페이스 토스트", isOn: $pacingToastEnabled)
                    Toggle("식사 종료 알림", isOn: $endNotifEnabled)
                }

                // signal §v1.1-1.C — 감도 모드 토글 + 친근 카피
                Section {
                    Toggle("감도 높임 모드", isOn: $sensitivityModeOn)
                        .onChange(of: sensitivityModeOn) { _, newValue in
                            let prefs = env.mealRepository.loadOrCreatePreferences()
                            try? env.mealRepository.setSensitivityMode(prefs: prefs, enabled: newValue)
                        }
                    Text("더 잘 잡히지만 가끔 잘못 잡을 수 있어요. 첫 식사 캘리브레이션이 끝나면 자동으로 꺼져요.")
                        .font(.caption1R)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("검출 감도")
                }

                Section("디바이스") {
                    HStack {
                        Image(systemName: "airpodspro")
                            .foregroundStyle(Color.brandPrimary)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("AirPods 호환성")
                                .font(.bodyR)
                            Text("AirPods Pro 2·AirPods 3·AirPods Max 권장")
                                .font(.caption1R)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("정직성") {
                    Button {
                        showHonestyPledge = true
                    } label: {
                        Label("정직성 약속 보기", systemImage: "hand.raised.fill")
                    }
                }

                Section("내 데이터") {
                    Button {
                        if let url = try? env.mealRepository.exportCSV() {
                            exportURL = url
                            showShareSheet = true
                        }
                    } label: {
                        Label("CSV로 내보내기", systemImage: "square.and.arrow.up")
                    }
                    Button(role: .destructive) {
                        showResetConfirm = true
                    } label: {
                        Label("모든 기록 삭제", systemImage: "trash")
                    }
                }

                // signal §v1.2-6 — 데이터 수집 옵트인 (베타). 옵션 G 친근·정직 톤.
                Section {
                    Toggle("데이터 수집 도움주기 (베타)", isOn: $imuOptedIn)
                        .onChange(of: imuOptedIn) { _, newValue in
                            let prefs = env.mealRepository.loadOrCreatePreferences()
                            prefs.imuDataCollectionOptedIn = newValue
                            try? env.mealRepository.flush()
                        }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("더 정확한 검출을 위해 익명 IMU 데이터를 기기에 저장합니다.")
                        Text("데이터는 기기에만 저장되며, 본인이 명시적으로 내보낼 때만 외부로 나갑니다.")
                        Text("언제든 끄거나, 이미 저장된 데이터를 삭제할 수 있어요.")
                    }
                    .font(.caption1R)
                    .foregroundStyle(.secondary)

                    if imuFrameStats.count > 0 {
                        HStack {
                            Image(systemName: "internaldrive")
                                .foregroundStyle(.secondary)
                                .accessibilityHidden(true)
                            Text(imuStorageDescription)
                                .font(.caption1R)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        Button(role: .destructive) {
                            showImuDeleteConfirm = true
                        } label: {
                            Label("수집된 IMU 데이터 모두 삭제", systemImage: "trash")
                        }
                    }
                } header: {
                    Text("정확도 개선 (베타)")
                }

                // signal §v1.1-4.F — 개발자 모드 (시뮬레이터 + 디버그 패널)
                Section {
                    Toggle("개발자 모드", isOn: $developerMode)
                    Text("식사 화면 하단에 검출 상태가 자세히 보여요. 시뮬레이터에서는 가짜 식사 신호가 자동으로 들어와요.")
                        .font(.caption1R)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("개발자")
                }

                Section("정보") {
                    Text("버전 0.1.0 (V1.1)")
                        .font(.calloutR)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("설정")
            .onAppear {
                let prefs = env.mealRepository.loadOrCreatePreferences()
                sensitivityModeOn = prefs.sensitivityModeEnabled
                imuOptedIn = prefs.imuDataCollectionOptedIn
                refreshImuStats()
            }
            .sheet(isPresented: $showHonestyPledge) {
                HonestyPledgeView()
                    .presentationDetents([.medium, .large])
            }
            .alert("모든 기록을 삭제할까요?", isPresented: $showResetConfirm) {
                Button("삭제", role: .destructive) {
                    try? env.mealRepository.deleteAll()
                }
                Button("취소", role: .cancel) {}
            } message: {
                Text("이 작업은 되돌릴 수 없어요.")
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
            .alert("수집된 IMU 데이터를 모두 삭제할까요?", isPresented: $showImuDeleteConfirm) {
                Button("삭제", role: .destructive) {
                    try? env.mealRepository.deleteAllIMUFrames()
                    refreshImuStats()
                }
                Button("취소", role: .cancel) {}
            } message: {
                Text("식사 기록과 씹은 횟수는 그대로 남아요. raw IMU 데이터만 삭제돼요.")
            }
        }
    }

    private var imuStorageDescription: String {
        if imuFrameStats.mb < 0.1 {
            return "이 데이터 약 \(imuFrameStats.count.formatted())개 frame 저장 중 (< 0.1 MB)"
        }
        return "이 데이터 약 \(String(format: "%.1f", imuFrameStats.mb)) MB 사용 중"
    }

    private func refreshImuStats() {
        let stats = env.mealRepository.imuFrameTotalStats()
        imuFrameStats = (stats.count, stats.estimatedMB)
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    SettingsView()
        .environment(\.appEnvironment, AppEnvironment.preview())
}
