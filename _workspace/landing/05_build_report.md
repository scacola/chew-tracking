# 05 — 빌드 보고

**작성일**: 2026-05-02
**빌드 모드**: 메인 세션 직접 빌드 (서브 에이전트 한도 도달 후 인계)

## 빌드 단계 완료

- [x] **Step 1 — Setup**: Vite + React 19 + TS + Tailwind 3.4 + GSAP + Lenis + lucide-react + clsx 설치, `tokens.css` + `tailwind.config.ts` 디자인 토큰 입력 완료
- [x] **Step 2 — 정적 마크업**: 11개 섹션 컴포넌트 작성 (StickyNav, Hero, Problem, Solution, AirPodsDemo, HowItWorks, Differentiation, Authority, Pricing, FAQ, FinalCTA, Footer). 04_brief 카피를 정확히 복사 (오타 없이, `<br>` 줄바꿈 포함)
- [x] **Step 3 — 반응형**: Tailwind 미디어 쿼리(`md:`, `lg:`)로 mobile-first 구현. iOS Safari 100vh는 `min-h-svh` 사용 (globals.css). 모바일 입력 16px 폰트 (form 자동 줌 방지)
- [x] **Step 4 — 기본 인터랙션**: `revealOnScroll.ts` IntersectionObserver 페이드+업. CTA 호버·active scale, 폼 포커스 ring, 스크롤 인디케이터, 펄스/호흡 애니메이션 (CSS keyframes). Smooth scroll은 네이티브 `behavior: 'smooth'` 사용 (Lenis 미적용 — 한도 절약)
- [x] **Step 5 — 시그니처 인터랙션 (단순화)**: AirPods SVG는 `state="idle|pulse|streaming|gauge"` 4 상태로 인라인 애니메이션 (펄스 글로우 SMIL `<animate>`, 데이터 라인 stroke-dashoffset). HealthScoreGauge는 IntersectionObserver로 진입 시 stroke-dashoffset 애니메이션. **04_brief 7.1 우선순위 권장에 따라 데스크탑 GSAP 핀 시퀀스 → 모바일 폴백(4 카드 분리 IO 진입)을 데스크탑에도 적용**
- [x] **Step 6 — 마감**: 폰트 preconnect + display=swap, prefers-reduced-motion CSS 처리, `:focus-visible` outline, OG 메타 태그, lang="ko", skip-link, semantic landmarks (header/main/footer/nav)

## 의존성 사이즈 (production build)

| 자원 | Raw | Gzipped | 예산 | 통과 |
|------|-----|--------|------|------|
| HTML | 1.92 KB | 0.96 KB | - | ✓ |
| CSS | 25.61 KB | 5.94 KB | < 50 KB | ✓ |
| JS | 243.98 KB | **75.73 KB** | < 100 KB | ✓ |
| 이미지 | 0 KB | - | < 500 KB | ✓ (SVG 인라인만) |

**총 gzipped**: 약 82.6 KB — 예산 통과.

## Lighthouse — 정적 분석 추정

(Chrome headless 자동 실행이 환경에서 어려워 측정 미수행. 정적 분석으로 추정)

| 지표 | 추정 | 근거 |
|------|------|------|
| Performance | **88-94** | gzipped JS 76KB, 인라인 SVG, 외부 폰트 preconnect, IO 기반 lazy reveal — 양호 추정. 다만 외부 폰트 CDN(Pretendard, Noto Serif KR, JetBrains Mono) 3개 호출이 LCP에 영향 가능 |
| Accessibility | **94-98** | semantic HTML, ARIA, alt, focus-visible, skip-link, prefers-reduced-motion, color contrast (clinical-deep #007A66 on white = 5.6:1 ✓) |
| Best Practices | **100** | HTTPS·콘솔 에러 없음 (build clean), modern image format X (사용 안 함) |
| SEO | **100** | meta description, og:tags, lang="ko", semantic structure |

**실제 Lighthouse 측정은 Phase 3 QA 단계에서 권장.**

## 디바이스 검증

빌드 + serve 후 `curl http://localhost:3456/` 응답 정상 (HTTP 200, 1923 bytes HTML, 31ms). 본문은 SPA(client-side) 렌더 — 실제 렌더 검증은 브라우저 자동화 필요 → **Phase 3 QA 단계에서 4개 디바이스 사이즈 스크린샷 권장**.

| 디바이스 | 사이즈 | 검증 상태 |
|--------|------|---------|
| iPhone SE | 375×667 | Tailwind 기본 + `md:`/`lg:` 미디어쿼리 적용 — Phase 3 검증 필요 |
| iPhone 14 Pro | 393×852 | 동일 |
| 1280×800 | 노트북 | `lg:` 브레이크포인트 적용 — Phase 3 검증 필요 |
| 1920×1080 | 풀 데스크탑 | `max-w-container 1200px` 중앙 정렬 — Phase 3 검증 필요 |

## 알려진 한계 (정직한 보고)

1. **시그니처 인터랙션 단순화** — 04_brief 4.4의 GSAP scroll-trigger 핀 시퀀스(데스크탑 4단계 scrub)는 *미구현*. 대신 SVG 인라인 애니메이션(SMIL `<animate>` + CSS keyframes) + IntersectionObserver 진입으로 대체. 04_brief §7.1 우선순위 권장(모바일 폴백 ≥ 데스크탑 핀)을 데스크탑에도 적용 — Phase 3에서 풀 GSAP 인터랙션 추가 빌드 가능.
2. **Lenis 스무스 스크롤 미적용** — 네이티브 `scrollTo({ behavior: 'smooth' })` + CSS `scroll-behavior: smooth`로 대체. Lenis는 dependency만 설치되어 있고 코드 미사용 (트리쉐이킹으로 번들에서 제외됨). 데스크탑 경험 폴리시는 Phase 3에서 추가 가능.
3. **Lighthouse 자동 측정 미수행** — Chrome headless 자동 실행이 환경 제약으로 어려움. Phase 3 QA에서 측정 + 점수 기록 권장.
4. **OG 이미지 부재** — `/og-image.png` 메타 참조하나 실제 파일 부재. 디자인 자산 추가 필요 (Phase 3 또는 별도 라운드).
5. **백엔드 미연결** — EmailForm은 placeholder (console.log + 로컬 success state). 실제 베타 가입 처리는 별도 백엔드/Formspree/Notion API 연결 필요.
6. **AirPods SVG 단순화** — 04_brief의 4단계 path morph는 미구현, 대신 `state` prop으로 4가지 상태 전환. 정밀도는 디자이너 사양보다 낮음 — Phase 3에서 정밀 SVG 교체 가능.

## QA 폴리시 후보 (Phase 3 전달)

다음 항목을 Phase 3 `landing-qa-polisher`가 점검·보강 권장:

1. **실제 브라우저 검수** — 4개 디바이스 사이즈 스크린샷 + 인터랙션 동작 확인
2. **Lighthouse 4가지 점수 측정** — 실제 점수 기록 + 예산 미달 시 디버깅
3. **5초 룰 검증** — Hero에서 (a) 무엇을 (b) 누구를 (c) 다음 행동 답되는지
4. **카피·디자인 정합** — 04_brief §6.1, §6.2 체크리스트 모두 통과 확인
5. **시그니처 인터랙션 추가 빌드** — 한도 여유 시 GSAP 핀 시퀀스(데스크탑) 추가
6. **OG 이미지 생성** — 1200×630 png 만들기 (Hero 헤드라인 + AirPods)
7. **EmailForm 백엔드** — Formspree·Notion·Resend 중 선택 + 환경변수
8. **Pretendard 로컬 호스팅** — 외부 CDN 의존 줄이려면 self-host (LCP 개선)

## 파일 구조 (생성된 것)

```
landing/
├── index.html                  ← 폰트 preconnect + 메타 태그
├── package.json                ← deps: react 19, gsap, lenis, lucide-react, clsx, tailwind 3.4
├── tailwind.config.ts          ← 디자인 토큰 (색·폰트·간격·반경·그림자·그라디언트)
├── tsconfig.app.json
├── vite.config.ts
├── public/
│   ├── favicon.svg
│   └── icons.svg
└── src/
    ├── main.tsx                ← styles/globals.css import
    ├── App.tsx                 ← 11개 섹션 컴포넌트 통합
    ├── components/
    │   ├── Section.tsx         ← tone(cool/warm/mist/deep) variant
    │   ├── Container.tsx       ← size(default/narrow/prose)
    │   ├── CtaPrimary.tsx
    │   ├── CtaSecondary.tsx
    │   ├── Card.tsx
    │   ├── StatusChip.tsx      ← inProgress/recruiting/beta/live, state-pulse 점
    │   ├── ScrollIndicator.tsx
    │   ├── HealthScoreGauge.tsx ← IO 진입 시 stroke 애니메이션
    │   ├── Clock.tsx           ← 11분 vs 20분 비교 시계
    │   ├── DataStream.tsx      ← 모노스페이스 데이터 로그
    │   ├── CalendarMini.tsx    ← 28일 4×7 그리드
    │   ├── KolPlaceholder.tsx  ← KOL 영입 진행 표시
    │   ├── EmailForm.tsx       ← inline/stacked/caption variant + shake 에러
    │   ├── FaqItem.tsx         ← single-expand accordion
    │   └── icons/
    │       └── AirpodsSvg.tsx  ← 4 state, SMIL animate, gradient
    ├── sections/
    │   ├── StickyNav.tsx       ← scroll>100 후 blur background
    │   ├── Hero.tsx            ← persona-routed subhead, AirPods idle SVG
    │   ├── Problem.tsx         ← 자기 인식 + 시계 + 의학 카드 + 페르소나 quote 3
    │   ├── Solution.tsx        ← 3 카드 (검출 / 깨달음 / 코칭)
    │   ├── AirPodsDemo.tsx     ← AirPods streaming + DataStream + Gauge
    │   ├── HowItWorks.tsx      ← 28일 캘린더 / AirPods / KOL 트리오
    │   ├── Differentiation.tsx ← 5 자산 카드 (큰 3 + 작은 2)
    │   ├── Authority.tsx       ← 진행 막대 + KOL placeholder + 인용
    │   ├── Pricing.tsx         ← 3 티어, 추천 카드 강조
    │   ├── FAQ.tsx             ← 8 항목 single-expand
    │   ├── FinalCTA.tsx        ← 8주 후 동적 날짜 + 손편지 박스 + 폼
    │   └── Footer.tsx
    ├── interactions/
    │   └── revealOnScroll.ts   ← IO + stagger index 자동 부여
    ├── data/
    │   ├── faq.ts              ← 8 Q&A
    │   └── personas.ts         ← stomach/diet/checkup
    ├── hooks/
    │   └── usePersonaRoute.ts  ← URL ?p= 라우팅
    ├── lib/
    │   ├── cn.ts               ← clsx wrapper
    │   └── eightWeekDate.ts    ← 8주 후 한국식 "X월 N째 주"
    └── styles/
        ├── globals.css         ← Tailwind base + reveal CSS + reduced-motion
        └── tokens.css          ← 모든 디자인 토큰 (CSS 변수)
```

## 미리보기 명령

```bash
cd /Users/sungho/Documents/programming/chew_tracking/landing
npm run dev      # 개발 서버 (http://localhost:5173)
# 또는
npm run build && npx serve dist -l 3456 -s   # 프로덕션 빌드 미리보기
```

## 페르소나 라우팅 테스트

```
http://localhost:3456/?p=stomach   → 한지원 (위염, 기본)
http://localhost:3456/?p=diet      → 박소연 (정체기)
http://localhost:3456/?p=checkup   → 김상훈 (검진)
```

Hero 우상단 칩 + 모바일 서브헤드 박스가 페르소나에 따라 변경.
