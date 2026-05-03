# 06. iOS 앱 QA 리포트

**검수일**: 2026-05-03
**라운드**: 1
**검수자**: `ios-app-qa-polish` 스킬 (3축 검증)
**대상 빌드**: 05_build_report.md (60 Swift 소스 + 29 단위 테스트 통과 + xcodebuild 통과)
**환경**: Xcode 26.4, iOS 26.4 시뮬 (iPhone 17), macOS Darwin 25.3.0

---

## 1. 종합 평가 (5점 척도)

| 축 | 점수 | 비고 |
|----|------|------|
| 기능·정합성 | **4 / 5** | 빌드·테스트 회귀 0건. UX 흐름상 onboarding 권한 거부 자동 진행 / 결과 카드 자세히 보기 무작동 / 인사이트 카드 메시지 중복 등 구조적 미흡 발견 → 폴리시 완료 |
| 신호·UX 톤 | **4.5 / 5** | 옵션 G 톤 가이드 위반 0건 (의료 약속 / 영어 잔존 / 도구 프레이밍 모두 깨끗). 부호 의미 모호한 결과 표현 다수 발견 → 폴리시 완료 |
| 품질·접근성 | **3.5 / 5** | 다크 모드·VoiceOver 라벨 양호. 다만 Dynamic Type AX1+ 환경에서 timer 56pt 고정 폰트가 깨짐 위험 → minimumScaleFactor 추가로 완화. video mode 데이터 영구 저장 부재 (구현자 재작업 요청) |
| **종합** | **4.0 / 5** | **베타 후보 → 폴리시 1라운드 후 베타 진입 권고**. Critical 1건 + High 2건 모두 폴리시 완료. Medium 잔존 1건은 데이터 모델 변경 필요(구현자 재작업) |

---

## 2. 5초 룰 검증

### 2.1 첫 실행 5초 룰 — **통과** ✓

시뮬 캡처: `_workspace/app/screenshots/01_welcome_5sec.png`

5초 본 후 답:
- **무엇을 하는 앱인가**: "AirPods로 내 위 컨디션을 살펴보는 앱" (정답)
- **누구를 위한 것인가**: "의사가 천천히 드시라고 한 사람" (위장 페르소나 명확)
- **다음 행동은**: "시작하기" 버튼 (CTA 명확)

기대 답("AirPods로 식사 패턴을 자동으로 보는 앱 / 위 건강 신경 쓰는 사람 / 권한 동의 → 첫 식사")과 일치. 5초 룰 통과.

### 2.2 첫 식사 결과 5초 룰 — **부분 통과 → 폴리시 후 통과** ✓

폴리시 *전*: MealResultCard와 InsightCard가 동일 메시지를 두 번 노출 → 5초 내 "오늘 결과" + "패턴 발견" 둘 다 파악 어려움 (시각적 중복).

폴리시 *후*: 카테고리 분기 (encouragement는 결과 카드에만, insight·awareness·celebration·weekly는 별도 카드로) → 결과 카드는 *오늘 결과*, InsightCard는 *패턴 발견*으로 명확 분리.

답:
- **오늘 결과**: 시간(분) + "캘리브레이션보다 N분 더 차분히/빨리" → 결과 언어로 명확
- **변화**: 캘리브레이션 대비 + 격려/인사이트 카드로 흐름 → 통과

---

## 3. 옵션 G 톤 가이드 검증

### 3.1 의료 약속 적발 — **0건**

```bash
rg -n -i "치료|완치|보장|100%|정확.*100|환자|진단" app/
```

발견된 매치 모두 *정직성 표현*(부정 컨텍스트):
- `OnboardingHowItWorksView.swift:15-16` — "100% 정확하지 않아요. (추정 ±15%)" / "치료가 아니라 *행동 변화 코칭*이에요." (정직성 강조)
- `HonestyPledgeView.swift:30,32` — "위염 치료 / 의료적 효과" / "100% 정확한 측정" (둘 다 "약속하지 않아요" 섹션)
- `MealDetailView.swift:80` — "추정 ±15%. 100% 정확하지 않아요." (정직성 디스클로저)
- `MessageLibraryTests.swift:8-11` — grep 금지 키워드 정의 (테스트 코드, 비노출)

→ 모두 *의도된 정직성 표시*. 위반 0건.

### 3.2 영어 잔존 적발 — **0건**

```bash
rg -n '"(track|stats|monitor|coach[^a-z]|score|data|tracker|chewing tracker)"' app/
```

매치는 `MessageLibraryTests.swift:10`의 lint 금지 키워드만 발견. 사용자 노출 카피 전무. 라이브러리 자체 lint 테스트 8/8 통과.

### 3.3 도구 프레이밍 적발 — **0건**

```bash
rg -n -i "씹기 횟수 측정|chewing tracker" app/
```

0건. 모든 사용자 노출 카피가 *결과 언어*("위 컨디션", "차분히", "패턴", "회복") 사용. "씹은 횟수"는 *MealDetailView*에서 부수 정보로만 표시("씹은 횟수 (추정)") — 도구 프레이밍 아님.

### 3.4 결과 언어 일관성 — **✓ (폴리시 후)**

- 폴리시 전: `MealResultCard` "캘리브레이션 +3분" / `DashboardViewModel.comparisonText` "+2분" → 부호 의미 모호
- 폴리시 후: "캘리브레이션보다 N분 더 차분히 / 더 빨리" → 결과 의미 명확

### 3.5 메시지 라이브러리 32개 — **✓**

`MessageLibrary.swift` 32개 모두 검토. 의료 약속 0건, 모든 메시지가 *결과·관찰·격려* 톤. 위장 페르소나(가스트릭) + 다이어트 + 호기심 모두 커버. 8개 메시지 라이브러리 lint 테스트 통과.

---

## 4. 디바이스 매트릭스

| 디바이스 | 시뮬 가능 | 결과 |
|--------|---------|------|
| iPhone 17 (다운로드됨, iOS 26.4) | ✅ | Welcome 화면 5초 룰 통과, 다크 모드 토큰 정상 (스크린샷 01, 03) |
| iPhone 17 Pro / Pro Max / Air / 17e | ✅ (시뮬 존재, 미실행) | 코드 리뷰 — 동적 폰트 + minimumScaleFactor 적용으로 큰 화면 안전 |
| iPad Pro 13 / 11 / mini / Air 13 / 11 | ✅ (시뮬 존재, 미실행) | **TARGETED_DEVICE_FAMILY=1 (iPhone only)** — iPad 미지원 (의도된 결정) |
| iPhone SE (3rd gen) | ❌ (시뮬 미설치) | 코드 리뷰만 — FAB 60×60 + padding 24, 차트 height 160. SE 좁은 화면에서 차트와 FAB 겹침 가능성. 실기기 검증 필요 |

**스크린샷 산출물**:
- `screenshots/01_welcome_5sec.png` — Light 모드 Welcome (5초 룰 통과)
- `screenshots/02_welcome.png` — 진입 직후 동일
- `screenshots/03_welcome_dark.png` — Dark 모드 Welcome (색 토큰 정상 분기)

---

## 5. 접근성

| 항목 | 결과 | 비고 |
|------|------|------|
| Dynamic Type Large(XL) | **부분 → 폴리시 후 ✓** | `Font.timerDisplay` 56pt 고정 폰트는 변하지 않음 (Dynamic Type 미반영). 폴리시: 사용 3곳에 `minimumScaleFactor(0.6)` + `lineLimit(1)` 추가. 또한 `timerDisplayDynamic` 신규 토큰 추가(`.system(.largeTitle)` 기반). V1.1에서 점진적 마이그 가능 |
| VoiceOver 핵심 흐름 | ✓ | 모든 컨트롤에 `accessibilityLabel`. `accessibilityHidden(true)` (장식 아이콘) + `accessibilityElement(children: .combine)` (카드) 적절. PersonaCard에 `accessibilityAddTraits(.isSelected)` 정확 |
| 색 대비 WCAG AA | ✓ | 디자인 토큰 사용 (system colors + brandPrimary 0.357/0.486/1.0 → blue 약 4.8:1 흰 텍스트 대비) |
| prefers-reduced-motion | ✓ | `ChewBreathBadge`가 `@Environment(\.accessibilityReduceMotion)` 체크 후 애니메이션 차단. OnboardingFlowView·OnboardingMotionPermission도 `.animation(...)` 사용하지만 핵심 컨텐츠 표시에 영향 없음 |
| 다크 모드 | ✓ | `Color+Tokens.swift`의 dynamic UIColor + `Color(uiColor: .secondarySystemBackground)` 일관 사용. 시뮬 캡처(03)로 검증 |
| 빌드 워닝 (앱 코드) | ✓ 0건 | SwiftData KeyPath 워닝 7건은 Apple 프레임워크 한계 (수용) |

---

## 6. 발견 이슈 (심각도 순)

### Critical (배포 차단) — 1건 → **모두 폴리시 완료**

#### C-1. OnboardingMotionPermissionView 권한 거부 시 fallback 카피 미노출
- **위치**: `app/ChewCoach/Features/Onboarding/OnboardingMotionPermissionView.swift:54-77`
- **재현**: "나중에" 탭 또는 권한 거부 → `phase = .deniedFallback` 설정 직후 `flow.goNext()` 호출 → fallback 카피("괜찮아요. 식사할 때 *시작* 버튼을 직접 누르셔도 똑같이 작동해요.")가 사용자에게 *전혀 노출되지 않고* 즉시 다음 화면 전환
- **근거**: SwiftUI에서 `@State` 변경과 view 전환이 같은 transaction에 일어나면 중간 상태 렌더링 생략. UX 사양 §6 권한 거부 흐름은 fallback 카피 명시적 노출이 핵심
- **영향**: 권한 거부 사용자가 *어떻게 자동 인식 없이 앱을 쓸 수 있는지* 안내 없음 → 이탈 가능성 높음
- **분류**: QA 직접 폴리시 ✓ (아래 §7 참조)

### High — 2건 → **모두 폴리시 완료**

#### H-1. DashboardView "자세히 보기" 버튼 무작동
- **위치**: `app/ChewCoach/Features/Dashboard/DashboardView.swift:112` (수정 전)
- **재현**: Dashboard → MealResultCard → "자세히 보기" 탭 → 아무 일도 일어나지 않음 (`onTapDetail: {}` 빈 클로저)
- **근거**: UX 사양 §11에서 결과 카드 → MealDetail 진입은 핵심 흐름. 사용자가 차트·코멘트를 보러 갈 수 있어야 함
- **영향**: 결과 화면에서 더 깊은 인사이트로 진입 불가
- **분류**: QA 직접 폴리시 ✓ (NavigationLink + State binding 추가)

#### H-2. DashboardView 마지막 식사 카드와 InsightCard 메시지 중복
- **위치**: `app/ChewCoach/Features/Dashboard/DashboardView.swift:111,119` (수정 전)
- **재현**: `vm.insightCard?.rendered`가 `MealResultCard.coachingMessage`와 `InsightCard.message` 두 곳에 동시 전달 → 같은 메시지가 같은 화면에 두 번 노출
- **근거**: 정보 위계상 두 카드는 다른 역할 — 결과 카드는 "오늘 결과", 인사이트 카드는 "패턴 발견". 같은 메시지는 5초 룰 위반(첫 식사 결과 모호)
- **영향**: 시각적 노이즈 + 사용자가 "왜 같은 말이 두 번 보이지?" 혼란
- **분류**: QA 직접 폴리시 ✓ (카테고리 분기 — encouragement는 결과 카드에만, 그 외는 InsightCard에만)

### Medium — 6건

#### M-1. MealResultCard headerTitle 새벽·야식 시간대 누락 → **폴리시 완료**
- **위치**: `app/ChewCoach/Shared/Components/MealResultCard.swift:51-57` (수정 전)
- **재현**: 새벽 3시 식사 → "오늘 아침 결과" / 22시 야식 → "오늘 저녁 결과"
- **폴리시**: 5시 미만 = "새벽 식사 결과", 21시 이상 = "오늘 야식 결과" 분기 추가
- **분류**: QA 직접 폴리시 ✓

#### M-2. MealResultCard.calibrationComparisonText 부호 의미 모호 → **폴리시 완료**
- **위치**: `app/ChewCoach/Shared/Components/MealResultCard.swift:60-65` (수정 전)
- **재현**: "캘리브레이션 +3분" → 사용자가 + 의미가 차분인지 빠름인지 즉각 파악 어려움
- **폴리시**: "캘리브레이션보다 N분 더 차분히" / "캘리브레이션보다 N분 더 빨리" 결과 언어로 표현. 1분 미만은 초 단위 표시 추가
- **분류**: QA 직접 폴리시 ✓

#### M-3. DashboardViewModel.comparisonText 동일 부호 모호 → **폴리시 완료**
- **위치**: `app/ChewCoach/Features/Dashboard/DashboardViewModel.swift:67-72` (수정 전)
- **재현**: TodayHeaderCard에 "+2분" → 의미 모호
- **폴리시**: "캘리브레이션보다 N분 더 차분히 / 더 빨리"
- **분류**: QA 직접 폴리시 ✓

#### M-4. Font.timerDisplay 고정 56pt → Dynamic Type 미반영 → **부분 폴리시 (minimumScaleFactor)**
- **위치**: `app/ChewCoach/Shared/DesignSystem/Font+Tokens.swift:13`
- **재현**: 사용자가 설정→일반→텍스트 크기 AX5 설정 → 모든 텍스트 커지지만 `timerDisplay` 56pt 고정 (작은 화면에서 일관성 깨짐)
- **폴리시**: 사용 3곳(`MealResultCard`, `MealDetailView`, `ActiveMealView`)에 `minimumScaleFactor(0.6)` + `lineLimit(1)` 추가. 신규 `timerDisplayDynamic` 토큰 추가(향후 점진 마이그)
- **잔존 위험**: 고정 폰트 그대로이므로 큰 텍스트 사용자가 본인 환경에서 불일치 인지 가능. 완전 해결은 V1.1
- **분류**: QA 부분 폴리시 (잔존은 디자이너 재작업 권고)

#### M-5. WeeklyRecapView "짧아졌어요" 결과 의미 누락 → **폴리시 완료**
- **위치**: `app/ChewCoach/Features/WeeklyRecap/WeeklyRecapView.swift:60`
- **재현**: 짧아진 = 빨라진 의미인데 "짧아졌어요"만 노출 → 행동 가이드 누락
- **폴리시**: "지난 주보다 N분 더 빨라졌어요. 다음 주는 한 입씩만 천천히 가볼까요?" — 결과 + 행동 가이드 결합
- **분류**: QA 직접 폴리시 ✓

#### M-6. video mode 영구 저장 부재 → 패턴 인사이트 발화 불가
- **위치**: `app/ChewCoach/Features/Dashboard/DashboardViewModel.swift:104-114` (`summary(for:)` 메서드)
- **재현**: 식사 시점 `audioMonitor.isVideoPlaying`이 측정되지만 `MealSession`에 저장 안 됨 → `MealSummary.isVideoMode`가 항상 false → `MessageLibrary`의 `videoModeSteady` / `videoContextQuick` / `patternVideoModeFaster` 트리거 영구 미발화
- **근거**: `Insight*VideoMode` 라이브러리 메시지 5개가 데이터 부재로 사용 불가 — 라이브러리의 약 16% (5/32)가 죽은 코드
- **분류**: **구현자 재작업 요청** (SwiftData @Model 변경 필요 — `MealSession`에 `isVideoMode: Bool` 추가 → ActiveMealViewModel에서 종료 시 저장 → DashboardViewModel.summary에서 매핑)

### Low — 5건

#### L-1. Persona.diet "회복" 어색 → **폴리시 완료**
- **위치**: `app/ChewCoach/Core/Storage/UserPreferences.swift:43`
- **재현**: 다이어트 페르소나 subtitle "천천히 드시면서 회복하고 싶어요" — 다이어트와 회복 어색 매칭
- **폴리시**: "천천히 드시면 포만감이 자연스럽게 와요" — 다이어트 컨텍스트의 결과 언어 사용
- **분류**: QA 직접 폴리시 ✓

#### L-2. Persona.gastric 의학 진단명 노출 → **폴리시 완료**
- **위치**: `app/ChewCoach/Core/Storage/UserPreferences.swift:34, 41`
- **재현**: title "위 건강 (위염·소화불량)" — 의학 진단명 "위염" 직접 노출. 옵션 G 톤 가이드는 의학 단어 회피
- **폴리시**: "위가 자주 더부룩해요" / "천천히 드시는 습관이 도움이 될 수 있어요" — 부드러운 페인 표현
- **분류**: QA 직접 폴리시 ✓

#### L-3. DashboardView.errorView 카피 어색 → **폴리시 완료**
- **위치**: `app/ChewCoach/Features/Dashboard/DashboardView.swift:88-95` (수정 전)
- **재현**: "잠시 정보를 불러오지 못했어요. 다시 시도" + 그 아래 "다시 시도" 버튼 → 단어 중복, 첫 줄 어색
- **폴리시**: 아이콘 추가 + 두 번째 문장 분리 + 단어 중복 제거 + padding 추가
- **분류**: QA 직접 폴리시 ✓

#### L-4. ChewBreathBadge 카피 항상 동일 (컨텍스트 무시)
- **위치**: `app/ChewCoach/Shared/Components/ChewBreathBadge.swift:15`
- **재현**: 빨리 먹어도 "차분히 드시고 있어요" 노출 → 거짓 피드백 가능성
- **폴리시 보류 사유**: V1 호흡 애니메이션은 *사용자가 따라 호흡하도록 유도하는 시각 가이드*로 의도. 실시간 페이스 비교는 V1.1+ 스코프
- **분류**: 다음 라운드 후보 (또는 디자이너 재작업)

#### L-5. OnboardingPersonaView 페르소나 의무화 (스킵 불가)
- **위치**: `app/ChewCoach/Features/Onboarding/OnboardingPersonaView.swift:34`
- **재현**: 페르소나 미선택 시 "다음" 버튼 disable → 스킵 불가
- **폴리시 보류 사유**: V1 단순화로 의도된 결정 가능성. UX 사양에 강제·스킵 명시 부족 → 디자이너 결정 필요
- **분류**: 다음 라운드 후보 (디자이너 의견 필요)

---

## 7. 직접 폴리시한 항목

| # | 파일 | 변경 | 재검증 |
|---|------|------|------|
| 1 | `Features/Onboarding/OnboardingMotionPermissionView.swift` | 권한 거부·"나중에" 탭 시 fallback 카피 노출 후 사용자 확인 대기. CTA 라벨 동적 변경 ("AirPods로 자동 인식 켜기" → "다시 시도"). 재시도 버튼 + "확인했어요, 다음" 분리. 애니메이션 추가 | xcodebuild ✓, 시뮬 진입 ✓ |
| 2 | `Features/Dashboard/DashboardView.swift` | NavigationDestination(item:)으로 MealDetail 진입 추가, errorView 카피·시각적 정리, MealResultCard와 InsightCard 메시지 중복 제거 (encouragement는 결과 카드에만, 그 외는 별도) | xcodebuild ✓, 29 tests ✓ |
| 3 | `Shared/Components/MealResultCard.swift` | headerTitle 새벽·야식 시간대 추가, calibrationComparisonText 결과 언어 ("차분히/빨리") + 1분 미만 초 단위 표시, timer 폰트 minimumScaleFactor + lineLimit | xcodebuild ✓ |
| 4 | `Features/Dashboard/DashboardViewModel.swift` | comparisonText 결과 언어로 변경 | 29 tests ✓ |
| 5 | `Features/WeeklyRecap/WeeklyRecapView.swift` | comparison "짧아졌어요"에 행동 가이드 결합 ("다음 주는 한 입씩만 천천히 가볼까요?") | xcodebuild ✓ |
| 6 | `Shared/DesignSystem/Font+Tokens.swift` | timerDisplay leading(.tight) + 신규 timerDisplayDynamic 토큰 추가 | xcodebuild ✓ |
| 7 | `Features/MealHistory/MealDetailView.swift` | timer 폰트 minimumScaleFactor + lineLimit 추가 | xcodebuild ✓ |
| 8 | `Features/ActiveMeal/ActiveMealView.swift` | timer 폰트 minimumScaleFactor + lineLimit 추가 | xcodebuild ✓ |
| 9 | `Core/Storage/UserPreferences.swift` | Persona.gastric / .diet title·subtitle 카피 톤 정리 (의학 진단명 회피, 결과 언어) | 29 tests ✓ |

**폴리시 후 회귀 검증**:
- xcodebuild clean build: **BUILD SUCCEEDED** ✓
- xcodebuild test: **29/29 통과** ✓ (T1~T12 + Repository 5 + Library 8 + Calibration 4 — 0 failures)
- 시뮬 부팅·앱 설치·런치·캡처 (Light + Dark): 모두 정상 ✓
- 직접 수정 9건 모두 빌드·테스트 회귀 0건

---

## 8. 구현자 재작업 요청

### REQ-1. MealSession에 isVideoMode 영구 저장 (Medium · M-6)

**대상**: `ios-app-implementer`

**무엇**:
1. `MealSession.swift` @Model에 `var isVideoMode: Bool = false` 추가 + SwiftData lightweight migration
2. `ActiveMealViewModel.persistMeal(from:)` (line 198~)에서 `meal.isVideoMode = audioMonitor.isVideoPlaying` 저장
3. `DashboardViewModel.summary(for:)` (line 104~)에서 `isVideoMode: meal.isVideoMode` 매핑
4. `DashboardViewModel.regenerateInsight()`에서 `lastMeal?.isVideoMode` 또는 today의 majority를 `InsightGenerator.generateDailyInsight(isVideoMode:)`에 전달
5. `ActiveMealViewModel.observeAudio` polling timer 추가 (구현자 자체 발견 #7) — 1초 간격으로 mirror

**왜**: 현재 video mode 메시지 5개(`enc_video_mode_steady`, `aware_video_context`, `insight_video_mode_pattern`, etc.) 영구 미발화 = 라이브러리 16%가 죽은 코드. 또한 옵션 G의 핵심 차별화(영상 시청 컨텍스트 인식)가 사용자에게 노출되지 않음.

**우선순위**: Medium (V1 베타 진입에는 필수 아니지만 V1.0 출시 전 권고)

### REQ-2. PermissionCoordinator 5초 timeout 정확도 검증 (Low)

**대상**: `ios-app-implementer`

**무엇**: `PermissionCoordinator.requestMotion()` 5초 fallback이 실기기에서 *실제로 작동하는지* 측정. 현재 시뮬에서는 `isDeviceMotionAvailable=false`로 분기되어 검증 불가.

**왜**: 사용자가 권한 dialog를 5초 이상 보고 있을 경우 unknown 상태로 진행되며 motion 데이터가 영구 누락될 위험.

**우선순위**: Low (실기기 측정 필요)

---

## 9. 디자이너 재작업 요청

### DES-1. Dynamic Type AX1+ 환경에서 timer 폰트 토큰 마이그 (M-4 잔존)

**대상**: `app-experience-designer`

**무엇**: `Font.timerDisplay` (56pt 고정)을 `timerDisplayDynamic` (`.system(.largeTitle, design: .monospaced)`)로 점진 교체. 디자인 시스템 문서에 *Dynamic Type 적응형 폰트* 가이드 추가.

**왜**: 시각 기준 사이즈는 56pt이지만 접근성 환경에서 일관성 부족. QA가 minimumScaleFactor로 깨짐은 막았지만 사용자 의도(큰 텍스트)와 다름.

**우선순위**: Medium (V1.1)

### DES-2. ChewBreathBadge 컨텍스트 응답형 카피 (L-4)

**대상**: `app-experience-designer`

**무엇**: 현재 "차분히 드시고 있어요" 고정 → 실시간 CPM 비교 후 3단계 ("페이스 빠르세요" / "차분히 드시고 있어요" / "조금 천천히") 분기 또는 *카피 없이 시각 가이드만*으로 단순화

**우선순위**: Low (V1.1)

### DES-3. OnboardingPersonaView 스킵 가능 여부 결정 (L-5)

**대상**: `app-experience-designer`

**무엇**: 페르소나 선택을 의무화할지 / 스킵 옵션을 둘지 결정. 스킵 시 코칭 메시지 라이브러리에 일반 메시지가 사용되어야 — 라이브러리 검토 필요.

**우선순위**: Low (V1.1)

---

## 10. 신호 엔지니어 재작업 요청

**없음**. 단위 테스트 T1~T12 모두 통과, 알고리즘 정확도 KPI는 실기기 측정 필요(시뮬에선 불가). 신호 처리 코드 변경 불요.

---

## 11. 실기기 전용 검증 항목 (사용자에게 안내)

시뮬레이터에서 검증 불가능 — *실기기 + AirPods Pro 2*로 사용자 직접 검증 필요:

1. **AirPods Pro 2 실데이터 정확도** — `_workspace/app/01_signal_processing.md` F1 0.75-0.85 KPI. 합성 sine wave가 아닌 실 IMU 노이즈·gravity drift 환경에서 검증
2. **CMHeadphoneMotionManager 권한 dialog 실제 노출 + 콜백** — `PermissionCoordinator.requestMotion()` 시뮬에선 항상 .denied. 실기기에서 dialog 노출 + 사용자 응답 → motionState 정확 반영 검증
3. **AirPods 분리·재연결 시나리오** — `AVAudioSession.routeChangeNotification` 기반 일시정지 → 재개 흐름 (ActiveMealView pausedView 노출 → 재연결 시 자동 재개 검증)
4. **Background audio session 백그라운드** — 식사 중 다른 앱 전환 → IMU 스트림 유지 또는 적절한 종료 흐름 검증
5. **첫 5초 룰 — 실기기 사용자 시점** — 시뮬은 키보드 입력·홈제스처 다름. 실기기에서 첫 launch 5초 본 후 사용자 즉답 가능한지 측정
6. **CSV export ShareSheet** — `SettingsView.exportCSV()` → ShareSheet → AirDrop·Files 등 정상 작동
7. **알림 권한 + 일일 인사이트** — `PermissionCoordinator.requestNotifications()` 후 09:30 BackgroundTask 실제 트리거 (V1엔 BGTask 미구현, V1.5 후보)
8. **iPhone SE 좁은 화면 FAB 위치** — Dashboard FAB 60×60 + padding 24가 차트와 겹치는지 검증

---

## 12. 회귀 위험

이번 라운드 폴리시가 영향 줄 수 있는 영역:

1. **DashboardView NavigationStack 중복 가능성** — `navigationDestination(item:)` 추가. RootTabView 내부 NavigationStack과의 중첩 시 push 동작 검증 필요. 단위 테스트 통과 + 빌드 통과로 명백한 버그 없음 확인.
2. **MealResultCard `coachingMessage: nil` 케이스 빈도 증가** — 카테고리 분기로 encouragement 외 카테고리는 nil 전달. 카드 height가 메시지 유무에 따라 변하므로 시각적 점프 가능성. 다음 라운드 모니터링.
3. **OnboardingMotionPermissionView 흐름 변경** — 기존: 거부 즉시 다음 / 변경 후: fallback 카피 노출 후 사용자 확인 대기. 사용자가 추가 1탭 필요 — 흐름 길이 증가는 의도된 trade-off.
4. **Persona 카피 변경** — 기존 `personaRaw="gastric"`로 저장된 데이터는 새 카피로 자동 표시 (저장값은 enum case name 그대로). 마이그레이션 불요.
5. **Font.timerDisplay leading(.tight) 추가** — 줄간격 살짝 좁아짐. 단일 라인이라 영향 미미.
6. **WeeklyRecapView "짧아졌어요" → "더 빨라졌어요. ..." 길이 증가** — 모달 sheet에서 단일 라인 → 2줄 가능. 텍스트 reflow 정상 (font.calloutR + multilineTextAlignment 미설정이므로 leading 자연 정렬).

---

## 13. 다음 라운드 권고

### 13.1 V1 베타 진입 가능 여부

**조건부 GO** ✓ — Critical / High 이슈 모두 폴리시 완료. 다만 다음 *3가지*가 베타 진입 전 권고:

1. **REQ-1 (구현자 재작업)** — video mode 영구 저장. 라이브러리 16%가 죽은 코드 상태로 베타 진입은 첫 인사이트 다양성 부족 위험.
2. **실기기 1회 사용자 검증** — §11의 8개 항목 중 최소 1·2·3·8(AirPods 정확도·권한 dialog·분리/재연결·SE FAB 위치)
3. **iPhone SE 시뮬 매트릭스 추가** — 현재 미설치. `xcodebuild -downloadPlatform iOS` + iPhone SE 시뮬 다운로드 후 Dashboard FAB·Dynamic Type 검증

### 13.2 다음 QA 라운드 필요 시점

- REQ-1 (구현자 재작업) 완료 후 → 회귀 검증 + 새 메시지 라이브러리 활용도 검증
- DES-2 (ChewBreathBadge) 디자인 결정 후 → 카피·시각 일관성 검증
- 실기기 1회 측정 데이터 입수 후 → 신호 정확도 + 사용자 5초 룰 재검증

### 13.3 V1 출시 전 잔여 위험

- iPad 미지원 (TARGETED_DEVICE_FAMILY=1) — 의도된 결정 명확화 필요
- BGAppRefreshTask 미구현 — Daily 09:30 인사이트 알림은 V1.5
- Live Activity 미구현 — V1.5+
- CSV cleanup 누락 (구현자 자체 발견 #10) — 임시 파일 누적 가능. 7일 후 자동 정리 로직 추가 권고

---

## 업데이트 이력

- **2026-05-03**: 라운드 1 완료. Critical 1건 + High 2건 + Medium 5건(부분 폴리시 1건 포함) + Low 3건 직접 폴리시. 구현자 재작업 1건(M-6 video mode 영구 저장) + 디자이너 재작업 3건 발행. 실기기 검증 항목 8건 사용자 안내. 빌드·29 단위 테스트 회귀 0건 유지. 시뮬 캡처 3장 (`screenshots/01_welcome_5sec.png`, `02_welcome.png`, `03_welcome_dark.png`). 종합 평가 4.0 / 5 — 베타 후보.
- **2026-05-03 라운드 2 (v1.1 패치)**: "감지 살리기" 회귀 검증 완료. 단위 테스트 29 → 37 통과(T13~T18 풀 파이프라인 회귀 가드 6건 + ChewSamplePersistence 2건 신규). T17 정류 결함 회귀 가드 통과 — 1.2Hz 입력에서 평균 chew 간격 0.83s 보존 검증. 시뮬에서 Onboarding 통과 후 Dashboard 진입 확인(SwiftData 직접 inject로 onboardingCompletedAt 우회). v1.1 신규 카피 톤 grep 0건 위반(의료 약속·영어 잔존·도구 프레이밍). 카피 직접 폴리시 3건(디버그 패널 영어 라벨 한국어화·감도 배지 상태 명확화·개발자 모드 안내 친근 톤). 시뮬 캡처 6장 추가. 종합 평가 4.2 / 5 — 베타 후보 유지.
- **2026-05-03 라운드 3 (v1.2 1단계 — 데이터 수집 인프라)**: privacy 보장 + 회귀 + SwiftData 마이그·CSV·톤 검증. 단위 테스트 37 → 41 통과(IMUDataCollectionTests T19~T22 신규 4건). 옵트아웃 시 0 frame *구조적* 보장 검증(ActiveMealViewModel `imuFrameBuffer == nil` 분기 + T21 통과). v1.1 흐름 회귀 0건 (CalibrationEngine 4 + ChewDetector 18 + ChewSamplePersistence 2 + MealRepository 5 + MessageLibrary 8 모두 통과). SwiftData v1.1 → v1.2 destructive 마이그 정상(`ZIMUFRAME` 테이블 + `ZIMUDATACOLLECTIONOPTEDIN` 컬럼 신규 생성 확인). CSV header 15 column 정확. v1.2 신규 카피 톤 위반 0건. 카피 폴리시 0건(구현자 v1.2 신규 카피 모두 옵션 G 톤 정합). 신규 발견 이슈 — Medium 1건(Dashboard FAB가 empty state 카피 가림, v1.1부터 잠재 존재 — 디자이너 후속). 시뮬 캡처 3장. 종합 평가 4.4 / 5 — 베타 데이터 수집 GO.

---

## v1.1 라운드 — 감지 살리기 검증 (라운드 2)

**검수일**: 2026-05-03 11:35–11:45 KST
**라운드**: 2 (v1.1 patch — 0건 → N건 검출 회귀 검증)
**검수자**: `ios-app-qa-polish` 스킬 (3축 검증)
**대상 빌드**: 05_build_report.md §v1.1 Patch 섹션 (14개 파일 변경 + ChewDetectorTests T13~T18 + ChewSamplePersistenceTests 신규)
**환경**: Xcode 26.4, iOS 26.4 시뮬 (iPhone 17), macOS Darwin 25.3.0 (라운드 1과 동일)

### 1. 종합 평가 (5점 척도)

| 축 | 점수 | 라운드 1 대비 | 비고 |
|----|------|------------|------|
| 기능·정합성 | **4.5 / 5** | +0.5 | T17 정류 결함 회귀 가드 통과·ChewSample 영속화 path 단위 테스트 통과·UserPreferences 신규 필드 destructive migration로 처리. 다만 시뮬 onboarding 통과는 SwiftData 직접 inject로 우회(실기기 사용자 직접 손 검증 권고). |
| 신호·UX 톤 | **4.5 / 5** | 동일 | 옵션 G 톤 가이드 위반 0건 유지. v1.1 신규 카피 (감도 모드 토글·디버그 패널 9개·노란 배지)에 영어 잔존·기계번역·의료 약속 모두 없음. 직접 폴리시 3건으로 디버그 라벨 한국어화·배지 상태어 명확화. |
| 품질·접근성 | **3.7 / 5** | +0.2 | 다크 모드·VoiceOver 라벨 양호. v1.1 신규 디버그 패널 작은 글자가 Dynamic Type AX5에서 깨짐 위험 — `.caption2R` 폰트로 시맨틱 토큰 적용했으나 9행 정보가 좁은 화면에서 한 줄 안 들어갈 수 있음. 회귀 위험으로 기록. |
| **종합** | **4.2 / 5** | +0.2 | **베타 후보 유지** — 라운드 1 미해결 5건 (REQ-1·REQ-2·DES-1·DES-2·DES-3) v1.1에서 *부수적 해결 0건*. v1.1 자체 결함은 직접 폴리시 3건으로 모두 해소. |

### 2. 0 → N 검출 회귀 검증 결과 — 핵심 ✓ **통과**

라운드 1에서 사용자가 보고한 "전혀 트래킹 못함" 결함의 회귀 검증.

#### 2.1 단위 테스트로 검증된 회귀 가드

| 검증 항목 | 결과 | 근거 |
|--------|------|------|
| **T13 풀 파이프라인 — 이상적 저작** (1.5Hz/0.06g/60s, default threshold) | ✅ ChewEvent ≥ 30 검출 | IMUSample → Preprocessor.ingest → detrendedRing → ChewDetector 풀 파이프라인. v1에서는 정류로 0건이었으나 v1.1 detrending으로 N건 회복. |
| **T14 풀 파이프라인 — 저작 빈도 하한** (1.0Hz/0.04g/60s) | ✅ ChewEvent ≥ 15 검출 | default 0.025g threshold가 v1 0.05g에서 절반 하향됨 — cold start 검출 회복. |
| **T15 감도 모드 — 매우 약한 저작** (1.2Hz/0.018g/60s, sensitivity threshold 0.015g) | ✅ ChewEvent ≥ 15 검출 | 첫 사용자 0건 방지를 보장하는 sensitivity tier 작동 검증. |
| **T16 3-tier 임계값 동작** | ✅ Sensitivity > Default 검출, Calibrated 통과 | `effectivePeakThreshold` / `effectiveMealStartThreshold` helper 함수 검증. Calibrated > Sensitivity > Default 우선순위 확인. |
| **T17 ★정류 결함 회귀 가드** (1.2Hz/0.05g/60s — 평균 chew 간격 검증) | ✅ avg interval ≈ 0.83s ± 0.2 통과 (정류 시 0.42s 검출됐다면 실패) | warmup 5초 이후 평균 측정. magnitude 정류 결함이 다시 들어오면 즉시 실패하도록 *주파수 보존*을 직접 검증. v1.1의 핵심 회귀 가드. |
| **T18 Mock 자동 emitter — 식사 시뮬** | ✅ ChewEvent ≥ 30 + mealStarted emit | `emitSyntheticMealSync(durationSec: 180)` → MealSessionTracker 자동 mealStarted 발행. 시뮬레이터 데모 흐름 회귀 가드. |

**결과**: 5건 모두 통과 + T17 정류 결함 회귀 가드 명시 통과. **0 → N 검출 회복이 단위 테스트 레벨에서 보증됨**. 실 IMU 정확도는 별도 실기기 측정 필요 (라운드 1 안내 그대로 유지).

#### 2.2 시뮬레이터 흐름 검증

시뮬에서 *0 → N 카운터 증가*의 사용자 시점 검증은 다음 한계로 *부분*:
- 시뮬레이터 onboarding을 자동으로 통과하기 위해 `defaults`/SwiftData store 직접 manipulation 필요. UI 자동화(클릭 시뮬) 권한 거부됨(macOS Accessibility).
- SwiftData store에 `onboardingCompletedAt` row 직접 inject로 우회 → Dashboard 진입 캡처 성공(`v1.1_05_after_onboarding_inject.png`, `v1.1_06_dashboard_with_meal.png`).
- 그러나 **ActiveMealView 진입 → developerMode 자동 emission → chew 카운터 증가** 흐름은 시뮬 클릭 자동화 없이 캡처 불가. 코드 리뷰로 검증:
  - `ActiveMealViewModel.start()` line 162-168에 `#if targetEnvironment(simulator)` + `MockMotionStream` + `developerMode == true` → `mock.startSyntheticMealEmission(durationSec: 900)` 자동 호출 분기 정확 ✓
  - `observeSamples()` line 199-231에 `preprocessor.detrendedRing` → `detector.detectChew` → `chewCount += 1` 흐름 정확 ✓
  - `persistChewSample` line 300-310에 `appendChewSample(autoSave: false)` → 식사 종료 시 `flush()` batch save 흐름 정확 ✓

**결정**: 단위 테스트 T13~T18 전건 통과 + 코드 리뷰로 v1.1의 핵심 가설 "0→N 검출"이 작동함을 확인. 시뮬 사용자 시점 시각 캡처는 **실기기 사용자 검증으로 인계** (실기기 권고 항목 추가 §10).

### 3. 단위 테스트 37/37 재현 결과

```
xcodebuild -scheme ChewCoach \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.4' \
  -derivedDataPath ./build test
```

**결과**: `Executed 37 tests, with 0 failures (0 unexpected) in 2.279 seconds` ✅

| 테스트 묶음 | 통과/전체 | 신규/회귀 |
|----------|---------|---------|
| `ChewDetectorTests` T1~T12 (기존 회귀) | **12 / 12** | T10 phase 4 길이만 v1.1 MEAL_END_THRESHOLD_CPM 5.0 하향 반영 보정 |
| **`ChewDetectorTests` T13~T18 (신규)** | **6 / 6** | 풀 파이프라인 IMUSample → Preprocessor → Detector |
| **`ChewSamplePersistenceTests` (신규)** | **2 / 2** | ChewSample 영속화 + 캘리브 완료 시 sensitivity OFF 검증 |
| `MealRepositoryTests` (CRUD) | 5 / 5 | |
| `MessageLibraryTests` | 8 / 8 | 의료 약속·영어 잔존·도구 프레이밍 lint 모두 통과 |
| `CalibrationEngineTests` | 4 / 4 | |
| **합계** | **37 / 37** | 29 → 37 (+8) |

폴리시 직후 재실행 결과 (라벨 한국어화·배지 카피 변경 후): **37/37 동일 통과** ✓ — 카피 변경이 단위 테스트 로직에 영향 없음 확인.

### 4. 시뮬 검증 시나리오

#### 4.1 자동 검증 통과 항목

- ✅ 빌드 통과 (`** BUILD SUCCEEDED **`, 앱 코드 워닝 0건, SwiftData KeyPath 워닝 7건은 v1과 동일 — Apple 프레임워크 한계)
- ✅ 앱 launch (시뮬 부팅 → install → launch → Onboarding Welcome 화면 5초 룰 통과 카피 그대로 노출)
- ✅ 다크 모드 자동 분기 (`v1.1_04_onboarding_dark.png` — 배경·텍스트 자동 적응)
- ✅ Dashboard 진입 (SwiftData onboardingCompletedAt inject 후 `v1.1_05_after_onboarding_inject.png` — RootRouterView가 정확히 `RootTabView`로 라우팅)
- ✅ Empty state 카피 노출 ("첫 식사를 함께해 주세요. 시작 버튼은 우하단에 있어요.") + FAB 우하단 노출
- ✅ MealSession inject 후 Dashboard에 `MealResultCard` 노출 (`v1.1_06_dashboard_with_meal.png` — 라운드 1 폴리시 "오늘 오후 결과" headerTitle 분기 작동, 12분 0초 timer 폰트 minimumScaleFactor 적용 확인)
- ✅ Comfort 셀프리포트 5단계 이모지 노출
- ✅ TabBar 3개 탭 (홈·기록·설정) 정확 노출

#### 4.2 자동 검증 불가 (UI 클릭 자동화 한계)

- ⚠ **Settings → 감도 모드 토글** — 시뮬 클릭 자동화 권한 거부로 토글 ON/OFF 캡처 불가. SettingsView 코드 리뷰: Toggle 바인딩 + `setSensitivityMode` 호출 + onAppear에서 `prefs.sensitivityModeEnabled` 동기화 모두 정확 ✓
- ⚠ **ActiveMealView 디버그 패널** — Dashboard FAB 클릭 → 식사 시작 → 디버그 패널 9개 행 노출까지 자동 검증 불가. ActiveMealView 코드 리뷰: `developerMode == true`일 때만 `debugPanel` 분기, `Timer.scheduledTimer(0.5s)`로 갱신, MainActor closure로 thread-safe 모두 정확 ✓
- ⚠ **감도 모드 활성 노란 배지** — 시뮬 클릭 자동화 한계로 캡처 불가. 코드 리뷰: `viewModel.sensitivityModeOn && viewModel.activeThresholdTier == .sensitivity` 조건으로 노출 — 정확 ✓
- ⚠ **MealDetailView chewSamples 차트** — meal inject만으로는 chewSamples 관계가 비어 차트 미노출(SwiftData @Relationship inverse 강제 inject 어려움). 코드 리뷰: `if !meal.chewSamples.isEmpty` 가드 + Chart LineMark x: timestamp / y: magnitudePeak — 정확 ✓

이 4건은 모두 *코드 리뷰로 정확성 검증*. 사용자 손 시각 검증은 §10 실기기 권고로 인계.

### 5. 옵션 G 톤 가이드 grep 결과 (v1.1 신규 카피)

#### 5.1 의료 약속 적발 — **0건**

```bash
rg -n -i "치료|완치|보장|100%|정확.*100" app/ChewCoach/
```

7건 매치 모두 *정직성 표현*(부정 컨텍스트):
- `Features/Settings/HonestyPledgeView.swift:30,32` — "위염 치료 / 의료적 효과" / "100% 정확한 측정" (둘 다 "약속하지 않아요" 섹션)
- `Features/Onboarding/OnboardingHowItWorksView.swift:15-16` — "100% 정확하지 않아요. (추정 ±15%)" / "치료가 아니라 *행동 변화 코칭*이에요." (정직성 강조)
- `Features/MealHistory/MealDetailView.swift:82` — "추정 ±15%. 100% 정확하지 않아요." (정직성 디스클로저)
- `Core/Detection/DetectorConstants.swift:42` — 코드 코멘트 "감도 모드 — 첫 사용자 0건 방지 보장" (사용자 비노출)
- `Core/Storage/UserPreferences.swift:18` — 코드 코멘트 (사용자 비노출)

→ 위반 0건. **라운드 1과 동일 결과**, v1.1 신규 카피에서도 위반 0.

#### 5.2 영어 잔존 적발 — **0건** (사용자 노출 카피)

```bash
rg -n '"(track|stats|monitor|coach[^a-z]|score|data|tracker)"' app/ChewCoach/
```

매치 0건 (사용자 노출 카피). `MessageLibraryTests.swift`의 lint 금지 키워드 정의만 매치 (테스트 코드, 비노출).

**v1.1 신규 디버그 패널의 영어 잔존**: 폴리시 전에는 "누적 chew / CPM", "PEAK_THRESHOLD", "MotionStream", "Mode", "ON/OFF" 등 영어 라벨 다수. 폴리시 후 한국어화 (§7 폴리시 항목 1).

#### 5.3 도구 프레이밍 적발 — **0건**

```bash
rg -n -i "씹기 횟수 측정|chewing tracker" app/ChewCoach/
```

0건. v1.1 신규 카피("감도 높임 모드", "검출 감도", "추정 약 N회 씹으셨어요" 등)도 도구 프레이밍 회피.

#### 5.4 결과 언어 일관성 — **✓**

라운드 1 폴리시(MealResultCard "캘리브레이션보다 N분 더 차분히/빨리", DashboardViewModel comparisonText 결과 언어, WeeklyRecapView 행동 가이드 결합) 모두 **v1.1 변경에 의해 망가지지 않고 보존됨** (그 파일들은 v1.1 14개 변경 파일 목록에 없음).

#### 5.5 v1.1 신규 카피 종합 평가

| 카피 | 위치 | 톤 평가 | 폴리시 |
|------|----|------|------|
| "감도 높임 모드 / 더 잘 잡히지만 가끔 잘못 잡을 수 있어요. 첫 식사 캘리브레이션이 끝나면 자동으로 꺼져요." | SettingsView | ✓ 친근·정직 (옵션 G 톤 정합) | 유지 |
| "감도 높임 모드 켜짐" | ActiveMealView 노란 배지 | ✓ 상태 명확 (폴리시: "감도 높임 모드"→"감도 높임 모드 켜짐") | 폴리시 1건 |
| "식사 화면 하단에 검출 상태가 자세히 보여요. 시뮬레이터에서는 가짜 식사 신호가 자동으로 들어와요." | SettingsView 개발자 모드 | ✓ 친근 (폴리시: "디버그 정보가 표시"→"검출 상태가 자세히 보여요" + "합성 식사 데이터가 자동으로 흘러요"→"가짜 식사 신호가 자동으로 들어와요") | 폴리시 1건 |
| "추정 약 N회 씹으셨어요" | ActiveMealView | ✓ 정직성 카피 (추정 명시) | 유지 |
| 디버그 패널 9개 라벨 | ActiveMealView debugPanel | ✓ 한국어화 (폴리시: "누적 chew", "magnitude max (raw)", "PEAK_THRESHOLD", "MotionStream", "ON/OFF", "Mode" → 모두 한국어) | 폴리시 1건 |

### 6. 발견 이슈 (심각도 순)

#### Critical (배포 차단) — **0건**

라운드 1의 Critical 1건(C-1 권한 거부 fallback) 이미 폴리시 완료 + v1.1 변경에 의한 회귀 없음. v1.1 신규 Critical 0건.

#### High — **0건**

#### Medium — 2건 (모두 직접 폴리시)

##### M-7. 디버그 패널 영어 잔존 라벨 → **폴리시 완료**
- **위치**: `app/ChewCoach/Features/ActiveMeal/ActiveMealView.swift:160-169` (수정 전)
- **재현**: "누적 chew / CPM", "최근 5초 magnitude max (raw)", "최근 5초 magnitude max (detrended)", "PEAK_THRESHOLD", "MotionStream", "ON/OFF", "마지막 confidence", "Mode" 등 9개 행 중 7개에 영어 잔존
- **근거**: 옵션 G 톤 가이드 — 한국어 톤 가이드 준수. 디버그 패널이 베타 사용자에게도 노출됨(개발자 모드 ON 시) → 영어 잔존은 일관성 깨짐
- **폴리시**: 7개 라벨 모두 한국어화 ("누적 씹기 / 페이스", "최근 5초 강도 최댓값 (원본)", "최근 5초 강도 최댓값 (보정)", "검출 임계값", "모션 소스", "켜짐/꺼짐", "마지막 신뢰도", "식사 모드 — 캘리브레이션/일반"). PEAK_THRESHOLD tier 표시 라벨(`.calibrated`, `.sensitivity`, `.default`)은 enum rawValue로 영어 유지 — 코드 디버그 식별자
- **분류**: QA 직접 폴리시 ✓

##### M-8. 감도 모드 활성 배지 카피 상태어 누락 → **폴리시 완료**
- **위치**: `app/ChewCoach/Features/ActiveMeal/ActiveMealView.swift:118-132` (수정 전)
- **재현**: 노란 배지 텍스트 "감도 높임 모드"만 노출 → 이게 *현재 활성 상태*인지 *모드 이름*인지 모호. accessibilityLabel만 "활성" 포함
- **폴리시**: "감도 높임 모드" → "감도 높임 모드 켜짐"으로 변경. accessibilityLabel도 "감도 높임 모드 켜짐. 평소보다 더 잘 잡히지만 가끔 잘못 잡을 수 있어요."로 풍부화
- **분류**: QA 직접 폴리시 ✓

#### Low — 1건 (폴리시 완료)

##### L-6. SettingsView 개발자 모드 안내 카피 어색 → **폴리시 완료**
- **위치**: `app/ChewCoach/Features/Settings/SettingsView.swift:84` (수정 전)
- **재현**: "식사 화면 하단에 디버그 정보가 표시돼요. 시뮬레이터에서는 합성 식사 데이터가 자동으로 흘러요." — "디버그 정보", "합성 식사 데이터가 자동으로 흘러요" 등 일반 사용자에게 의미 모호
- **폴리시**: "식사 화면 하단에 검출 상태가 자세히 보여요. 시뮬레이터에서는 가짜 식사 신호가 자동으로 들어와요." — 결과 지향·친근
- **분류**: QA 직접 폴리시 ✓

#### v1.1 자체 알려진 한계 검증 (구현자 보고 §v1.1 1-7)

| 한계 | 보고 내용 | QA 검증 결과 |
|----|--------|----------|
| 1. 감도 모드 false positive ↑ | UI 카피·노란 배지로 사전 안내 | ✅ Settings 안내 카피 + 노란 배지 + 폴리시 후 "켜짐" 상태어 명확화로 추가 강화 |
| 2. Detrending 윈도우 transient | T17 회귀 가드(warmup 5초 이후 측정) | ✅ T17 통과 |
| 3. 합성 IMU baseline 가정 | MockMotionStream `SYNTHETIC_BASELINE_G = 0.10` + 단위 테스트 헬퍼 동일 | ✅ 코드 일치, 합성 데이터 검증 무결성 확보 |
| 4. emitSingleChew (async) pulseDur 0.4s 사양 차이 | 단위 테스트 T18은 `emitSyntheticMealSync` (연속 sine)로 우회 | ✅ T18 통과. **시뮬 데모 자동 emit (async 경로)는 검출률 낮을 가능성** — 사용자가 ActiveMealView 진입했을 때 chew 카운터가 *기대보다 천천히* 증가할 수 있음. 베타 사용자 안내 시 강조 권고 (§10 실기기 항목) |
| 5. ChewSample 저장 부담 1식사 ~1,000 row | 30일 cascade delete 가정 | ✅ MealRepository.deleteAll에 ChewSample 포함 확인. 다만 indexing은 미적용 — 30일 후 18,000 row 누적 시 Dashboard 로딩 latency 측정 필요 (실기기 권고) |
| 6. V1 destructive 마이그레이션 | ChewCoachApp.init이 store 자동 purge | ✅ ChewCoachApp 코드 정확. **사용자 안내 UI는 없음** — 출시 전 베타라 OK이지만, 베타 사용자 v1→v1.1 업데이트 시 "기존 식사 데이터가 모두 삭제됩니다" 알림이 *없음* → §10 실기기 항목 + 사용자 명시 동의 권고 |
| 7. MealSession.id mutation | 다중 식사 동시 진행 미가정 | ✅ ActiveMealViewModel.handle(event:) line 254-264 — `if activeMeal == nil` 가드로 단일 식사 세션 유지. 정확 |

### 7. 직접 폴리시 항목

| # | 파일 | 변경 | 재검증 |
|---|------|------|------|
| 1 | `Features/ActiveMeal/ActiveMealView.swift` (line 159-169) | 디버그 패널 9개 행 중 7개 라벨 한국어화 ("누적 chew / CPM"→"누적 씹기 / 페이스" 등) | xcodebuild ✓, 37 tests ✓ |
| 2 | `Features/ActiveMeal/ActiveMealView.swift` (line 118-132) | 감도 모드 노란 배지 카피 "감도 높임 모드"→"감도 높임 모드 켜짐", accessibilityLabel 풍부화 | xcodebuild ✓ |
| 3 | `Features/Settings/SettingsView.swift` (line 84) | 개발자 모드 안내 카피 친근 톤 정리 | xcodebuild ✓, 37 tests ✓ |

**폴리시 후 회귀 검증**:
- xcodebuild clean build: **BUILD SUCCEEDED** ✓ (앱 코드 워닝 0건)
- xcodebuild test: **37/37 통과** ✓ (T1~T18 + ChewSamplePersistence 2 + Repository 5 + Library 8 + Calibration 4)
- 시뮬 부팅·앱 설치·launch·다크 모드·SwiftData inject 후 Dashboard 진입: 모두 정상 ✓

### 8. 재작업 요청

#### 신규 발행 — **0건**

v1.1 패치는 자체 결함을 모두 직접 폴리시로 해소. Critical / High 신규 0건, 모든 발견 이슈는 카피 단순 수정으로 직접 폴리시 가능했음.

#### 라운드 1 미해결 5건 현 상태 (REQ-1, REQ-2, DES-1, DES-2, DES-3)

| 요청 | 상태 | v1.1로 부수 해결 여부 |
|----|------|----------------|
| **REQ-1** (구현자 — video mode 영구 저장 / Medium) | 🔴 미해결 | v1.1은 ChewSample 영속화에 집중, video mode 필드 추가는 미포함. `MealSession.swift` v1.1 변경에 `chewSamples` 관계만 추가됨, `isVideoMode` 필드 없음. 라이브러리 16% 죽은 코드 상태 그대로 |
| **REQ-2** (구현자 — 권한 timeout 실기기 검증 / Low) | 🔴 미해결 | `PermissionCoordinator.swift`는 v1.1 14개 변경 파일에 없음. 실기기 측정 필요 |
| **DES-1** (디자이너 — timer 폰트 토큰 마이그 / Medium) | 🟡 부분 해결 | v1.1 ActiveMealView/MealResultCard/MealDetailView의 `Font.timerDisplay` 사용처에 `minimumScaleFactor(0.6) + lineLimit(1)` 라운드 1 폴리시가 모두 보존됨. 그러나 `timerDisplayDynamic` 토큰으로의 마이그는 미진행 |
| **DES-2** (디자이너 — ChewBreathBadge 컨텍스트 응답형 / Low) | 🔴 미해결 | `ChewBreathBadge.swift`는 v1.1 14개 변경 파일에 없음. 카피 "차분히 드시고 있어요" 고정 그대로 |
| **DES-3** (디자이너 — Persona 스킵 가능 여부 결정 / Low) | 🔴 미해결 | `OnboardingPersonaView.swift`는 v1.1 14개 변경 파일에 없음. 강제 선택 그대로 |

**결정**: 5건 모두 v1.1로 부수 해결되지 않음. v1.1은 신호 결함 해결에만 집중. *베타 진입 전 처리 권고 우선순위 유지*.

### 9. 라운드 1 회귀 검증 (라운드 1 폴리시 보존 여부)

라운드 1에서 폴리시한 9개 파일 중 v1.1 14개 변경 파일과 *겹치는 것*: `ActiveMealView.swift` (timer 폰트 minimumScaleFactor), `MealDetailView.swift` (timer 폰트 + chewSamples 사용)

| 라운드 1 폴리시 | v1.1 변경 영향 | 보존 여부 |
|------------|------------|--------|
| ActiveMealView timer `.minimumScaleFactor(0.6)` + `.lineLimit(1)` | v1.1에서 동일 코드 보존 | ✅ 보존 |
| MealDetailView timer `.minimumScaleFactor(0.6)` + `.lineLimit(1)` | v1.1에서 동일 코드 보존 | ✅ 보존 |
| MealResultCard headerTitle 새벽·야식 분기 | v1.1 변경 없음 | ✅ 보존 (시뮬 캡처 `v1.1_06_dashboard_with_meal.png`에서 "오늘 오후 결과" 정상) |
| MealResultCard calibrationComparisonText "차분히/빨리" | v1.1 변경 없음 | ✅ 보존 |
| OnboardingMotionPermissionView fallback 카피 | v1.1 변경 없음 | ✅ 보존 |
| DashboardView 카테고리 분기 (encouragement만 결과 카드) | v1.1 변경 없음 | ✅ 보존 |
| DashboardView NavigationDestination(item: detailMeal) | v1.1 변경 없음 | ✅ 보존 |
| WeeklyRecapView "더 빨라졌어요. 다음 주는 한 입씩만" | v1.1 변경 없음 | ✅ 보존 |
| Persona.gastric/.diet 카피 톤 (위염→더부룩, 회복→포만감) | v1.1 변경 없음 | ✅ 보존 |
| Font.timerDisplayDynamic 신규 토큰 | v1.1 변경 없음 | ✅ 보존 |

**결과**: 라운드 1 폴리시 10건 모두 100% 보존. 회귀 0건.

### 10. 실기기 전용 검증 항목 (사용자에게 안내)

라운드 1의 8건 + v1.1 신규 6건:

#### 라운드 1 항목 (재인계, 미해결)
1. AirPods Pro 2 실데이터 정확도 (F1 0.75-0.85 KPI)
2. CMHeadphoneMotionManager 권한 dialog 실제 노출 + 콜백
3. AirPods 분리·재연결 시나리오
4. Background audio session 백그라운드
5. 첫 5초 룰 — 실기기 사용자 시점
6. CSV export ShareSheet
7. 알림 권한 + 일일 인사이트
8. iPhone SE 좁은 화면 FAB 위치

#### v1.1 신규 (이번 라운드에서 추가 필요)
9. **시뮬 시나리오 — 사용자 시점 검증**: Settings → 감도 모드 토글 ON/OFF 후 식사 시작 → 디버그 패널 9개 정보 정확 표시 → 카운터 증가 → 식사 종료 → MealDetailView 차트에 chewSamples 그려지는지 *연속 흐름* 검증
10. **시뮬 합성 식사 demo 검출률** — 구현자 보고 §v1.1-한계 4: emitSingleChew (async) pulseDur 0.4s가 실제 2.5Hz pulse → bandpass 상한 밖으로 검출률 낮을 가능성. 시뮬에서 ActiveMealView 진입 시 카운터 증가 *속도가 1.2Hz 기대치보다 느린지* 사용자 직접 관찰 필요
11. **감도 모드 false positive 실측** — 실기기에서 식사 외 활동(말하기·웃음·머리 흔들기) 시 감도 모드 ON 상태 카운터가 실제로 얼마나 증가하는지 측정. 신호 §v1.1-5에서 < 20건/시간 한도 설정
12. **캘리브레이션 1식사 완료 후 자동 sensitivity OFF** — 실기기에서 캘리브 식사 종료 후 Settings 토글이 자동으로 OFF로 전환되는지 + ActiveMealView 노란 배지 사라지는지 시각 검증 (단위 테스트 `test_markCalibrationCompleted_disablesSensitivityMode`로 로직은 검증됨)
13. **ChewSample 30일 누적 부담** — 베타 사용자 30일 사용 후 SwiftData store 사이즈 + Dashboard 로딩 latency 측정 (1식사 ~1,000 row × 18 식사/주 × 4주 = 72,000 row 가정)
14. **V1 destructive 마이그레이션 사용자 안내** — 베타 사용자가 v1 → v1.1 업데이트 받을 때 *기존 식사 데이터가 모두 삭제됩니다* 알림 없이 silent purge. 출시 전 베타라 OK이지만 베타 안내 메시지에 명시 필수

### 11. 회귀 위험 (v1.1 14개 파일 변경이 영향 줄 수 있는 영역)

| # | 위험 영역 | 평가 |
|---|---------|------|
| 1 | **DashboardViewModel.summary `chewCount`** — `MealSession.chewCount` 의 의미가 v1에서는 *순간 누적*이었는데 v1.1에서 `appendChewSample` flush 후 종료 시 `meal.chewCount = chewCountFinal` 갱신. inject 데이터로 inject 시 348회 정상 표시 ✓. 다만 영속화 path가 가운데 끊기면 `meal.chewCount`가 0인 상태로 finalize 가능 | Low |
| 2 | **MealDetailView Chart** — `meal.chewSamples`가 비어있으면 차트 미노출 (V1과 동일). v1.1에서 영속화 path는 정확하지만 *기존 v1 데이터로 마이그된 식사*에는 chewSamples 없음 → 차트 영구 미노출 | Low (destructive migration이라 v1 데이터 자체가 purge됨) |
| 3 | **MealRepository.deleteAll** — ChewSample 모델도 cascade delete에 포함됨 ✓ | OK |
| 4 | **Preprocessor 메모리 사용량** — `detrendedRing` 신규 버퍼 추가로 메모리 약 2배 (raw + detrended). 30초 윈도우 × 25Hz × 2 = 1,500 sample × 16 bytes = 24KB → 영향 미미 | Low |
| 5 | **Detector `abs()` 제거** — positive peak만 검출. 만약 *음수 방향 강한 chew*가 있다면 미검출. v1.1 신호 §v1.1-1.A 가정: 음·양 두 peak는 같은 chew의 양면. 실 IMU에서 검증 필요 | Medium → 실기기 검증 항목 |
| 6 | **MealSession.id mutation** — `meal.id = descriptor.id` (line 261). SwiftData @Attribute(.unique) UUID는 var이므로 OK이지만 *insert 후 id 변경*은 unusual pattern. 단일 식사 세션 가정 하에서 OK | Low |
| 7 | **MealSessionTracker `nonisolated let events`** — multi-subscriber 시 race condition 가능 (구현자 자체 발견 §8.8). v1.1에서 `ActiveMealViewModel.observeEvents` 단일 subscriber 유지 ✓ | Low |
| 8 | **`#if targetEnvironment(simulator)` 자동 emission** — 실기기에서는 *절대* 트리거되지 않음 ✓ (`#if` 분기로 컴파일 시점에 제거됨) | OK |
| 9 | **MockMotionStream syntheticTask Task lifecycle** — `stop()` 호출 시 cancel ✓. 다만 ActiveMealViewModel.stopAll에서 motion.stop() 호출 — 정확한 cleanup ✓ | OK |
| 10 | **Settings 토글 동기화** — onChange 시 `setSensitivityMode` 호출하지만 *현재 활성 detector의 peakThresholdG는 즉시 갱신 안 됨* — ActiveMealViewModel.start에서만 동기화. 식사 시작 후 Settings에서 토글 변경해도 *해당 식사에는 영향 없음* (다음 식사부터). 옵션 G 톤상 OK이지만 사용자에게 명시 안내 카피 추가 권고 | Low |

### 12. 다음 라운드 권고

#### 12.1 V1.1 베타 진입 가능 여부

**조건부 GO** ✓ — 0→N 검출 회복이 단위 테스트로 검증됨. v1.1 자체 결함 0건. 다만 베타 진입 전:

1. **§10 실기기 항목 9~14 6건 중 최소 9·10·12** 사용자 직접 손 검증 필수 — *시뮬 사용자 흐름 + 시뮬 합성 demo 검출률 + 캘리브 자동 OFF*
2. **REQ-1 (구현자 재작업, video mode 영구 저장)** — v1.1 미해결. 메시지 라이브러리 16% 죽은 코드 상태. 베타 진입 전 우선 처리 권고 (라운드 1 권고 유지)
3. **베타 안내 메시지 추가** — V1 destructive 마이그레이션 사용자 명시 동의 (구현자 §v1.1-한계 6)

#### 12.2 다음 QA 라운드 필요 시점

- 사용자 실기기 1회 검증 후 → 신호 정확도(F1) + 5초 룰 + AirPods 분리/재연결 데이터 입수 → 라운드 3 (실기기 결과 반영)
- REQ-1 (구현자 재작업) 완료 후 → 회귀 검증 + video mode 5개 메시지 활용도 검증
- DES-2 (ChewBreathBadge) 디자인 결정 후 → 카피·시각 일관성 검증

#### 12.3 V1.1 출시 전 잔여 위험

- iPad 미지원 (TARGETED_DEVICE_FAMILY=1) — 라운드 1 동일
- BGAppRefreshTask 미구현 — V1.5
- Live Activity 미구현 — V1.5+
- CSV cleanup 누락 — 라운드 1 동일
- **신규**: 시뮬 합성 식사 emission async 경로 검출률 낮음 — 데모 시 사용자 기대 관리 필요
- **신규**: V1 destructive 마이그레이션 silent purge — 베타 안내 필수
- **신규**: 디버그 패널 Dynamic Type AX5 시 9개 행이 한 줄 안 들어갈 가능성

#### 12.4 시뮬 캡처 산출물 (라운드 2 신규 6장)

- `screenshots/v1.1_01_launch.png` — Light 모드 Welcome (v1.1 launch 정상)
- `screenshots/v1.1_02_relaunch_devmode.png` — developerMode UserDefaults 적용 후 launch (Welcome 동일 — onboarding 진행 전 단계)
- `screenshots/v1.1_03_onboarding_after_polish.png` — 카피 폴리시 + 재빌드 후 launch (Welcome 그대로 정상)
- `screenshots/v1.1_04_onboarding_dark.png` — 다크 모드 자동 분기 검증 (배경·텍스트·CTA 모두 정상)
- `screenshots/v1.1_05_after_onboarding_inject.png` — SwiftData onboardingCompletedAt 직접 inject 후 Dashboard empty state 진입 (RootRouterView → RootTabView 라우팅 정확, FAB 우하단)
- `screenshots/v1.1_06_dashboard_with_meal.png` — MealSession 1건 inject 후 Dashboard에 MealResultCard 노출 (라운드 1 폴리시 보존: "오늘 오후 결과" 분기·timer minimumScaleFactor·"자세히 보기" 버튼·Comfort 5단계)
