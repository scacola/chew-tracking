---
name: visual-experience-design
description: Apple·Linear·Stripe·Vercel·Calm급 인터랙티브 웹 디자인을 설계하는 방법론 — 디자인 시스템(색·폰트·간격) + 정보 흐름 + 인터랙션·모션 사양을 한 패키지로 만든다. 랜딩 페이지·마케팅 사이트의 비주얼·UX·모션 설계 시 반드시 사용. "디자인 시스템", "랜딩 페이지 디자인", "인터랙션 사양", "Apple급 모션", "스크롤 시퀀스" 같은 요청에서 트리거.
---

# Visual Experience Design

*세상 어디서도 보지 못할 퀄리티*는 막연한 감각이 아니라 *측정 가능한 디테일의 집합*이다. 이 스킬은 그 디테일을 설계 가능한 형태로 분해한다. `visual-experience-designer` 에이전트가 사용한다.

## 왜 이 스킬이 필요한가

"Apple 스타일로 만들어주세요"는 *디자인 사양이 아니다*. 이 스킬은 그것을 다음으로 변환한다:
- 어느 레퍼런스의 *어느 부분*을 차용할지
- 색·폰트·간격을 *숫자로*
- 인터랙션을 *duration·easing·트리거*로
- frontend-implementer가 *그대로 빌드 가능한* 사양으로

## 벤치마크 분석 프로토콜

"Apple급"을 만들려면 먼저 *Apple의 무엇*을 배울지 명확히 한다. 다음 사이트에서 *각각 다른 부분*을 차용:

| 사이트 | 학습 포인트 |
|-------|-----------|
| **apple.com** (제품 페이지) | 스크롤 시퀀스, 비주얼 우위, 폰트 무게 |
| **stripe.com** | 그라데이션 배경, 정보 위계, 코드 시각화 |
| **linear.app** | 모션 디테일, 터미널 미학, 일관된 호버 |
| **vercel.com** | 그라데이션 + 어두운 배경, 타이포 임팩트 |
| **framer.com** | 시그니처 인터랙션, 키네틱 타이포 |
| **calm.com** | 따뜻한 색감, 마음챙김 톤 |
| **headspace.com** | 일러스트 + 진정성 |
| **notion.so** | 일관된 컴포넌트, 정보 밀도 균형 |

차용 시 *명시적으로* 적는다: "Stripe Hero의 그라데이션 패턴 → 우리 Hero에 적용 (단, 색 톤은 우리 팔레트로 변환)".

## 디자인 시스템 — 옵션 G 정체성

옵션 G는 *임상 차가움 + 코칭 따뜻함*의 혼합이다. 두 정체성이 **섹션마다 비율이 다르게** 나타나야 한다:

- **데이터·임상 섹션**: 차가운 톤 — 흰색 배경, 검정 헤드라인, 민트(#00C9A7) 또는 코발트 액센트
- **코칭·페르소나 섹션**: 따뜻한 톤 — 베이지(#F5EFE6) 또는 코랄(#FF8A65) 액센트, 부드러운 그라데이션
- **시그니처 섹션 (AirPods 시각화)**: 두 톤의 *전환점* — 그라데이션 또는 분리된 영역

### 컬러 팔레트 권장 (수정 가능 출발점)

```
--color-bg-cool:      #FFFFFF
--color-bg-warm:      #F5EFE6
--color-text-primary: #0A0E1A   /* 거의 검정, 약간 청남 */
--color-text-muted:   #5A5F6E
--color-clinical:     #00C9A7   /* 임상 액센트 */
--color-coaching:     #FF8A65   /* 코칭 액센트 */
--color-trust:        #2563EB   /* CTA·신뢰 */
--color-line:         #E5E7EB
```

WCAG AA 검증: Primary text on bg-cool ≥ 4.5:1 ✓

### 타이포그래피 — 한영 페어링

```
한글: Pretendard Variable (full weight)
영문: Inter Variable
모노: JetBrains Mono (코드·데이터)

Display:    52/60, weight 600  (Hero 1차)
Heading 1:  40/48, weight 600
Heading 2:  32/40, weight 600
Heading 3:  24/32, weight 600
Body Large: 18/28, weight 400
Body:       16/26, weight 400
Caption:    14/20, weight 400
```

모바일은 모든 사이즈 *0.85배*. Display는 모바일에서 36/44.

### 간격 — 8px 기반

```
4·8·12·16·24·32·48·64·96·128 (px)
```

섹션 간 vertical padding: desktop 128px / mobile 64px가 표준.

### 그리드

```
mobile (<640):    4 cols, 16px gutter, 16px margin
tablet (640-1024): 8 cols, 24px gutter, 32px margin
desktop (>1024):  12 cols, 32px gutter, max-width 1200px
```

## 정보 흐름 — 옵션 G 권장 구조

5초 룰 + 점진적 설득:

```
1. Hero (0-100vh)         — "당신은 모른다" + CTA
2. Problem (100-200vh)    — 자기 인식 트리거 + 의학 근거
3. Solution (200-300vh)   — 3단계 메커니즘
4. AirPods Demo (300-400vh) — 시그니처 인터랙션
5. How it works (400-500vh)  — 28일 코스 + KOL
6. Differentiation (500-600vh) — Apple 흡수 방어
7. Authority (600-700vh)  — KOL·임상 RCT·베타
8. Pricing (700-800vh)    — 9,900원 정당화
9. FAQ (800-900vh)        — 6-10개
10. Final CTA + Footer    — 결과 약속 반복
```

각 섹션은 *5-10초 안에* 핵심을 전달해야. 더 길면 사용자가 떠난다.

## 인터랙션·모션 사양

### 사양 작성 표준 형식

```
인터랙션 이름: 무엇을 하는가
트리거: 무엇이 시작시키는가 (스크롤, 호버, 클릭, 마운트)
타이밍: duration + delay + easing
변화: 무엇이 어떻게 (opacity 0→1, transform Y20→0)
종료 조건: 무엇이 끝내는가
접근성: prefers-reduced-motion 시 어떻게 대체
구현 라이브러리: GSAP / Framer / CSS 중 하나
```

### 표준 모션 라이브러리 (옵션 G 어필)

| 모션 | duration | easing | 사용처 |
|------|---------|--------|-------|
| 페이드 인 + 위로 슬라이드 | 0.6s | cubic-bezier(0.16, 1, 0.3, 1) | 스크롤 진입 |
| 호버 lift | 0.2s | ease-out | 카드·버튼 |
| CTA 클릭 피드백 | 0.15s scale 0.97 | ease-in-out | 모든 CTA |
| 스크롤 인디케이터 | infinite | linear | Hero 끝 |
| 스무스 스크롤 | linear interp 0.1 | - | 페이지 전체 (Lenis) |

### 시그니처 인터랙션 — AirPods 시각화

옵션 G 페이지의 *기억에 남는 모먼트*. 다음 옵션 중 *하나*를 선택 (둘 다 만들지 말 것):

**옵션 A: Three.js 3D AirPods + 데이터 스트림**
- AirPods Pro 3D 모델 (3-5만 폴리, glTF 압축)
- 사용자 스크롤에 따라 회전 → 식사 데이터 입자가 귀에서 흘러나와 점수로 응결
- 모바일에서는 첫 1초 placeholder PNG → Three.js lazy load

**옵션 B: 정밀 SVG AirPods + GSAP morph**
- 벡터 SVG (가벼움)
- 스크롤에 따라 스타일·색·모양 변형 + 데이터 라인 그리기
- 모바일에서도 60fps

권장: **옵션 B** (성능 안전, 한국 모바일 80% 환경 우호)

## 비주얼 자산 명세

### 차트·시각화

- **식사 속도 차트** — 가로 시간축, 빠른 식사 빨간 영역, 우리 코스 후 녹색
- **위 건강 점수** — 0-100 원형 게이지, 임상 색감
- **28일 진행 그래프** — 점진적 향상 곡선

차트는 Recharts·D3·custom canvas 중 가벼운 것 (Recharts 추천 — React 호환).

### 아이콘 + 일러스트

- 아이콘: Lucide (오픈, 가벼움) — 24px, 1.5px stroke
- 일러스트: 커스텀 SVG (3-5개) — 페르소나·메커니즘·결과
- 사진: 사용 시 *권한 명확*한 것만 (Unsplash·Pexels 라이센스 확인)

## 반응형 가드레일

- 모바일에서 *생략*하는 인터랙션: 시그니처 옵션 A의 3D 회전, 마이크로 호버 (터치 환경)
- 모바일에서 *대체*: 3D → SVG, 호버 효과 → 탭 효과
- 모바일 폼 입력: iOS 자동 줌 방지 (font-size 16px+)
- iOS Safari 100vh 버그 (svh 사용)

## 접근성

- WCAG AA: 모든 텍스트 색 대비 ≥ 4.5:1, 큰 텍스트 ≥ 3:1
- `prefers-reduced-motion` 대응: 모든 모션 0.01s로 감소 + opacity 변화만 유지
- 키보드 네비게이션: 모든 CTA·링크 tab 가능
- ARIA 라벨: 시각 자료에 `aria-label` 또는 `aria-describedby`
- 폰트 크기: 사용자가 200%까지 확대 가능

## 성능 가드레일

- LCP < 2.5s (모바일 4G): Hero 이미지·폰트 preload
- CLS < 0.1: 이미지 width/height 명시, 폰트 fallback 매칭
- INP < 200ms: 무거운 JS는 idle callback 또는 defer
- Total bundle: JS < 100KB / CSS < 50KB / Images < 500KB

## 출력 형식

`visual-experience-designer`의 출력 `_workspace/landing/02_visual_ux.md`는 *frontend-implementer가 결정 없이 빌드 가능한* 사양으로:
- 디자인 토큰은 CSS 변수 또는 Tailwind config 형태로 즉시 사용 가능
- 인터랙션은 의사코드 (예: GSAP scroll-trigger 호출 형태) 포함
- 모든 섹션의 와이어프레임 + 모바일/데스크탑 변형
