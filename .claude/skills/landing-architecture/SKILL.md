---
name: landing-architecture
description: 카피와 디자인 사양을 frontend-implementer가 그대로 빌드 가능한 통합 기술 명세로 변환하는 방법론. 기술 스택 결정, 컴포넌트 분해, 라이브러리 선택, 성능·접근성 예산 설정 시 반드시 사용. "기술 스택 결정", "컴포넌트 분해", "랜딩 빌드 계획", "통합 브리프" 같은 요청에서 트리거.
---

# Landing Architecture

Phase 1 팀의 *번역자*. 카피와 디자인 사양을 받아 *빌드 가능한 단일 명세서*로 합친다. `landing-architect` 에이전트가 사용한다.

## 왜 이 스킬이 필요한가

frontend-implementer가 *카피·디자인·기술 결정을 동시에* 해야 하면 일관성이 무너진다. 이 스킬은 *모든 결정을 사전에 단일 문서에 통합*하여, 구현자가 "코드에만 집중"할 수 있게 한다. 한 마디로 *분업의 인터페이스*다.

## 기술 스택 결정 프레임

랜딩 페이지 1개에 적합한 스택 선택지 — *목표가 결정한다*:

| 목표 | 권장 스택 | 비추천 |
|------|---------|-------|
| 가벼움 + 빠른 빌드 | Vite + Vanilla TS + Tailwind | Next.js (오버킬) |
| 컴포넌트 재사용·복잡도 | Vite + React + Tailwind | jQuery |
| SEO·OG 우수 | Astro (정적 생성) | SPA만 |
| Apple급 시그니처 인터랙션 | + GSAP + Lenis (어떤 베이스든) | Framer Motion 단독 (3D·스크롤 시퀀스 약함) |
| 마운트 후 변경 거의 없음 | Astro 또는 vanilla | React (낭비) |

옵션 G 랜딩 권장 출발점:

```
Vite + React (TypeScript) + Tailwind CSS
+ GSAP (시그니처 스크롤 시퀀스)
+ Lenis (스무스 스크롤)
+ Recharts (식사 데이터 차트)
+ Lucide (아이콘)
```

이유:
- **Vite**: 빌드 빠름, 단순
- **React**: 컴포넌트 분해로 카피·디자인 변경 시 영향 격리
- **Tailwind**: 디자인 토큰을 config로 관리 → 디자이너 사양과 1:1 매핑
- **GSAP**: AirPods 시그니처 + 스크롤 시퀀스에 표준
- **Lenis**: 스무스 스크롤이 *경험 품질*에 큰 차이
- **Recharts**: React 호환 차트, 가벼움
- **Lucide**: 아이콘 트리 셰이킹

호스팅: **Vercel** (이미 vercel:deploy 스킬 환경에 있음).

## 파일 구조 — 권장

```
landing/
├── index.html
├── package.json
├── vite.config.ts
├── tailwind.config.ts
├── tsconfig.json
├── public/
│   ├── og-image.png
│   ├── favicon.ico
│   └── airpods-3d.glb (사용 시)
└── src/
    ├── main.tsx
    ├── App.tsx
    ├── styles/
    │   ├── globals.css      (Tailwind base + custom)
    │   └── tokens.css       (디자인 토큰 — CSS 변수)
    ├── sections/            (페이지 섹션 = 컴포넌트)
    │   ├── Hero.tsx
    │   ├── Problem.tsx
    │   ├── Solution.tsx
    │   ├── AirPodsDemo.tsx
    │   ├── HowItWorks.tsx
    │   ├── Differentiation.tsx
    │   ├── Authority.tsx
    │   ├── Pricing.tsx
    │   ├── FAQ.tsx
    │   └── FinalCTA.tsx
    ├── components/          (재사용)
    │   ├── Button.tsx
    │   ├── Card.tsx
    │   ├── ScrollIndicator.tsx
    │   └── GradientCanvas.tsx
    ├── interactions/        (모션·시그니처)
    │   ├── airpodsScroll.ts (GSAP scroll-trigger)
    │   ├── fadeInOnScroll.ts
    │   └── smoothScroll.ts  (Lenis init)
    ├── data/                (정적 데이터)
    │   ├── faq.ts
    │   ├── personas.ts
    │   └── kol.ts
    └── lib/
        └── analytics.ts     (이벤트 트래킹 placeholder)
```

## 컴포넌트 명세 표준

각 컴포넌트마다 다음 형식:

```markdown
### `<Hero>`
**책임**: 페이지 첫 시각 + 1차 CTA
**Props**:
  - `headline: string`
  - `subhead: string`
  - `ctaLabel: string`
  - `onCtaClick: () => void`
**상태**: 없음 (정적)
**의존**: `<Button>`, `<GradientCanvas>`, `<ScrollIndicator>`
**모션 마운팅**: `useEffect` 안에서 `airpodsScroll.init()` 호출 (시그니처 인터랙션이 Hero에 걸쳐 있으므로)
**접근성**: `<h1>` 태그, 1개만; CTA는 `<button>` (링크면 `<a>`)
**테스트 항목**: 모바일 320px 너비에서 헤드라인 줄바꿈 자연스러운가
```

이 형식이 frontend-implementer에게 *결정 없이 빌드 가능*한 입력이다.

## 인터랙션 의사코드 패턴

### 스크롤 진입 페이드 (모든 섹션 공통)

```ts
// src/interactions/fadeInOnScroll.ts
import { gsap } from 'gsap'
import { ScrollTrigger } from 'gsap/ScrollTrigger'

gsap.registerPlugin(ScrollTrigger)

export function fadeInOnScroll(selector: string) {
  gsap.utils.toArray<HTMLElement>(selector).forEach((el) => {
    gsap.from(el, {
      opacity: 0,
      y: 24,
      duration: 0.6,
      ease: 'cubic-bezier(0.16, 1, 0.3, 1)',
      scrollTrigger: {
        trigger: el,
        start: 'top 85%',
      },
    })
  })
}

// prefers-reduced-motion 시 모션 비활성화
if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
  gsap.set('*', { opacity: 1, y: 0 })
}
```

### AirPods 시그니처 (옵션 B SVG 권장)

```ts
// src/interactions/airpodsScroll.ts
// SVG path를 GSAP morph로 스크롤 진행률에 매핑
// 데이터 입자(<circle>)를 stagger로 그려 시각화
// 상세는 visual-experience-designer 사양 참고
```

## 데이터 모델

랜딩 페이지에 백엔드는 없지만 일부 데이터는 모델링:

```ts
// src/data/personas.ts
export type Persona = 'office-worker' | 'dieter' | 'gastritis-patient'

export const personas: Record<Persona, {
  name: string
  age: number
  story: string
  subhead: string
}> = { /* ... */ }

// 쿼리스트링 ?p=dieter 로 페르소나 분기 (실험용)
```

```ts
// src/lib/analytics.ts (추후 PostHog 등 연결)
export function track(event: string, props?: Record<string, any>) {
  if (typeof window === 'undefined') return
  console.log('[track]', event, props)  // dev placeholder
}
```

## 성능·접근성 예산

| 메트릭 | 목표 | 측정 방법 |
|--------|------|---------|
| LCP | < 2.5s (모바일 4G) | Lighthouse, PageSpeed Insights |
| CLS | < 0.1 | Lighthouse |
| INP | < 200ms | Lighthouse |
| JS 번들 | < 100KB (gzipped) | `vite build` 출력 |
| CSS 번들 | < 50KB (gzipped) | 동상 |
| 이미지 합 | < 500KB | `du -sh public/` |
| Lighthouse Performance | ≥ 90 | CI |
| Lighthouse Accessibility | ≥ 95 | CI |
| Lighthouse SEO | = 100 | CI |

예산을 *측정 가능*하게 하라. "빠르게" 같은 모호 표현 금지.

## 빌드 단계 — frontend-implementer가 따를 6단계

각 단계 끝에 *반드시* 검증:

```
1. Setup (30min)
   - npm init vite + 의존성 설치
   - tsconfig, tailwind, vite 설정
   - 디자인 토큰을 tailwind.config / tokens.css 에 입력
   - 검증: dev 서버 시동 + 빈 페이지 정상 표시

2. 정적 마크업·스타일 (3-5h)
   - 모든 섹션 컴포넌트 골격 (카피 그대로 입력)
   - Tailwind 유틸로 디자인 토큰 적용
   - 모바일 우선, 데스크탑 미디어 쿼리 후속
   - 검증: 모든 섹션이 시안과 시각적 일치 (스크린샷 비교)

3. 반응형 (1-2h)
   - 모든 브레이크포인트 검증
   - 터치·마우스 인풋 차이 처리
   - iOS Safari 100vh 처리 (svh)
   - 검증: 4개 디바이스 사이즈에서 깨짐 없음

4. 기본 인터랙션 (2-3h)
   - 호버, 클릭, 폼 포커스
   - 스크롤 진입 페이드 (fadeInOnScroll 적용)
   - 스무스 스크롤 (Lenis init)
   - 검증: 모든 인터랙션이 60fps

5. 시그니처 인터랙션 (3-5h)
   - AirPods SVG morph + 데이터 스트림 (GSAP scroll-trigger)
   - 차트 모션
   - 검증: 모바일·데스크탑 양쪽에서 60fps + 시각 일관성

6. 성능·접근성 마감 (2-3h)
   - 이미지 최적화 (webp, lazy load)
   - 폰트 preload + fallback 매칭
   - prefers-reduced-motion 대응
   - WCAG AA 색 대비 검증
   - Lighthouse 측정 → 예산 통과 확인
   - 검증: Lighthouse 4가지 점수 모두 통과
```

총 예상 11-19h. 한 사람이 1.5-3일 작업 분량.

## 04_brief_consolidated.md 형식

이 파일이 *전달의 핵심*. 다음 구조 엄격 준수:

```markdown
# Chew & Calm Coach 랜딩 페이지 통합 브리프

## 1. 카피 (섹션별)
[01_strategy_copy.md에서 그대로 복사 — frontend가 다른 파일 안 보도록]

## 2. 디자인 토큰
### CSS 변수
```css
:root {
  --color-bg-cool: #FFFFFF;
  /* ... */
}
```
### Tailwind config
```ts
export default {
  theme: { extend: { colors: { /* ... */ } } }
}
```

## 3. 컴포넌트 명세
[위 형식의 컴포넌트별 카드]

## 4. 인터랙션 사양
[의사코드 + 라이브러리 선택]

## 5. 빌드 단계
[6단계 — 각 단계 검증 항목 체크리스트]

## 6. 성공 기준 체크리스트
- [ ] 모든 섹션 시안 일치
- [ ] 4개 디바이스 사이즈 검증
- [ ] Lighthouse 4점 통과
- [ ] (전체 검증 항목)
```

## 후속 작업

- 기술 스택 변경 (예: Astro로 마이그레이션) 요청 시 03_architecture만 갱신, 04_brief의 영향 부분 동기화
- 새 컴포넌트 추가 시 명세 + 빌드 단계에 추가
- 성능 예산 미달 시 디자인 사양과 *협상* (예: "3D 모델을 SVG로 다운그레이드 권고")
