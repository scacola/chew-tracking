# 02. App Architecture — Chew & Calm Coach iOS V1

**작성일**: 2026-05-02
**작성**: `ios-app-architect`
**대상 독자**: `ios-app-implementer` (이 문서 + `04_app_brief_consolidated.md` 단독으로 빌드)
**스코프**: 옵션 G "Chew & Calm Coach" V1 — 측정 엔진 + 사용자 대시보드 + 코칭 메시지 골격
**상위 입력**: `_brief.md` (V1 스코프·환경), `01_signal_processing.md` §7 "ios-app-architect 6개 입력", `03_app_ux_spec.md` §12 "다음 에이전트 가이드", `discovery_report.md` §5.1 옵션 G

---

## 0. 결론 한 줄

> **Swift 5.9 + SwiftUI + iOS 17 + SwiftData + async/await + Swift Charts** 단일 표준 조합으로, **3-Stage 신호 파이프라인(Preprocessor / Detector / Orchestrator) + 11화면 SwiftUI Feature 모듈 + 32개 코칭 메시지 엔진**을 외부 의존성 0으로 빌드한다. **xcodegen 2.45.3 기반 `project.yml`**로 Xcode 프로젝트 생성, **6단계 빌드 순서**(Storage → 알고리즘 Mock → UI → Live Motion → Coaching → Polish), **권한 일괄 요청 0건**(Motion은 첫 식사 직전·Notifications는 첫 인사이트 직후), **백그라운드 약속 0건**(foreground + audio session active 우선 — `01_signal_processing.md` §5.1#3 + `03_app_ux_spec.md` §4.1 정합).

---

## 1. 기술 스택 결정

각 결정은 *대안 + trade-off + 채택 이유*까지 명시. *외부 의존성 0건*이 V1 원칙.

| 영역 | 채택 | 대안 | 채택 이유 (V1 trade-off) |
|------|------|------|----------------------|
| **언어** | Swift 5.9+ | (없음) | iOS 표준. Xcode 26.4 기본 toolchain. |
| **UI Framework** | SwiftUI 5+ (iOS 17+) | UIKit / Hybrid | `@Observable`, `Charts`, `SwiftData` 모두 iOS 17+ 1st-party. UIKit 보일러플레이트 회피. UX §3 모든 화면 SwiftUI 표준 컴포넌트로 구현 가능 (TabView·Form·NavigationStack·Sheet·Charts). |
| **최소 iOS** | iOS 17.0 | iOS 16+ | `_brief.md` §4: AirPods Pro 2 사용자 대부분 iOS 17+. iOS 16 추가 지원 시 SwiftData·Observation·`#Preview` 매크로 수동 백포트 부담 大 (≈+5일 작업) — 1순위 페르소나 한지원(IT 개발자, 32세) 100% iOS 17+ 가능. |
| **데이터 영속화** | SwiftData (iOS 17+) | Core Data / SQLite.swift / GRDB | 보일러플레이트 최소(`@Model` 선언만), `@Query`로 SwiftUI 자동 갱신, V1 모델 4개(MealSession/ChewSample/DailyInsight/UserCalibration) 단순. **Trade-off**: iOS 17 미만 사용자 차단 (수용), CloudKit sync는 V1.5 결정. |
| **동시성** | async/await + AsyncSequence | Combine / RxSwift / GCD | `CMHeadphoneMotionManager` 콜백 → `AsyncStream<IMUSample>` 래핑이 가장 단순. Combine은 SwiftUI ↔ ViewModel 경계만 잠재적 활용(`@Observable`로 우선 회피). RxSwift 도입 시 의존성·러닝커브 비용 大. |
| **차트** | Swift Charts (1st party) | Charts (DGCharts) / SwiftUICharts | UX §5.2 7일 막대 + RuleMark + AnnotationMark 모두 1st-party 표준 마크로 구현 가능. 외부 의존성 회피. |
| **신호 처리 (DSP)** | vDSP (Accelerate.framework) | scipy 포팅 / 외부 SPM 라이브러리 | `01_signal_processing.md` §2.3 권고 — Butterworth 4차 IIR biquad cascade. `vDSP_biquad`는 iOS 표준, 외부 의존성 0. SOS 계수는 SciPy로 *오프라인 사전 계산* 후 hard-code. |
| **의존성 관리** | Swift Package Manager (V1: 0개) | CocoaPods / Carthage | V1은 *외부 패키지 0개*. SPM은 V1.5에서 CoreML 분류기 model 패키지화 시 활용 예정. |
| **프로젝트 생성** | xcodegen 2.45.3 (`project.yml`) | 직접 `.xcodeproj` 편집 / Tuist | `_brief.md` §5: 환경에 설치됨. `.xcodeproj`는 git 머지 충돌 다발 → `project.yml`이 진리. Tuist는 V1엔 과함. |
| **테스트** | XCTest + Swift Testing (옵션) | Quick/Nimble | XCTest는 1st-party. iOS 17은 Swift Testing(@Test)도 사용 가능하나 V1은 XCTest로 통일(러닝커브·Xcode 26.4 안정성). |
| **분석 SDK** | (V1 제외) | Mixpanel / Amplitude / Firebase | 외부 SDK는 사용자 데이터 흐름 의문 발생. V1은 로컬 SwiftData만, 익명 통계는 V2 결정 (옵트인 후). |
| **HealthKit** | V1 제외, V1.5 후보 | V1 통합 | discovery §5.1: V1 측정·대시보드 슬라이스 우선. HealthKit는 read/write 범위 결정·심사·사용자 동의 흐름 필요 — V1.5 별도 트랙. |
| **CoreML** | V1 제외, V1.5 후보 | V1 분류기 | `01_signal_processing.md` §6.2: 학습 데이터 부재 — 룰 기반 V1만으로 학술 baseline F1 0.71-0.80 달성 가능. ML 도입은 누적 라벨 1,000건 후. |

**원칙 명시**: *V1 외부 SPM 의존성 0개*. SPM 사용은 V1.5에 CoreML 모델 패키지·HealthKit helper 등으로 한정.

---

## 2. Xcode 프로젝트 구조 (`project.yml` 기반)

`xcodegen` 2.45.3 표준. `app/project.yml`이 단일 진리. `.xcodeproj`는 git ignore 후보 (또는 `xcodegen generate` 결과만 commit, 머지 충돌 시 재생성).

### 2.1 디렉토리 트리 (스킬 표준 + UX·신호 매핑)

```
app/
├── project.yml                          # xcodegen 정의 (단일 진리)
├── ChewCoach.xcodeproj                  # xcodegen 생성 (commit 권장: 환경 일관성)
├── ChewCoach/
│   ├── App/
│   │   ├── ChewCoachApp.swift           # @main + ModelContainer + AppEnvironment 주입
│   │   └── AppEnvironment.swift         # DI 컨테이너 (MotionStream/Repository/Engine)
│   ├── Features/
│   │   ├── Onboarding/
│   │   │   ├── OnboardingFlow.swift             # 5단계 router (enum 기반)
│   │   │   ├── OnboardingWelcomeView.swift      # UX §3.1
│   │   │   ├── OnboardingPersonaView.swift      # UX §3.2
│   │   │   ├── OnboardingHowItWorksView.swift   # UX §3.3 정직성 카드
│   │   │   ├── OnboardingMotionPermissionView.swift  # UX §3.4
│   │   │   └── OnboardingCalibrationIntroView.swift  # UX §3.5
│   │   ├── ActiveMeal/
│   │   │   ├── ActiveMealView.swift             # UX §3.6
│   │   │   ├── ActiveMealViewModel.swift        # @Observable, MealSessionState 구독
│   │   │   └── MealStartConfirmationSheet.swift # UX §3.12 sheet
│   │   ├── Dashboard/
│   │   │   ├── DashboardView.swift              # UX §3.7
│   │   │   ├── DashboardViewModel.swift
│   │   │   ├── MealHistoryView.swift            # UX §3.8 (탭바 2)
│   │   │   ├── MealDetailView.swift             # UX §3.9
│   │   │   └── WeeklyRecapView.swift            # UX §3.10 sheet
│   │   └── Settings/
│   │       ├── SettingsView.swift               # UX §3.11
│   │       ├── HonestyPledgeView.swift          # UX §3.11 "정직성 약속"
│   │       └── DataExportSheet.swift
│   ├── Core/
│   │   ├── Sensing/
│   │   │   ├── MotionStream.swift               # protocol — Live/Mock 분기
│   │   │   ├── LiveMotionStream.swift           # CMHeadphoneMotionManager 구현
│   │   │   └── MockMotionStream.swift           # synthetic IMU generator (시뮬·테스트)
│   │   ├── Detection/
│   │   │   ├── Preprocessor.swift               # signal §2.2 Stage 1
│   │   │   ├── ChewDetector.swift               # signal §2.3 Stage 2 (bandpass + peak)
│   │   │   ├── MealSessionTracker.swift         # signal §2.4 Stage 3 (state machine)
│   │   │   ├── ArtifactFilter.swift             # signal §2.5 4대 false positive
│   │   │   ├── BiquadFilter.swift               # vDSP_biquad wrapper
│   │   │   └── DetectorConstants.swift          # signal 부록 A 매직 넘버 표
│   │   ├── Calibration/
│   │   │   ├── CalibrationEngine.swift          # signal §4.1 사용자별 임계값 산출
│   │   │   └── UserCalibration.swift            # @Model
│   │   ├── Storage/
│   │   │   ├── MealSession.swift                # @Model
│   │   │   ├── ChewSample.swift                 # @Model
│   │   │   ├── ComfortReport.swift              # @Model — UX §5.5 selfreport
│   │   │   ├── DailyInsight.swift               # @Model
│   │   │   ├── UserPreferences.swift            # @Model — persona, honestyAccepted, settings
│   │   │   ├── MealRepository.swift             # CRUD + @Query helper
│   │   │   └── MigrationPlan.swift              # SwiftData VersionedSchema (V1.0 only)
│   │   ├── Coaching/
│   │   │   ├── CoachingMessage.swift            # struct — UX §8.2 라이브러리
│   │   │   ├── MessageLibrary.swift             # static let library: [CoachingMessage] (32개)
│   │   │   ├── TriggerEvaluator.swift           # context dictionary → bool
│   │   │   ├── MessagePicker.swift              # 카테고리·컨텍스트 → 1개 선택
│   │   │   ├── PatternEngine.swift              # UX §5.3 Discoveries 패턴 검출
│   │   │   ├── InsightGenerator.swift           # DailyInsight 생성
│   │   │   └── KoreanParticle.swift             # UX §8.4 한국어 조사 helper
│   │   ├── Permissions/
│   │   │   ├── PermissionCoordinator.swift      # 시점 분리 — 일괄 요청 금지
│   │   │   └── PermissionState.swift
│   │   └── AudioContext/
│   │       └── AudioSessionMonitor.swift        # AVAudioSession.isOtherAudioPlaying 감시
│   ├── Shared/
│   │   ├── DesignSystem/
│   │   │   ├── Color+Tokens.swift               # UX §9.1 brand_primary/accent
│   │   │   ├── Font+Tokens.swift                # UX §9.2 timer_display 등
│   │   │   ├── Spacing.swift                    # UX §9.3
│   │   │   └── Motion.swift                     # UX §9.4 + reduce_motion
│   │   └── Components/
│   │       ├── MealResultCard.swift             # UX §6
│   │       ├── ChewBreathBadge.swift            # UX §3.6 호흡 애니메이션
│   │       ├── ComfortSelfReportRow.swift       # UX §5.5
│   │       ├── InsightCard.swift                # UX §5.3
│   │       ├── MealTrendChartCard.swift         # UX §5.2 Swift Charts
│   │       ├── PersonaCard.swift                # UX §3.2
│   │       └── TodayHeaderCard.swift            # UX §5.4
│   ├── Resources/
│   │   ├── Assets.xcassets                      # AppIcon + brand_primary/accent ColorSet
│   │   ├── Info.plist                           # NSMotionUsageDescription 등
│   │   └── Localizable.xcstrings                # ko 우선, en fallback
│   └── Preview Content/
│       └── PreviewSamples.swift                 # SwiftUI #Preview용 샘플 데이터
├── ChewCoachTests/
│   ├── PreprocessorTests.swift
│   ├── ChewDetectorTests.swift                  # signal §3.4 T1~T7
│   ├── MealSessionTrackerTests.swift            # signal §3.4 T8~T11
│   ├── DetectorLatencyTests.swift               # signal §3.4 T12
│   ├── CalibrationEngineTests.swift
│   ├── MessageLibraryTests.swift                # 32개 lint (UX §8.3 금지 표현)
│   ├── KoreanParticleTests.swift
│   └── MealRepositoryTests.swift
└── ChewCoachUITests/
    ├── OnboardingFlowUITests.swift
    └── DashboardUITests.swift
```

### 2.2 `project.yml` 골격 (구현자 작성용 base — `04_brief` §8에 더 자세)

```yaml
name: ChewCoach
options:
  bundleIdPrefix: com.chewcoach
  deploymentTarget:
    iOS: "17.0"
  developmentLanguage: ko
settings:
  base:
    SWIFT_VERSION: "5.9"
    IPHONEOS_DEPLOYMENT_TARGET: "17.0"
    ENABLE_USER_SCRIPT_SANDBOXING: YES
    SWIFT_STRICT_CONCURRENCY: minimal   # V1: minimal. V2: complete
targets:
  ChewCoach:
    type: application
    platform: iOS
    sources:
      - path: ChewCoach
    resources:
      - path: ChewCoach/Resources/Assets.xcassets
      - path: ChewCoach/Resources/Localizable.xcstrings
    info:
      path: ChewCoach/Resources/Info.plist
      properties:
        CFBundleDisplayName: Chew Coach
        CFBundleShortVersionString: "0.1.0"
        CFBundleVersion: "1"
        UILaunchScreen: {}
        NSMotionUsageDescription: "AirPods 모션으로 식사 시작·끝을 자동으로 살펴봐요. 데이터는 기기 내에서만 처리됩니다."
        UIBackgroundModes:
          - audio    # audio session active 시 IMU 수신 (V1 백그라운드 전략 §5)
        UIApplicationSceneManifest:
          UIApplicationSupportsMultipleScenes: false
        UISupportedInterfaceOrientations:
          - UIInterfaceOrientationPortrait
    dependencies: []   # V1: 외부 의존성 0
  ChewCoachTests:
    type: bundle.unit-test
    platform: iOS
    sources:
      - path: ChewCoachTests
    dependencies:
      - target: ChewCoach
  ChewCoachUITests:
    type: bundle.ui-testing
    platform: iOS
    sources:
      - path: ChewCoachUITests
    dependencies:
      - target: ChewCoach
schemes:
  ChewCoach:
    build:
      targets:
        ChewCoach: all
    test:
      targets:
        - ChewCoachTests
        - ChewCoachUITests
```

### 2.3 모듈 경계 원칙

- **Feature → Core / Shared만 의존** (Feature 간 의존 0건)
- **Core → Shared만 의존** (Core 간은 protocol로 분리)
- **Core/Sensing은 protocol(`MotionStream`) 우선** — Live(실기기) / Mock(시뮬·테스트) 교체 가능
- **Core/Coaching은 데이터 입력만 받음** — UI/Sensing 직접 의존 X (입력은 Storage 모델 + 컨텍스트 dictionary)

---

## 3. 컴포넌트·모듈 명세 (4축: 책임·주입·상태·이벤트)

UX §3 화면 11개 + Custom 컴포넌트 7개 + Core 모듈 핵심을 모두 4축으로.

### 3.1 Onboarding Feature

#### 3.1.1 OnboardingFlow

- **책임**: 5단계 router. `currentStep: OnboardingStep` 상태로 SwitchView.
- **주입**: `PermissionCoordinator`, `UserPreferences`(SwiftData), `CalibrationEngine`
- **상태 (`@Observable`)**: `currentStep: OnboardingStep`, `selectedPersona: Persona?`, `motionPermission: PermissionState`
- **이벤트**: `next()` `back()` `selectPersona(_:)` `requestMotion()` `startCalibration()`
- **에러**: 권한 거부 시 `motionPermission = .denied` + Step 5 진입 시 calibrate 비활성

#### 3.1.2 OnboardingWelcomeView (UX §3.1)

- **책임**: 5초 룰 첫 화면. "AirPods + 위 건강" 단어 노출.
- **주입**: `OnboardingFlow` (parent observable)
- **상태**: idle (단일 상태)
- **이벤트**: `onTapStart()` → `flow.next()`

#### 3.1.3 OnboardingPersonaView (UX §3.2)

- **책임**: 페르소나 자기 식별. 3 카드 중 1개 선택.
- **주입**: `OnboardingFlow`
- **상태**: `selected: Persona?` (parent에서 binding)
- **이벤트**: `selectPersona(_:)` → flow에 반영, "다음" 활성

#### 3.1.4 OnboardingHowItWorksView (UX §3.3)

- **책임**: 정직성 카드 3장 (TabView page style). Card 3 = 정확도 ±15% 노출.
- **상태**: `currentPage: 0..2`
- **이벤트**: `onComplete()` → `flow.next()`

#### 3.1.5 OnboardingMotionPermissionView (UX §3.4)

- **책임**: Motion 권한 요청 + 거부 fallback
- **주입**: `PermissionCoordinator`
- **상태**: `phase: .idle | .requesting | .granted | .denied`
- **이벤트**: `onTapAllow()` → `coordinator.requestMotion()` async → state 갱신; `onTapLater()` → fallback 카피 노출 후 next 활성

#### 3.1.6 OnboardingCalibrationIntroView (UX §3.5)

- **책임**: 캘리브레이션 식사 시작 트리거
- **이벤트**: `onTapStart()` → `ActiveMealView(mode: .calibrating)` 진입; `onTapLater()` → Dashboard 진입

### 3.2 ActiveMeal Feature

#### 3.2.1 ActiveMealView (UX §3.6)

- **책임**: 식사 중 라이브 화면 — 진행 시간·호흡 애니메이션·종료 트리거. 영상 시청 모드 자동 dim.
- **주입**: `ActiveMealViewModel`
- **상태 (ViewModel `@Observable`)**:
  - `currentDurationSec: Int`
  - `currentChewCount: Int` (estimate)
  - `currentCPM: Double?`
  - `phase: MealUIPhase` (`.idle | .active | .paused | .ending`)
  - `videoMode: Bool` (`AudioSessionMonitor` 구독)
  - `mode: ActiveMealMode` (`.calibrating | .auto | .manualTrigger`)
- **이벤트**:
  - `onAppear()` → tracker 구독 시작
  - `onTapEnd()` → `tracker.endSession(reason: .userTriggered)` → `MealResultCard` 노출 후 dismiss
  - tracker `.paused` emit → phase 갱신 + UI dim
  - tracker `.ending` emit → "혹시 식사 끝나셨어요?" CTA
- **에러 상태**:
  - AirPods 분리 → `phase = .paused`
  - Motion 권한 미허용 + manual mode → 정상 진행 (수동 트리거)

#### 3.2.2 ActiveMealViewModel

- **주입**: `MealSessionTracker`, `MotionStream`, `MealRepository`, `AudioSessionMonitor`, `CalibrationEngine`
- **AsyncStream 구독**: `for await event in tracker.events { ... }`
- **저장**: 종료 시 `repository.save(mealSession)`

### 3.3 Dashboard Feature

#### 3.3.1 DashboardView (UX §3.7)

- **책임**: 홈 — TodayHeader / MealResultCard / Comfort row / 차트 / Insight / WeeklyRecap entry / FAB
- **주입**: `DashboardViewModel`
- **상태 (ViewModel)**:
  - `state: DashboardUIState` (`.empty | .calibrationDone | .normal | .error`)
  - `todayMeals: [MealSession]`
  - `weekMeals: [MealSession]` (최근 7일)
  - `latestUnseenMeal: MealSession?` (MealResultCard 노출 조건)
  - `currentInsight: CoachingMessage?`
  - `discovery: PatternResult?`
- **이벤트**:
  - `onAppear()` → 데이터 로드 + 첫 인사이트 노출 시 알림 권한 요청 sheet
  - `onTapStartMeal()` → `MealStartConfirmationSheet` 노출
  - `onComfortReported(_:)` → repository update + toast
- **에러**: data load fail → retry 카피

#### 3.3.2 MealHistoryView (UX §3.8)

- **책임**: 누적 식사 리스트 (탭바 2)
- **주입**: `MealRepository` (`@Query` 직접 사용도 가능)
- **상태**: `state: .empty | .loaded | .error`

#### 3.3.3 MealDetailView (UX §3.9)

- **책임**: 단일 식사 깊이 보기. `MealTimelineChart` (분당 chew 빈도 라인 차트)

#### 3.3.4 WeeklyRecapView (UX §3.10)

- **책임**: Day 7+ 주간 회고 시트
- **주입**: `WeeklyRecapEngine`(InsightGenerator의 weekly variant), `MealRepository`
- **상태**: `state: .loading | .loaded | .noData`

### 3.4 Settings Feature

#### 3.4.1 SettingsView (UX §3.11)

- **책임**: 권한·알림·데이터·정보 관리. 비-AirPods/시뮬레이터 안내(§8 알려진 한계 표시).
- **주입**: `PermissionCoordinator`, `UserPreferences`, `MealRepository`
- **상태**: 각 항목 toggle binding
- **이벤트**: 데이터 내보내기 (CSV) → `DataExportSheet`; 모두 삭제 → confirm alert

### 3.5 Custom 컴포넌트 7개 (UX §12.1)

#### MealResultCard (UX §6)

- **책임**: 식사 종료 직후 Dashboard 상단 카드 — 시각·시간·비교·코칭 메시지·Comfort row
- **주입**: `meal: MealSession`, `calibrationDuration: Int?`, `coachingMessage: CoachingMessage?`, `onTapDetail: () -> Void`
- **상태**: stateless (parent 데이터 의존)
- **VoiceOver**: 카드 단위 합쳐진 라벨 (UX §10.1)

#### ChewBreathBadge (UX §3.6)

- **책임**: 호흡 애니메이션 원 + "차분히 드시고 있어요" 라벨
- **주입**: `intensity: BreathIntensity` (default: .normal)
- **상태**: `@State scale: CGFloat`, 4초 사이클 `Animation.easeInOut`
- **접근성**: `@Environment(\.accessibilityReduceMotion)` true 시 정적 원

#### ComfortSelfReportRow (UX §5.5)

- **책임**: 1-5 이모지 selfreport 1탭
- **주입**: `current: Int?`, `onSelect: (Int) -> Void`
- **상태**: `submitted: Bool` (1초 toast)
- **VoiceOver**: 각 이모지 "1점 매우 안 좋음" 등

#### InsightCard (UX §5.3)

- **책임**: Discoveries 카드 1개
- **주입**: `pattern: PatternResult`, `message: CoachingMessage`, `onTapDetail: () -> Void`

#### MealTrendChartCard (UX §5.2)

- **책임**: 7일 식사 시간 막대 차트
- **주입**: `data: [MealDataPoint]`, `targetMinutes: Int = 11`, `onTapBar: (MealSession) -> Void`
- **Swift Charts**: `BarMark` + `RuleMark` (목표선) + `AnnotationMark` (오늘)

#### PersonaCard (UX §3.2)

- **책임**: 페르소나 선택 카드 1장

#### TodayHeaderCard (UX §5.4)

- **책임**: 오늘 식사 N회·평균·코칭 1줄
- **주입**: `todayMealCount: Int`, `todayAvgDurationSec: Int?`, `coachingLine: String?`

### 3.6 Core 모듈 핵심 명세

#### MotionStream (protocol — Sensing)

```
public protocol MotionStream: Sendable {
    var samples: AsyncStream<IMUSample> { get }
    func start() async throws
    func stop() async
    var isAvailable: Bool { get async }    // AirPods 호환성 체크
}
```

- 구현 1: `LiveMotionStream` — `CMHeadphoneMotionManager` 래핑
- 구현 2: `MockMotionStream` — synthetic IMU generator (sine wave, walking, impulse 케이스)

#### Preprocessor (Detection — signal §2.2)

- **책임**: IMUSample → PreprocessedSample (magnitude). 30s ring buffer.
- **API**: `func ingest(_ sample: IMUSample)`, `var buffer: [PreprocessedSample]`

#### ChewDetector (Detection — signal §2.3)

- **책임**: bandpass 필터 + 피크 검출 + ArtifactFilter. ChewEvent emit.
- **주입**: `BiquadFilter`, `ArtifactFilter`, `DetectorConfig`
- **API**: `func detectChew(buffer:, now:) -> ChewEvent?`
- **단위 테스트**: signal §3.4 T1~T7

#### MealSessionTracker (Detection — signal §2.4)

- **책임**: 식사 세션 state machine (idle/calibrating/awaitingMeal/inMeal/ending). MealStartedEvent / CPMUpdate / MealEnded emit.
- **주입**: `Preprocessor`, `ChewDetector`, `OrchestratorConfig`, `MealRepository`
- **API**: `var events: AsyncStream<MealEvent>`, `func startManual()`, `func endManual()`
- **단위 테스트**: signal §3.4 T8~T11

#### CalibrationEngine (signal §4.1)

- **책임**: 캘리브레이션 식사 종료 시 사용자별 임계값 산출 (p70 magnitude, MEAL_START_THRESHOLD)
- **저장**: `UserCalibration` SwiftData 엔티티

#### TriggerEvaluator + MessagePicker (Coaching)

- **책임**: 컨텍스트 dictionary → 32개 메시지 중 1개 선택
- **API**:
  ```
  func pick(category: Category, context: [String: Any]) -> CoachingMessage?
  func evaluate(_ trigger: TriggerCondition, context: [String: Any]) -> Bool
  ```

#### PermissionCoordinator (Permissions)

- **책임**: 권한 시점 분리 (Motion / Notifications / Live Activity). 일괄 요청 *금지*.
- **API**: `requestMotion()`, `requestNotifications(reason:)`, `currentMotionState`, `currentNotificationState`

#### AudioSessionMonitor

- **책임**: `AVAudioSession.sharedInstance().isOtherAudioPlaying` 폴링 (`AVAudioSession.routeChangeNotification` + 1Hz check)
- **API**: `var isVideoPlaying: AsyncStream<Bool>`

---

## 4. 데이터 모델 (SwiftData)

### 4.1 엔티티 5개 + 마이그레이션

```swift
import SwiftData
import Foundation

// MARK: - MealSession

@Model
final class MealSession {
    @Attribute(.unique) var id: UUID
    var startedAt: Date
    var endedAt: Date?
    var durationSec: Int?           // computed at finalize
    var chewCount: Int              // detected chews
    var avgCPM: Double?
    var detectionConfidence: Double?    // 0..1
    var sourceRaw: String           // "auto" | "manualTrigger" | "calibration"
    var notes: String?
    var seenInDashboard: Bool       // MealResultCard 노출 조건 (UX §6.1)
    @Relationship(deleteRule: .cascade) var samples: [ChewSample]
    @Relationship(deleteRule: .cascade) var comfortReport: ComfortReport?

    init(startedAt: Date, source: MealSource = .auto) {
        self.id = UUID()
        self.startedAt = startedAt
        self.chewCount = 0
        self.sourceRaw = source.rawValue
        self.seenInDashboard = false
        self.samples = []
    }

    enum MealSource: String { case auto, manualTrigger, calibration }
    var source: MealSource { MealSource(rawValue: sourceRaw) ?? .auto }
}

// MARK: - ChewSample

@Model
final class ChewSample {
    var sessionId: UUID
    var timestamp: Date
    var intensity: Double           // magnitude g
    var confidence: Double          // 0..1

    init(sessionId: UUID, timestamp: Date, intensity: Double, confidence: Double) {
        self.sessionId = sessionId
        self.timestamp = timestamp
        self.intensity = intensity
        self.confidence = confidence
    }
}

// MARK: - ComfortReport (UX §5.5)

@Model
final class ComfortReport {
    @Attribute(.unique) var id: UUID
    var mealId: UUID?               // null = 일반 daily report
    var reportedAt: Date
    var score: Int                  // 1-5
    var note: String?               // 30자 제한 (UX §5.5)

    init(mealId: UUID?, score: Int, note: String? = nil) {
        self.id = UUID()
        self.mealId = mealId
        self.reportedAt = Date()
        self.score = score
        self.note = note
    }
}

// MARK: - DailyInsight

@Model
final class DailyInsight {
    @Attribute(.unique) var date: Date     // 일 단위 키 (00:00:00)
    var mealsCount: Int
    var totalDurationSec: Int
    var avgCPM: Double?
    var comfortAvg: Double?
    var generatedMessageId: String  // CoachingMessage.id
    var generatedMessageRendered: String   // 변수 치환 완료된 본문
    var generatedAt: Date

    init(date: Date, mealsCount: Int, totalDurationSec: Int, messageId: String, rendered: String) {
        self.date = date
        self.mealsCount = mealsCount
        self.totalDurationSec = totalDurationSec
        self.generatedMessageId = messageId
        self.generatedMessageRendered = rendered
        self.generatedAt = Date()
    }
}

// MARK: - UserCalibration (signal §4.1)

@Model
final class UserCalibration {
    @Attribute(.unique) var id: UUID
    var calibratedAt: Date
    var peakThresholdG: Double
    var mealStartThreshold: Int
    var calibrationDurationSec: Int
    var calibrationCPM: Double
    var sourceMealId: UUID

    init(peakThresholdG: Double, mealStartThreshold: Int,
         calibrationDurationSec: Int, calibrationCPM: Double, sourceMealId: UUID) {
        self.id = UUID()
        self.calibratedAt = Date()
        self.peakThresholdG = peakThresholdG
        self.mealStartThreshold = mealStartThreshold
        self.calibrationDurationSec = calibrationDurationSec
        self.calibrationCPM = calibrationCPM
        self.sourceMealId = sourceMealId
    }
}

// MARK: - UserPreferences (페르소나 선택, 정직성 동의 기록, 알림 설정)

@Model
final class UserPreferences {
    @Attribute(.unique) var id: UUID = UUID()    // singleton
    var personaRaw: String?         // "gastric" | "diet" | "curious"
    var honestyAcknowledgedAt: Date?    // UX §3.3 정직성 카드 진입 기록
    var notificationsAllowedAt: Date?
    var dailyInsightTime: Date      // default 09:30
    var weeklyRecapDayOfWeek: Int   // 1-7 (default 1=일요일)
    var weeklyRecapTime: Date       // default 21:00
    var pacingToastLevel: String    // "off" | "light" | "standard"
    var endNotifLevel: String       // "off" | "light" | "standard"

    init() { /* defaults */ }
}
```

### 4.2 마이그레이션 정책

- **V1.0 출시 전**: destructive migration OK (`isStoredInMemoryOnly` 또는 dev wipe)
- **V1.0 출시 후**: SwiftData `VersionedSchema` + `MigrationPlan` (lightweight 우선, custom는 필요 시)
- **첫 스키마 ID**: `SchemaV1` (아래 5 엔티티)
- **HealthKit 연동(V1.5)**: 별도 export adapter — 스키마 변경 없이 read-only 추가

### 4.3 MealRepository API

```swift
@MainActor
final class MealRepository {
    private let context: ModelContext
    init(context: ModelContext) { self.context = context }

    func save(_ meal: MealSession) throws
    func recentMeals(days: Int) -> [MealSession]
    func todayMeals() -> [MealSession]
    func meal(id: UUID) -> MealSession?
    func attachComfort(mealId: UUID, score: Int, note: String?) throws
    func markSeen(mealId: UUID) throws
    func deleteAll() throws
    func exportCSV() throws -> URL
}
```

---

## 5. 백그라운드·권한·생명주기

### 5.1 권한 요청 시퀀스 (UX §7.2 시점 분리)

| 권한 | Info.plist 키 | 요청 시점 | 거부 fallback |
|------|--------------|----------|---------------|
| **Motion** | `NSMotionUsageDescription` | OnboardingMotionPermissionView (Step 4 — 첫 식사 직전) | 자동 검출 비활성. 수동 시작 트리거만으로 V1 정상 작동. Settings 딥링크 안내. |
| **Notifications** | (런타임만) | 첫 인사이트 카드 노출 직후 sheet (Day 1 또는 Day 2) | in-app 카드만. 푸시 없음. Dashboard 재방문 배너로 재요청. |
| **Live Activity** | `NSSupportsLiveActivities` (V1.5+) | Day 3+ 사용자가 수동 시작 트리거 사용 시 | 식사 중 화면 표준 모드만. |
| **HealthKit** | (V1 제외) | V1.5 — Settings에서 사용자 선택 | 비활성화. |
| **Background Refresh** | `UIBackgroundModes: audio` | 시스템 자동 (요청 안 함) | Settings 안내만. |

**원칙**: 첫 실행 권한 일괄 요청 *금지*. 각 시점에 컨텍스트 카피로 거부율 ↓.

### 5.2 동작 모드 (signal §5.1, UX §4.1·§4.3 정합)

| 모드 | 트리거 | 동작 | 한계 |
|------|--------|------|------|
| **Foreground active** | 사용자 앱 진입 + 식사 시작 (수동/자동) | `LiveMotionStream` 25Hz 수신 + UI 실시간 갱신 | 사용자가 백그라운드 보내면 중단 |
| **Audio session active** | 영상·음악 재생 중 (`UIBackgroundModes: audio` 활성) | IMU 수신 유지 [signal §5.1#3] | audio 종료 시 중단. 영상 시청 컨텍스트 = `ActiveMealView.videoMode = true` (UI dim) |
| **True background** | (V1 제외) | (시스템 정책 강함, 짧은 윈도우만) | V1.5 후보 |

**Audio session 설정**: `AVAudioSession.Category.playback`(또는 `playAndRecord`) + `mode = .default`. 식사 시작 시 활성화 또는 사용자가 영상 재생 중이면 우연히 정합 (별도 활성화 불요).

### 5.3 AirPods 분리 시나리오 (UX §3.6 paused 상태)

- **식사 중 분리** → `LiveMotionStream` connect 콜백 false → `MealSessionTracker.pause()` → UI `phase = .paused` ("AirPods가 잠시 끊겼어요")
- **5분 내 재연결** → 자동 재개 (`tracker.resume()`)
- **5분 초과** → 세션 자동 종료, `endedAt` = 분리 시점, `partialData = true` flag → MealResultCard에 "부분 기록" 안내

### 5.4 앱 생명주기

- **첫 실행**: ChewCoachApp `init()` → ModelContainer 생성 → `OnboardingFlow` 진입 (UserPreferences 없음 또는 onboardingComplete=false)
- **재실행**: onboardingComplete=true → `RootTabView` (Dashboard / History / Settings)
- **백그라운드 진입 (식사 중)**: audio session active이면 IMU 유지, 아니면 `tracker.pause()`
- **앱 종료 (강제)**: 진행 중 세션 자동 finalize (다음 실행 시 복구)

---

## 6. 빌드·검증 단계 계획 (구현자 6단계)

각 단계 끝 검증 항목을 04_brief §8 체크리스트로 그대로 노출.

### Step 1 — 데이터 모델·스토리지 (1~1.5일)

- `project.yml` 작성 + `xcodegen generate` → `.xcodeproj` 생성
- `App/ChewCoachApp.swift` + `ModelContainer` 구성
- `Core/Storage/` 5개 `@Model` + `MealRepository` + `MigrationPlan`
- **검증**:
  - `xcodebuild -project app/ChewCoach.xcodeproj -scheme ChewCoach -destination 'generic/platform=iOS Simulator' build` 통과
  - `MealRepositoryTests` CRUD 통과 (save / recentMeals / attachComfort / markSeen / deleteAll)
  - 빌드 워닝 0

### Step 2 — 코어 알고리즘 (3~4일)

- `Core/Sensing/MotionStream.swift` (protocol) + `MockMotionStream` (synthetic generator)
- `Core/Detection/Preprocessor.swift` + `BiquadFilter.swift` (vDSP 기반, SOS 계수 hard-code)
- `Core/Detection/ChewDetector.swift` + `ArtifactFilter.swift`
- `Core/Detection/MealSessionTracker.swift` (state machine)
- `DetectorConstants.swift` (signal 부록 A 매직 넘버 표 그대로)
- `Core/Calibration/CalibrationEngine.swift`
- **검증**:
  - signal §3.4 단위 테스트 12개 모두 통과 (T1~T12)
  - `MealSessionTrackerTests` 시작·종료·grace·짧은 false positive 폐기
  - Mock 분기 — `XCTAssertNoThrow(try await mockStream.start())` 시뮬레이터 동작

### Step 3 — UI 화면 (3~4일)

- `Shared/DesignSystem/` (Color/Font/Spacing/Motion 토큰)
- `Shared/Components/` (Custom 7개)
- `Features/Onboarding/` (5개 View + Flow)
- `Features/Dashboard/` (Dashboard / MealHistory / MealDetail / WeeklyRecap)
- `Features/Settings/` (SettingsView / HonestyPledgeView)
- `Features/ActiveMeal/` (ActiveMealView + Sheet)
- 네비게이션: `RootTabView` (3 tabs) + `NavigationStack`
- **검증**:
  - 시뮬레이터 진입 가능, 11화면 + 모달 3개 모두 도달 가능
  - SwiftUI `#Preview` 모든 화면 렌더링 OK (Mock 데이터)
  - 네비게이션 끊김 0건

### Step 4 — 라이브 모션 통합 (1.5~2일)

- `Core/Sensing/LiveMotionStream.swift` (`CMHeadphoneMotionManager`)
- `Core/Permissions/PermissionCoordinator.swift` (Motion + Notifications)
- `Core/AudioContext/AudioSessionMonitor.swift`
- `AppEnvironment` 분기: 시뮬레이터 → Mock / 실기기 → Live
- Info.plist `NSMotionUsageDescription` 한국어 카피 (UX §3.4)
- **검증**:
  - 시뮬레이터에서 Mock 자동 분기 (식사 시뮬 동작)
  - 실기기 권한 요청 다이얼로그 노출 (실기기 검증은 사용자가)
  - 권한 거부 시 fallback UI 정상 (Settings 딥링크)

### Step 5 — 코칭 메시지 엔진 (2일)

- `Core/Coaching/CoachingMessage.swift` (struct + Category/Tone enum)
- `Core/Coaching/MessageLibrary.swift` (32개 static let)
- `Core/Coaching/TriggerEvaluator.swift` + `MessagePicker.swift`
- `Core/Coaching/KoreanParticle.swift`
- `Core/Coaching/PatternEngine.swift` (UX §5.3 V1 패턴 검출)
- `Core/Coaching/InsightGenerator.swift` (DailyInsight 생성, BackgroundTasks API로 일일 트리거)
- **검증**:
  - `MessageLibraryTests`: 32개 메시지 모두 lint 통과 (UX §8.3 금지 표현 0건)
  - 컨텍스트 dictionary 입력 → 카테고리별 1개 선택 시뮬레이션
  - DailyInsight 자동 생성 — 7일 시뮬 데이터 입력 → 7개 insight 생성 + WeeklyRecap 시드 1개

### Step 6 — 폴리시·접근성 (1.5~2일)

- Dynamic Type AX1~AX5 모든 화면 깨짐 없음 (`ViewThatFits` 적용)
- VoiceOver 라벨 (UX §10.1 — 모든 Custom 컴포넌트)
- 다크 모드 — `Color.label` / `.systemBackground` 100% 사용 검증
- prefers-reduced-motion (UX §10.4)
- `accessibilityReduceMotion` 환경 적용 (`ChewBreathBadge`)
- 빌드 워닝 0
- **검증**:
  - `xcodebuild build` 워닝 0건
  - 시뮬레이터 다크 모드 토글 시 모든 화면 적응
  - VoiceOver 흐름 5개 (UX §10.5) 완주
  - 5초 룰 시나리오 5개 (UX §11.1) 시뮬레이터 self-audit

**총 예상 11~16일** — 1인 빌드 기준. signal §6.1 11일과 정합.

---

## 7. 테스트 전략

### 7.1 단위 테스트 (XCTest) — Mock 모션 스트림

`MockMotionStream` synthetic IMU generator + `Preprocessor` + `ChewDetector` + `MealSessionTracker`만으로 *CMHeadphoneMotionManager mock 불필요*하게 12개 테스트 통과.

| # | 케이스 | 입력 | 기대 출력 | 출처 |
|---|--------|------|---------|----|
| T1 | 이상적 저작 | 1.5 Hz sine, 0.08g, 60s | ChewEvent 90 ±5 | signal §3.4 |
| T2 | 저작 빈도 하한 | 1.0 Hz, 0.06g, 60s | ChewEvent 60 ±5 | signal §3.4 |
| T3 | 저작 빈도 상한 | 1.95 Hz, 0.07g, 60s | ChewEvent 117 ±5 | signal §3.4 |
| T4 | 대역 외 (말하기) | 3.5 Hz, 0.05g, 60s | ChewEvent 0 (bandpass reject) | signal §3.4 |
| T5 | 대역 외 (끄덕임) | 0.6 Hz, 0.05g, 60s | ChewEvent 0 (bandpass reject) | signal §3.4 |
| T6 | 걷기 시뮬 | 2.0 Hz, 0.30g, 60s | ChewEvent 0 (avgMag > 0.15g reject) | signal §3.4 |
| T7 | AirPods 임펄스 | 0.8g spike + 무신호 | ChewEvent 0 (peakMag > 0.5g reject) | signal §3.4 |
| T8 | 식사 시작 검출 | 1.5 Hz, 0.08g, 90s | MealStartedEvent emit, source=.auto | signal §3.4 |
| T9 | 명시 트리거 | manualTrigger + 무신호 | MealStartedEvent emit, source=.manualTrigger | signal §3.4 |
| T10 | 종료 grace | 1.5Hz 60s → 무신호 60s → 1.5Hz 30s → 무신호 120s | 단일 MealSession (270s), 중간 60s 흡수 | signal §3.4 |
| T11 | 짧은 false positive 폐기 | 1.5Hz 60s 단일 | MealSession 발생 후 finalize에서 폐기 (90s 미만) | signal §3.4 |
| T12 | 검출 latency | 1.5Hz pulse train 시작 후 첫 ChewEvent 시간 | 첫 emit ≤ 2.5s | signal §3.4 |

### 7.2 추가 단위 테스트

- **CalibrationEngineTests** — 캘리브레이션 IMU 입력 → p70 magnitude·MEAL_START_THRESHOLD 산출 + clamp(0.03~0.12) 검증
- **MessageLibraryTests** — 32개 메시지 lint:
  - 카피에 UX §8.3 금지 표현 0건 ("치료" / "100%" / "track" / 영어 잔존 등)
  - 모든 변수 자리 (`{{var}}`) 변수 정의에 매칭
  - 모든 메시지 해요체 종결
- **KoreanParticleTests** — 이/가, 을/를, 은/는 자동 처리 (받침 유무 분기)
- **TriggerEvaluatorTests** — 컨텍스트 dictionary → bool, nil 변수 처리

### 7.3 시뮬레이터 검증 가능 / 실기기 전용 분리

| 검증 가능 환경 | 항목 |
|------------|----|
| **시뮬레이터 (`generic/platform=iOS Simulator`)** | 빌드 통과, UI 화면 렌더링 (`#Preview`), Mock 모션 분기, SwiftData CRUD, 단위 테스트 12개 + α, Dynamic Type, VoiceOver, 다크 모드 |
| **시뮬레이터 (디바이스 다운로드 후)** | 11 화면 + 모달 3개 네비게이션 흐름, 알림 sheet 노출, Settings 딥링크 |
| **실기기 (AirPods Pro 2 + iPhone)** | LiveMotionStream 실제 IMU 수신, 권한 시스템 다이얼로그, 캘리브레이션 식사 정확도, audio session active 백그라운드, AirPods 분리 콜백 |

`_brief.md` §5: 시뮬레이터 디바이스 0개 환경 — `xcodebuild` generic destination으로 빌드만 검증, 시뮬 실행은 사용자가 별도 다운로드.

### 7.4 UI 스냅샷 테스트

V1엔 *제외* (외부 SDK 의존, 1인 유지보수 부담). 대신 SwiftUI `#Preview`로 시각 확인.

### 7.5 xcodebuild 명령 (시뮬레이터 0개 환경)

```bash
# 빌드 (시뮬 미설치도 통과)
xcodebuild -project app/ChewCoach.xcodeproj \
  -scheme ChewCoach \
  -destination 'generic/platform=iOS Simulator' \
  -skipPackagePluginValidation \
  build

# 단위 테스트 (시뮬 1개 다운로드 후)
xcodebuild -project app/ChewCoach.xcodeproj \
  -scheme ChewCoach \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=17.0' \
  test
```

시뮬 디바이스가 없는 경우 빌드만 검증하고 단위 테스트는 사용자가 시뮬 다운로드 후 실행.

---

## 8. 알려진 한계 사전 표시

V1에서 *반드시 사용자에게 노출*해야 하는 한계. 모두 Settings 화면 + 관련 UI 안내 카피로.

### 8.1 한계 표

| # | 한계 | 영향 | UX 표시 위치 | 카피 |
|---|------|------|-----------|------|
| 1 | **안드로이드 미지원** | 안드로이드 사용자 0% 도달 | App Store 설명 (V1.5+ 등록 시) + 마케팅 페이지 | "iOS 17 이상 + AirPods Pro/3세대/Max 한정" |
| 2 | **비-AirPods 헤드폰 미지원** | 일반 무선 이어폰·AirPods 1세대 사용자 차단 | OnboardingMotionPermissionView (디바이스 체크 후 안내) + Settings → 디바이스 | "AirPods Pro·3세대·Max를 끼고 식사하시면 자동 인식돼요. 다른 이어폰은 *수동 시작* 모드만 작동해요." |
| 3 | **시뮬레이터 디바이스 0개 (개발 환경)** | 시뮬 실행 검증 차단 | (개발자 메모 — 사용자 가시 X) | `_brief.md` §5 안내 따름. xcodebuild generic destination으로 빌드만 |
| 4 | **백그라운드 보장 미흡** | 영상 시청 외 백그라운드 자동 검출 불안정 [signal §5.1#3] | OnboardingHowItWorksView 카드 3 + Settings 정직성 약속 | "영상 보시면서는 자동 인식, 그 외에는 살짝 늦을 수 있어요." |
| 5 | **자유생활 정확도 천장 F1 0.71-0.80** | 100% 약속 불가 | OnboardingHowItWorksView 카드 3 + Settings 정직성 약속 + MealDetailView | "추정 정확도 ±15%. 행동 변화 코칭용이에요." |
| 6 | **이갈이 검출 불가** | 25Hz Nyquist 한계 [signal §5.4] | (V1 카피에 노출 0건 — 약속 안 함으로 회피) | — |
| 7 | **음식 종류·칼로리 인식 불가** | Vessyl 함정 회피 | Settings 정직성 약속 | "칼로리·음식 종류 자동 인식하지 않아요." |
| 8 | **HealthKit 미통합 (V1)** | Apple Health 연동 0건 | Settings → 데이터 (V1.5 안내만) | "Apple 건강 앱 연동은 다음 버전에서 준비 중이에요." |
| 9 | **클라우드 백업 미지원 (V1)** | 기기 변경 시 데이터 이전 불가 | Settings → 데이터 | "데이터는 기기 내에만 저장돼요. 백업 옵션은 다음 버전에서 준비 중이에요." |

### 8.2 SettingsView "정직성 약속" 화면 카피 (UX §3.11 + §5.3 가드레일)

```
우리는 약속해요:
- 식사 시간을 추정으로 보여드려요 (정확도 ±15%)
- 패턴 인사이트를 제공해요
- 행동 변화를 도와드려요

우리는 약속하지 않아요:
- 위염 치료 / 의료적 효과
- 칼로리·음식 종류 자동 인식
- 100% 정확한 측정
- 이갈이 / 야간 grinding 검출
```

이 카피는 V1 출시 전 *사용자가 클릭 안 해도 한 번 노출되도록* HowItWorks 카드 3에 핵심 발췌 (UX §3.3).

---

## 9. 후속 작업 (V1.5+ 결정 영향)

이 문서가 흔들리지 않게 V1 ≠ V1.5 분리 명시:

- **HealthKit 통합 (V1.5)**: read = `.dietaryEnergyConsumed` (manual export only) / write = `.mindfulSession`(식사 명상 시간). 사용자 명시 동의.
- **CoreML 분류기 (V1.5)**: 누적 라벨 1,000건 후 — 1D-CNN 50K params, < 200KB. Stage 2 후처리.
- **Live Activity (V1.5)**: 식사 중 Dynamic Island. ActivityKit. 권한 추가.
- **CloudKit sync (V2)**: SwiftData CloudKit 통합 — 사용자 옵트인 후 익명화.
- **Apple Watch complication (V2)**: 수동 트리거 채널 (signal §2.5 mitigation 1).

---

## 10. 흔한 실수 자가 점검 (출시 전)

- [ ] 외부 SPM 의존성 추가됨? → V1은 0개 유지
- [ ] iOS 16 fallback 코드 들어감? → V1은 17+ 한정
- [ ] 권한 일괄 요청? → Motion·Notifications 시점 분리 (UX §7)
- [ ] 백그라운드 약속 카피? → audio session active 외 약속 0건
- [ ] HealthKit 무의식적 의존? → V1 import 0건
- [ ] Combine + RxSwift? → async/await만
- [ ] Core Data? → SwiftData만
- [ ] `01_signal_processing.md` §5.3 약속 금지 어휘 카피 잔존? → MessageLibraryTests로 검증

---

## 부록 A. 매직 넘버 인용 표 (signal 부록 A 그대로 — DetectorConstants.swift)

```swift
enum DetectorConstants {
    static let SAMPLE_RATE: Double = 25.0          // [기술-1.1] CMHeadphoneMotionManager
    static let BAND_LOW_HZ: Double = 0.94          // [기술-2.1] 일반 저작 빈도 하한
    static let BAND_HIGH_HZ: Double = 2.0          // [기술-2.1] 일반 저작 빈도 상한
    static let MIN_PEAK_INTERVAL_SEC: Double = 0.3 // 분당 200회 생리 상한
    static let DETECT_WINDOW_SEC: Double = 2.0     // 검출 슬라이딩 윈도우
    static let DEFAULT_PEAK_THRESHOLD_G: Double = 0.05  // [IMChew 2024] 캘리브 가능
    static let MEAL_START_WINDOW_SEC: Double = 60.0
    static let DEFAULT_MEAL_START_THRESHOLD: Int = 25   // 캘리브 가능
    static let MEAL_END_WINDOW_SEC: Double = 120.0
    static let MEAL_END_THRESHOLD_CPM: Double = 8.0
    static let END_GRACE_SEC: Double = 90.0
    static let MIN_MEAL_DURATION_SEC: Double = 90.0
    static let WALKING_AVG_THRESHOLD: Double = 0.15
    static let IMPULSE_THRESHOLD: Double = 0.5
    static let BUFFER_SECONDS: Double = 30.0
    static let CALIBRATION_THRESHOLD_MIN: Double = 0.03
    static let CALIBRATION_THRESHOLD_MAX: Double = 0.12
    static let CALIBRATION_PERCENTILE_FACTOR: Double = 0.7   // p70
    static let CALIBRATION_START_FACTOR: Double = 0.6
    static let CALIBRATION_START_FLOOR: Int = 15
}
```

---

## 부록 B. 핵심 출처 인용 (이 문서에 반영된 결정)

- `_brief.md` §4·§5 — Xcode 26.4 + xcodegen 2.45.3 + iOS 17+ 환경, 시뮬 0개
- `01_signal_processing.md` §2 — 3 stage 파이프라인, vDSP biquad, 매직 넘버 표
- `01_signal_processing.md` §3.4 — 단위 테스트 12개 케이스 (Detector·Tracker)
- `01_signal_processing.md` §4.1 — 캘리브레이션 5단계 시퀀스
- `01_signal_processing.md` §5.1 — 한계 7개 표
- `01_signal_processing.md` §7.2 — architect 6개 입력 (모듈 분해/SwiftData/백그라운드/CPU/권한/테스트)
- `03_app_ux_spec.md` §3 — 11화면 + 모달 3개 인벤토리
- `03_app_ux_spec.md` §4.1 — 햅틱 0건, 사후 리포트 우선
- `03_app_ux_spec.md` §7 — 권한 시점 분리 표
- `03_app_ux_spec.md` §8 — 코칭 메시지 라이브러리 32개
- `03_app_ux_spec.md` §9 — 디자인 토큰 (색·폰트·간격·모션)
- `03_app_ux_spec.md` §10 — 접근성 가드 (VoiceOver/Dynamic Type/대비/reduce_motion)
- `03_app_ux_spec.md` §12 — 다음 에이전트 가이드 (architect / implementer)
- `discovery_report.md` §5.1 — 옵션 G 1순위, 결과 프레이밍 톤, Apple 흡수 방어선

---

## 업데이트 이력

- **2026-05-02**: 초안. 8개 필수 섹션 (기술 스택·프로젝트 구조·컴포넌트·데이터 모델·백그라운드·빌드 단계·테스트·한계) 작성. signal §7 6개 입력 직접 인용으로 매핑. UX §3 11화면 + §8 32메시지 + §10 접근성 가드 모두 반영. 외부 의존성 0건 원칙 명시. xcodegen project.yml 골격 + DetectorConstants 부록 A 포함.
