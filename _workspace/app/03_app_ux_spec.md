# 03. App UX Spec — Chew & Calm Coach iOS V1

**작성일**: 2026-05-02
**작성**: `app-experience-designer`
**대상 독자**: `ios-app-architect` (SwiftUI 컴포넌트 트리·상태 모델·네비게이션 결정), `ios-app-implementer` (코칭 메시지 라이브러리를 Swift enum/struct로 변환)
**스코프**: 옵션 G "Chew & Calm Coach" V1의 *화면 흐름·실시간 피드백·대시보드·온보딩·코칭 메시지 라이브러리* — SwiftUI로 그대로 빌드 가능한 명세
**상위 입력**: `_brief.md` (V1 스코프), `01_signal_processing.md` (검출 가능 신호·정확도·지연), `discovery_report.md` 옵션 G §3.3·§5.1, `04_product_ideation.md` 옵션 G

---

## 0. 결론 한 줄

> **위염 직장인 한지원이 영상 보면서 점심 먹는 8분이 어떻게 11분이 되는가** — V1은 *온보딩 캘리브레이션 1식사 → 자동 검출 → 식사 종료 사후 카드 1장 → 다음날 위 컨디션 셀프리포트 → 7일째 주간 회고 + Discovery 1개*의 7일 코어 루프로, **씹기 트래커가 아닌 위 컨디션 결과 코치**의 톤(다노식 친근 + 임상 권위, 의료 약속 0건, "추정 ±15%" 정직 표시)을 11개 화면 / 32개 코칭 메시지에 박아넣는다. 실시간 햅틱은 *비권장* (신호 latency 10초로 늦음 — `01_signal_processing.md` §3.1·§7.1) — 사후 리포트가 더 정직하고 영상 시청을 안 깬다.

---

## 1. 페르소나 컨텍스트 (3 + 상황적)

### 1.1 사용자 페르소나 (디스커버리 §3.3·§5.1 직접 인용)

| 우선 | 이름·세그먼트 | 페인 강도 | 핵심 인용 | UX에 미치는 영향 |
|----|------------|---------|---------|---------------|
| **1순위** | **한지원** — 32세 IT 개발자, 미혼, 서울. 위염 진단 | **8/10** | "의사가 천천히 드세요 했지만 실천 안 됨. 월 2–3회 위장약." | 12분 점심·영상 시청 우선 컨텍스트. 결과 언어 = "위 컨디션". CTA "위 컨디션 보러가기" |
| **2순위** | **박소연** — 29세 마케터, 1인 가구. 다이어트 정체기 | 7/10 | "정체기 원인을 *천천히 먹지 못함*으로 자가 진단 완료. 인앱 결제 익숙." | 결과 언어 = "체중 정체 탈출 가능성". V1엔 보조 카피만 (위 컨디션 우선). |
| **3순위 (V2)** | **김상훈** — 45세, 대사증후군 경계, 환경 제약 큼 | 6/10 | "자기 의지 약하지만 *전문가가 보고 있다*는 외부 책임이 동기" | V2 — B2B2C 외부 책임 모드. V1엔 코칭 메시지 톤 *권위형* 1개로만 시드. |

### 1.2 상황적 사용 컨텍스트 — *V1 카피·인터랙션의 진짜 제약*

| 컨텍스트 | 디테일 | UX 강제 사항 |
|--------|------|-----------|
| **점심 12분** | 회사 근처 식당 또는 자리에서 12분 안에 끝. 모든 인터랙션 < 5초 | 카드 1장에 메시지 1개. 셀프리포트 = 1탭 (이모지 5개) |
| **영상 시청 중** | 유튜브·트위치 풀스크린. AirPods 끼고 있음 | 식사 중 모달 알림 *금지*. 종료 후 푸시 1회만 |
| **한 손 사용** | 다른 손은 수저 / 폰 거치 | CTA를 thumb zone (화면 하단 ⅓) + 44pt 이상. swipe 제스처 회피 (탭 우선) |
| **다음 날 회상 어려움** | "어제 점심 어땠더라" 회상 부정확 | 셀프리포트 입력 = 식사 종료 직후 푸시 + 잠금화면 진입 1탭 |

**자기 투사 회피 (디스커버리 모순 5)**: 발의자 = 페르소나 인접 세그먼트. → V1 카피는 *반대 가설 사용자*도 거슬리지 않게 (50대·비IT 사용자 검증 시 "내 톤 아님" 거부 회피) — 이모지 1개 이내, 영어 잔존 0건, 한자어 과다 회피.

---

## 2. 사용자 여정 맵 (7일 코어 루프)

> **검증 가설**: 7일 후 1회 이상 자기보고 + 1회 이상 일반 식사 자동 검출 + 주간 회고 진입 = "이 앱이 내 식습관을 바꿀 수 있다" 인식. 이 3개 KPI를 위해 화면·메시지가 설계됨.

### 2.1 Day 0 — 첫 실행 → 캘리브레이션 식사

| 시점 | 트리거 | 화면·메시지 | 검증 가설 |
|----|------|----------|--------|
| 0초 | 앱 첫 실행 | `OnboardingWelcomeView` — "AirPods로 위 컨디션을 살펴보는 코치예요" + "1분이면 시작해요" | **5초 룰**: "AirPods + 위 건강" 두 단어로 무슨 앱인지 이해 |
| 30초 | Welcome → Next | `OnboardingPersonaView` — 3개 카드 (위 건강 / 다이어트 / 그냥 궁금) — 결과 카피 톤 가지치기 시드 | 페르소나 자기 식별 완료율 ≥ 80% |
| 60초 | 페르소나 선택 | `OnboardingHowItWorksView` — 3장 카드 (자동 검출·캘리브레이션 1식사·정직성 약속) | 다음 단계 진입율 ≥ 90% |
| 90초 | "AirPods 권한 켜기" | `OnboardingMotionPermissionView` — 거부 시 "괜찮아요. 직접 시작 버튼으로도 쓸 수 있어요" fallback | 모션 권한 수락율 ≥ 70% (Apple 평균 60% + 컨텍스트 카피로 +10pp 노림) |
| 120초 | 권한 결과 | `OnboardingCalibrationIntroView` — "이 한 끼만 평소처럼 드시면 다음부터는 자동이에요" | 캘리브레이션 식사 완료율 ≥ 60% (1주 누적) |

**Day 0 마무리 메시지**: "오늘 잘 오셨어요. 첫 식사가 끝나면 다시 만나요." → 푸시 권한 *요청 안 함* (첫 인사이트 후 §7 참고).

### 2.2 Day 1 — 첫 일반 식사 → 사후 카드

| 시점 | 트리거 | 화면·메시지 |
|----|------|----------|
| 식사 시작 (자동 또는 수동) | `MealSessionState = .inMeal` | `ActiveMealView` 진입 — 영상 시청 중이면 자동 dim 모드 |
| 식사 종료 검출 (90초 grace 후) | `Orchestrator.finalizeMeal()` | 푸시 안 함 (Day 1은 첫 인사이트 직후 알림 권한 요청) — 사용자가 다음에 앱 열 때 카드 노출 |
| 다음 앱 진입 | `DashboardView` 첫 진입 | `MealResultCard` — "오늘 점심 11분 — 캘리브레이션과 비슷한 페이스예요" + Comfort 셀프리포트 1탭 진입 |

**검증 가설**: Day 1 카드 진입 후 셀프리포트 1회 완료율 ≥ 30% / 다음날(Day 2) 재방문율 ≥ 50%.

### 2.3 Day 3 — 첫 위 컨디션 자기보고 매칭

| 시점 | 트리거 | 화면·메시지 |
|----|------|----------|
| 누적 식사 5회 + 셀프리포트 2회 | `InsightEngine.canMatchComfort = true` | `DashboardView` 상단 `InsightCard` — "최근 5분 미만 식사 후 위 컨디션이 평균 1.4점 낮아요. 패턴이 보이기 시작했어요" |

**검증 가설**: Day 3 InsightCard 진입 → 다음 식사에서 *수동 시작 트리거* 사용율 ≥ 20% (=스스로 의식 시작).

### 2.4 Day 7 — 첫 주간 회고 + Discovery 1개

| 시점 | 트리거 | 화면·메시지 |
|----|------|----------|
| Day 7 첫 진입 | `WeeklyDigestEngine.isReady = true` | `WeeklyRecapSheet` 자동 노출 (modal sheet) — "이번 주 평균 9분 → 12분으로 차분해졌어요. 가장 빠른 식사는 화요일 점심이었어요" + Discovery 카드 1개 |

**검증 가설**: Day 7 `WeeklyRecapSheet` 완료율 ≥ 40% / 8일차 retention ≥ 35%.

---

## 3. 화면 인벤토리 (V1)

V1 화면 11개 + 모달/시트 3개. 각 화면은 *목적 1개 / CTA 1–2개 / SwiftUI 표준 컴포넌트 우선* 원칙. Custom 컴포넌트는 `MealResultCard`, `ChewBreathBadge`, `ComfortSelfReportRow` 3개로 한정.

### 3.1 OnboardingWelcomeView

- **목적**: 5초 룰 통과 — "이게 무슨 앱인지" 답
- **진입**: 첫 실행 / 데이터 초기화 후
- **SwiftUI**: `NavigationStack` 루트 → `VStack` + `Image(systemName:)` + `Text` + `Button`
- **상태 변화**: idle (단일 상태)
- **컴포넌트**:
  - 상단 일러스트 — `Image(systemName: "airpodspro")` + 한 줄 모션 (페이드인 0.6s, prefers-reduced-motion 시 즉시)
  - 헤드라인 (Display, semibold)
  - 본문 (Body, regular)
  - Primary CTA `Button("시작하기")` — 화면 하단 thumb zone, full-width
- **텍스트 와이어**:
  ```
  [airpodspro icon, 80pt]

  AirPods로
  내 위 컨디션을
  살펴봐요

  의사가 "천천히 드세요"라고
  하셨다면, 1분이면 시작해요.

  ────────────────────────
  [          시작하기          ]
  ```

### 3.2 OnboardingPersonaView

- **목적**: 페르소나 자기 식별 → 톤 가지치기 시드 (V1엔 카피 1–2건만 가지치기, V2 확장)
- **진입**: Welcome → Next
- **SwiftUI**: `VStack` + `ForEach(personas) { Button(card) }` (3 카드 수직 스택)
- **상태**: `selected: Persona?` (none → one)
- **컴포넌트 — 페르소나 카드 (Custom `PersonaCard`)**:
  - SF Symbol 아이콘 + 제목 + 한 줄 부제
  - 선택 시 brand_primary 외곽선 + checkmark
- **카드 카피**:
  | 카드 | 제목 | 부제 |
  |---|---|---|
  | A | 위 건강 (위염·소화불량) | 더부룩함이 줄어드는 게 목표예요 |
  | B | 다이어트 정체기 | 천천히 드시면서 회복하고 싶어요 |
  | C | 그냥 궁금해서 | 내 식습관 패턴을 보고 싶어요 |
- **상태 변화**: empty → 1 selected → next 활성

### 3.3 OnboardingHowItWorksView

- **목적**: *어떻게 작동하는지* 정직 설명 + Vessyl/Healbe 함정 회피 신호
- **진입**: Persona → Next
- **SwiftUI**: `TabView(.page)` 3장 + 하단 `PageIndicator` + 우하단 `Button("다음")`
- **카드 와이어**:
  ```
  Card 1/3
  [airpods.gen3 icon]

  AirPods를 끼고 식사하시면
  자동으로 식사 시간을
  살짝 기록해요.

  Card 2/3
  [chart.bar.fill icon]

  처음 한 끼만 직접 시작 버튼을 누르시면
  다음부터는 자동이에요.

  Card 3/3
  [hand.raised.fill icon]

  100% 정확하지 않아요. (추정 ±15%)
  치료가 아니라 *행동 변화 코칭*이에요.
  ```
- **상태**: page 1/2/3 → 다음 활성 (page 3)
- **카피 가드레일**: card 3 = 정직성 카드 = §5.3 약속 금지 라인을 사용자에게 *먼저* 노출 → 신뢰 빌드

### 3.4 OnboardingMotionPermissionView

- **목적**: 모션 권한 컨텍스트 설명 + 거부 시 fallback
- **진입**: HowItWorks → Next
- **SwiftUI**: `VStack` + `Button("AirPods로 자동 인식 켜기", action: requestMotionPermission)` + `Button("나중에", style: .plain)`
- **상태 변화**:
  - `idle` → `requesting` → `granted` (다음 화면) / `denied` (fallback 메시지 + Next)
- **권한 요청 카피**:
  - 시스템 prompt 위 카피: "AirPods 모션 데이터로 식사 시간을 자동으로 살펴봐요. 데이터는 기기에서만 처리되고 7일 후 자동 삭제돼요."
  - Info.plist `NSMotionUsageDescription`: "AirPods 모션으로 식사 시작·끝을 자동으로 살펴봐요. 데이터는 기기 내에서만 처리됩니다."
- **거부 fallback**: "괜찮아요. 식사할 때 *시작* 버튼을 직접 누르셔도 똑같이 작동해요." → Next 자동 활성

### 3.5 OnboardingCalibrationIntroView

- **목적**: 첫 캘리브레이션 식사 마찰 ↓
- **진입**: Permission → Next
- **SwiftUI**: `VStack` + `Image` + `Text` + `Button("이번 끼니에 시작할게요")` + `Button("나중에")`
- **상태 변화**: idle → start → `ActiveMealView (calibrating)`
- **카피**:
  ```
  [bowl.fill icon, brand_accent]

  이 한 끼만 함께해요

  평소처럼 드시면 됩니다.
  AirPods가 옆에서 한 번만
  당신의 페이스를 익혀요.

  ─────────────────────
  [    이번 끼니에 시작할게요    ]
  [        나중에 할게요        ]
  ```

### 3.6 ActiveMealView (식사 중 화면)

- **목적**: 진행 시간 가시화 + 종료 트리거 + *영상 시청 중 거슬리지 않게*
- **진입**: 캘리브레이션 시작 / 수동 시작 / 자동 식사 검출 (시작 알림 탭 시)
- **SwiftUI**: `ZStack` (배경 dim 가능) + `VStack(.center)` (`Text(timer)` + `ChewBreathBadge` + `Button(end)`)
- **상태 변화**:
  | 상태 | 트리거 | 화면 |
  |---|---|---|
  | `idle` | 진입 | "준비됐어요. 한 입 드셔보세요." (캘리브레이션만) |
  | `active` | 첫 chew event | 큰 타이머 + breath 애니메이션 (4초 사이클) |
  | `paused` | AirPods 분리 콜백 | "AirPods가 잠시 끊겼어요. 다시 끼시면 이어 가요." |
  | `ending` | grace 90초 시작 | "혹시 식사 끝나셨어요?" + [계속] [종료] |
- **컴포넌트**:
  - 큰 타이머 — 화면 상단 ⅓, Display 56pt mono, mm:ss
  - `ChewBreathBadge` (Custom) — 호흡 애니메이션 원 + "차분히 드시고 있어요" 부속 텍스트
  - "추정 약 {n}회 씹으셨어요" — Caption, 부속 정보로 작게 (정확도 컨텍스트 §5)
  - Bottom CTA `Button("식사 끝났어요")` — full-width, brand_accent, thumb zone
- **영상 시청 모드** (audio session active 검출):
  - 화면 자동 dim (밝기 60%)
  - 타이머 + breath만 노출, 나머지 hide
  - 햅틱 *비활성* (§4 참고)
- **텍스트 와이어**:
  ```
  ┌──────────────────────────┐
  │                          │
  │         07:42            │
  │                          │
  │       ◯ ◯ ◯              │
  │   차분히 드시고 있어요      │
  │                          │
  │  추정 약 84회 씹으셨어요     │
  │                          │
  │                          │
  │   [   식사 끝났어요    ]    │
  └──────────────────────────┘
  ```
- **`paused` 상태 와이어**:
  ```
  ┌──────────────────────────┐
  │                          │
  │        잠시 멈춤           │
  │       AirPods가          │
  │      잠깐 끊겼어요          │
  │                          │
  │   다시 끼시면 이어 가요     │
  │                          │
  │   [    수동으로 종료     ]   │
  └──────────────────────────┘
  ```

### 3.7 DashboardView (홈/탭바 1)

- **목적**: 오늘·이번 주 한눈에 + 코칭 메시지 1줄 + Comfort 셀프리포트 1탭 진입
- **진입**: 앱 진입 / 탭바 1 / 식사 종료 후 자동 (push tap)
- **SwiftUI**: `NavigationStack` + `ScrollView` + `LazyVStack`
- **컴포넌트 (위→아래)**:
  1. **`TodayHeaderCard`** — 오늘 식사 N회·평균 X분·코칭 메시지 1줄 (CoachingMessageEngine 인용)
  2. **`MealResultCard`** (Custom) — 직전 식사 결과 (조건부 노출, §6.1)
  3. **`ComfortSelfReportRow`** (Custom) — 1–5 이모지 선택 1탭
  4. **`MealTrendChartCard`** (Swift Charts) — 7일 식사 시간 추이 (§6.2)
  5. **`InsightCard`** — Discoveries V1.5 (Day 3+ 노출 조건, §6.3)
  6. **`WeeklyRecapEntryButton`** — Day 7+ 노출 (§6.4)
- **상태 변화**:
  | 상태 | 조건 | 카피 |
  |---|---|---|
  | empty (Day 0) | 식사 0회 | "첫 식사를 함께해 주세요. 시작 버튼은 우하단에 있어요." + 일러스트 |
  | calibrating done (Day 1 직전) | 식사 1회 | "캘리브레이션 완료! 다음 식사부터 자동으로 살펴봐요." |
  | normal (Day 2+) | 식사 ≥ 2회 | TodayHeader + 정상 카드 스택 |
  | error | data load fail | "잠시 정보를 불러오지 못했어요. 다시 시도" + retry |
- **Floating Action**: 우하단 fab `Button(image: "play.fill", "식사 시작")` — 수동 트리거
- **텍스트 와이어 (normal)**:
  ```
  ┌─────────────────────────────┐
  │  오늘 12:30                  │
  │  ─────────────────           │
  │  점심 1회·평균 11분            │
  │  어제보다 3분 차분해졌어요      │
  ├─────────────────────────────┤
  │  ▌오늘 점심 결과              │
  │   11분 32초                   │
  │   캘리브레이션 +2분             │
  │   [위 컨디션 알려주기]          │
  ├─────────────────────────────┤
  │  ▌이번 주 식사 시간            │
  │   [Swift Charts 7일 막대]     │
  │   평균 10분 12초               │
  ├─────────────────────────────┤
  │  ▌처음 보이는 패턴 (3일째)     │
  │   화요일 점심이 평소보다       │
  │   30% 빨라요. 회의 후라        │
  │   그럴까요?                   │
  └─────────────────────────────┘
                          [▶ 식사 시작]
  ```

### 3.8 MealHistoryView (탭바 2)

- **목적**: 누적 식사 세션 리스트 + 상세 진입
- **진입**: 탭바 2 / TodayHeaderCard 탭
- **SwiftUI**: `NavigationStack` + `List` + section per day + `NavigationLink`
- **상태 변화**: empty / loaded / error
- **컴포넌트**:
  - List row — 시각·시간(mm:ss)·CPM·comfort 이모지
  - Section header — Date (오늘·어제·요일)
- **텍스트 와이어**:
  ```
  ┌──────────────────────────┐
  │  ◀  식사 기록             │
  ├──────────────────────────┤
  │  오늘                      │
  │  12:30  점심  11:32  ⓘ   │
  │  08:14  아침  07:48  ⓘ   │
  │  어제                      │
  │  19:42  저녁  09:12  ⓘ   │
  │  ...                      │
  └──────────────────────────┘
  ```
- **빈 상태**: "아직 기록이 없어요. 첫 식사를 함께해 주세요."

### 3.9 MealDetailView

- **목적**: 단일 식사 깊이 보기
- **진입**: MealHistoryView row 탭 / MealResultCard "자세히" 탭
- **SwiftUI**: `ScrollView` + `VStack` (`MealTimelineChart` + `Text(coachingMessage)` + `ComfortSelfReportRow`)
- **컴포넌트**:
  - 상단 헤더 — 시각·시간·CPM
  - `MealTimelineChart` (Swift Charts) — 분당 chew 빈도 라인 차트
  - 코칭 메시지 카드 1개 (`InsightCardCompact`)
  - Comfort 셀프리포트 (해당 식사용)

### 3.10 WeeklyRecapView (시트, Day 7+)

- **목적**: 주간 회고 + Discovery 1개 + 다음 주 가벼운 약속
- **진입**: Day 7 첫 진입 자동 (modal sheet) / DashboardView "이번 주 회고" 버튼
- **SwiftUI**: `Sheet` (`.large` detent) + `ScrollView` + `VStack`
- **컴포넌트**:
  1. 헤더 — "이번 주 회고" + 기간 (5/2 ~ 5/8)
  2. 주간 평균 카드 — "평균 10분 12초 / 지난 주 대비 +1분 24초"
  3. 7일 막대 차트 (Swift Charts)
  4. Discovery 카드 1개 — "월요일 점심이 가장 빨라요"
  5. 다음 주 약속 — Toggle "다음 주에도 함께할게요"
- **상태**: loading / loaded / no_data (식사 < 3회 시 "아직 회고할 데이터가 부족해요")

### 3.11 SettingsView (탭바 3)

- **목적**: 권한·알림·데이터·정보 관리
- **진입**: 탭바 3
- **SwiftUI**: `NavigationStack` + `List` (grouped) + `Form`
- **섹션**:
  | 섹션 | 항목 | 액션 |
  |---|---|---|
  | 디바이스 | AirPods 호환성 / 연결 상태 | 자동 |
  | 권한 | 모션 / 알림 | 시스템 설정 딥링크 |
  | 알림 | 식사 종료 후 / 일일 인사이트 / 주간 회고 | toggle (§4·§7) |
  | 데이터 | 식사 기록 내보내기 (CSV) / 모두 삭제 | sheet / 확인 alert |
  | 정보 | 앱 정보 / 정직성 약속 (§5.3 카피 노출) / 라이선스 | NavigationLink |
- **"정직성 약속" 화면** — Vessyl/Healbe 함정 회피 카피를 사용자에게 *공개*:
  > 우리는 약속해요:
  > - 식사 시간을 추정으로 보여드려요 (정확도 ±15%)
  > - 패턴 인사이트를 제공해요
  > - 행동 변화를 도와드려요
  >
  > 우리는 약속하지 않아요:
  > - 위염 치료 / 의료적 효과
  > - 칼로리·음식 종류 자동 인식
  > - 100% 정확한 측정

### 3.12 모달·시트 3개

| 이름 | 트리거 | 목적 | SwiftUI |
|----|------|------|---------|
| `ComfortDetailSheet` | ComfortSelfReportRow 탭 | 1–5 슬라이더 + 자유텍스트(옵션) | `.sheet(.medium)` + `Slider` + `TextField` |
| `MealStartConfirmationSheet` | FAB "식사 시작" | 수동 시작 확인 + AirPods 연결 체크 | `.sheet(.fraction(0.4))` |
| `NotificationPermissionPromptSheet` | 첫 인사이트 직후 (§7) | 알림 권한 요청 컨텍스트 | `.sheet(.medium)` |

---

## 4. 실시간 피드백 사양

### 4.1 핵심 원칙 — 신호 엔지니어 권고 직접 인용

`01_signal_processing.md` §3.1 latency `≤ 10초` + §7.1 *"실시간 햅틱은 비권장 — 10초 latency는 햅틱엔 늦음. 사후 리포트가 더 정직"*. 이 권고를 V1 UX는 **그대로** 따른다 — *식사 중 햅틱·진동·소리 알림 = 0건*. 사후 리포트가 주, 식사 중 시각 피드백은 *호흡 애니메이션 1개*만.

> **약속 금지 (§5.3 인용)**: "씹을 때마다 진동" / "빨리 먹으면 알림" — V1 약속 안 함. V2에서 신호 latency가 < 3초로 검증되면 재검토.

### 4.2 실시간 피드백 매트릭스

| 컨텍스트 | 신호 | 강도 | 사용자 통제 | 영상 시청 모드 |
|--------|------|------|----------|------------|
| 식사 중 (foreground) | `ChewBreathBadge` 호흡 애니메이션 | 매우 약함 (시각만) | 항상 ON | 화면 dim, breath 유지 |
| 식사 중 5분 경과 | toast 1회 ("페이스 좋아요") | 약함 (시각만, 햅틱 X) | off / 약 / 표준 | toast 생략 |
| 식사 종료 검출 (Orchestrator emit) | local notification 1회 + Lock screen | 표준 | off / 약 / 표준 | 즉시 노출 (영상 끝나면 봄) |
| 일일 인사이트 생성 (다음날 아침) | local notification 1회, 사용자 지정 시간 | 약함 | off / 약 | 영향 없음 (식사 중 아님) |
| 주간 회고 (Day 7+ 매주) | local notification 1회, 일요일 21:00 | 약함 | off / 약 | 영향 없음 |
| AirPods 분리 (식사 중) | toast "잠시 끊겼어요" | 매우 약함 | 항상 ON | toast 노출 |

**알림 빈도 천장 (영상 시청 컨텍스트 회피 휴리스틱)**:
- 식사 *중* 알림 < 1회/식사 (toast 1회)
- 식사 *후* 알림 ≤ 2회/식사 (종료 + 다음날 인사이트)
- 일일 총 알림 ≤ 5회

### 4.3 영상 시청 컨텍스트 검출 휴리스틱

신호 엔지니어 §2.5 + 시스템 API 활용:
- `AVAudioSession.sharedInstance().isOtherAudioPlaying == true` AND
- 식사 윈도우 active

→ 검출 시 `ActiveMealView.videoMode = true`:
- 화면 dim 60%
- toast 비활성
- 햅틱 비활성 (V1엔 햅틱 자체 없음, 안전망)

### 4.4 사용자 통제 (Settings)

| 설정 | 기본값 | 옵션 |
|----|------|----|
| 식사 중 페이스 toast | 약 | off / 약 / 표준 |
| 식사 종료 알림 | 표준 | off / 약 / 표준 |
| 일일 인사이트 시간 | 09:30 | 시간 선택 / off |
| 주간 회고 알림 | 일요일 21:00 | 요일·시간 선택 / off |
| 햅틱 (V1 비활성) | — | (V2 추가 예정 안내) |

---

## 5. 대시보드 시각화 명세

### 5.1 위 컨디션 점수 카드 (`ComfortScoreCard`)

> ⚠️ V1엔 *수치 점수가 아닌 추세 카피*로 노출. 점수는 V1.5+에서 GERDQ 척도 통합 시 정식. (디스커버리 §5.1 MVP #3)

- **컴포넌트 위치**: DashboardView 상단 (TodayHeaderCard 안 inline 또는 ComfortDetailSheet 내부)
- **데이터**:
  - 입력: `ComfortReport(mealId, score 1-5)` 누적
  - 계산: 직전 7일 ComfortReport 평균
- **표시**:
  - 메인: 5단계 이모지 추세 (😞 → 😊)
  - 서브: "최근 7일 평균 컨디션이 살짝 좋아졌어요" (변화 ≥ 0.3 시) / "비슷한 컨디션을 유지하고 계세요" (변화 < 0.3 시)
- **카피 가드레일**: *숫자 노출 안 함* (V1) — Vessyl 함정 회피 (정확도 약속 위험)
- **VoiceOver**: "최근 7일 위 컨디션 평균 4점 만점, 어제 대비 0.4점 좋아졌어요"

### 5.2 식사 시간 추이 차트 (`MealTrendChartCard`)

- **컴포넌트**: Swift Charts `BarMark` (식사별) + `RuleMark` (목표선) + `AnnotationMark` (오늘)
- **데이터**:
  ```swift
  struct MealDataPoint {
      let date: Date
      let durationSec: Int
      let comfort: Int?
  }
  ```
- **시각**:
  - X축: 7일 (요일 라벨)
  - Y축: 시간 (분, 0~20)
  - 막대 색: brand_primary (식사 < 5분 시 warning 색으로 강조)
  - 목표선 (RuleMark, dash): 11분
  - 오늘 막대 위 annotation "오늘 11분"
- **인터랙션**: 막대 탭 시 해당 식사 상세 (`MealDetailView`) 진입
- **빈 상태**: "이번 주 첫 식사를 함께해 주세요" + 점선 placeholder
- **VoiceOver**: 각 막대를 "월요일 9분 30초, 위 컨디션 좋음" 형태로 라벨
- **prefers-reduced-motion**: 그래프 그려지는 애니메이션 0.4s → 0s (즉시)

### 5.3 Discoveries 카드 (`InsightCard`)

옵션 G MVP #5 + V1.5 Discoveries 모듈 (옵션 F 흡수). V1엔 단순 패턴 1개부터.

- **노출 조건**:
  - V1: 누적 식사 ≥ 5회 + Comfort 보고 ≥ 2회
  - V1.5: + 시청 콘텐츠 메타 (Now Playing) 결합
- **계산 로직** (V1):
  ```
  pattern_engine.detect():
      - 요일별 평균 식사 시간 가장 빠른 요일
      - 시간대별 평균 (점심 vs 저녁) 차이 ≥ 2분
      - 5분 미만 식사 직후 Comfort 평균 vs 전체 평균 차이 ≥ 0.8점
      → 가장 강한 신호 1개 선택
  ```
- **카피 템플릿**: §8 코칭 라이브러리 `insight_*` 카테고리
- **시각**:
  - 카드 외곽 — brand_accent 옅은 배경
  - 헤더 — "처음 보이는 패턴" + 정보 아이콘
  - 본문 — 1–2문장
  - 하단 — "더 알아보기" disclosure (탭 시 어떻게 계산했는지 정직 공개)

### 5.4 Today Header 카드 (`TodayHeaderCard`)

- **데이터**: 오늘 식사 수 + 평균 시간 + 코칭 메시지 1줄
- **상태 변화**:
  | 상태 | 카피 예 |
  |---|---|
  | 식사 0회 | "오늘 첫 식사를 함께해 주세요." |
  | 식사 1회 | "오늘 점심 11분, 캘리브레이션과 비슷한 페이스예요." |
  | 식사 2+회 | "오늘 평균 10분 30초, 어제보다 1분 차분해졌어요." |
  | 데이터 없음 (Day 0) | "AirPods가 옆에서 함께 식사하면 자동으로 보여드려요." |

### 5.5 Comfort Self-Report Row (`ComfortSelfReportRow`)

- **컴포넌트**: 인라인 row, DashboardView·MealDetailView·MealResultCard 안에 임베드
- **상태**: not_yet / reporting / submitted
- **시각**:
  ```
  지금 위 컨디션 어떠세요?
  😞   🙁   😐   🙂   😊
  ```
- **인터랙션**: 이모지 탭 → 즉시 저장 + "기록했어요. 고마워요" 1초 toast
- **자유텍스트 (옵션)**: "한 줄 메모 (선택)" — TextField, 30자 제한
- **44pt 이상 hit area**: 이모지 간 간격 16pt + 각 이모지 44×44pt

### 5.6 주간 회고 화면 (`WeeklyRecapView`)

§3.10 화면 인벤토리 참고. 시각 명세:
- Hero — "이번 주 한 줄 평" (코칭 메시지 `weekly_*` 카테고리)
- 주간 평균 vs 지난 주 — 비교 막대 (Swift Charts)
- 7일 막대 추이 (요일별)
- Discovery 1개
- "다음 주 가벼운 약속" — toggle 1개, "다음 주에도 함께할게요"

---

## 6. 추가 화면 디테일 — `MealResultCard` (식사 종료 직후)

`DashboardView`에서 노출되는 핵심 카드 — 식사 종료 후 *5초 안에 오늘 결과*가 무엇인지 답.

### 6.1 노출 조건

- 직전 24시간 내 종료 세션 1개 이상 AND
- 해당 세션이 *대시보드에서 아직 한 번도 노출 안 됨*

### 6.2 컴포넌트

```
┌─────────────────────────────┐
│  오늘 점심 결과              │
│  ─────────────────────────   │
│        11분 32초              │
│                              │
│   캘리브레이션 +2분           │
│   "차분해진 페이스예요"        │
│                              │
│   ─────────────────────      │
│   지금 위 컨디션 어떠세요?     │
│   😞  🙁  😐  🙂  😊          │
│                              │
│   [    자세히 보기     ]      │
└─────────────────────────────┘
```

### 6.3 데이터 매핑

| UI 요소 | 데이터 소스 | 카피 변형 |
|------|---------|--------|
| 헤드 시각 | meal.startTime | "오늘 점심" / "오늘 저녁" / "어제 야식" |
| 큰 시간 | meal.durationSec | mm분 ss초 |
| 비교 | calibrationDuration vs meal.durationSec | "+2분" / "-3분" / "비슷한 페이스" |
| 코칭 메시지 1줄 | CoachingMessageEngine.pick(category: .meal_complete) | §8 라이브러리 |
| Comfort row | new (ComfortSelfReportRow) | — |

### 6.4 5초 룰 검증

- 진입 후 1초: "오늘 점심 결과" 헤드 인지
- 3초: 시간 + 비교 정보 인지
- 5초: 코칭 메시지 + Comfort 진입 가능 인지

---

## 7. 온보딩 시퀀스 + 권한 요청 시점

### 7.1 시퀀스 (5단계)

| Step | 화면 | 핵심 결정 |
|---|---|---|
| 1 | OnboardingWelcomeView | 5초 룰 통과 |
| 2 | OnboardingPersonaView | 페르소나 자기 식별 |
| 3 | OnboardingHowItWorksView | 정직성 카드 (§3.3 카드 3) |
| 4 | OnboardingMotionPermissionView | **모션 권한 요청** ← 첫 식사 시도 *직전* |
| 5 | OnboardingCalibrationIntroView | 캘리브레이션 시작 트리거 |

### 7.2 권한 요청 시점 (일괄 요청 *금지*)

| 권한 | 요청 시점 | 카피 |
|----|---------|------|
| Motion (`NSMotionUsageDescription`) | 온보딩 step 4 — 첫 식사 직전 | "AirPods 모션으로 식사 시간을 자동으로 살펴봐요. 데이터는 기기 내에서만 처리되고 7일 후 자동 삭제돼요." |
| Notifications (`UNAuthorizationStatus`) | **첫 인사이트 카드 노출 직후** (Day 1 또는 Day 2 — DashboardView에 카드 진입 시 sheet) | "다음 식사 결과를 살짝 알려드릴까요? 하루 1번 정도예요." |
| Live Activity / Dynamic Island (옵션) | Day 3+ 사용자가 *수동 시작* 트리거 사용 시 | "식사 중에 실시간으로 시간을 보고 싶으시면 켜둘게요." |
| Background Refresh | 시스템 자동 (요청 안 함) — Settings 안내만 | — |

### 7.3 거부 시 fallback

| 권한 | 거부 시 |
|----|--------|
| Motion | 자동 검출 비활성. *수동 시작* 트리거만으로 V1 정상 작동. Settings에서 재요청 가능 안내. |
| Notifications | in-app 카드만 노출. 푸시 없음. 사용자 자발적 진입에 의존. |
| Live Activity | 식사 중 화면 표준 모드만 사용. |

---

## 8. 코칭 메시지 라이브러리 (32개)

> **다노식 친근 + 임상 권위 균형 톤**. 의료적 약속 0건. 변수 자리(`{{variable}}`) 명시. 구현자가 그대로 Swift enum/struct로 변환.

### 8.1 카테고리 분포

| 카테고리 | 개수 | 트리거 컨텍스트 |
|---------|----|------------|
| `encouragement` (격려) | 10 | 일반 식사 직후 / 추세 양호 |
| `insight` (인사이트·패턴) | 10 | 누적 데이터 기반 패턴 발견 |
| `awareness` (자기인식 트리거) | 5 | 식사 중 / 빠른 식사 직후 |
| `celebration` (축하) | 5 | 주간 마일스톤 / 연속 달성 |
| `weekly` (주간 회고) | 2 | Day 7+ |
| **합계** | **32** | — |

### 8.2 YAML 라이브러리 (Swift `enum` + `struct` 변환 가능 형태)

> **구현자 변환 노트**: 각 메시지를 Swift `struct CoachingMessage { let id: String; let category: Category; let trigger: TriggerCondition; let template: String; let variables: [Variable]; let tone: Tone }` 로 매핑. `template` 안의 `{{var}}`는 String interpolation으로 치환. `tone` enum은 (encouraging, gentle, curious, celebratory, authoritative_gentle) 5종.

```yaml
# ────────────────────────────────────────
# Category: encouragement (격려) — 10개
# ────────────────────────────────────────

- id: enc_slowed_down_d2d
  category: encouragement
  trigger: avg_duration_today > avg_duration_yesterday + 60
  template: "어제보다 {{deltaSec}}초 차분해졌어요. 잘하고 계세요."
  variables:
    - { name: deltaSec, type: Int, unit: 초 }
  tone: encouraging

- id: enc_steady_pace
  category: encouragement
  trigger: |
    today_meals.count >= 1 AND
    abs(today_avg - calibration_duration) <= 60
  template: "캘리브레이션과 비슷한 페이스예요. 안정적이세요."
  variables: []
  tone: gentle

- id: enc_first_long_meal
  category: encouragement
  trigger: meal_duration_sec >= 600 AND today_meals.count == 1
  template: "오늘 첫 식사를 {{minutes}}분에 드셨어요. 좋은 시작이에요."
  variables:
    - { name: minutes, type: Int }
  tone: encouraging

- id: enc_after_quick_meal
  category: encouragement
  trigger: meal_duration_sec < 300
  template: "이번엔 짧았네요. 다음 식사를 1분만 더 가볼까요?"
  variables: []
  tone: gentle

- id: enc_consistency_3day
  category: encouragement
  trigger: consecutive_days_avg_above_8min >= 3
  template: "3일 연속 8분 넘게 드셨어요. 꾸준함이 보여요."
  variables: []
  tone: encouraging

- id: enc_after_calibration
  category: encouragement
  trigger: state == .calibration_just_completed
  template: "캘리브레이션 완료! 다음 식사부터 자동으로 살펴봐요."
  variables: []
  tone: gentle

- id: enc_video_mode_steady
  category: encouragement
  trigger: meal_in_video_mode AND meal_duration_sec >= 600
  template: "영상 보시면서도 차분하게 드셨어요."
  variables: []
  tone: encouraging

- id: enc_breakfast_logged
  category: encouragement
  trigger: meal_time == .breakfast
  template: "아침을 챙기셨네요. 위장이 천천히 깨어나요."
  variables: []
  tone: gentle

- id: enc_recovery_after_quick
  category: encouragement
  trigger: |
    last_meal_duration < 300 AND
    current_meal_duration > 600
  template: "직전 식사보다 {{deltaMin}}분 더 천천히 드셨어요. 회복하셨네요."
  variables:
    - { name: deltaMin, type: Int }
  tone: encouraging

- id: enc_weekend_calm
  category: encouragement
  trigger: |
    is_weekend AND
    today_avg_duration > weekday_avg_duration + 120
  template: "주말이라 그런가, 평일보다 차분히 드시고 계세요."
  variables: []
  tone: gentle

# ────────────────────────────────────────
# Category: insight (인사이트·패턴) — 10개
# ────────────────────────────────────────

- id: insight_fastest_weekday
  category: insight
  trigger: pattern_engine.found(.fastest_weekday)
  template: "{{weekday}} 점심이 평소보다 {{percent}}% 빨라요. 회의 후라 그럴까요?"
  variables:
    - { name: weekday, type: String, example: "화요일" }
    - { name: percent, type: Int, range: "20~50" }
  tone: curious

- id: insight_lunch_vs_dinner
  category: insight
  trigger: pattern_engine.found(.meal_time_diff)
  template: "저녁이 점심보다 평균 {{deltaMin}}분 더 천천히세요. 환경 차이가 있는 것 같아요."
  variables:
    - { name: deltaMin, type: Int }
  tone: curious

- id: insight_quick_meal_to_comfort
  category: insight
  trigger: |
    pattern_engine.found(.quick_meal_low_comfort) AND
    comfort_diff >= 0.8
  template: "5분 미만으로 드신 다음 위 컨디션이 평균 {{comfortDelta}}점 낮아요. 패턴이 보이기 시작했어요."
  variables:
    - { name: comfortDelta, type: Double, format: "1자리" }
  tone: authoritative_gentle

- id: insight_video_mode_pattern
  category: insight
  trigger: pattern_engine.found(.video_mode_faster)
  template: "영상 보시면서 드실 때 평균 {{deltaMin}}분 더 빠르세요. 한 입씩 의식해 보실래요?"
  variables:
    - { name: deltaMin, type: Int }
  tone: curious

- id: insight_morning_shorter
  category: insight
  trigger: pattern_engine.found(.morning_meals_shorter)
  template: "아침 식사가 다른 시간대보다 평균 {{deltaMin}}분 짧으세요. 시간이 부족하셨나 봐요."
  variables:
    - { name: deltaMin, type: Int }
  tone: gentle

- id: insight_consistency_pattern
  category: insight
  trigger: pattern_engine.found(.weekly_consistency)
  template: "이번 주 식사 시간 편차가 줄어들었어요. 패턴이 안정적으로 자리 잡고 있어요."
  variables: []
  tone: encouraging

- id: insight_evening_late_quick
  category: insight
  trigger: pattern_engine.found(.late_dinner_quick)
  template: "21시 이후 저녁이 평소보다 {{percent}}% 빠르세요. 야식은 천천히가 위에 좋아요."
  variables:
    - { name: percent, type: Int }
  tone: authoritative_gentle

- id: insight_cpm_trend
  category: insight
  trigger: |
    week.avg_cpm < last_week.avg_cpm AND
    delta_cpm >= 5
  template: "이번 주 씹는 페이스가 분당 {{deltaCPM}}회 차분해졌어요."
  variables:
    - { name: deltaCPM, type: Int }
  tone: encouraging

- id: insight_first_pattern_emerging
  category: insight
  trigger: |
    meals.count >= 5 AND
    comforts.count >= 2 AND
    no_pattern_found_yet
  template: "데이터가 모이고 있어요. 일주일 정도 함께하면 처음 패턴이 보여요."
  variables: []
  tone: gentle

- id: insight_calibration_drift
  category: insight
  trigger: |
    days_since_calibration >= 14 AND
    avg_drift_from_calibration >= 90
  template: "처음과 비교해 평균 {{deltaSec}}초 변화가 있어요. 새 캘리브레이션을 시도해 보실래요?"
  variables:
    - { name: deltaSec, type: Int }
  tone: gentle

# ────────────────────────────────────────
# Category: awareness (자기인식 트리거) — 5개
# ────────────────────────────────────────

- id: aware_during_meal_5min
  category: awareness
  trigger: meal_active AND elapsed_sec == 300
  template: "지금 5분 지났어요. 한 입 더 천천히 음미해 보세요."
  variables: []
  tone: gentle

- id: aware_after_quick_meal
  category: awareness
  trigger: meal_just_ended AND meal_duration_sec < 300
  template: "오늘은 {{minutes}}분 만에 드셨어요. 위가 따라잡을 시간이 부족했을 수 있어요."
  variables:
    - { name: minutes, type: Int }
  tone: gentle

- id: aware_video_context
  category: awareness
  trigger: |
    meal_just_ended AND
    audio_session_was_active AND
    meal_duration_sec < calibration_duration - 120
  template: "영상 보시면서 드실 때 평소보다 빠르세요. 한 손은 영상, 한 손은 천천히."
  variables: []
  tone: curious

- id: aware_streak_break
  category: awareness
  trigger: |
    yesterday_avg >= 8 AND
    today_avg < 5 AND
    today_meals.count >= 1
  template: "어제까진 8분 넘게 드셨는데 오늘은 짧으셨네요. 바쁜 하루였나요?"
  variables: []
  tone: gentle

- id: aware_no_comfort_reported
  category: awareness
  trigger: |
    days_since_last_comfort >= 3 AND
    meals_since_last_comfort >= 5
  template: "최근 며칠간 위 컨디션이 어떠셨어요? 한 번만 알려주시면 패턴이 더 잘 보여요."
  variables: []
  tone: gentle

# ────────────────────────────────────────
# Category: celebration (축하) — 5개
# ────────────────────────────────────────

- id: celeb_7day_streak
  category: celebration
  trigger: consecutive_days_avg_above_8min == 7
  template: "7일 연속 8분 넘게 드셨어요. 큰 변화가 시작되고 있어요."
  variables: []
  tone: celebratory

- id: celeb_weekly_improvement
  category: celebration
  trigger: |
    week.avg_duration > last_week.avg_duration + 90
  template: "이번 주 평균 {{deltaMin}}분 더 차분해졌어요. 지난 주보다 {{percent}}% 개선했어요."
  variables:
    - { name: deltaMin, type: Int }
    - { name: percent, type: Int }
  tone: celebratory

- id: celeb_first_long_meal_in_week
  category: celebration
  trigger: |
    meal_duration_sec >= 900 AND
    week.has_no_meal_above_900
  template: "이번 주 처음으로 15분 넘게 드셨어요. 페이스 잘 잡으셨네요."
  variables: []
  tone: celebratory

- id: celeb_comfort_improved
  category: celebration
  trigger: |
    week.avg_comfort > last_week.avg_comfort + 0.5
  template: "이번 주 위 컨디션 평균이 살짝 좋아졌어요. 천천히 드신 효과가 보여요."
  variables: []
  tone: celebratory

- id: celeb_30day_journey
  category: celebration
  trigger: days_since_first_meal == 30
  template: "함께한 지 30일이에요. 처음과 비교해 평균 {{deltaMin}}분 차분해졌어요."
  variables:
    - { name: deltaMin, type: Int }
  tone: celebratory

# ────────────────────────────────────────
# Category: weekly (주간 회고) — 2개
# ────────────────────────────────────────

- id: weekly_recap_improved
  category: weekly
  trigger: weekly_recap AND week.avg > last_week.avg
  template: "이번 주는 평균 {{thisWeek}}분 — 지난 주보다 {{deltaMin}}분 차분해졌어요. 가장 빠른 식사는 {{fastestDay}}이었어요."
  variables:
    - { name: thisWeek, type: String, example: "10분 12초" }
    - { name: deltaMin, type: Int }
    - { name: fastestDay, type: String, example: "월요일 점심" }
  tone: celebratory

- id: weekly_recap_steady
  category: weekly
  trigger: weekly_recap AND abs(week.avg - last_week.avg) < 60
  template: "이번 주는 평균 {{thisWeek}}분 — 지난 주와 비슷한 페이스를 유지하셨어요. 꾸준함이 진짜 변화를 만들어요."
  variables:
    - { name: thisWeek, type: String }
  tone: gentle
```

### 8.3 금지 표현 라이브러리 (구현자 lint 규칙)

| 금지 | 이유 | 대체 |
|----|----|----|
| "치료" / "회복 보장" / "완치" | 의료 약속 (§5.3) | "행동 변화 도와요" / "패턴이 보여요" |
| "100% 정확" / "정확하게 측정" | Vessyl 함정 | "추정으로 살펴봐요 (±15%)" |
| "체중 ?kg 빠짐" / "다이어트 보장" | Healbe 함정 | "회복하시는 중이에요" |
| "왜 또" / "안 좋아요" / "실패" | 비난 톤 | "오늘은 짧으셨네요" / "다음 식사를" |
| "track" / "data" / "stats" / "monitor" | 영어 잔존 | "살펴봐요" / "기록" / "패턴" |
| "씹기 횟수 N회" (전면 노출) | 도구 프레이밍 | "차분히 드셨어요" / "추정 약 84회" (부속) |
| "위염 환자" / "환자" 호칭 | 의료 라벨 | (호칭 없이) |

### 8.4 변수 치환 안전 가드 (구현자 메모)

- 모든 변수는 `nil` 시 *문장 자체를 폐기*하고 fallback 메시지로 (예: `enc_slowed_down_d2d` 폐기 시 → `enc_steady_pace`)
- 숫자 0 / 음수는 카테고리 매칭 실패로 처리 (negative drift = "차분해진" 메시지 트리거 안 함)
- 한국어 조사 (이/가, 을/를, 은/는) 변수 뒤 자동 처리 — 구현자가 `ko_particle()` helper 마련 권장

---

## 9. 디자인 토큰

### 9.1 색

```yaml
colors:
  # Brand
  brand_primary: "#5B7CFF"      # 차분한 파랑 — 위 건강 톤, 의료 신뢰감
  brand_accent:  "#FFB54A"      # 따뜻한 주황 — 식사·CTA 액센트, 다노식 친근

  # System (Apple)
  text_primary:        Color.label             # adaptive
  text_secondary:      Color.secondaryLabel
  text_tertiary:       Color.tertiaryLabel
  background_primary:  Color.systemBackground
  background_grouped:  Color.systemGroupedBackground
  separator:           Color.separator

  # Semantic
  positive:  "#34C759"  # Apple system green
  warning:   "#FF9500"  # Apple system orange (5분 미만 식사 강조)
  critical:  "#FF3B30"  # Apple system red (V1엔 사용 거의 X)

  # Chart palette (Swift Charts)
  chart_primary:    brand_primary
  chart_secondary:  brand_accent
  chart_neutral:    Color.tertiaryLabel    # 비교선
```

**원칙**:
- Apple 시스템 색 우선 (다크모드·접근성 자동)
- 브랜드 색은 차트·CTA·강조 영역에만 절제 사용 (페이지의 < 20% 면적)
- warning은 "5분 미만 식사" 강조 1곳만

### 9.2 타이포그래피

```yaml
typography:
  # SF Pro (영문) + 시스템 한국어 fallback (Pretendard if installed)
  display:    .largeTitle  (34pt, bold)        # OnboardingWelcomeView 헤드라인
  title1:     .title       (28pt, semibold)    # 화면 타이틀
  title2:     .title2      (22pt, semibold)    # 카드 헤드
  title3:     .title3      (20pt, regular)     # 섹션 헤드
  headline:   .headline    (17pt, semibold)    # 강조 본문
  body:       .body        (17pt, regular)     # 본문 (Dynamic Type 기준)
  callout:    .callout     (16pt, regular)     # 카드 안 보조
  caption1:   .caption     (12pt, regular)     # 정확도 표기
  caption2:   .caption2    (11pt, regular)     # 메타 정보

  # Special
  timer_display: SF Mono, 56pt, semibold       # ActiveMealView mm:ss
```

**Dynamic Type**: 모든 텍스트 `.font(.body)` 등 시맨틱 토큰 사용 → 자동 스케일링. `.fontWeight(.semibold)` 같은 modifier로 강조.

### 9.3 간격·레이아웃

```yaml
spacing:
  xs: 4
  sm: 8
  md: 16
  lg: 24
  xl: 32
  xxl: 48

corner_radius:
  card:   16
  button: 12
  pill:   999
  small:  8

shadow:
  card_elevation_1: y=2 blur=8 alpha=0.06
  card_elevation_2: y=4 blur=16 alpha=0.08

hit_area:
  min: 44   # Apple HIG 최소

safe_zones:
  thumb_zone_bottom_third: 200pt 이하 우측 (오른손잡이)
  fab_position: bottom: 24, trailing: 16
```

### 9.4 모션

```yaml
motion:
  default_duration_sec: 0.3
  long_duration_sec:    0.6
  spring:               { response: 0.4, damping: 0.8 }

  # prefers-reduced-motion 시
  reduced:
    duration_sec: 0    # 즉시 전환
    spring:       null # fade only
```

**원칙**: 의미 있는 상태 변화에만 모션. `ChewBreathBadge`의 4초 호흡 사이클은 *예외적으로 유지* (사용자 페이스 가이드 가치) — prefers-reduced-motion 시엔 정적 원으로 대체.

---

## 10. 접근성 가드

### 10.1 VoiceOver 라벨 의무 사항

| 컴포넌트 | 라벨 예 |
|------|------|
| `Button("식사 끝났어요")` | "식사 끝났어요. 버튼" (자동) |
| `MealResultCard` | "오늘 점심 결과. 11분 32초. 캘리브레이션보다 2분 더 차분해졌어요. 자세히 보려면 두 번 탭하세요." |
| `ComfortSelfReportRow` | "위 컨디션 보고. 1점부터 5점까지. 현재 미입력. 두 번 탭하여 입력" |
| `ComfortSelfReportRow` 이모지 | "1점, 매우 안 좋음" / "5점, 매우 좋음" |
| `MealTrendChartCard` | "이번 주 식사 시간 추이 차트. 7일 평균 10분 12초. 차트 탭하여 상세 보기" |
| `MealTrendChartCard` 막대 | "{요일} {분}분 {초}초, 위 컨디션 {수}점" |
| `ChewBreathBadge` | "차분히 드시고 있어요" (정적 라벨) |
| `InsightCard` | "처음 보이는 패턴. {본문 전체}" |

### 10.2 Dynamic Type

- 모든 텍스트 `.font(.body)` / `.headline` / `.title` 등 시맨틱 토큰
- AX1~AX5까지 깨지지 않게 `Layout` 적응형 (`ViewThatFits` 활용 권장 — `ios-app-architect`에게)
- `MealResultCard` 같은 정보 밀집 카드는 AX3+ 시 세로 배치로 fallback

### 10.3 색 대비 (WCAG AA)

| 조합 | 대비 | 통과 |
|----|----|----|
| brand_primary `#5B7CFF` on white | 4.59:1 | ✓ AA Body |
| brand_accent `#FFB54A` on white | 1.97:1 | ✗ Body 텍스트 금지 → CTA 배경에만 사용, 텍스트는 white 또는 dark |
| Color.label on systemBackground | 자동 (Apple) | ✓ |
| warning `#FF9500` on white | 2.92:1 | ✗ Body 텍스트 금지, icon/border만 |

**규칙**: brand_accent / warning은 배경·아이콘·테두리에만. 본문 텍스트는 항상 `Color.label` / `Color.secondaryLabel`.

### 10.4 prefers-reduced-motion

- `@Environment(\.accessibilityReduceMotion)` 활용
- `ChewBreathBadge` → 정적 원 + 라벨만
- 차트 grow-in 애니메이션 → 즉시 표시
- 화면 transition → 페이드 (slide 회피)

### 10.5 VoiceOver-only 핵심 흐름 가능성

다음 5개 흐름은 *VoiceOver만으로* 완료 가능해야 함:
1. 온보딩 → 캘리브레이션 시작
2. 수동 식사 시작 → 종료
3. Comfort 셀프리포트 입력
4. 주간 회고 진입
5. 알림 설정 끄기/켜기

### 10.6 Hit Area

- 모든 인터랙티브 요소 ≥ 44×44pt
- ComfortSelfReportRow 이모지 — 각 44pt + 간격 16pt
- 차트 막대 탭 영역 — 막대 자체 좁아도 invisible padding으로 44pt 보장

### 10.7 한국어 조사·존댓말 일관성

- 모든 코칭 메시지 존댓말 (해요체) — 절대 반말 X (잔소리 톤 회피)
- 호칭 없음 (사용자 이름 / "환자님" / "회원님" 모두 회피 — V1)
- 이모지 사용 — Comfort row + 페르소나 카드만 (메시지 본문엔 X — 50대 검증 시 거부 회피)

---

## 11. 5초 룰 / 안티-함정 체크리스트

### 11.1 5초 룰 검증 시나리오 (실제 사용자 5초 테스트)

| # | 화면 | 0–1초 인지 | 1–3초 인지 | 3–5초 인지 | 통과 조건 |
|---|----|--------|--------|--------|--------|
| 1 | OnboardingWelcomeView | "AirPods + 위 건강 앱" | "1분이면 시작" | 시작 버튼 | 5/5 응답자 "위 건강 코칭" 키워드 회상 |
| 2 | DashboardView (Day 2) | "오늘 N분" | "어제보다 차분" | Comfort 진입 가능 | 4/5 응답자 "오늘 결과" 키워드 회상 |
| 3 | MealResultCard (Day 1) | "오늘 점심 결과" | "11분 32초" | Comfort row 진입 가능 | 5/5 응답자 "오늘 식사 결과" 회상 |
| 4 | ActiveMealView | "지금 식사 중" | 타이머 인지 | 종료 버튼 인지 | 5/5 응답자 "지금 측정 중" 회상 |
| 5 | WeeklyRecapSheet | "이번 주 회고" | 평균 시간 비교 | Discovery 1개 | 4/5 응답자 "주간 변화" 회상 |

### 11.2 안티-함정 체크리스트 (출시 전 self-audit)

- [ ] **씹기 트래커 도구 프레이밍** — 모든 화면 헤드/CTA에 "씹기 횟수" / "트래킹" 단어 0건 (디스커버리 §5.1)
- [ ] **의료적 약속** — "치료" / "회복 보장" / "위염 회복" 모든 카피 0건 (Vessyl·Healbe 함정 회피)
- [ ] **정확도 100% 약속** — "정확하게" / "100%" 표현 0건. "추정 ±15%" 표시 ≥ 3곳 (HowItWorks card 3, Settings 정직성, MealDetail)
- [ ] **권한 일괄 요청** — Motion·Notifications 동시 요청 0건 (§7 시점 분리)
- [ ] **영상 시청 컨텍스트 무시** — 식사 중 햅틱·소리 알림 0건 (V1 햅틱 자체 비활성)
- [ ] **다크 모드 사후 대응** — `.systemBackground` / `Color.label` 사용 ≥ 100%, 하드코딩 white/black 0건
- [ ] **Dynamic Type 사후 대응** — `.font(.body)` 등 시맨틱 토큰 사용. 하드코딩 `.font(.system(size: 16))` 0건
- [ ] **VoiceOver 흐름** — 5개 핵심 흐름 (§10.5) 모두 VoiceOver-only 통과
- [ ] **영어 잔존** — UI 카피에 "track" / "data" / "stats" / "monitor" / "score" (영문) 0건
- [ ] **반말·잔소리** — 모든 코칭 메시지 해요체. "왜" / "안" / "실패" 0건
- [ ] **호칭 강제** — 사용자 이름·환자·회원 호칭 0건 (V1)
- [ ] **이모지 과다** — 메시지 본문 이모지 0건. UI 카드 이모지는 Comfort row + persona card만
- [ ] **Hit area 44pt** — 모든 버튼·이모지·차트 막대 탭 영역 ≥ 44×44pt
- [ ] **brand_accent 본문 텍스트 사용** — 0건 (대비 1.97:1로 AA 미달, 배경/아이콘만)
- [ ] **빈 상태 카피 누락** — DashboardView·MealHistoryView·차트 모두 빈 상태 카피 정의됨

### 11.3 검증 체크포인트 (`ios-app-qa` 단계)

- 시뮬레이터에서 폰트 크기 AX5(가장 큰)로 모든 화면 깨지지 않음 (overflow 0건)
- 다크 모드 토글 시 모든 화면 자동 색 적응 확인
- VoiceOver 켠 상태에서 온보딩 → 첫 식사 종료 → Comfort 보고 흐름 완주 가능
- 빠른 5초 첫인상 테스트 — 협력자 N=3 이상 응답에서 §11.1 키워드 회상

---

## 12. 다음 에이전트 인용 가이드

### 12.1 → `ios-app-architect`

**컴포넌트 트리 결정 인풋**:
- §3 화면 인벤토리 11개 + 모달 3개
- Custom 컴포넌트 = `MealResultCard`, `ChewBreathBadge`, `ComfortSelfReportRow`, `InsightCard`, `MealTrendChartCard`, `PersonaCard`, `TodayHeaderCard` 7개
- Tab Bar 구조: `DashboardView` / `MealHistoryView` / `SettingsView` 3 tabs
- `Sheet` 3개 — `ComfortDetailSheet`, `MealStartConfirmationSheet`, `NotificationPermissionPromptSheet`
- 화면 전환은 `NavigationStack` (`NavigationLink`) 우선, 모달은 `.sheet(detents:)` (medium/large)

**상태 모델 결정 인풋**:
- `MealSessionState` (signal §2.4) → ViewModel 그대로 매핑
- `OnboardingFlow` 5단계 → enum 기반 router
- 페르소나 선택 → `UserDefaults` 또는 SwiftData 단일 entity
- Coaching message engine — `CoachingMessageRepository` (§8 YAML → Swift array) + `MessagePicker(context:) -> CoachingMessage?`

**SwiftUI 표준 컴포넌트 선택**:
- `TabView(selection:) { ... }.tabViewStyle(.page)` — OnboardingHowItWorksView
- `Form` + `Toggle` — SettingsView
- `Charts` (BarMark, RuleMark, AnnotationMark) — MealTrendChart
- `@Environment(\.accessibilityReduceMotion)` — ChewBreathBadge

### 12.2 → `ios-app-implementer`

**Coaching message library Swift 변환** (§8.2 YAML → enum/struct):
```swift
struct CoachingMessage {
    let id: String
    let category: Category
    let trigger: TriggerCondition
    let template: String
    let variables: [Variable]
    let tone: Tone

    enum Category: String { case encouragement, insight, awareness, celebration, weekly }
    enum Tone: String { case encouraging, gentle, curious, celebratory, authoritativeGentle }
}
```

- 32개 메시지 모두 `static let library: [CoachingMessage] = [...]` 단일 배열
- Trigger evaluation은 별도 `TriggerEvaluator` — 컨텍스트 dictionary 입력 → bool
- `template` 안 `{{var}}` 치환은 `String.replacingOccurrences` 또는 dedicated formatter
- 한국어 조사 helper `ko_particle(_ noun: String, particleType: ParticleType) -> String` 권장

**금지 표현 lint** (§8.3) — 빌드 시 `swiftlint` custom rule 또는 unit test로 모든 카피 string 검사 권장.

### 12.3 → 신호 엔지니어 (역방향 피드백)

**UX의 신호 요구사항 확인**:
- 식사 종료 검출 후 `MealResultCard`까지 노출 latency ≤ 5초 권고 (식사 종료 후 사용자가 폰을 들 때 이미 카드가 준비되어 있어야 함)
- `paused` 상태 트리거 — `CMHeadphoneMotionManager` connect/disconnect 콜백 필요 (§3.6 ActiveMealView)
- Audio session active 검출 — `AVAudioSession` API로 video mode 토글 (§4.3)

신호 엔지니어 §7.1의 "사후 리포트가 더 정직" 권고 *완전 수용* — V1 햅틱 0건. V2에서 latency가 < 3초로 줄어들면 햅틱 재검토.

---

## 부록 A. 빠른 참조 — 11개 화면 한 줄 요약

| # | 화면 | 한 줄 |
|---|----|----|
| 1 | OnboardingWelcomeView | "AirPods로 위 컨디션 살펴봐요" — 5초 룰 |
| 2 | OnboardingPersonaView | 3카드 페르소나 자기 식별 |
| 3 | OnboardingHowItWorksView | 3단계 정직성 카드 (정확도 ±15%) |
| 4 | OnboardingMotionPermissionView | 모션 권한 요청 + 거부 fallback |
| 5 | OnboardingCalibrationIntroView | 첫 캘리브레이션 식사 트리거 |
| 6 | ActiveMealView | 타이머 + 호흡 애니메이션 (영상 모드 dim) |
| 7 | DashboardView | Today + MealResultCard + 차트 + Insight |
| 8 | MealHistoryView | 식사 세션 리스트 |
| 9 | MealDetailView | 단일 식사 깊이 보기 |
| 10 | WeeklyRecapView (Sheet) | Day 7+ 주간 회고 + Discovery |
| 11 | SettingsView | 권한·알림·정직성 약속·데이터 |

## 부록 B. 디스커버리·신호 인용 인덱스

| 인용 | 출처 | UX에 반영된 곳 |
|----|----|----|
| 결과 프레이밍 톤 | discovery §5.1 | 모든 카피 (씹기 트래커 단어 0건) |
| 한지원 페르소나 | discovery §3.3 | §1.1 + §11 5초 룰 시나리오 |
| 다노식 친근 톤 | discovery §4.6 | §8 코칭 라이브러리 |
| 정확도 ±15% | signal §3.1, §5.1 | §3.3 card 3, §3.11 정직성, §11.2 |
| 사후 리포트 권고 | signal §7.1 | §4.1 햅틱 0건 결정 |
| 식사 외 false positive | signal §2.5 | §3.6 paused 상태, §3.11 자동/수동 듀얼 |
| 캘리브레이션 1식사 | signal §4 | §3.5 OnboardingCalibrationIntroView |
| Vessyl·Healbe 함정 | discovery §4.2 | §8.3 금지 표현 + §3.11 정직성 약속 |
| 영상 audio session | signal §5.6 | §4.3 video mode 검출 |
| MEAL_END_THRESHOLD_CPM 등 매직넘버 | signal 부록 A | §3.6 ending 상태, §3.7 빈 상태 카피 |

---

## 업데이트 이력

- **2026-05-02**: 초안. 11개 필수 섹션 모두 작성. 화면 11개 + 모달 3개. 코칭 메시지 라이브러리 32개 (encouragement 10·insight 10·awareness 5·celebration 5·weekly 2). 신호 엔지니어 §7.1 권고 *완전 수용* — V1 햅틱 0건, 사후 리포트 우선. 다음 에이전트(`ios-app-architect`·`ios-app-implementer`) 인용 가이드 §12 포함.
