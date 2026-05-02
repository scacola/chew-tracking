---
name: frontend-craft
description: 통합 브리프(04_brief_consolidated.md)를 받아 작동하는 인터랙티브 랜딩 페이지를 빌드하고 자체 검증·폴리시까지 수행하는 방법론. Vite·React·Tailwind·GSAP·Lenis 기반 빌드, 디바이스 매트릭스 검증, Lighthouse 통과 기준 포함. 인터랙티브 웹 빌드, 랜딩 페이지 구현, "사이트 만들어줘" 같은 요청에서 트리거.
---

# Frontend Craft

빌드의 핵심은 *결정하지 않는 것*. 카피·디자인·기술 결정은 04_brief_consolidated에 있다. 구현자는 *그것을 정확히 코드로 변환*하면 된다. 변환 정확도와 디테일이 *세상 어디서도 보지 못할 퀄리티*를 가른다. `frontend-implementer` 에이전트가 사용한다.

## 왜 이 스킬이 필요한가

LLM 기반 frontend 빌드의 흔한 실패:
- 사양과 *살짝 다르게* 코드 생성 (색·간격 미세 차이)
- 단계 건너뛰기 (반응형 검증 안 함)
- 자체 결정 (사양 없는 부분을 추측으로 채움)
- 검증 없이 "다 했어요" 보고

이 스킬은 *정확성·단계 준수·자체 검증*을 강제한다.

## 6단계 빌드 — 순서 엄수

각 단계 끝에 *반드시* 검증. 다음 단계로 가기 전 체크리스트 통과 필수.

### Step 1: Setup (30min)

```bash
cd /Users/sungho/Documents/programming/chew_tracking
mkdir landing && cd landing
npm create vite@latest . -- --template react-ts
npm install
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p
npm install gsap lenis recharts lucide-react
```

설정:
- `tailwind.config.ts` — 04_brief의 디자인 토큰 입력
- `src/styles/globals.css` — Tailwind directive + tokens.css import
- `tsconfig.json` — strict mode

검증:
```bash
npm run dev
# → http://localhost:5173 접속, 빈 페이지 정상 표시
```

### Step 2: 정적 마크업·스타일 (3-5h)

각 섹션 컴포넌트를 *시안 그대로* 빌드. 인터랙션 없이 정적으로 먼저.

```tsx
// src/sections/Hero.tsx
export function Hero() {
  return (
    <section className="relative min-h-svh flex items-center justify-center px-4 md:px-8">
      <div className="max-w-4xl text-center">
        <h1 className="text-display font-semibold leading-tight">
          {/* 04_brief의 정확한 카피 */}
        </h1>
        {/* ... */}
      </div>
    </section>
  )
}
```

원칙:
- **카피는 정확히 복사** — 띄어쓰기, 줄바꿈, 따옴표 모두
- **디자인 토큰만 사용** — 인라인 색·크기 절대 금지. `bg-clinical` 같은 토큰만
- **모바일 먼저** — 기본 스타일은 모바일, 데스크탑은 `md:` `lg:` 미디어 쿼리

검증:
```bash
# dev 서버에서 모든 섹션 시각 확인
# Bash로 백그라운드 dev 서버 + browse 스킬로 스크린샷
```

### Step 3: 반응형 (1-2h)

- 320px (iPhone SE), 375px, 393px, 1280px, 1920px 5개 사이즈 검증
- iOS Safari 100vh 버그 → `min-h-svh` 사용
- 폰트 사이즈 모바일 0.85배 적용
- 터치 영역 ≥ 44×44px
- 입력 필드 font-size 16px+ (iOS 자동 줌 방지)

검증: `browse` 스킬 또는 Playwright로 5개 사이즈 스크린샷, 깨짐 없음 확인.

### Step 4: 기본 인터랙션 (2-3h)

- 호버: `transition-all duration-200 ease-out hover:scale-[1.02] hover:shadow-lg`
- 클릭 피드백: `active:scale-[0.97]`
- 스크롤 진입 페이드: `fadeInOnScroll('.fade-in')` 패턴 적용
- Lenis 스무스 스크롤 init (모바일 disable 옵션)
- 폼 포커스 ring

```ts
// src/interactions/smoothScroll.ts
import Lenis from 'lenis'

export function initSmoothScroll() {
  if (window.matchMedia('(pointer: coarse)').matches) return  // 모바일 스킵
  const lenis = new Lenis({ duration: 1.2 })
  function raf(time: number) {
    lenis.raf(time)
    requestAnimationFrame(raf)
  }
  requestAnimationFrame(raf)
}
```

검증: 60fps 유지, 콘솔 경고 없음. Chrome DevTools Performance 탭으로 측정.

### Step 5: 시그니처 인터랙션 (3-5h)

AirPods 시각화 (옵션 B SVG morph 권장 — 모바일 안전):

```tsx
// src/sections/AirPodsDemo.tsx
import { useEffect, useRef } from 'react'
import { gsap } from 'gsap'
import { ScrollTrigger } from 'gsap/ScrollTrigger'

gsap.registerPlugin(ScrollTrigger)

export function AirPodsDemo() {
  const ref = useRef<HTMLDivElement>(null)
  useEffect(() => {
    if (!ref.current) return
    const ctx = gsap.context(() => {
      const tl = gsap.timeline({
        scrollTrigger: {
          trigger: ref.current,
          start: 'top center',
          end: 'bottom top',
          scrub: 1,
        }
      })
      tl.from('.airpods-svg path', { drawSVG: 0, stagger: 0.05 })
        .to('.data-particle', { y: -100, opacity: 0, stagger: 0.02 })
    }, ref)
    return () => ctx.revert()
  }, [])
  return <div ref={ref}>{/* SVG + 입자 */}</div>
}
```

(GSAP `drawSVG`는 유료 플러그인. 대안: stroke-dashoffset 애니메이션으로 동일 효과 무료 구현.)

검증: 데스크탑·모바일 모두 60fps. iOS Safari 별도 검증.

### Step 6: 성능·접근성 마감 (2-3h)

이미지:
```bash
# webp 변환
brew install webp
cwebp public/og-image.png -o public/og-image.webp -q 85
```

폰트:
```html
<link rel="preload" as="font" type="font/woff2" href="..." crossorigin />
```

prefers-reduced-motion:
```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}
```

WCAG AA 검증:
- 색 대비 도구 (Contrast Checker)로 모든 텍스트·배경 조합 측정
- 키보드 only 네비게이션 가능
- ARIA 라벨 누락 없음

Lighthouse:
```bash
npm run build
npm install -g serve
serve -s dist
# 다른 터미널: chrome --headless lighthouse http://localhost:3000
```

목표: Performance ≥ 90, Accessibility ≥ 95, SEO = 100. 예산 미달 시 디버깅 (큰 의존성·이미지 식별).

## 자체 검증 — 빌드 보고

빌드 끝나면 `_workspace/landing/05_build_report.md` 작성:

```markdown
# 빌드 보고

## 빌드 단계 완료
- [x] Step 1: Setup
- [x] Step 2: 정적 마크업
- [x] Step 3: 반응형
- [x] Step 4: 기본 인터랙션
- [x] Step 5: 시그니처 인터랙션
- [x] Step 6: 마감

## 의존성 사이즈
- React + ReactDOM: 42KB (gzipped)
- GSAP: 38KB
- Lenis: 4KB
- 합계 JS: 89KB ✓ (예산 100KB 이내)

## Lighthouse 점수
- Performance: 94 ✓
- Accessibility: 96 ✓
- Best Practices: 100
- SEO: 100 ✓

## 디바이스 검증 (스크린샷 첨부)
- iPhone SE (375): screenshots/iphone-se.png ✓
- iPhone 14 Pro (393): ✓
- 1280×800: ✓
- 1920×1080: ✓

## 알려진 한계
- iOS Safari 시그니처 인터랙션 첫 로드 1.2s — placeholder PNG 권고
- Three.js 3D는 사용 안 함 (옵션 B SVG 채택)

## QA 폴리시 후보
- Hero CTA 위치를 80px → 40px 좁혀 fold 안에 들어오게 권고
- FAQ 섹션 호버 효과 누락 가능성
```

QA에서 *이 보고서를 출발점*으로 검수하므로, 거짓 표시 절대 금지.

## 라이브러리 사용 가드

- ❌ jQuery, Bootstrap (현대적 아님)
- ❌ Lottie (옵션 G에 적합한 자산 없음)
- ❌ Framer Motion + GSAP 동시 사용 (중복)
- ❌ moment.js (덩어리, dayjs로 대체)
- ✅ GSAP, Lenis, Recharts, Lucide
- ✅ 필요 시 Three.js (지연 로드 + placeholder)

## 흔한 실수

- ❌ "다 만든 후" 시안 비교 — 단계마다 비교
- ❌ 콘솔 경고 무시
- ❌ 폰트 FOUT 처리 누락 (텍스트 점프)
- ❌ 이미지 raw 사용 (압축·webp 변환 필수)
- ❌ 사양 불확실 시 추측 (사용자/팀에 질문)
- ❌ Tailwind arbitrary value 남용 (`w-[127px]` 같은 것 — 토큰만 사용)

## 후속 작업

- QA 발견 이슈 → 해당 컴포넌트만 수정, 다른 곳 영향 X
- 사용자가 카피·디자인 변경 요청 → Phase 1 팀이 브리프 갱신 후 재호출 (구현자가 직접 X)
- 새 섹션 → 04_brief에 명세 추가 후 진행
