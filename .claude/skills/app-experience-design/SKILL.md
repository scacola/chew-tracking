---
name: app-experience-design
description: 옵션 G "Chew & Calm Coach" iOS 앱의 화면 흐름·실시간 피드백·대시보드 시각화·온보딩·친근한 한국어 코칭 메시지 라이브러리를 SwiftUI 빌드 가능한 형태로 설계하는 방법론. Calm·Headspace·Oura급 헬스 앱 톤 + 한국 위장 페르소나 적용. iOS 앱 UX 설계, 코칭 메시지 라이브러리, 대시보드 시각화 설계 시 반드시 사용.
---

# App Experience Design

iOS 앱의 *정보 흐름 + 인터랙션 + 시각 + 코칭 톤*을 한 패키지로 설계한다. 픽셀 시안이 아니라 *SwiftUI 빌드 가능한 명세*. `app-experience-designer` 에이전트가 사용한다.

## 왜 이 스킬이 필요한가

헬스 앱 UX 설계의 흔한 실패:
- "씹기 트래커"로 포지셔닝 → 옵션 G 결과 프레이밍 위반
- 의료적 약속 ("위염 치료") → 법적·신뢰 리스크
- 코칭 메시지가 *영어 기계번역* 톤
- 권한 요청 일괄 → 거부율
- 영상 시청 중 알림 거슬림 (회피 휴리스틱 누락)
- 픽셀 시안에 시간 낭비 → SwiftUI는 컴포넌트·토큰만 정확하면 빌드 가능
- 다크 모드·Dynamic Type 사후 대응

이 스킬은 *결과 프레이밍 + 다노식 친근 톤 + 컴포넌트 명세 + 코칭 라이브러리*를 강제한다.

## 입력 컨텍스트 우선 확인

다음 파일에서 *페르소나·톤·검출 가능 신호*를 인용 가능한 형태로 정리:
- `discovery_report.md` 옵션 G 섹션 — 페르소나 (한지원·박소연·김상훈), 결과 프레이밍, MVP 5기능
- `_workspace/04_product_ideation.md` 옵션 G — 페르소나 인용·코칭 가설
- `_workspace/app/01_signal_processing.md` — 검출 가능 신호 종류·정확도·지연 (UX 가능성 정의)

## 옵션 G 톤 가이드 — 5대 원칙

### 1. 결과 프레이밍
*"씹기 트래커"가 아닌 *위 건강·체중 결과 코치*. 모든 카피가 결과 언어로.

| 도구 언어 (금지) | 결과 언어 (권장) |
|---------------|---------------|
| "분당 씹기 횟수" | "오늘은 평소보다 차분하게 드셨네요" |
| "식사 시간 측정 완료" | "11분 — 어제보다 3분 천천히" |
| "정확도 87%" (전면) | (필요 곳에만 "추정 ±15%") |

### 2. 다노식 친근 + 임상 권위 균형
- 다정하게: "오늘 8분에 드셨어요. 다음 식사를 11분에 가볼까요?"
- 권위는 *근거 인용*으로: "5분 미만 식사가 위염 위험을 +71% 높인다는 연구가 있어요"
- 잔소리·비난 톤 금지: "왜 또 빨리 드셨어요?" ❌

### 3. 거짓 약속 금지
| 약속 OK | 약속 금지 |
|--------|---------|
| "식사 패턴을 추정으로 보여줍니다" | "위염 치료에 도움" |
| "결과 경향성 알림" | "100% 정확한 칼로리" |
| "행동 변화 코칭" | "체중 감소 보장" |

### 4. 5초 룰 (앱 버전)
- 첫 실행 5초: "이게 무슨 앱인지" 답 가능
- 첫 식사 종료 5초: "오늘 결과가 뭔지" 답 가능
- 화면 진입 1초: "여기서 뭐 하라는 건지" 답 가능

### 5. 모바일·점심·한 손 컨텍스트
- 한지원 페르소나 = 점심 12분, 영상 시청, 한 손
- 카드 한 장에 한 메시지
- 오른손잡이 thumb zone 우선 CTA 배치
- 영상 위 alert 거슬리지 않게: 토스트 < 햅틱 < 위젯 < 모달 (강도 순)

## 사용자 여정 맵 (7일 코어 루프)

| Day | 이벤트 | 화면·메시지 | 검증 가설 |
|-----|--------|-----------|---------|
| 0 | 첫 실행 | Onboarding (3-5단계) → 권한(모션) → 캘리브레이션 식사 1회 | 5초 룰: "AirPods로 식사 패턴을 보는 앱이구나" |
| 1 | 첫 일반 식사 | 자동 검출 → 종료 후 카드 1장 ("오늘 11분, 어제보다 3분 천천히") | 다음날 다시 열고 싶다 |
| 3 | 첫 위 컨디션 자기보고 | 식사 종료 시 1탭 자기보고 (1-5 stomach comfort) | 자기보고 1회 이상 완료 |
| 7 | 첫 주간 회고 + Discoveries 1개 | "이번 주 평균 9분 → 12분으로 개선", "월요일 점심이 가장 빨라요" | 7일차 retention |

V2에서 28일 코스·KOL 콘텐츠 추가. V1은 *측정·대시보드 + 코칭 카드 골격*만.

## 화면 인벤토리 (V1)

```markdown
### Screen: OnboardingFlow
- 진입: 첫 실행
- 단계:
  1. Welcome — "AirPods로 식습관을 자동으로 살펴봐요" (5초 룰)
  2. Personalize — 페르소나 빠른 선택 (위 건강 / 다이어트 / 마음챙김 — 옵션)
  3. Permission — 모션 권한 요청 (거부 시 수동 모드)
  4. Calibration intro — "이 한 끼만 평소처럼 드시면 다음부터 자동이에요"
- SwiftUI: TabView (PageTabViewStyle) + transition

### Screen: ActiveMealView
- 진입: 캘리브레이션 또는 사용자가 "식사 시작" 트리거
- 컴포넌트:
  - 큰 진행 시간 (mm:ss)
  - 추정 저작 수 (작게, 부속 정보로)
  - 종료 버튼 (큰 thumb-friendly)
  - 일시정지 버튼 (AirPods 분리 시 자동)
- 영상 시청 모드: 화면 dim + 위젯형 작은 카드만
- 상태: idle / active / paused / ending

### Screen: DashboardView
- 진입: 식사 종료 후 또는 탭바
- 컴포넌트 (스크롤):
  1. Today 카드 — 오늘 식사 수·평균 시간·코칭 메시지 1줄
  2. Comfort 카드 — 위 컨디션 자기보고 입력 (1-5 슬라이더)
  3. 식사 시간 추이 차트 (Swift Charts, 7일)
  4. Discoveries 카드 (V1.5) — "월요일 점심이 가장 빨라요"
  5. 주간 회고 진입 버튼

### Screen: MealHistoryView
- 진입: Today 카드 탭
- 컴포넌트: 식사 세션 리스트, 각 항목 (시각·시간·CPM·comfort)
- 상세 진입 시: 시간선 차트 + 코칭 메시지

### Screen: SettingsView
- 진입: 탭바 또는 프로필
- 항목: 권한 상태 / AirPods 호환성 안내 / 알림 / 데이터 내보내기 / 정보
```

각 화면을 이 형식으로 03_app_ux_spec에 모두 명세 (애스키 와이어 또는 텍스트 설명 포함, 픽셀 시안 X).

## 실시간 피드백 사양

| 컨텍스트 | 신호 | 강도 | 사용자 통제 |
|---------|------|------|-----------|
| Foreground active 식사 | 5분 경과 시 토스트 1회 | 약함 | off / 약 / 표준 |
| Audio session active (영상) | 햅틱 부드럽게 1회 | 매우 약함 | off / 약 |
| 식사 종료 검출 | 알림 + 카드 진입 유도 | 표준 | off / 표준 |
| 일일 인사이트 생성 | 알림 1회 (지정 시간 또는 첫 앱 진입) | 약함 | off / 약 |

원칙: *영상 시청 중엔 거슬리지 않게*. 알림 빈도 < 1회 / 식사.

## 코칭 메시지 라이브러리 (30개+ 템플릿)

카테고리:
- **격려** (10개) — "어제보다 천천히 드셨네요. 잘하고 계세요."
- **인사이트** (10개) — "월요일 점심이 평소보다 30% 빨라요. 회의 후라 그럴까요?"
- **자기인식 트리거** (5개) — "지금 화면을 보고 계신가요? 한 입씩 의식해서 드셔보세요."
- **축하** (5개) — "7일 연속 11분 이상! 지난 주보다 24% 천천히."

각 메시지 형식:
```yaml
- id: encouragement_slowed_down_d2d
  category: encouragement
  trigger: avgDuration_today > avgDuration_yesterday + 60sec
  template: "어제보다 {{deltaSec}}초 천천히 드셨네요. 잘하고 계세요."
  variables:
    - deltaSec: Int (초 단위)
  tone: 다정·격려
```

라이브러리는 03_app_ux_spec에 *YAML 또는 Swift enum stub*으로 첨부 → 구현자가 그대로 코드 변환.

**금지 표현 라이브러리도 함께:**
- "치료에 도움", "정확도 100%", "체중 감소 보장"
- "왜 또", "안 좋아요", "실패"
- 영어 잔존 ("track", "stats" 한국어 번역 필수)

## 디자인 토큰

```yaml
colors:
  brand_primary: "#5B7CFF"  # 차분한 파랑 (위 건강 톤)
  brand_accent: "#FFB54A"   # 식사 액센트
  text_primary: Color.label
  text_secondary: Color.secondaryLabel
  background_primary: Color.systemBackground
  background_grouped: Color.systemGroupedBackground
  positive: "#34C759"
  warning: "#FF9500"

typography:
  display: SF Pro Display, 32pt, semibold
  title1: SF Pro Display, 28pt, semibold
  body: SF Pro Text, 17pt, regular
  caption: SF Pro Text, 12pt, regular
  korean_fallback: System (Pretendard if installed)

spacing:
  xs: 4
  sm: 8
  md: 16
  lg: 24
  xl: 32

corner_radius:
  card: 16
  button: 12
  pill: 999
```

Apple 시스템 색·폰트 우선. 브랜드 액센트는 차트·CTA에만 절제 사용.

## 접근성 가드 (필수)

- VoiceOver 라벨: 모든 컨트롤·카드에 의미 있는 라벨
- Dynamic Type: 본문 텍스트는 `.body` 토큰 사용 (자동 스케일)
- 색 대비: WCAG AA 이상 (텍스트 4.5:1, 큰 텍스트 3:1)
- prefers-reduced-motion: 화면 전환 + 차트 애니메이션 비활성화
- VoiceOver만으로 핵심 흐름 가능: 온보딩 → 식사 시작 → 종료 → 대시보드
- Hit area: 최소 44×44pt

## 출력 — `_workspace/app/03_app_ux_spec.md`

다음 모두 포함:
1. 결론 한 줄
2. 페르소나 컨텍스트 (간결)
3. 7일 사용자 여정 맵
4. 화면 인벤토리 (V1 모든 화면)
5. 실시간 피드백 사양
6. 대시보드 시각화 명세 (차트 종류·색·라벨)
7. 온보딩 시퀀스 + 권한 흐름 시점
8. 코칭 메시지 라이브러리 30개+ (YAML 또는 Swift enum stub)
9. 디자인 토큰
10. 접근성 가드
11. 5초 룰 검증 시나리오

## 팀 통신 시 주의

- 신호 엔지니어가 "검출 지연 5–10초"라고 하면 → 실시간 햅틱은 *즉각 반응* 약속 안 하고, 사후 1회 알림으로 디자인
- 아키텍트가 "iOS 17+ 한정"이라고 하면 → SwiftData·Charts·Observation 적극 사용
- 충돌 시 *옵션 G 톤 가이드*가 결정 기준 (결과 프레이밍 양보 X)

## 후속 작업

- QA에서 5초 룰 미통과 → 해당 화면 카피·정보 위계 재구성
- 코칭 메시지 부족 → 라이브러리 카테고리 확장
- 페르소나 추가 (예: 박소연 다이어트 강화) → 메시지 라이브러리 페르소나별 가지치기

## 흔한 실수

- ❌ "씹기 횟수 측정" 같은 도구 프레이밍
- ❌ 의료적 약속 카피
- ❌ 코칭 메시지에 "track", "data", "monitor" 같은 영어 잔존
- ❌ 픽셀 시안에 시간 낭비 (Figma 시안보다 컴포넌트·토큰·코칭 메시지가 훨씬 가치 큼)
- ❌ 권한 일괄 요청
- ❌ 다크 모드·Dynamic Type 사후 대응
- ❌ 영상 시청 컨텍스트 무시 → 알림 거슬림
