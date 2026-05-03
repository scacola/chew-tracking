---
name: ios-app-craft
description: 통합 브리프(04_app_brief_consolidated.md)를 받아 빌드 통과하는 Swift/SwiftUI iOS 앱을 빌드하고 자체 검증·폴리시까지 수행하는 방법론. Xcode 프로젝트 생성·CMHeadphoneMotionManager 통합·SwiftData 모델·신호 알고리즘 Swift 구현·시뮬레이터 검증 포함. iOS 앱 빌드, Swift 코드 작성, AirPods 모션 통합 시 반드시 사용.
---

# iOS App Craft

설계가 끝났으면 만든다. *xcodebuild 통과 + 시뮬레이터 동작*하는 앱으로. 옵션 G의 약속은 코드로만 증명된다. `ios-app-implementer` 에이전트가 사용한다.

## 왜 이 스킬이 필요한가

iOS 앱 빌드 LLM의 흔한 실패:
- 사양과 *살짝 다르게* 코드 생성 (이름·필드 미세 차이)
- 시뮬레이터에서 안 되는 것을 무시 (CMHeadphoneMotionManager Mock 누락)
- async/await Swift 6 strict concurrency 워닝 무시
- SwiftData 스키마 변경 시 마이그레이션 누락
- 권한 거부 흐름 미구현
- 영어 placeholder 카피 한국어 번역 누락
- Xcode 프로젝트 파일을 손으로 편집 → 머지 충돌

이 스킬은 *6단계 빌드 순서 + 단계별 검증 + 시뮬레이터 한계 인정*을 강제한다.

## 6단계 빌드 — 순서 엄수

각 단계 끝에 *반드시* 검증. 다음 단계 전 체크리스트 통과 필수.

### Step 0: Xcode 프로젝트 생성 (30min-1h)

**옵션 A — `xcodebuild -create-project` (Xcode 16+)** 또는 **옵션 B — `xcodegen` (project.yml 기반)**.

`project.yml` 사용 권장 (재현성 + 머지 친화):

```yaml
name: ChewCoach
options:
  bundleIdPrefix: com.chewcoach
  deploymentTarget:
    iOS: '17.0'
  developmentLanguage: ko
settings:
  base:
    SWIFT_VERSION: '5.9'
    SWIFT_STRICT_CONCURRENCY: complete
targets:
  ChewCoach:
    type: application
    platform: iOS
    sources:
      - ChewCoach
    info:
      path: ChewCoach/Info.plist
      properties:
        NSMotionUsageDescription: "AirPods의 모션 데이터로 식사 패턴을 자동으로 살펴봐요."
        UILaunchScreen: {}
        CFBundleDevelopmentRegion: ko_KR
        CFBundleLocalizations: [ko, en]
  ChewCoachTests:
    type: bundle.unit-test
    platform: iOS
    sources: ChewCoachTests
    dependencies:
      - target: ChewCoach
```

```bash
cd /Users/sungho/Documents/programming/chew_tracking
mkdir -p app && cd app
brew install xcodegen 2>&1 | tail -1
xcodegen generate
xcodebuild -list  # 타겟 확인
```

검증:
```bash
xcodebuild -scheme ChewCoach -destination 'platform=iOS Simulator,name=iPhone 15' clean build | tail -20
# → BUILD SUCCEEDED
```

### Step 1: 데이터 모델·스토리지 (1-2h)

SwiftData @Model 클래스 작성, ModelContainer 설정, Repository 레이어.

```swift
// ChewCoach/Core/Storage/MealSession.swift
import Foundation
import SwiftData

@Model
final class MealSession {
    @Attribute(.unique) var id: UUID
    var startedAt: Date
    var endedAt: Date?
    var chewCount: Int
    var avgChewsPerMinute: Double?
    var durationSec: Int?
    var userReportedComfort: Int?
    var detectionConfidence: Double?
    @Relationship(deleteRule: .cascade) var samples: [ChewSample]

    init(startedAt: Date) {
        self.id = UUID()
        self.startedAt = startedAt
        self.chewCount = 0
        self.samples = []
    }
}
```

```swift
// ChewCoach/App/ChewCoachApp.swift
import SwiftUI
import SwiftData

@main
struct ChewCoachApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [MealSession.self, ChewSample.self, DailyInsight.self])
    }
}
```

검증: 단위 테스트로 Repository CRUD 통과.

### Step 2: 코어 알고리즘 with Mock (2-3h)

`MotionStream` 프로토콜 + `MockMotionStream` + `ChewDetector` 구현.

```swift
protocol MotionStream {
    func samples() -> AsyncStream<IMUSample>
    func start() async throws
    func stop()
}

struct IMUSample {
    let timestamp: Date
    let accelX, accelY, accelZ: Double
    var accelMagnitude: Double { sqrt(accelX*accelX + accelY*accelY + accelZ*accelZ) }
}

final class MockMotionStream: MotionStream {
    // 학습된 시나리오 재생: chewing 패턴, walking, speaking
    func samples() -> AsyncStream<IMUSample> { ... }
    func start() async throws { ... }
    func stop() { ... }
}
```

신호 처리는 `01_signal_processing.md`의 의사코드를 그대로 변환:

```swift
final class ChewDetector {
    private let mealStartThreshold: Int
    private let peakThreshold: Double
    private var state: DetectionState

    init(...) { ... }

    func process(_ sample: IMUSample) -> DetectionEvent? {
        state.recentSamples.append(sample)
        state.recentSamples.dropOlderThan(state.now.addingTimeInterval(-30))

        if !state.inMealSession {
            let recentChews = countChewPeaks(state.recentSamples, lastSec: 60)
            if recentChews >= mealStartThreshold {
                return .mealStarted(at: sample.timestamp)
            }
            return nil
        }

        if let peak = detectPeak(...), !isLikelySpeechOrWalking(peak, state: state) {
            state.recordChew(peak)
            return .chewDetected(at: peak.timestamp)
        }

        // Meal end check ...
        return nil
    }
}
```

매직 넘버는 모두 `01_signal_processing.md` 인용 주석 + 캘리브레이션 가능 형태로.

검증: XCTest로 알려진 Mock 시나리오 → 예상 chew count 매칭.

### Step 3: UI 화면 — Onboarding → Dashboard → ActiveMeal → Settings (3-5h)

각 화면을 03_app_ux_spec의 인벤토리대로. SwiftUI + @Observable ViewModel.

```swift
@Observable
final class ActiveMealViewModel {
    enum Phase { case idle, active, paused, ending }

    var phase: Phase = .idle
    var currentDurationSec: Int = 0
    var currentChewCount: Int = 0
    var currentCPM: Double?

    private let tracker: MealSessionTracker
    private let motion: MotionStream
    private let repo: MealRepository

    init(tracker: MealSessionTracker, motion: MotionStream, repo: MealRepository) { ... }

    func start() async { ... }
    func end() async { ... }
}

struct ActiveMealView: View {
    @State var vm: ActiveMealViewModel

    var body: some View {
        VStack(spacing: 24) {
            Text(vm.currentDurationSec.formattedDuration)
                .font(.system(size: 64, weight: .semibold, design: .rounded))
                .accessibilityLabel("식사 시간 \(vm.currentDurationSec)초")

            // ...

            Button {
                Task { await vm.end() }
            } label: {
                Text("식사 마치기")
                    .frame(maxWidth: .infinity, minHeight: 56)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
```

원칙:
- 디자인 토큰 (03_app_ux_spec)을 정확히 사용 — 인라인 색·크기 금지
- 카피는 *한국어 그대로*, 영어 placeholder 잔존 X
- 모든 컨트롤에 `accessibilityLabel`
- Dynamic Type 자동 (`.font(.body)`, `.title`)

검증: 시뮬레이터에서 모든 화면 진입, 네비게이션 끊김 없음.

### Step 4: 라이브 모션 통합 — `LiveMotionStream` (1-2h)

```swift
import CoreMotion

final class LiveMotionStream: MotionStream {
    private let manager = CMHeadphoneMotionManager()

    func start() async throws {
        guard manager.isDeviceMotionAvailable else {
            throw MotionError.unavailable
        }
        // 권한은 첫 startDeviceMotionUpdates 시 자동 요청
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let motion else { return }
            // continuation으로 AsyncStream에 전달
        }
    }

    func samples() -> AsyncStream<IMUSample> { ... }
    func stop() { manager.stopDeviceMotionUpdates() }
}
```

권한 흐름: `NSMotionUsageDescription`이 Info.plist에 있어야 첫 호출에 시스템 다이얼로그 표시.

검증: 빌드 통과. 실기기 + AirPods Pro 2 동작 검증은 *별도 표시* (시뮬레이터에서는 Mock 분기 자동).

```swift
enum MotionStreamFactory {
    static func make() -> any MotionStream {
        #if targetEnvironment(simulator)
        return MockMotionStream()
        #else
        if CMHeadphoneMotionManager().isDeviceMotionAvailable {
            return LiveMotionStream()
        } else {
            return MockMotionStream()  // fallback (or manual mode)
        }
        #endif
    }
}
```

### Step 5: 코칭 메시지 엔진 (1-2h)

```swift
enum CoachingMessage {
    case slowedDownYesterday(deltaSec: Int)
    case mondayLunchInsight(deltaPercent: Int)
    case sevenDayStreak(avgDurationSec: Int)
    // ...

    var rendered: String {
        switch self {
        case .slowedDownYesterday(let delta):
            return "어제보다 \(delta)초 천천히 드셨네요. 잘하고 계세요."
        // ...
        }
    }
}

final class InsightGenerator {
    func generateDailyInsight(for date: Date, history: [MealSession]) -> DailyInsight {
        // 03_app_ux_spec의 trigger 로직대로
    }
}
```

03_app_ux_spec의 메시지 라이브러리를 *enum 기반*으로 — 컴파일 시 빠진 case 발견 가능.

### Step 6: 폴리시·접근성 마감 (1-2h)

- Dynamic Type Large(XL)에서 텍스트 깨짐 검증 (시뮬레이터 Accessibility Inspector)
- VoiceOver로 핵심 흐름 통과
- 다크 모드 대비 검증
- 빌드 워닝 0개 — `SWIFT_STRICT_CONCURRENCY: complete`에서 누락된 `@MainActor`, `Sendable` 모두 fix
- prefers-reduced-motion: 차트 애니메이션·전환 비활성화

```swift
.transaction { tx in
    if UIAccessibility.isReduceMotionEnabled { tx.animation = nil }
}
```

## 자체 검증 — 빌드 보고

빌드 끝나면 `_workspace/app/05_build_report.md` 작성:

```markdown
# 빌드 보고

## 환경
- Xcode: 16.x
- iOS deployment target: 17.0
- Swift: 5.9
- 빌드 도구: xcodegen

## 빌드 단계 완료
- [x] Step 0: Xcode 프로젝트 생성
- [x] Step 1: 데이터 모델·스토리지
- [x] Step 2: 코어 알고리즘 (Mock)
- [x] Step 3: UI 화면
- [x] Step 4: 라이브 모션 통합 (LiveMotionStream — 시뮬레이터 빌드만, 실기기 미검증)
- [x] Step 5: 코칭 메시지 엔진
- [x] Step 6: 폴리시·접근성

## 의존성
- (SPM) 외부 의존성 없음 — 1st party만

## xcodebuild 결과
- clean build: SUCCEEDED
- test: PASSED (12 of 12)
- 워닝: 0

## 시뮬레이터 검증 시나리오
- 첫 실행 → Onboarding 5단계 → 권한 다이얼로그 표시 → 캘리브레이션 화면 진입 ✓
- Mock 모션 스트림 → 식사 세션 시작 → 5분 시뮬 → 종료 → 데이터 저장 → 대시보드 반영 ✓
- 다크 모드 진입 → 모든 화면 정상 ✓
- Dynamic Type XL → 화면 깨짐 없음 ✓
- VoiceOver → 온보딩 → 식사 시작 → 대시보드 통과 ✓

## 알려진 한계 — 실기기 필요
- AirPods Pro 2 실데이터 검출 정확도
- audio session active 백그라운드 동작 검증
- AirPods 분리 시 일시정지 동작 (시뮬레이터에선 트리거 불가)

## QA 폴리시 후보
- (구현자가 자체 발견한 이슈)
- (예: 다크 모드에서 차트 라벨 색 대비 미세 부족)
```

QA가 *이 보고서를 출발점*으로 검수하므로, 거짓 표시 절대 금지.

## 시뮬레이터·실기기 명확 분리

| 검증 항목 | 시뮬레이터 가능 | 실기기 + AirPods 필요 |
|---------|--------------|------------------|
| UI 진입·네비게이션 | ✓ | — |
| Mock 모션 → 데이터 흐름 | ✓ | — |
| 알고리즘 단위 테스트 | ✓ | — |
| Dynamic Type · VoiceOver | ✓ | — |
| 권한 다이얼로그 표시 | ✓ | — |
| 실데이터 검출 정확도 | ✗ | ✓ |
| audio session 백그라운드 | ✗ | ✓ |
| AirPods 분리 시나리오 | ✗ | ✓ |

빌드 보고서에 *실기기 전용* 항목을 명확히 표시 → QA가 사용자에게 안내.

## 흔한 실수

- ❌ Xcode 프로젝트 파일을 손으로 편집 → 머지 충돌 (xcodegen 사용)
- ❌ CMHeadphoneMotionManager Mock 분기 누락 → 시뮬레이터 크래시
- ❌ async/await Swift 6 워닝 무시 → 누적되어 노이즈
- ❌ SwiftData 스키마 변경 시 마이그레이션 누락
- ❌ 권한 거부 흐름 미구현
- ❌ 영어 placeholder 한국어 번역 누락
- ❌ 단위 테스트 없이 알고리즘 변경
- ❌ 빌드 워닝을 *나중에* 처리

## 후속 작업

- QA 발견 이슈 → 해당 모듈만 수정, 단위 테스트 추가
- 사용자 사양 변경 → Phase 1 팀 재호출 (구현자 단독 결정 X)
- 새 화면 추가 → 04_brief에 명세 추가 후 진행
