# 03 — 기술 아키텍처 결정 문서 (Chew & Calm Coach 랜딩)

**제품**: Chew & Calm Coach (옵션 G)
**작성일**: 2026-05-01
**작성자**: landing-architect
**참조**: `_brief.md`, `01_strategy_copy.md`, `02_visual_ux.md`, `.claude/skills/landing-architecture/SKILL.md`
**다음 작업자**: `frontend-implementer` (`04_brief_consolidated.md`을 직접 입력으로 사용)

> 이 문서는 *기술 결정의 근거*를 기록한다. frontend-implementer는 이 문서가 아니라 `04_brief_consolidated.md`만 보고 빌드해도 된다.
> 이 문서는 *왜 이 결정을 했는가*에 답한다.

---

## 0. 카피라이터 회신 메모 R1–R4 처리 결정 (선결)

`02_visual_ux.md` §10의 4건. 합리적 결정으로 진행, 사용자에게 별도 묻지 않음.

### R1 — 헤드라인 폰트: Pretendard 800 + 액센트 컬러 (디자이너 결정 채택)

- **결정**: 디자이너 결정 그대로 채택. Hero H1은 `font-sans Pretendard 800` + "11분"·"8주"만 `--color-clinical-deep` 액센트.
- **근거**: (1) 모바일 한글 가독성 + LCP 보호(세리프 추가 로드 300KB+). (2) Pretendard 800 64px가 Noto Serif KR Bold 56px보다 시각 무게가 강하다는 디자이너 측정. (3) Noto Serif KR Italic은 *학술 인용 출처(Hurst 2018)·페르소나 트리거 카드·권위 인용·Final CTA 손편지 박스* 4곳에 한정 — 학술 톤 시각 시그널로만 작동.
- **카피라이터 동의 가정**: M1의 *"통계 트리거 무게"*는 디자인이 다른 수단(굵기·사이즈·액센트)으로 보존하므로 카피 의도 위배 없음.

### R2 — Hero 보조 1줄 모바일 줄바꿈: B 옵션 채택 (모바일 3줄 분기)

- **결정**: `<br className="hidden md:inline" />` / `<br className="md:hidden" />` 패턴으로 *데스크탑 2줄 / 모바일 3줄* 분기.
  - **데스크탑 (≥1024px)**:
    ```
    이미 끼고 있는 AirPods가 식사 속도를 자동으로 보여주고,
    임상 28일 코스가 매일 2-3분, 함께 걸어요.
    ```
  - **모바일 (<1024px)**:
    ```
    이미 끼고 있는 AirPods가
    식사 속도를 보여주고,
    임상 28일 코스가 매일 2-3분 함께 걸어요.
    ```
- **근거**: 호흡 리듬 보존. "AirPods가 — 보여주고 — 함께 걸어요"는 한국어 자연 호흡 위치. 1문장 합치기(C안)는 카피라이터 의도(부드러운 두 절)와 충돌. 그대로(A안)는 모바일 좁은 화면에서 어색한 위치 줄바꿈.
- **카피 손상 0**: 단어 변경 없음, 줄바꿈만.

### R3 — Final CTA self-aware 문장 손편지 박스 처리: 디자이너 안 채택

- **결정**: 디자이너의 *별도 박스 + 좌측 1px 라인 + Noto Serif KR Italic + 작가의 손편지 톤* 채택. 카피 길이·단어 보존.
- **근거**: §6 보존 필수 카피 6번("1만 명이 합류했다고 거짓말하지 않아요")의 정직 시그널은 *시각적 분리*로 강화된다. 마케팅 카피 흐름 안에 묻히면 *공식 톤* 잡음에 흡수되어 진정성이 죽는다. 손편지 박스는 *진정성 시각 신호*로 옵션 G 정체성에 직접 봉사.
- **카피 §6 보존 필수에 추가 권고**: "이 두 줄은 별도 박스 + 세리프 이탤릭으로 시각 처리, 줄임 금지" — 04_brief에 명시.

### R4 — Pricing 추천 라벨 단어 확정: "추천" + "한 달 무료" 칩

- **결정**:
  - 카드 1 헤더: `월간`
  - 카드 2 헤더: `연간` + 우상단 칩 `추천` (한국어 단어 채택, "Most Popular" 영어 직역 회피)
  - 카드 2 우상단 보조 칩: `한 달 무료` (33%가 1/12 ≈ 한 달 무료라는 카피 §3.7의 *"한 달 무료에 가까워요"*와 정합)
  - 카드 3 헤더: `28일 코스 단품`
- **근거**: 영어 "Most Popular"·"Best Value"는 §1.5 Banned List의 *과도한 영어*에 저촉. "베타 추천"은 베타가 아닌 *영구 가격*이라 부정확. "추천"이 가장 짧고 정직.

---

## 1. 기술 스택 결정

### 1.1 최종 스택

```
Vite 5.x + React 18 (TypeScript)
+ Tailwind CSS 3.4 (디자인 토큰)
+ GSAP 3.12 + ScrollTrigger (시그니처 + 스크롤 모션)
+ Lenis 1.1 (스무스 스크롤, 데스크탑 한정)
+ Lucide React (아이콘, 트리쉐이킹)

호스팅: Vercel
폰트: Pretendard Variable Dynamic Subset (CDN preload) + Noto Serif KR (subset)
차트: Recharts 미사용 — 모든 차트는 인라인 SVG (번들 절약)
```

### 1.2 결정 표 — 대안과 트레이드오프

| 결정 영역 | 채택 | 대안 | 채택 근거 |
|---|---|---|---|
| **빌드 도구** | Vite 5 | Next.js, Astro, Webpack | 단일 페이지 랜딩 — Next.js의 SSR/SSG는 오버킬. Astro는 React 인터랙션 hydration이 GSAP scrub과 미세 충돌. Vite는 빌드 5초 + dev HMR 즉시. |
| **UI 프레임워크** | React 18 | Vanilla TS, Astro, Svelte | 18개 컴포넌트 분해 + 카피·디자인 변경 영향 격리에 React가 유리. 카피라이터/디자이너 후속 변경 시 컴포넌트별 수정. Vanilla는 EmailForm 3 위치 + 폼 상태 관리에서 손해. |
| **스타일링** | Tailwind 3.4 + CSS 변수 | CSS Modules, vanilla-extract, Emotion | 디자인 토큰을 `tailwind.config.ts`에 1:1 매핑 → 디자이너 사양 그대로. CSS 변수는 *런타임 토큰* 역할(다크 테마 확장 여지) + Tailwind 내부에서 `bg-clinical/[var(--color-clinical)]` 형태로 호환. |
| **시그니처 모션** | GSAP 3.12 + ScrollTrigger | Framer Motion, Anime.js, CSS only | AirPods Demo의 핀 + scrub + 4단계 path morph는 ScrollTrigger 표준. Framer Motion의 `useScroll`+`useTransform`은 가능하지만 path morph + stagger 조합에서 GSAP 타임라인이 압도적으로 깔끔. |
| **path morph 플러그인** | **stroke-dashoffset 무료 대안** | drawSVG 유료 플러그인, MorphSVG 유료 | **drawSVG는 GSAP Premium 유료** — Phase 1 무료. 라인 그리기는 `stroke-dasharray + stroke-dashoffset` 무료 표준 기법으로 동등 효과. 게이지 응결은 path `d` 속성 보간 대신 *2개 SVG 페이드 전환*으로 단순화 (라인 SVG fade out + 게이지 SVG fade in, 0.4s overlap). 시각 결과 95% 동등, 0원. |
| **스무스 스크롤** | Lenis 1.1 (데스크탑 only) | Locomotive Scroll, Smooth Scrollbar, 없음 | Lenis는 ScrollTrigger와 공식 동기화 패턴 + 7KB 가벼움. 모바일은 비활성 (M3 사용자가 Lenis 프록시 스크롤 대신 OS 모멘텀을 선호). |
| **차트** | 인라인 SVG | Recharts, Chart.js, D3 | 우리 차트는 4종(원형 진행도 2개, 게이지 1개, 4×7 격자, 8막대)으로 단순. Recharts는 60KB+ 추가 — 번들 예산 위협. 직접 SVG로 16KB 절약. |
| **아이콘** | Lucide React (트리쉐이킹) | Heroicons, Tabler, 인라인 SVG | 9개 아이콘만 사용 — Lucide ESM tree-shake로 ≈3KB. 인라인 SVG도 가능하나 일관성 위해 라이브러리. |
| **폼 처리** | Vanilla `<form onSubmit>` + fetch | React Hook Form, Formik | 1필드 폼 3개 — 외부 라이브러리는 사치. 자체 훅 `useEmailSubmit`로 50줄 처리. |
| **분석** | placeholder `track()` 함수 | PostHog, Plausible, GA4 | Phase 1은 베타 게이트 검증이 핵심. 분석 도구는 베타 합류 *후* 결정. `lib/analytics.ts`에 인터페이스만, 실제 SDK는 추후. |
| **호스팅** | Vercel | Netlify, Cloudflare Pages, GitHub Pages | `.claude/skills/vercel:deploy`가 이미 환경에 있어 친화. Edge 네트워크 + zero config + ISR 옵션 보유. |
| **i18n** | 미사용 | i18next, FormatJS | 한국어 단일. 영어 동시 노출 요구 없음. |

### 1.3 시그니처 인터랙션 구현 가능성 검증

옵션 B (정밀 SVG morph + GSAP scroll-trigger + 4단계 핀 시퀀스).

| 단계 | 구현 기법 | 라이브러리 비용 | 모바일 60fps 가능? |
|---|---|---|---|
| Phase 1 → 2: 정지 → 펄스 | GSAP `tl.to({ scale, opacity })` on `<circle>` | 무료 (core) | OK (transform·opacity만) |
| Phase 2 → 3: 데이터 라인 그려짐 | `stroke-dasharray + strokeDashoffset` 보간 | 무료 (drawSVG 불필요) | OK |
| Phase 2 → 3: typewriter 텍스트 | GSAP stagger 0.07s | 무료 | OK |
| Phase 3 → 4: 라인 → 게이지 morph | **2개 SVG cross-fade** (path interp 대체) | 무료 | OK |
| Phase 4: 점수 카운트업 0→72 | GSAP `snap: { textContent: 1 }` | 무료 | OK |
| 핀 + scrub | ScrollTrigger pin | 무료 | **데스크탑만** — 모바일은 비활성, 4 카드 분리 진입 (디자이너 §3.4 명시) |

**결론**: 모든 단계 무료 라이브러리로 구현 가능. 모바일은 디자이너 명세대로 핀/scrub 비활성 → 4 카드 분리 IO 진입.

---

## 2. 파일 구조

SKILL.md 표준 구조 + 본 프로젝트 추가.

```
landing/
├── index.html
├── package.json
├── vite.config.ts
├── tailwind.config.ts
├── tsconfig.json
├── postcss.config.js
├── .env.example                   # VITE_BETA_SUBMIT_URL 등 (베타 폼 endpoint)
├── public/
│   ├── og-image.png               # 1200×630, Hero 정적 캡처
│   ├── favicon.ico
│   ├── favicon.svg
│   └── robots.txt
└── src/
    ├── main.tsx                   # ReactDOM.createRoot + Lenis init
    ├── App.tsx                    # 페이지 조합 (10개 섹션)
    ├── styles/
    │   ├── globals.css            # Tailwind base/components/utilities + reset + reduced-motion
    │   └── tokens.css             # :root CSS 변수 (디자인 토큰 전체)
    ├── sections/                  # 페이지 섹션
    │   ├── StickyNav.tsx
    │   ├── Hero.tsx
    │   ├── Problem.tsx
    │   ├── Solution.tsx
    │   ├── AirPodsDemo.tsx        # 시그니처 — GSAP pin
    │   ├── HowItWorks.tsx
    │   ├── Differentiation.tsx
    │   ├── Authority.tsx
    │   ├── Pricing.tsx
    │   ├── FAQ.tsx
    │   └── FinalCTA.tsx           # Footer 포함
    ├── components/                # 재사용 UI
    │   ├── Section.tsx
    │   ├── Container.tsx
    │   ├── Heading.tsx
    │   ├── Display.tsx
    │   ├── CtaPrimary.tsx
    │   ├── CtaSecondary.tsx
    │   ├── Card.tsx
    │   ├── StatCard.tsx
    │   ├── QuoteCard.tsx
    │   ├── KolPlaceholder.tsx
    │   ├── StatusChip.tsx
    │   ├── PriceCard.tsx
    │   ├── FaqItem.tsx
    │   ├── EmailForm.tsx
    │   ├── Clock.tsx              # SVG circular progress
    │   ├── HealthScoreGauge.tsx   # SVG gauge
    │   ├── CalendarMini.tsx       # 4×7 격자
    │   ├── DataStream.tsx         # 모노스페이스 텍스트 스트림
    │   ├── ScrollIndicator.tsx
    │   └── icons/                 # 커스텀 SVG 5개
    │       ├── AirpodsSvg.tsx     # variant + state props
    │       ├── HealthGaugeSvg.tsx
    │       ├── StomachSoftSvg.tsx
    │       ├── CoachAvatarSvg.tsx
    │       └── KolSilhouetteSvg.tsx
    ├── interactions/              # 모션 셋업
    │   ├── airpodsScroll.ts       # GSAP scroll-trigger 시그니처
    │   ├── revealOnScroll.ts      # IntersectionObserver 기반 reveal
    │   ├── smoothScroll.ts        # Lenis init + ScrollTrigger 연동
    │   ├── reducedMotion.ts       # prefers-reduced-motion 감지
    │   └── chartAnimations.ts     # 시계, 게이지, 캘린더, 막대 진입 모션
    ├── data/                      # 정적 데이터
    │   ├── faq.ts                 # 8개 Q&A
    │   ├── personas.ts            # 한지원/박소연/김상훈
    │   ├── pricing.ts             # 3 티어
    │   └── medicalEvidence.ts     # Hurst 2018, Ohkuma 2015
    ├── lib/
    │   ├── analytics.ts           # placeholder track()
    │   ├── betaSubmit.ts          # 이메일 폼 제출
    │   └── eightWeekDate.ts       # today + 56일 → ISO 주차 첫 주 한글 포맷
    └── hooks/
        ├── usePersonaRoute.ts     # ?p=stomach|diet|checkup
        ├── useReducedMotion.ts
        └── useEmailSubmit.ts
```

---

## 3. 컴포넌트 명세 (전체)

각 컴포넌트의 명세 카드. 04_brief에 동일 형식으로 복제.

### `<App>`
- **책임**: 10개 섹션 조립 + 전역 모션 init + 페르소나 라우팅
- **Props**: 없음 (root)
- **상태**: `persona` (URL `?p=` 파싱), `reducedMotion` (boolean)
- **의존**: 모든 `sections/*`
- **모션 마운팅**: `useEffect`로 Lenis init + GSAP register, `prefers-reduced-motion` 감지
- **접근성**: Skip link 첫 자식, `<main id="main">` 래퍼

### `<StickyNav>`
- **책임**: 상단 네비게이션 + 100vh 스크롤 후 blur 발화
- **Props**: 없음
- **상태**: `scrolled` (boolean, scroll > 100vh)
- **의존**: `<CtaSecondary>` (베타 버튼), 로고 SVG
- **모션 마운팅**: scroll listener (passive)
- **접근성**: `<nav aria-label="주요 메뉴">`, 키보드 도달 가능
- **테스트**: 데스크탑/모바일 햄버거 분기 — 모바일 햄버거는 *생략*(베타 진입 마찰 줄임), 모바일 우상단 [베타 합류] CTA만

### `<Hero>`
- **책임**: H1 + 보조 + Primary CTA + 진실 시그널 + AirPods 정적 SVG
- **Props**: `{ persona: Persona }` — 페르소나에 따라 서브헤드라인 분기
- **상태**: 없음
- **의존**: `<Display>`, `<CtaPrimary>`, `<CtaSecondary>`, `<EmailForm>` (Hero 폼 *없음* — Final CTA에만), `<AirpodsSvg variant="light" state="idle">`, `<ScrollIndicator>`
- **모션 마운팅**: 마운트 시 fade+up 시퀀스 (H1 0.8s → 보조 0.2s 딜레이 → CTA 0.4s 딜레이). AirPods SVG는 즉시 표시(LCP 보호). 데이터 점선만 0.6s 딜레이로 strokeDashoffset.
- **접근성**: `<h1>` 1개, "11분"·"8주"는 `<span class="text-clinical-deep">`로 라벨 (의미는 그대로 텍스트로 읽힘)
- **테스트**: 모바일 320px에서 H1 두 줄 유지 (`<br>` 강제), `100svh`로 iOS Safari URL bar 대응

### `<Problem>`
- **책임**: 자기 인식 트리거 + 11분 vs 20분 시각화 + 의학 근거 카드 2 + 페르소나 트리거 3
- **Props**: 없음
- **상태**: 없음 (모바일 캐러셀은 CSS scroll-snap, 상태 불필요)
- **의존**: `<Heading>`, `<Clock>` x2, `<StatCard>` x2, `<QuoteCard>` x3
- **모션 마운팅**: scroll 진입 시 시계 자동 채움 (0.45/1.0 회전, GSAP)
- **접근성**: `<svg role="img" aria-label="한국 직장인 평균 점심 시간 11분 대 권장 20분">`
- **테스트**: 모바일에서 페르소나 카드 수평 스크롤 snap 작동, 점 인디케이터 표시

### `<Solution>`
- **책임**: 3단계 (검출 → 깨달음 → 코칭) 카드
- **Props**: 없음
- **의존**: `<Card>` x3, `<AirpodsSvg variant="light" state="pulse">`, 코치 카드 목업, `<CalendarMini completedDays={8}>`, `<KolPlaceholder>`(우상단 미니어처)
- **모션 마운팅**: stagger 페이드+업 (0/0.15/0.3s 딜레이). AirPods 펄스 무한 루프, 막대 그래프 0→실제값 0.8s, 캘린더 셀 1~8 순차 0.06s 간격
- **테스트**: `prefers-reduced-motion` 시 펄스 정지

### `<AirPodsDemo>` (시그니처)
- **책임**: 4단계 스크롤 시퀀스 — Desktop pin / Mobile 4 카드 분리
- **Props**: 없음
- **상태**: 없음 (GSAP timeline이 scroll 위치 매핑)
- **의존**: `<AirpodsSvg variant="mono" state="streaming">`, `<DataStream>`, `<HealthScoreGauge>`
- **모션 마운팅**: `useEffect`에서 viewport ≥1024px 감지 시 `airpodsScroll.init()`. 모바일은 4 카드 + IntersectionObserver fade.
- **성능 가드레일**: AirPods SVG 인라인, `will-change: transform` 핀 시작/종료에 토글
- **접근성**: `<figure aria-label="AirPods가 식사 속도를 측정해 위 건강 점수로 변환하는 과정">`. 데이터 스트림은 실제 `<ul>`. 게이지 결과 `aria-live="polite"`. `prefers-reduced-motion` 시 정적 4 카드.
- **테스트**: 데스크탑 핀 동안 60fps, 모바일 카드 진입 60fps, reduced-motion에서 즉시 최종 상태

### `<HowItWorks>`
- **책임**: 28일 코스 + AirPods + KOL 트리오 (3 컬럼)
- **Props**: 없음
- **의존**: `<CalendarMini>`, `<AirpodsSvg variant="light">`, `<KolPlaceholder>`, `<CoachAvatarSvg>`, 호환 모델 칩들
- **모션 마운팅**: stagger 진입, 캘린더 1주차 7셀 순차 점등
- **테스트**: 호환 칩(Pro/3/4) 정확히 표시

### `<Differentiation>`
- **책임**: 5개 자산 카드 — 큰 카드 3 (a/c/d) + 작은 가로 카드 2 (b/e)
- **Props**: 없음
- **의존**: `<Card variant="elevated">` x3 (큰), `<Card variant="flat">` x2 (작은), `<KolPlaceholder>` 미니어처, `<CalendarMini>` 미니어처, 코치 카드 미니어처
- **모션 마운팅**: stagger 진입 (5장)
- **테스트**: 5장 모두 라벨 (a)~(e) 정확

### `<Authority>`
- **책임**: 정직 사회증거 3 카드 + 권위 인용
- **Props**: 없음
- **의존**: `<StatusChip status="inProgress">` x3, `<KolPlaceholder>`, RCT 8막대 SVG, 사람 12 그리드 SVG, `<QuoteCard>`(권위 인용)
- **모션 마운팅**: KOL 호흡(`motion.kolBreathe`, 무한 루프), 상태 칩 펄스 점, 막대 진입 0→8 stagger, 사람 그리드 4개 stagger
- **접근성**: 호흡 애니메이션은 `prefers-reduced-motion` 시 opacity 고정
- **테스트**: KOL placeholder가 "부끄럽지 않게" 자신감 있는 톤(opacity 0.7~0.9, *not* 0.3)

### `<Pricing>`
- **책임**: 3 가격 카드 (월간/연간/단품), 연간 강조
- **Props**: 없음
- **의존**: `<PriceCard>` x3, 가격 정당화 카피, 환불 정책 1줄
- **모션 마운팅**: stagger 진입, 연간 카드 mount glow + scale 1.04 유지
- **테스트**: 모바일에서 연간이 *최상단*, 데스크탑에서 가운데 강조 위치

### `<FAQ>`
- **책임**: 8개 Q&A 단일 펼침 아코디언
- **Props**: 없음
- **상태**: `openIndex: number | null`
- **의존**: `<FaqItem>` x8 (data/faq.ts에서 매핑)
- **모션 마운팅**: max-height 0→실측 높이 0.3s + arrow rotate 180
- **접근성**: `<button aria-expanded>` + `<div role="region" aria-labelledby>`. Q2/Q6/Q7 *"신뢰 핵심"* 라벨은 `<span class="sr-only">신뢰 핵심:</span>` 아닌 시각 라벨로 노출(라벨이 의미 정보)
- **테스트**: Tab 키로 모든 Q 도달, Enter/Space로 토글, 새 Q 펼치면 기존 닫힘

### `<FinalCTA>` + Footer
- **책임**: 큰 헤더 + 손편지 박스 + 베타 가입 폼 + Secondary 링크 + Footer
- **Props**: 없음
- **상태**: 폼 상태 (`useEmailSubmit`)
- **의존**: `<Display size="lg">`, `<EmailForm>` (1필드), `<CtaSecondary>`, Footer 마크업
- **모션 마운팅**: 헤더 fade+up, 손편지 박스 0.4s 딜레이, 폼 포커스 시 보더 강조
- **데이터**: "7월 첫 주" 자동 계산 — `lib/eightWeekDate.ts`로 today + 56일의 ISO 주차 첫 주를 한글 포맷("M월 첫째 주" 등) 반환
- **접근성**: 폼 `<label>` 명시(visually-hidden), 성공/실패 메시지 `aria-live="polite"`
- **테스트**: 폼 제출 → 로딩 스피너 → 성공 메시지, 실패 시 shake

### 재사용 컴포넌트 — 간단 명세

| 컴포넌트 | Props | 책임 |
|---|---|---|
| `<Section tone paddingY>` | `tone: 'cool'\|'warm'\|'mist'\|'deep', paddingY?: 'lg'\|'xl'` | 섹션 래퍼 + 배경 토큰 |
| `<Container size>` | `size: 'default'\|'narrow'\|'prose'` | max-width 1200/880/680 + 좌우 패딩 |
| `<Heading level accent as>` | `level: 1-4, accent?, as?: 'h1'\|'h2'` | 타이포 토큰 매핑 |
| `<Display size accentWords>` | `size: 'xl'\|'lg', accentWords?: string[]` | accentWords 자동 wrap with `text-clinical-deep` |
| `<CtaPrimary href label icon>` | `href, label, icon?` | `--color-cta` 버튼 + 호버/active |
| `<CtaSecondary href label>` | `href, label` | 텍스트 링크 + 화살표 |
| `<Card variant tone>` | `variant: 'flat'\|'elevated'\|'highlight', tone?` | 패딩/그림자/라운드 + 호버 lift |
| `<StatCard label stat source>` | `label, stat, source` | 임상 메타분석 카드 (Problem) |
| `<QuoteCard quote persona label>` | `quote, persona, label` | 손글씨톤 인용 (Noto Serif KR Italic) |
| `<KolPlaceholder role status>` | `role, status: 'recruiting'` | 회색 실루엣 + "영입 진행 중" 라벨 + breathe |
| `<StatusChip status>` | `status: 'inProgress'\|'beta'\|'live'` | pulse 점 + 한글 라벨 |
| `<PriceCard tier price period features recommended>` | `tier, price, period, features[], recommended?` | 가격 카드 |
| `<FaqItem q a highlight isOpen onToggle>` | `q, a, highlight?, isOpen, onToggle` | 단일 펼침 아코디언 행 |
| `<EmailForm onSubmit placeholder ctaLabel variant>` | `onSubmit, placeholder, ctaLabel, variant: 'inline'\|'stacked'\|'caption'` | 1필드 + 1버튼 + 보조 텍스트, 3 사용처 |
| `<Clock minutes target label>` | `minutes, target, label` | SVG circular progress |
| `<HealthScoreGauge score change>` | `score, change` | SVG gauge + 카운트업 |
| `<CalendarMini weeks completedDays>` | `weeks: 4, completedDays: number` | 4×7 격자 |
| `<DataStream rows>` | `rows: { time, label }[]` | 모노 텍스트 스트림 |
| `<AirpodsSvg variant state>` | `variant: 'mono'\|'light', state: 'idle'\|'pulse'\|'streaming'\|'gauge'` | 인라인 SVG, GSAP 타겟용 named groups |
| `<ScrollIndicator>` | 없음 | Hero 하단 ↓ + "스크롤" |

---

## 4. 데이터 모델

### 4.1 페르소나
```ts
// src/data/personas.ts
export type Persona = 'stomach' | 'diet' | 'checkup' | 'default'

export interface PersonaContent {
  id: Persona
  name: string
  age: number
  painLevel: number
  subhead: string  // Hero 서브헤드라인 (string with \n)
}

export const personas: Record<Persona, PersonaContent> = {
  default:  { ... },  // 한지원형 카피 동일 (1차 페르소나)
  stomach:  { ... },  // 한지원
  diet:     { ... },  // 박소연
  checkup:  { ... },  // 김상훈
}
```

### 4.2 FAQ
```ts
// src/data/faq.ts
export interface FaqEntry {
  id: string  // 'q1'..'q8'
  question: string
  answer: string
  highlight?: 'trust-core'  // Q2, Q6, Q7
}

export const faq: FaqEntry[] = [
  { id: 'q1', question: '가격이 왜 9,900원이에요? 너무 싸 보여요.', answer: '...' },
  { id: 'q2', question: '정확도는 얼마나 돼요? "95% 정확" 같은 광고를 본 적 있어요.', answer: '...', highlight: 'trust-core' },
  // ... q3-q8
]
```

### 4.3 가격
```ts
// src/data/pricing.ts
export interface Tier {
  id: 'monthly' | 'yearly' | 'single'
  header: string
  price: string
  period: string
  recommended?: boolean
  badges?: string[]  // ["추천", "한 달 무료"]
  features: string[]
  cancelPolicy: string
}
```

### 4.4 의학 근거
```ts
// src/data/medicalEvidence.ts
export const evidence = [
  { stat: '+71%', desc: '빠른 식사군은 미란성 위염 위험이 71% 더 높아요.', source: 'Hurst & Fukuda, 2018' },
  { stat: '2.15배', desc: '빠른 식사 습관은 비만 위험을 2.15배 높여요.', source: 'Ohkuma et al., 2015' },
]
```

### 4.5 KOL 자리 표시
```ts
// 영입 진행 중 — 데이터로 자리 표시만, 실제 사진/이름은 영입 후 교체
export const kolSlots = [
  { id: 'gastro', role: '소화기내과 전문의', status: 'recruiting' as const },
  { id: 'neuro', role: '신경과학자', status: 'recruiting' as const },
]
```

### 4.6 분석 이벤트 placeholder
```ts
// src/lib/analytics.ts
export type AnalyticsEvent =
  | 'page_view'
  | 'persona_routed'         // ?p=... 진입
  | 'cta_click_hero'
  | 'cta_click_pricing'
  | 'cta_click_final'
  | 'faq_open'               // { id }
  | 'beta_form_submit'       // { source: 'hero'|'final'|'footer' }
  | 'beta_form_success'
  | 'beta_form_error'
  | 'pricing_tier_view'      // { tier }
  | 'scroll_depth'           // { depth: 25|50|75|100 }

export function track(event: AnalyticsEvent, props?: Record<string, unknown>): void {
  if (typeof window === 'undefined') return
  if (import.meta.env.DEV) console.log('[track]', event, props)
  // Phase 2: PostHog/Plausible SDK 연결 지점
}
```

### 4.7 베타 폼 endpoint
```ts
// .env (개발) / Vercel 환경 변수 (프로덕션)
VITE_BETA_SUBMIT_URL=https://api.example.com/beta-signup  // Phase 1: Vercel serverless 또는 Formspree
```

---

## 5. 성능·접근성 예산

### 5.1 Core Web Vitals (모바일 4G)

| 메트릭 | 목표 | 측정 방법 | 가드 전략 |
|---|---|---|---|
| **LCP** | < 2.5s | Lighthouse CI / PageSpeed Insights | Hero H1을 LCP 후보로. Pretendard `font-display: swap`. AirPods SVG 인라인. Critical CSS inline (Hero만). |
| **CLS** | < 0.1 | Lighthouse | 모든 SVG·이미지 width/height 명시. 폰트 fallback `size-adjust` 매칭. |
| **INP** | < 200ms | Lighthouse / RUM | GSAP·Lenis idle init. ScrollTrigger refresh를 마운트 직후 1회만. |
| **FCP** | < 1.8s | Lighthouse | Critical CSS, JS defer. |
| **TBT** | < 200ms | Lighthouse | JS 청크 분할. AirPods Demo GSAP은 IntersectionObserver lazy. |

### 5.2 번들 사이즈 예산

| 자원 | 목표 (gzipped) | 측정 |
|---|---|---|
| **JS 총합** | < 100KB | `vite build` 출력 + `vite-bundle-visualizer` |
| **CSS 총합** | < 50KB | 동상 + Tailwind purge |
| **이미지/SVG 총합** | < 500KB | `du -sh public/` (사진 0장이라 SVG·아이콘만) |
| **폰트** | < 120KB | Pretendard Variable Dynamic Subset ≈80KB + Noto Serif KR subset ≈30KB |

**JS 예상 분해**:
- React + ReactDOM (gzip): ≈45KB
- GSAP core + ScrollTrigger: ≈40KB
- Lenis: ≈7KB
- Lucide React (트리쉐이크 9개 아이콘): ≈3KB
- 자체 코드: ≈10KB
- **합계**: ≈105KB — 5KB 초과 위험. **대응**: Lenis는 데스크탑 전용 dynamic import (`import('lenis')`)로 모바일 진입 시 0KB. GSAP ScrollTrigger도 시그니처 진입 직전 dynamic import 가능 (코드 분할).

### 5.3 Lighthouse 목표

| 카테고리 | 목표 | CI |
|---|---|---|
| Performance (Mobile) | ≥ 90 | Lighthouse CI on PR |
| Performance (Desktop) | ≥ 95 | 동상 |
| Accessibility | ≥ 95 | 동상 |
| Best Practices | ≥ 95 | 동상 |
| SEO | = 100 | 동상 |

### 5.4 접근성 예산 (WCAG AA)

- **색 대비**: §02 §2.2 검증표 그대로. 본문은 ≥4.5, 큰 텍스트(24px+) ≥3.0. 액센트 컬러 본문 사용 시 *-deep 변형* 의무.
- **키보드 네비게이션**: 모든 인터랙티브 요소 Tab 도달, `:focus-visible` 2px outline.
- **스크린 리더**: 시맨틱 HTML, ARIA labelledby/expanded, 차트 SVG에 텍스트 대안.
- **prefers-reduced-motion**: 전역 처리 (§7.2 of 02), 시그니처는 정적 4 카드로.
- **사용자 200% 확대**: 모든 폰트 사이즈 rem 단위.

### 5.5 측정 자동화

```yaml
# .github/workflows/lighthouse.yml (예시)
- uses: treosh/lighthouse-ci-action@v11
  with:
    urls: |
      https://chew-calm-coach.vercel.app/
      https://chew-calm-coach.vercel.app/?p=stomach
    budgetPath: .lighthouseci/budget.json
```

---

## 6. 빌드 단계 계획 (frontend-implementer 6단계)

각 단계 끝에 *반드시* 검증.

### Step 1 — Setup (30min)

- [ ] `npm create vite@latest landing -- --template react-ts`
- [ ] 의존성: `react@18 react-dom@18 gsap lenis lucide-react clsx`
- [ ] 개발 의존성: `tailwindcss@3.4 postcss autoprefixer @types/react @types/react-dom typescript vite`
- [ ] `tailwind.config.ts`에 디자인 토큰 매핑 (04_brief §2)
- [ ] `src/styles/tokens.css`에 :root CSS 변수 전체 (04_brief §2)
- [ ] `src/styles/globals.css`에 Tailwind base + reset + reduced-motion media query
- [ ] Pretendard Variable + Noto Serif KR preload 태그 (`index.html`)
- [ ] `<html lang="ko">` + meta description + OG 메타
- **검증**:
  - [ ] `npm run dev` → localhost 정상 렌더
  - [ ] 빈 페이지에 `bg-clinical text-coaching font-sans` 적용해보기 — 토큰 작동 확인
  - [ ] 폰트 로드 — Pretendard 글리프 보임

### Step 2 — 정적 마크업 + 스타일 (4-5h)

- [ ] 10개 섹션 컴포넌트 골격 (`sections/*`)
- [ ] 카피는 04_brief §1에서 *그대로 복사*. 다른 파일 안 봄.
- [ ] 재사용 컴포넌트 19개 (`components/*`)
- [ ] Tailwind 유틸로 토큰 적용 — `bg-bg-cool text-text-primary`
- [ ] 모바일 우선, 데스크탑 미디어 쿼리 후속 (`md:` `lg:`)
- [ ] 헤드라인 줄바꿈 `<br>` 강제 (보존 필수 카피)
- [ ] 데이터 파일 4개 (`data/*`) 입력
- [ ] OG 이미지 1200×630 생성 (Hero 정적 캡처 또는 디자인 prepro)
- **검증**:
  - [ ] 모든 섹션이 시안과 시각적 일치 (스크린샷 비교 — 각 섹션별)
  - [ ] 모든 카피 *§6 보존 필수 6개* 손상 없음 (검색으로 확인)
  - [ ] 페르소나 라우팅 `?p=stomach` 등에서 서브헤드라인 변경

### Step 3 — 반응형 (1-2h)

- [ ] 320 / 414 / 768 / 1024 / 1280 / 1920 6개 너비 검증
- [ ] iOS Safari 100svh 처리
- [ ] 폼 인풋 16px+ (자동 줌 방지)
- [ ] 터치/마우스 분기 (`@media (hover: hover)`)
- [ ] Pricing 모바일 세로 스택 — 연간이 최상단
- [ ] Problem 페르소나 카드 모바일 수평 스크롤 snap
- **검증**:
  - [ ] 6개 너비 깨짐 없음
  - [ ] iOS Safari 실기 테스트 (Hero 100svh 정확)
  - [ ] 폼 인풋 탭 시 자동 줌 *없음*

### Step 4 — 기본 인터랙션 (2-3h)

- [ ] `interactions/revealOnScroll.ts` IntersectionObserver
- [ ] `[data-reveal]` 모든 섹션 헤더·카드에 적용
- [ ] `interactions/smoothScroll.ts` Lenis init (데스크탑 한정 dynamic import)
- [ ] Lenis ↔ GSAP ScrollTrigger 동기화
- [ ] CTA 호버/active 표준 모션 (Tailwind utilities 또는 globals.css)
- [ ] FAQ 단일 펼침 아코디언 (`<FaqItem>` 상태 hoisting)
- [ ] EmailForm 포커스/제출/성공/실패 피드백
- [ ] StickyNav 100vh 통과 시 backdrop-blur
- [ ] Hero 스크롤 인디케이터 진동
- [ ] `prefers-reduced-motion` 전역 처리
- **검증**:
  - [ ] 모든 인터랙션 60fps (Chrome DevTools Performance)
  - [ ] reduced-motion 시 모션 정지 + 즉시 최종 상태
  - [ ] FAQ Tab/Enter 키 작동
  - [ ] EmailForm 3 위치(없음 — 보정: Final CTA + Footer 2 위치, Hero는 CTA 버튼만) 모두 정상

### Step 5 — 시그니처 인터랙션 (3-5h)

- [ ] `interactions/airpodsScroll.ts` GSAP timeline
- [ ] AirpodsSvg 인라인 SVG (named groups: airpod-body / -stem / -pulse / -data-line)
- [ ] Phase 1→2: 펄스
- [ ] Phase 2→3: strokeDashoffset 라인 + typewriter stagger
- [ ] Phase 3→4: 라인 SVG fade-out + 게이지 SVG fade-in (cross-fade, drawSVG 회피)
- [ ] Phase 4: 점수 카운트업 0→72
- [ ] 모바일 분기 (`ScrollTrigger.matchMedia`) — 핀/scrub 비활성, 4 카드 IO 진입
- [ ] Problem 시계 자동 채움 (0.45/1.0 회전)
- [ ] Solution 28일 캘린더 stagger 점등
- [ ] Authority KOL breathe + 상태 칩 pulse
- [ ] Pricing 추천 카드 glow
- **검증**:
  - [ ] 데스크탑·모바일 양쪽 60fps (DevTools Performance, Lighthouse)
  - [ ] 시각 일관성 — 디자이너 시안과 4 단계 매칭
  - [ ] reduced-motion 시 정적 4 카드 즉시 표시

### Step 6 — 성능·접근성 마감 (2-3h)

- [ ] 이미지 최적화 — SVG inline (이미 적용), favicon webp 변형
- [ ] 폰트 preload + `font-display: swap` + fallback `size-adjust` 매칭
- [ ] Lighthouse 측정 → 4점 통과
- [ ] WCAG AA 색 대비 검증 (Stark/Axe DevTools)
- [ ] 키보드 네비게이션 풀 테스트 (Tab으로 모든 인터랙티브 요소 도달)
- [ ] 스크린 리더 테스트 (VoiceOver 또는 NVDA로 Hero → AirPods Demo → FAQ → Final CTA)
- [ ] structured data (Product, FAQPage)
- [ ] sitemap.xml + robots.txt
- [ ] Vercel 배포 + 프로덕션 Lighthouse 측정
- **검증**:
  - [ ] Lighthouse Mobile Performance ≥ 90
  - [ ] Lighthouse Accessibility ≥ 95
  - [ ] Lighthouse SEO = 100
  - [ ] JS 번들 < 100KB gzipped
  - [ ] CSS 번들 < 50KB gzipped
  - [ ] CLS < 0.1, LCP < 2.5s, INP < 200ms

**총 예상**: 12-18h (한 사람 1.5-2.5일).

---

## 7. 기술 충돌 해결 — 디자인 ↔ 카피 ↔ 성능

### 충돌 #1 — AirPods Demo 핀 시퀀스 vs 모바일 60fps 예산

**문제**: 디자이너 §3.4 시그니처는 데스크탑 핀+scrub 4단계지만, 모바일 60fps 보장이 어려움.

**해결**: 디자이너가 이미 §3.4·§6.2에서 모바일은 핀/scrub 비활성, 4 카드 분리 IO 진입으로 명시. **추가 결정 없음** — 명세 그대로 구현. 단:
- **구현 우선순위**: Step 5에서 *모바일 4 카드 분리 진입*을 *먼저* 구현. 그 후 데스크탑 핀 시퀀스 추가. 모바일이 80% 사용자라 핵심 경험.
- **GSAP `ScrollTrigger.matchMedia` 사용 의무** — viewport ≥1024px에서만 핀 활성화.

### 충돌 #2 — Recharts vs 번들 예산

**문제**: 카피·디자인은 차트 4종을 요구. Recharts 추가 시 ≈60KB → 100KB 예산 초과.

**해결**: **Recharts 미사용**, 인라인 SVG로 직접 구현. 차트 4종은 모두 단순(원형 진행도, 게이지, 4×7 격자, 8 막대). D3·Chart.js도 미사용. `<Clock>`·`<HealthScoreGauge>`·`<CalendarMini>` 컴포넌트로 자체 구현. 16KB 절약.

### 충돌 #3 — drawSVG 유료 플러그인 vs 무료 빌드

**문제**: AirPods Demo Phase 3→4 라인→게이지 morph는 GSAP drawSVG가 표준. 그러나 drawSVG는 GSAP Premium 유료 ($99/년 Club Greensock).

**해결**: **2개 SVG cross-fade로 대체**. 라인 SVG와 게이지 SVG를 동일 위치에 겹쳐 두고, Phase 3→4 구간에서 라인 fade-out + 게이지 fade-in (0.4s overlap). 시각 결과 95% 동등. drawSVG 미사용. **0원**.

### 충돌 #4 — 카피 분량 vs 디자인 시안 (사소)

**문제**: Pricing 카드의 가격 정당화 카피("한국 내과 진료 1회 평균 비용이 약 12,000~25,000원이에요. ... 미국 Eat Right Now($24.99/월, 약 35,000원)의 1/3 이하예요. 진료를 대체하지 않아요. 진료가 닿지 못하는 8주의 일상을 채워요.")가 모바일 카드 아래 영역에서 4-5줄 차지.

**해결**: 카피 §6 보존 필수 #4("12,000~25,000원, $24.99/월, 9,900원 그대로")를 위배 안 함. 단:
- **모바일에서 `body-sm` (14px) `--color-text-muted`로 처리**. 줄바꿈은 자연 위치 (`word-break: keep-all`).
- 4-5줄이 시각 부담이면 *접기/펼치기* 토글 — but 이건 신뢰 카피라 *항상 보임*이 원칙. **결정: 모바일에서도 항상 표시, 폰트만 작게.**

### 충돌 #5 — Hero 폼 위치

**문제**: 카피 §3.1 Hero CTA는 `[ 베타에 합류하기 ] / [ 어떻게 작동하는지 보기 ]`. 폼이 아닌 *버튼*. 디자이너 §3.1도 동일. M6은 "베타 가입 폼 1필드"인데 *Final CTA*에만 적용.

**해결**: Hero는 *버튼만*, 클릭 시 Final CTA 섹션으로 스크롤(앵커). 폼은 Final CTA + Footer 2곳에 둠. **EmailForm은 Hero에 *없음*.** 위 §3 컴포넌트 명세에 반영. (이전 구현자가 헷갈리지 않도록 04_brief에도 명시.)

---

## 8. 후속 작업 가이드라인

- **카피 변경 시**: 04_brief §1만 갱신 (또는 `data/*.ts`만 — FAQ·페르소나·가격은 데이터 분리). 03 파일은 컴포넌트 구조가 안 바뀌면 갱신 불필요.
- **디자인 토큰 변경 시**: 04_brief §2 + `src/styles/tokens.css` + `tailwind.config.ts` 동시 갱신.
- **새 섹션 추가 시**: 03 §3 컴포넌트 명세 + §6 빌드 단계 + 04_brief §3 갱신.
- **시그니처 인터랙션 변경 시**: 03 §1.3 + §7 충돌 #1·#3 + 04_brief §4 갱신.
- **성능 예산 미달 시**: 03 §5 + 04_brief §6 검증 항목 갱신. 디자인 사양과 협상 (예: KOL breathe 무한 루프 비활성).

---

## 9. 결론

옵션 G 랜딩은 *Vite + React + Tailwind + GSAP + Lenis*의 표준 스택으로 구현 가능. 시그니처 인터랙션은 무료 라이브러리 조합으로 옵션 B 충실 구현. 모바일 60fps는 핀/scrub 비활성 + 4 카드 분리로 보장. 가장 큰 충돌은 *drawSVG 유료 회피* — cross-fade로 해결.

frontend-implementer는 다음 파일만 보면 된다: `04_brief_consolidated.md`.
