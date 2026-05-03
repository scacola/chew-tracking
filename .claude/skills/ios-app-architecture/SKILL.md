---
name: ios-app-architecture
description: 신호 알고리즘과 UX 사양을 *ios-app-implementer가 그대로 빌드 가능한* iOS 앱 통합 기술 명세로 변환하는 방법론. Swift/SwiftUI/SwiftData/CMHeadphoneMotionManager 통합 패턴, 모듈 분해, 백그라운드·권한 전략, 빌드 단계 결정 시 반드시 사용. iOS 앱 아키텍처 설계, Xcode 프로젝트 구조, AirPods IMU 통합 명세 작성에 적용.
---

# iOS App Architecture

옵션 G "Chew & Calm Coach" iOS 앱의 *기술 결정 + 구현 가이드*를 만든다. 이 단계가 부실하면 구현자가 헤매고, 앱이 사양과 다르게 나온다. `ios-app-architect` 에이전트가 사용한다.

## 왜 이 스킬이 필요한가

iOS 앱 아키텍처의 흔한 실패:
- 의존성 과다 추가 (V1에 RxSwift + Combine + 외부 차트 동시)
- 백그라운드 동작 *과대 약속* (discovery_report 한계 무시)
- 권한 요청 일괄 → 거부율 폭증
- 컴포넌트 분해 모호 → 구현자가 모듈 경계 추측
- HealthKit 무의식적 의존 → 카테고리 fit 검증 없이 V1 포함
- 04_brief에 알고리즘·UX 누락 → 구현자가 다른 파일을 다시 뒤짐

이 스킬은 *근거 있는 기술 결정 + 구현자가 그대로 빌드할 수 있는 통합 브리프*를 강제한다.

## 표준 기술 스택 (V1)

특별한 사유 없으면 다음 채택. 채택 시 *왜 이게 V1에 적합한지* 한 줄 명시:

| 영역 | 선택 | 이유 (한 줄) |
|------|------|-------------|
| 언어 | Swift 5.9+ | iOS 표준 |
| UI | SwiftUI 5+ | iOS 17+ 한정으로 SwiftData·Observation 호환 + 보일러플레이트 최소 |
| 최소 iOS | iOS 17.0 | SwiftData·Observation·Charts 기본 지원, AirPods Pro 2 사용자 대부분 17+ |
| 동시성 | async/await + AsyncSequence | Combine보다 단순, Swift 6 strict concurrency 친화 |
| 데이터 | SwiftData | iOS 17+ 표준, Core Data 보다 보일러플레이트 적음 |
| 차트 | Swift Charts (1st party) | 외부 의존성 0 |
| 의존성 관리 | SPM | CocoaPods 회피 |
| ML (필요 시) | CoreML | 외부 추가 X. V1은 룰 기반 우선 |
| 분석 | (V1 제외 또는 Apple 자체) | 사용자 동의 없는 외부 SDK 회피 |

대안 채택 시 (예: iOS 16+ 지원, Core Data 유지) → 03_architecture에 *근거*와 trade-off 명시.

## Xcode 프로젝트 구조 표준

```
app/
├── ChewCoach.xcodeproj
├── ChewCoach/
│   ├── App/
│   │   ├── ChewCoachApp.swift     (@main + ModelContainer 설정)
│   │   └── AppEnvironment.swift   (DI 컨테이너)
│   ├── Features/
│   │   ├── Onboarding/
│   │   │   ├── OnboardingFlow.swift
│   │   │   ├── PermissionRequestView.swift
│   │   │   └── CalibrationMealView.swift
│   │   ├── ActiveMeal/
│   │   │   ├── ActiveMealView.swift
│   │   │   └── ActiveMealViewModel.swift
│   │   ├── Dashboard/
│   │   │   ├── DashboardView.swift
│   │   │   ├── MealHistoryView.swift
│   │   │   ├── InsightCard.swift
│   │   │   └── DashboardViewModel.swift
│   │   └── Settings/
│   ├── Core/
│   │   ├── Sensing/
│   │   │   ├── MotionStream.swift              (프로토콜)
│   │   │   ├── LiveMotionStream.swift          (CMHeadphoneMotionManager)
│   │   │   └── MockMotionStream.swift          (시뮬레이터·테스트용)
│   │   ├── Detection/
│   │   │   ├── ChewDetector.swift              (신호 처리 알고리즘)
│   │   │   ├── MealSessionTracker.swift        (식사 윈도우 검출)
│   │   │   └── DetectionState.swift
│   │   ├── Storage/
│   │   │   ├── MealSession.swift               (@Model)
│   │   │   ├── ChewSample.swift                (@Model)
│   │   │   ├── DailyInsight.swift              (@Model)
│   │   │   └── MealRepository.swift
│   │   └── Coaching/
│   │       ├── MessageEngine.swift
│   │       ├── MessageTemplates.swift
│   │       └── InsightGenerator.swift
│   ├── Shared/
│   │   ├── DesignSystem/
│   │   └── Localization/
│   └── Resources/
│       └── Localizable.xcstrings
├── ChewCoachTests/
│   ├── ChewDetectorTests.swift
│   ├── MealSessionTrackerTests.swift
│   └── MessageEngineTests.swift
└── ChewCoachUITests/
```

원칙:
- **Feature 폴더 하나가 한 화면 흐름** — 다른 Feature 의존 X (Core·Shared만)
- **Core/Sensing은 프로토콜로 분리** — Live vs Mock 교체 가능 (시뮬레이터·테스트)
- **MVVM 또는 @Observable ViewModel** — 화면 상태와 비즈니스 로직 분리

## 컴포넌트·모듈 명세 작성법

각 화면·모듈에 다음 4축으로 명세:

```markdown
### ActiveMealView
- **책임**: 식사 중 라이브 화면 — 진행 시간·실시간 저작 수·사용자 종료 버튼
- **주입**: `MealSessionTracker`, `MotionStream`, `MealRepository`
- **상태 (@Observable)**:
  - `currentDurationSec: Int`
  - `currentChewCount: Int`
  - `currentCPM: Double?`
  - `phase: .idle | .active | .ending`
- **이벤트**:
  - `onStart()` → tracker.startSession()
  - `onEnd()` → tracker.endSession() → 대시보드로 navigate
- **에러 상태**:
  - AirPods 분리 → 일시정지 + 안내
  - 권한 거부 → 수동 모드 안내
```

각 화면을 이 형식으로 04_brief에 모두 명세한다. 구현자가 *추측 없이* 빌드 가능하도록.

## 데이터 모델 (SwiftData)

```swift
@Model
final class MealSession {
    @Attribute(.unique) var id: UUID
    var startedAt: Date
    var endedAt: Date?
    var chewCount: Int
    var avgChewsPerMinute: Double?
    var durationSec: Int?
    var userReportedComfort: Int?  // 1-5 자기보고
    var detectionConfidence: Double?  // 알고리즘 신뢰도
    var notes: String?
    @Relationship(deleteRule: .cascade) var samples: [ChewSample]

    init(startedAt: Date) {
        self.id = UUID()
        self.startedAt = startedAt
        self.chewCount = 0
        self.samples = []
    }
}

@Model
final class ChewSample {
    var sessionId: UUID
    var timestamp: Date
    var intensity: Double

    init(sessionId: UUID, timestamp: Date, intensity: Double) { ... }
}

@Model
final class DailyInsight {
    @Attribute(.unique) var date: Date  // 일 단위 키
    var mealsCount: Int
    var totalDurationSec: Int
    var avgCPM: Double?
    var comfortTrend: Double?  // 자기보고 평균
    var generatedMessage: String  // 코칭 카드 카피
    var generatedAt: Date

    init(date: Date) { ... }
}
```

마이그레이션 정책 V1: 스키마 변경 시 SwiftData `VersionedSchema` + `MigrationPlan` 사용. V1 출시 전엔 destructive 마이그레이션 OK, 출시 후엔 lightweight + custom.

## 백그라운드·권한·생명주기

### 권한 요청 시퀀스 (사양)

| 권한 | 요청 시점 | 거부 시 fallback |
|------|----------|---------------|
| Motion (`NSMotionUsageDescription`) | 첫 식사 시도 시 (Onboarding 캘리브레이션 직전) | 수동 모드 안내 + Settings 딥링크 |
| Notifications | 첫 일일 인사이트 생성 직후 | 대시보드 재방문 시 알림 받기 OK 배너 |
| HealthKit (V1.5+) | Settings에서 사용자가 연결 선택 시 | 비활성화 |

첫 실행에 일괄 요청 금지. iOS는 `NSMotionUsageDescription` Info.plist 키 필수.

### 동작 모드

| 모드 | 트리거 | 동작 | 한계 |
|------|--------|------|------|
| **Foreground active** | 사용자가 앱 진입 + 식사 시작 | 실시간 검출 + UI 업데이트 | 사용자가 백그라운드 보내면 중단 |
| **Audio session active** | 영상·음악 재생 중 | 검출 가능 [기술-한계#5.6] | audio 종료 시 중단 |
| **Background task** | 시스템 정책 | 짧은 윈도우만 (V1 제외, V1.5 후보) | iOS 정책 강함 |

V1은 *foreground + audio session*에 집중. true background는 V1.5 이후.

### AirPods 분리 시나리오

- 식사 중 분리 → 일시정지 + UI 안내 + 5분 내 재연결 시 세션 재개
- 5분 초과 → 세션 자동 종료, 데이터는 *부분 데이터*로 저장 + 사용자 confirm

## 빌드 단계 (구현자 6단계)

```
1. 데이터 모델·스토리지 (SwiftData @Model + Repository)
   → 검증: ChewCoachTests에 Repository CRUD 단위 테스트 통과

2. 코어 알고리즘 (Mock 모션 스트림으로)
   → ChewDetector + MealSessionTracker 구현
   → 검증: MockMotionStream이 알려진 IMU 시퀀스를 입력 → 예상 chew count 매칭

3. UI 화면 (Onboarding → Dashboard → ActiveMeal → Settings)
   → 시뮬레이터 진입 가능, 네비게이션 끊김 없음

4. 라이브 모션 통합 (CMHeadphoneMotionManager)
   → LiveMotionStream 구현, 권한 요청 흐름
   → 검증: 빌드 통과, 시뮬레이터에서는 Mock 분기 자동

5. 코칭 메시지 엔진
   → MessageEngine + InsightGenerator
   → 검증: DailyInsight 자동 생성 시뮬레이션

6. 폴리시·접근성
   → Dynamic Type, VoiceOver, 다크 모드, 빌드 워닝 0
```

각 단계 끝 검증 항목을 04_brief에 *체크리스트*로 포함.

## 04_app_brief_consolidated.md 작성 (구현자 입력)

이 한 파일만 보고 구현자가 빌드 가능해야:

```markdown
# Chew Coach iOS App — 통합 빌드 브리프

## 0. 개요
- 옵션 G 측정·대시보드 슬라이스 V1
- 타겟: iOS 17+, AirPods Pro 2/3/Max
- 빌드 결과: app/ 디렉토리 Xcode 프로젝트

## 1. 알고리즘 (신호 엔지니어 산출)
[01_signal_processing.md의 의사코드를 Swift 변환 가이드와 함께 첨부]

## 2. UX (디자이너 산출)
[03_app_ux_spec.md의 화면 인벤토리·코칭 메시지 라이브러리 첨부]

## 3. 아키텍처 (이 문서)
[02_app_architecture.md의 모듈 명세·데이터 모델·권한 흐름 첨부]

## 4. 빌드 단계 + 단계별 검증 체크리스트
[6단계 + 각 단계 통과 기준]

## 5. 성공 기준
[QA에 넘기기 전 체크리스트]
```

빠진 게 있으면 구현자가 다른 파일을 다시 뒤져야 함 → 시간 낭비. 이 한 파일에 모든 빌드 정보 압축.

## 흔한 실수

- ❌ Combine + RxSwift 동시 사용 (V1엔 둘 다 필요 없음 — async/await만)
- ❌ Core Data를 V1에 채택 (보일러플레이트 폭증, SwiftData가 표준)
- ❌ 백그라운드 동작을 *기본 가정* (discovery_report 한계 위반)
- ❌ 권한 일괄 요청
- ❌ HealthKit 자동 통합 (사용자 동의 없는 데이터 흐름)
- ❌ 04_brief에 알고리즘·UX 누락
- ❌ 빌드 단계 없이 구현자에게 던지기
- ❌ 모듈 경계 모호 (Core·Feature·Shared 혼재)

## 후속 작업

- 사용자가 "안드로이드 지원 추가" → 디스커버리 결과(불가) 인용 + PWA·웹 dashboard 대안 제시
- QA에서 모듈 경계 이슈 발견 → 해당 모듈 재분해
- 신규 화면·기능 추가 → 컴포넌트 명세 + 빌드 단계 갱신
