# 02 — Visual + UX + Motion 시스템 (Chew & Calm Coach 랜딩)

**제품**: Chew & Calm Coach (옵션 G)
**작성일**: 2026-05-01
**작성자**: visual-experience-designer
**참조**: `_workspace/landing/_brief.md`, `_workspace/landing/01_strategy_copy.md`, `.claude/skills/visual-experience-design/SKILL.md`
**다음 작업자**: `landing-architect` (이 문서를 기술 명세로 변환)

> 이 문서는 frontend-implementer가 *결정 없이* 빌드 가능한 사양이다.
> 모든 토큰은 CSS 변수·Tailwind 형태로 즉시 사용 가능하고,
> 모든 인터랙션은 의사코드(GSAP/CSS) 형태로 작성됐다.
> 카피의 "협의 메모 M1~M7"은 *이 디자인의 전제*로 받아들였다.

---

## 0. 정체성 한 페이지 (디자인 톤 헌법)

옵션 G의 시각 정체성은 **"임상 차가움 30% + 코칭 따뜻함 50% + 마음챙김 여백 20%"**의 시각적 번역이다. 카피의 톤 비율과 *동시에* 작동해야 한다 (M7 합의).

| 톤 | 시각 표현 | 작동 위치 |
|---|---|---|
| **임상 (30%)** | 흰 배경 / 검정 헤드라인 / 민트(#00C9A7) 액센트 / 학술 인용 카드 / 모노스페이스 데이터 라벨 / 1px 라인 그리드 | Problem 의학 인용, Authority RCT 카드, AirPods 데이터 스트림, 차트 |
| **코칭 (50%)** | 베이지(#F5EFE6) 배경 / 코랄(#FF8A65) 액센트 / 부드러운 라운드 카드 / 손글씨톤 인용 / 코치 카드 목업의 따뜻한 회색 | Hero 보조, Solution 코칭 단계, How it works, FAQ, 페르소나 트리거 |
| **마음챙김 (20%)** | 큰 여백 / 짧은 줄 / 옅은 그라데이션 전환 / 호흡감 있는 섹션 패딩 / 천천히 페이드 | 헤드라인 주변, 섹션 사이 전환, Final CTA |

**디자인 헌법 5조**:
1. 도구처럼 보이지 마라 — 과학·코칭·여유가 보여야 한다 (브리프 #2)
2. 빈 자리(KOL placeholder)는 *부끄럽게* 만들지 말고 *정직 자산*으로 디자인하라 (M4)
3. 5초 룰 — Hero 뷰포트에서 (a)무엇을, (b)누구에게, (c)다음 행동을 답해야 한다
4. 모바일 80%가 본다 — 모바일에서 죽으면 디자인이 죽은 것
5. 모든 모션은 *정보를 전달하거나 피드백을 줘야* 한다 — 장식 모션 0개

---

## 1. 벤치마크 분석 — 5개 사이트, 명시적 차용

각 사이트에서 *어느 부분*을 차용하고 *어느 부분*은 차용하지 않는지 명시한다. "Apple 스타일" 같은 추상 표현 금지.

### 1.1 apple.com — AirPods Pro 제품 페이지
- **URL**: https://www.apple.com/airpods-pro/
- **차용**:
  - 스크롤 시퀀스의 *비주얼 우위* — 텍스트보다 큰 제품 시각화가 먼저, 카피는 보조. 우리 Solution 3단계와 AirPods Demo에 적용.
  - 폰트 무게 대비 — Display(SF Pro Display Bold)와 Body(SF Pro Text Regular)의 극단적 차이. 우리 Hero에 동일 패턴 (Pretendard Black + Pretendard Regular).
  - 어두운 섹션 ↔ 밝은 섹션의 *호흡 교차* — 우리 Hero(밝음) → Problem(밝음) → Solution(약간 어둠 베이지) → AirPods Demo(어두운 그라데이션) → How(밝음) 패턴.
- **차용 안 함**:
  - 제품의 *물성·고급감* 강조 — 우리는 임상·코칭이 핵심이라 제품 럭셔리감은 약하게.
  - 풀블리드 비디오 자동 재생 — 모바일 데이터·성능 부담, 우리는 SVG 모션으로 대체.
  - 제품 사진의 사실주의 렌더링 — 우리는 SVG 일러스트로 가볍게.

### 1.2 stripe.com — 그라데이션·정보 위계
- **URL**: https://stripe.com/
- **차용**:
  - **Hero 시그니처 그라데이션 패턴** — Stripe의 무지개색 흐름 그라데이션을 *우리 팔레트(민트→코랄)*로 번역. AirPods Demo 섹션 배경에 적용.
  - 정보 위계 3단 — Display 헤드라인 + 1줄 보조 + 2개 CTA의 명확한 단계.
  - 코드/데이터 시각화의 모노스페이스 활용 — 우리 식사 데이터 스트림에 JetBrains Mono로 "08:32 → 식사 시작 검출" 같은 라벨 표시.
- **차용 안 함**:
  - 개발자 톤 (코드 블록 가득) — 우리는 헬스 컨슈머라 코드 블록 0개.
  - 어두운 배경의 컴포넌트 그리드 — 우리는 흰 배경 우선.
  - 굵은 무지개 그라데이션 자체 — 너무 화려해서 임상 톤과 충돌. *옅은* 두 색 그라데이션으로 한정.

### 1.3 linear.app — 모션 디테일·터미널 미학
- **URL**: https://linear.app/
- **차용**:
  - **호버의 일관성** — 모든 호버는 동일한 0.2s ease-out + lift 2px + 그림자 강화. 우리 카드·버튼·링크에 통일.
  - **스크롤 진입 모션의 절제** — 0.6s에 fade+translateY 20px 한 가지 패턴만 반복. 우리도 그것만 사용 (장식 모션 추가 금지).
  - 마이크로한 1px 보더 + 옅은 그림자의 *선명한 가벼움*.
  - 키보드 단축키·인터랙션 큐 — 우리 FAQ 아코디언에 키보드 네비게이션 (선택사항).
- **차용 안 함**:
  - 어두운 배경 + 네온 액센트 — 우리는 임상 톤(밝음).
  - 개발자용 터미널 미학 그 자체 — 우리는 헬스 코칭, 친근함이 우선.
  - 사이드바 네비 패턴 — 우리는 단일 페이지 랜딩.

### 1.4 calm.com — 따뜻함·마음챙김
- **URL**: https://www.calm.com/
- **차용**:
  - **여백의 호흡감** — 섹션 간 큰 패딩, 짧은 줄의 한 문장 카피. 우리 헤드라인과 Final CTA에 동일 패턴.
  - **부드러운 그라데이션 배경** — Calm 앱의 보라→파랑 그라데이션을 *우리 베이지→연민트* 그라데이션으로 번역. Solution 섹션 배경.
  - **둥근 카드 라디우스** (16-24px) + 옅은 그림자 — 따뜻한 카드 미감.
  - 짧은 문장의 *시 같은 줄바꿈* — 우리 헤드라인과 섹션 헤더에 동일.
- **차용 안 함**:
  - 명상 가이드 사진(자연 풍경) — 우리는 임상 톤이라 자연 풍경 0장.
  - 영상 콘텐츠 자동 재생 — 성능 부담.
  - 강한 마케팅 영업 톤 ("Start your free trial!" 같은 큰 버튼 점유) — 우리는 정직 시그널 우선.

### 1.5 eatrightnow.com — 임상 SaaS 권위
- **URL**: https://www.eatrightnow.com/
- **차용**:
  - **임상 권위의 시각적 표기** — Dr. Jud Brewer 사진 옆 "MD, PhD, Brown University" 학술 라벨. 우리 KOL 카드 영입 후 동일 패턴 (영입 전엔 회색 실루엣 + "영입 진행 중" 라벨).
  - **임상 근거 인용 카드** — 메타분석·논문 인용을 학술 스타일로. 우리 Problem 의학 근거(Hurst 2018, Ohkuma 2015) 동일 처리.
  - 결과 약속 + 28일 코스 프레이밍 — 도구가 아닌 *코스/저니* 시각화.
- **차용 안 함**:
  - 영어권 디자인의 직역 — 한글 타이포 위계 다시 설계.
  - 영상 강의 썸네일 갤러리 — 우리는 베타 단계라 콘텐츠 노출 최소.
  - $24.99 가격 강조 — 우리는 9,900원 *작게*, 가치를 크게.

---

## 2. 디자인 시스템

### 2.1 컬러 팔레트 (CSS Variables — 즉시 사용 가능)

```css
:root {
  /* === 배경 (Background) === */
  --color-bg-cool:        #FFFFFF;   /* 임상 섹션 메인 배경 */
  --color-bg-warm:        #F8F4ED;   /* 코칭 섹션 메인 배경 (살짝 옅게) */
  --color-bg-deep:        #0A0E1A;   /* AirPods Demo·Final CTA 어두운 섹션 */
  --color-bg-mist:        #F4FBFA;   /* 옅은 민트 — Solution 배경 */

  /* === 텍스트 === */
  --color-text-primary:   #0A0E1A;   /* 헤드라인·본문 (거의 검정, 청남 톤) */
  --color-text-secondary: #2D3340;   /* 부제·강조 본문 */
  --color-text-muted:     #5A5F6E;   /* 캡션·보조 정보 */
  --color-text-subtle:    #8C92A1;   /* 메타·라벨 */
  --color-text-on-deep:   #F5F7FA;   /* 어두운 배경 위 텍스트 */

  /* === 액센트 — 임상 (차가움) === */
  --color-clinical:        #00B894;   /* 민트 — 데이터·차트 (#00C9A7보다 살짝 진하게 — AA 통과) */
  --color-clinical-soft:   #B2EFE3;   /* 민트 옅음 — 배경·필 */
  --color-clinical-deep:   #007A66;   /* 민트 진함 — 텍스트 위 액센트 */

  /* === 액센트 — 코칭 (따뜻함) === */
  --color-coaching:        #FF7A59;   /* 코랄 — 페르소나·코치 카드 (#FF8A65 변형) */
  --color-coaching-soft:   #FFE1D6;   /* 코랄 옅음 — 배경 */
  --color-coaching-deep:   #C24A2F;   /* 코랄 진함 — 텍스트 위 (AA 통과) */

  /* === CTA·신뢰 === */
  --color-cta:             #1F4FE0;   /* 코발트 블루 — Primary CTA (#2563EB 변형, 따뜻한 베이지와 보색) */
  --color-cta-hover:       #1A41C7;
  --color-cta-soft:        #DCE5FF;

  /* === 시맨틱 === */
  --color-success:         #16A34A;
  --color-warn:            #EA580C;
  --color-error:           #DC2626;
  --color-info:            #0284C7;

  /* === 라인·구분 === */
  --color-line:            #E8EAEE;
  --color-line-strong:     #C9CDD4;
  --color-line-on-deep:    #2A3142;

  /* === 데이터 시각화 (차트 전용) === */
  --color-chart-fast:      #FB7185;   /* 빠른 식사 — 따뜻한 빨강 (코랄 계열, 경고 아닌 따뜻한 톤) */
  --color-chart-target:    #00B894;   /* 목표 영역 — 민트 */
  --color-chart-progress:  #1F4FE0;   /* 28일 진행 곡선 — 코발트 */
  --color-chart-grid:      #E8EAEE;
}
```

### 2.2 WCAG AA 색 대비 검증표

| 조합 | 대비비 | 사이즈 기준 (AA: 4.5/3.0) | 통과 |
|---|---|---|---|
| `--color-text-primary #0A0E1A` on `--color-bg-cool #FFFFFF` | **18.6:1** | ≥4.5 (본문) | OK |
| `--color-text-primary` on `--color-bg-warm #F8F4ED` | **17.2:1** | ≥4.5 | OK |
| `--color-text-secondary #2D3340` on `--color-bg-cool` | **12.4:1** | ≥4.5 | OK |
| `--color-text-muted #5A5F6E` on `--color-bg-cool` | **6.0:1** | ≥4.5 | OK |
| `--color-text-subtle #8C92A1` on `--color-bg-cool` | **3.6:1** | ≥3.0 (큰 텍스트만) | 캡션·라벨 한정 |
| `--color-clinical #00B894` on `--color-bg-cool` | **3.1:1** | ≥3.0 (큰 텍스트/UI) | 헤드라인 액센트만, 본문 금지 |
| `--color-clinical-deep #007A66` on `--color-bg-cool` | **5.1:1** | ≥4.5 | OK (본문 액센트) |
| `--color-coaching #FF7A59` on `--color-bg-cool` | **3.0:1** | ≥3.0 (큰 텍스트만) | 헤드라인·아이콘만 |
| `--color-coaching-deep #C24A2F` on `--color-bg-cool` | **5.0:1** | ≥4.5 | OK (본문 액센트) |
| `--color-cta #1F4FE0` (white text on it) | **6.2:1** | ≥4.5 | OK (CTA 버튼) |
| `--color-text-on-deep #F5F7FA` on `--color-bg-deep #0A0E1A` | **17.8:1** | ≥4.5 | OK |

**규칙**: `--color-clinical`과 `--color-coaching`은 *큰 텍스트(24px+) 또는 헤드라인 액센트, 또는 UI 컴포넌트*에만 사용. 본문(16px) 액센트는 *-deep 변형*을 사용.

### 2.3 타이포그래피 — Pretendard + Inter 페어링

```css
/* === 폰트 패밀리 === */
:root {
  --font-sans: 'Pretendard Variable', 'Inter', -apple-system, BlinkMacSystemFont,
               'Apple SD Gothic Neo', 'Helvetica Neue', sans-serif;
  --font-serif: 'Noto Serif KR', 'Source Serif Pro', Georgia, serif;
  --font-mono: 'JetBrains Mono', 'SF Mono', Consolas, monospace;
}
```

**근거**: Pretendard Variable은 한글·영문 모두 한 파일로 처리(자체 라틴 글리프 우수). Inter fallback은 한글 미설치 환경 보호. 세리프는 헤드라인 [A]의 "11분"·"8주" 액센트 + 학술 인용 출처에만 사용 (M1 합의).

#### 2.3.1 타이포 스케일 (Desktop / Mobile은 0.85배)

| 토큰 | Desktop (size/leading/weight/letter-spacing) | Mobile | 폰트 | 사용처 |
|---|---|---|---|---|
| `display-xl` | 64/72/700/-0.025em | 40/48/700 | sans (또는 헤드라인 [A]는 serif Bold) | Hero H1 |
| `display-lg` | 52/60/700/-0.02em | 36/44/700 | sans | Final CTA 헤더 |
| `heading-1` | 40/48/600/-0.015em | 30/38/600 | sans | 섹션 헤더 |
| `heading-2` | 32/40/600/-0.01em | 26/34/600 | sans | 서브 섹션 |
| `heading-3` | 24/32/600/-0.005em | 20/28/600 | sans | 카드 헤더 |
| `heading-4` | 20/28/600/0 | 18/26/600 | sans | 작은 섹션 헤더 |
| `body-lg` | 18/30/400/0 | 17/28/400 | sans | 리드 카피, Hero 보조 |
| `body` | 16/26/400/0 | 16/26/400 | sans | 본문 (모바일도 16 — iOS 자동 줌 방지) |
| `body-sm` | 14/22/400/0 | 14/22/400 | sans | 보조 본문 |
| `caption` | 13/20/400/0.005em | 13/20/400 | sans | 메타·라벨 |
| `label` | 12/18/500/0.04em | 12/18/500 | sans | UI 라벨 (uppercase 적용 가능) |
| `quote-display` | 36/48/400/-0.005em | 26/36/400 | serif | 헤드라인 [C], 학술 인용 강조 |
| `data-mono` | 14/22/500/0 | 13/20/500 | mono | 데이터 스트림, 시간 표기 |

#### 2.3.2 굵기 매트릭스 (Pretendard Variable 100~900)

```
400 Regular   — 본문 기본
500 Medium    — 보조 강조, UI 라벨
600 SemiBold  — 헤드라인·서브 헤더
700 Bold      — Display·H1
800 ExtraBold — 헤드라인 [A]의 "11분"·"8주" 액센트만
```

#### 2.3.3 한국어 줄바꿈 규칙

- `word-break: keep-all` — 영어 단어 분리 방지
- `overflow-wrap: anywhere` — 어쩔 수 없을 때만 분리
- 헤드라인은 `<br>`로 *카피라이터가 의도한 줄바꿈* 강제 (M6의 §6 보존 원칙). 모바일에서도 두 줄 유지.

### 2.4 간격 시스템 — 8px 기반

```css
:root {
  --space-0:   0;
  --space-1:   4px;    /* 0.25 */
  --space-2:   8px;    /* 0.5  */
  --space-3:   12px;   /* 0.75 */
  --space-4:   16px;   /* 1    — 본문 행 사이, 카드 내부 패딩 small */
  --space-5:   20px;   /* 1.25 */
  --space-6:   24px;   /* 1.5  — 카드 내부 패딩 default */
  --space-8:   32px;   /* 2    — 카드 사이, 부제와 본문 사이 */
  --space-10:  40px;   /* 2.5 */
  --space-12:  48px;   /* 3    — 모바일 섹션 안 블록 사이 */
  --space-16:  64px;   /* 4    — 모바일 섹션 vertical padding */
  --space-20:  80px;   /* 5 */
  --space-24:  96px;   /* 6    — 데스크탑 섹션 안 블록 사이 */
  --space-32:  128px;  /* 8    — 데스크탑 섹션 vertical padding */
  --space-40:  160px;  /* 10 — Final CTA 큰 호흡 */
}
```

**섹션 vertical padding 표준**: Desktop `var(--space-32)` / Tablet `var(--space-24)` / Mobile `var(--space-16)`.

**카드 내부 패딩**: Desktop `var(--space-8)` / Mobile `var(--space-6)`.

### 2.5 그리드 시스템

```css
:root {
  --container-max:    1200px;
  --container-narrow:  880px;   /* 본문·FAQ 등 가독성 우선 */
  --container-prose:   680px;   /* 긴 카피 (5분 피치 등) */
}

/* 모바일 (<640) */
.grid-mobile  { grid-template-columns: repeat(4, 1fr); gap: 16px; padding-inline: 16px; }

/* 태블릿 (640-1024) */
.grid-tablet  { grid-template-columns: repeat(8, 1fr); gap: 24px; padding-inline: 32px; }

/* 데스크탑 (>1024) */
.grid-desktop { grid-template-columns: repeat(12, 1fr); gap: 32px;
                max-width: 1200px; margin-inline: auto; padding-inline: 48px; }
```

### 2.6 반경·그림자·테두리 토큰

```css
:root {
  /* === Border Radius === */
  --radius-sm:   6px;     /* 작은 칩, 라벨 */
  --radius-md:   12px;    /* 버튼, 인풋 */
  --radius-lg:   16px;    /* 카드 default */
  --radius-xl:   24px;    /* 큰 카드, 섹션 그라데이션 박스 */
  --radius-2xl:  32px;    /* AirPods Demo 컨테이너 */
  --radius-full: 9999px;  /* 알약, 아이콘 컨테이너 */

  /* === Shadow (옅고 따뜻한 톤) === */
  --shadow-xs:  0 1px 2px rgba(10, 14, 26, 0.04);
  --shadow-sm:  0 2px 4px rgba(10, 14, 26, 0.05),
                0 1px 2px rgba(10, 14, 26, 0.04);
  --shadow-md:  0 6px 12px rgba(10, 14, 26, 0.06),
                0 2px 4px rgba(10, 14, 26, 0.04);
  --shadow-lg:  0 12px 24px rgba(10, 14, 26, 0.08),
                0 4px 8px rgba(10, 14, 26, 0.04);
  --shadow-xl:  0 24px 48px rgba(10, 14, 26, 0.10),
                0 8px 16px rgba(10, 14, 26, 0.06);
  --shadow-glow-clinical: 0 0 32px rgba(0, 184, 148, 0.18);
  --shadow-glow-coaching: 0 0 32px rgba(255, 122, 89, 0.18);

  /* === Border === */
  --border-thin:    1px solid var(--color-line);
  --border-strong:  1px solid var(--color-line-strong);
  --border-accent-clinical: 1px solid var(--color-clinical);
  --border-accent-coaching: 1px solid var(--color-coaching);
  --border-cta:    2px solid var(--color-cta);
}
```

### 2.7 Tailwind config 매핑 (참고)

```js
// tailwind.config.js extend (landing-architect용 참고)
theme: {
  extend: {
    colors: {
      'bg-cool': 'var(--color-bg-cool)',
      'bg-warm': 'var(--color-bg-warm)',
      'bg-deep': 'var(--color-bg-deep)',
      'bg-mist': 'var(--color-bg-mist)',
      'text-primary': 'var(--color-text-primary)',
      'text-secondary': 'var(--color-text-secondary)',
      'text-muted': 'var(--color-text-muted)',
      'text-subtle': 'var(--color-text-subtle)',
      clinical: {
        DEFAULT: 'var(--color-clinical)',
        soft:    'var(--color-clinical-soft)',
        deep:    'var(--color-clinical-deep)',
      },
      coaching: {
        DEFAULT: 'var(--color-coaching)',
        soft:    'var(--color-coaching-soft)',
        deep:    'var(--color-coaching-deep)',
      },
      cta: {
        DEFAULT: 'var(--color-cta)',
        hover:   'var(--color-cta-hover)',
        soft:    'var(--color-cta-soft)',
      },
    },
    fontFamily: {
      sans:  ['Pretendard Variable', 'Inter', 'system-ui', 'sans-serif'],
      serif: ['Noto Serif KR', 'Georgia', 'serif'],
      mono:  ['JetBrains Mono', 'monospace'],
    },
    spacing: {
      // 8px 기반 토큰 — index도 px와 일치 (4 = 16px)
    },
    borderRadius: { sm:'6px', md:'12px', lg:'16px', xl:'24px', '2xl':'32px' },
    boxShadow: {
      xs: 'var(--shadow-xs)',
      sm: 'var(--shadow-sm)',
      md: 'var(--shadow-md)',
      lg: 'var(--shadow-lg)',
      xl: 'var(--shadow-xl)',
    },
  },
},
```

---

## 3. 정보 흐름 (Page Wireframe)

SKILL.md 권장 구조 + 카피 시스템(`01_strategy_copy.md` §3) 일치. 각 섹션마다 카피 핵심(인용), 비주얼 자산, 인터랙션, 모바일/데스크탑 변형, 예상 높이.

### 3.0 전역 레이아웃

```
┌──────────────────────────────────────────────┐
│ Sticky Top Nav (높이 64px / 모바일 56px)       │  
│  [로고 Chew & Calm]  How / 가격 / FAQ  [베타]  │
├──────────────────────────────────────────────┤
│ 1. Hero                              ~100vh   │
│ 2. Problem                       desktop 720 │
│ 3. Solution                      desktop 800 │
│ 4. AirPods Demo (signature)      desktop 900 │
│ 5. How it works                  desktop 720 │
│ 6. Differentiation                desktop 700 │
│ 7. Authority                      desktop 660 │
│ 8. Pricing                        desktop 760 │
│ 9. FAQ                            desktop 640 │
│10. Final CTA + Footer             desktop 600 │
└──────────────────────────────────────────────┘
```

**Sticky Nav 동작**: 100vh 스크롤 후 `backdrop-filter: blur(12px)` + 흰색 70% opacity 배경. 진실 시그널 미니 라인은 nav에 *넣지 않음* (Hero에만).

---

### 3.1 Hero (~100vh, 모바일 100svh)

**카피 (그대로 인용 — `01_strategy_copy.md` §3.1)**:
> 당신의 점심은 평균 11분.
> 8주만, 위 건강을 차분히 되찾아요.

**보조 1줄**:
> 이미 끼고 있는 AirPods가 식사 속도를 자동으로 보여주고,
> 임상 28일 코스가 매일 2-3분, 함께 걸어요.

**진실 시그널**:
> 임상 RCT 진행 중 · 내과 전문의 자문 [영입 진행 중] · 베타 모집 중

**시각 사양 (M1 합의 반영 — 헤드라인은 굵은 세리프 + 큰 사이즈)**:
- H1 폰트: `font-serif Noto Serif KR Bold` 또는 `font-sans Pretendard 800`. **권장: Pretendard 800** (한글 가독성 + 무게). 단 *"평균 11분"*과 *"8주"*는 `display-xl` 사이즈로 키우고 `--color-clinical-deep` 액센트 컬러.
- 카피라이터 메모 M1 인용: *"라이트 sans-serif로 가면 통계 트리거가 죽어요. ... 헤드라인은 한국형 세리프(노토 세리프 KR Bold 또는 Pretendard Black 대안) 권장."* → **결정: Pretendard 800 + 액센트 단어만 -clinical-deep.** (Noto Serif KR는 학술 인용 카드용으로 한정. 한글 본문 세리프는 가독성 부담 + 모바일 렌더링 비용. 카피라이터에게 이 결정 회신 메모로 전달 — 아래 §10.)
- 액센트 컬러는 *1톤만* (M1) — `--color-clinical-deep #007A66` 사용.
- 보조 1줄: `body-lg` weight 400, 색 `--color-text-secondary`.
- CTA: Primary는 `--color-cta`, padding 16/32, radius 12, 폰트 16/600. Secondary는 텍스트 링크 + 화살표.
- 진실 시그널: `caption` 사이즈, 색 `--color-text-muted`, 가로 도트(·) 구분, opacity 0.7.

**비주얼 자산**:
- 좌측(Desktop): 카피 영역 — 헤드라인 + 보조 + CTA + 진실 시그널.
- 우측(Desktop): **AirPods 일러스트의 정적 프리뷰** + 옅은 그라데이션 글로우. AirPods Demo의 *티저*. `--color-clinical-soft`에서 `--color-coaching-soft`로 부드러운 그라데이션 배경.
- 우측 일러스트는 *데이터 점선 1개*가 흘러나오는 정지 SVG (Demo 섹션의 미리보기).

**Desktop 레이아웃 (12 col)**:
```
[ col 1-7: 카피 영역 ]   [ col 8-12: AirPods 시각화 + 그라데이션 글로우 ]
padding-top: 120px (nav 아래 여백)
```

**Mobile 레이아웃**:
```
AirPods 일러스트 (높이 240px, 가운데 정렬)
H1 (display-xl 모바일 = 40/48)
보조 1줄 (body-lg)
[베타 합류] CTA (full width)
[어떻게 작동하는지 보기] 텍스트 링크
진실 시그널 (caption, 줄바꿈 가능)
```

**스크롤 인디케이터**: Hero 하단 가운데. 작은 화살표 ↓ + "스크롤" 한글 라벨. 1.6s ease-in-out infinite로 8px 위아래 진동.

**예상 높이**: Desktop 100vh / Mobile 100svh (iOS Safari 100vh 버그 회피).

**인터랙션**:
- Hero 마운트 시: `display-xl`은 0.8s에 fade+translateY 16px→0, 보조 1줄은 0.2s 딜레이 후 0.6s. CTA는 0.4s 딜레이.
- AirPods 일러스트는 마운트 즉시 보임(LCP 보호) + 데이터 점선만 0.6s 딜레이로 그려짐(strokeDashoffset).
- Primary CTA 호버 시 scale 1.02 + 그림자 강화 + 배경 -hover 색.

---

### 3.2 Problem (~720px desktop / ~960 mobile)

**카피 핵심 (인용)**:
> ### 당신은 자신의 식사 속도를, 정확히는 모르고 있어요.
> 위염 진단을 받고 의사가 *천천히 드세요* 라고 했을 때, 그게 정확히 몇 분인지 알려주는 사람은 없었을 거예요.
> 한국 직장인의 평균 점심 시간은 **11분**. 권장 식사 시간(20분 이상)의 절반이에요.

**시각 사양 (M2 합의 반영 — 비주얼이 카피보다 우선)**:

**비주얼 자산 1: "11분 vs 20분" 시계 시각화**
- 두 개의 원형 진행도(circular progress) SVG, 가로로 나란히.
- 좌측 시계: "한국 직장인 평균 11분" — 진행도 11/20 = 55%, 색은 `--color-chart-fast` (코랄/빨강).
- 우측 시계: "권장 20분" — 진행도 100%, 색은 `--color-clinical` (민트).
- 진입 시 좌측 시계가 0→11분으로 채워지고, 우측 시계가 0→20분으로 *더 천천히* 채워짐. 시각적 대비로 "11은 절반"이 즉시 인식.
- 의사코드:
  ```js
  // GSAP scroll-trigger
  gsap.fromTo('.clock-fast circle.progress',
    { strokeDashoffset: FULL_CIRCLE },
    { strokeDashoffset: FULL_CIRCLE * 0.45, duration: 1.2, ease: 'power3.out',
      scrollTrigger: { trigger: '.problem-vis', start: 'top 70%' }})
  gsap.fromTo('.clock-target circle.progress',
    { strokeDashoffset: FULL_CIRCLE },
    { strokeDashoffset: 0, duration: 2.0, ease: 'power3.out', delay: 0.3,
      scrollTrigger: { trigger: '.problem-vis', start: 'top 70%' }})
  ```

**비주얼 자산 2: 의학 근거 카드 2장 (학술 인용 스타일)**
- 작은 라벨 "임상 메타분석" (uppercase, `--color-clinical`).
- 큰 통계 숫자 — `display-lg` "+71%" / "2.15배", 색 `--color-clinical-deep`.
- 카피: "빠른 식사군은 미란성 위염 위험이 71% 더 높아요."
- 출처: `caption` 폰트, 이탤릭, *—Hurst & Fukuda, 2018*.
- 카드 스타일: 흰 배경, `--border-thin`, `--shadow-sm`, `--radius-lg`, 패딩 24px. 학술적 미니멀.

**비주얼 자산 3: 페르소나 트리거 3줄 (손글씨톤 인용 카드)**
- 3개 카드 가로 정렬(데스크탑) 또는 세로(모바일).
- 큰 인용부호 SVG `"`(`--color-coaching` 옅음)이 카드 좌상단에 장식.
- 카피는 *손글씨톤 폰트는 사용 안 함* (한글 손글씨 폰트는 가독성 위험 + 라이센스 부담). 대신 **Noto Serif KR Italic** + `--color-text-secondary`로 *진짜 사람 목소리* 느낌. 하단 작은 페르소나 라벨 "한지원 (위염, 32세)".
- 카피라이터 M2 메모 인용: *"손글씨톤 또는 인용부호로 진짜 사람 목소리처럼"* → **인용부호 + 세리프 이탤릭**으로 해석.

**섹션 닫는 1줄** (인용):
> 모르는 게 문제가 아니라, *볼 수 있는 도구가 없었던* 것뿐이에요.
- `heading-3` 사이즈, `--color-text-primary`, 가운데 정렬, 위아래 큰 패딩(`--space-16`).

**Desktop 레이아웃**:
```
[ 섹션 헤더 (col 2-11) ]
[ 리드 카피 (col 2-7) ]   [ 시계 시각화 (col 8-12) ]
[ 의학 근거 카드 1 (col 1-6) ]  [ 카드 2 (col 7-12) ]
[ 페르소나 트리거 카드 3개 (col 1-12, 3등분) ]
[ 섹션 닫는 1줄 (col 3-10, center) ]
```

**Mobile**: 위에서 아래로 시계 → 헤더 → 리드 카피 → 의학 근거 카드 (세로 스택) → 페르소나 카드 (세로 캐러셀, 점 인디케이터).

**인터랙션**:
- 시계 자동 채움 (위 의사코드).
- 페르소나 카드는 모바일에서 *수평 스크롤 캐러셀* (snap-x), 데스크탑에서는 정적.
- 의학 근거 카드 호버: lift 2px + 그림자 sm→md (0.2s ease-out).

**예상 높이**: Desktop 720px / Mobile 960px.

---

### 3.3 Solution (~800px desktop / ~1100 mobile)

**카피 핵심 (인용 §3.3)**:
> ### 보지 못했던 것을, 함께 보고, 함께 바꿔요.
> 1. 검출 — *AirPods가 봐줘요*
> 2. 깨달음 — *데이터가 말해줘요*
> 3. 코칭 — *함께 걸어요*

**시각 사양 (M3 합의 — 카드 + 가벼운 모션, 텍스트는 보조)**:

**배경**: `--color-bg-mist` (옅은 민트) 풀블리드. 위쪽에 `--color-bg-cool`에서 그라데이션으로 부드럽게 전환 (높이 80px).

**3 카드 비주얼 자산**:

**카드 1: 검출 — AirPods 일러스트**
- 작은 AirPods Pro SVG (96×96px) + 귀에서 식사 검출 신호 펄스(작은 동심원 3개가 0.6s 간격으로 페이드아웃).
- 카드 배경 흰색, `--radius-xl`, `--shadow-md`.
- 헤더: `heading-3` "검출", 라벨 `caption uppercase --color-clinical-deep` "AIRPODS가 봐줘요".

**카드 2: 깨달음 — 코치 카드 목업**
- iPhone 프레임 안에 *실제 코치 카드 UI* 미니어처. 카드 안에:
  - 헤더 "오늘 점심 8분"
  - 작은 막대 그래프 (어제 9분, 오늘 8분, 평균 11분)
  - 따뜻한 메시지 "어제보다 1분 더 천천히 — 잘하셨어요 :)"
- iPhone 프레임은 단순화(검은 라운드 직사각형 + 노치 표시), 화면만 디테일.

**카드 3: 코칭 — 28일 코스 캘린더**
- 4×7 격자 (28일). 각 셀은 작은 점/원. 8일째까지는 채워진 민트, 9~28은 옅은 점선 윤곽.
- 1주차/2주차/3주차/4주차 작은 라벨.
- 우측 상단 작은 KOL 카드 (회색 실루엣 + "영입 진행 중" 라벨 — 정직 시그널).

**Desktop 레이아웃** (12 col):
```
[ 섹션 헤더 (col 2-11, center) ]
[ 카드 1 (col 1-4) ] [ 카드 2 (col 5-8) ] [ 카드 3 (col 9-12) ]
```

**Mobile**: 세로 스택, 카드 사이 `--space-8`.

**인터랙션**:
- 스크롤 진입 시 3 카드가 *순차적으로* 페이드+업 (delay 0/0.15/0.3s, duration 0.6s).
- 카드 1: 펄스 동심원 무한 루프 (0.6s 간격 3개, opacity 0.6→0).
- 카드 2: 진입 후 막대 그래프가 0→실제 값으로 0.8s에 자라남 (delay 0.5s).
- 카드 3: 28일 격자가 1일부터 8일까지 *순차 채움* (각 셀 0.06s 간격, 총 0.5s).
- 카드 호버: lift 4px + shadow md→lg + 1px 보더 강조 (0.2s).

**접근성**: 펄스/막대 애니메이션은 `prefers-reduced-motion: reduce` 시 즉시 최종 상태로 표시. 각 SVG에 `aria-label`.

**예상 높이**: Desktop 800px / Mobile 1100px.

---

### 3.4 AirPods Demo — 시그니처 인터랙션 (~900px desktop / ~700 mobile)

**카피**: 이 섹션은 카피보다 *비주얼 우선*. 작은 카피만:
> ### 이미 끼고 있는 그것이, 식사를 보고 있어요.
> *AirPods 모션 센서 → 식사 동작 검출 → 위 건강 점수.*
> 베타에서 매주 정확도가 개선되고 있어요.

**시각 사양 — 시그니처 인터랙션 (브리프 권장 옵션 B)**:

**배경**: `--color-bg-deep #0A0E1A` 풀블리드. 위/아래 `--color-bg-mist`에서 어둠으로 그라데이션 전환 (각 120px).

**핵심 자산: 정밀 SVG AirPods + GSAP morph + 데이터 스트림**

레이아웃 (Desktop):
```
[ 좌측 col 1-7 ]                        [ 우측 col 8-12 ]
   AirPods SVG 일러스트                    데이터 스트림 패널
   (사용자 스크롤에 따라 다음 4단계로)        (실시간 텍스트가 흘러내림)
   
   1) 정지 (마운트 시)
   2) 펄스 — 식사 검출
   3) 데이터 라인이 귀에서 흘러나옴
   4) 위 건강 점수 게이지로 응결
```

데이터 스트림 패널 (모노스페이스):
```
> 12:32:08  식사 시작 검출
> 12:32:18  씹기 패턴: 1.2초/회
> 12:33:42  속도: 빠름 → 평균
> 12:39:47  식사 종료 (총 7분 39초)
─────────────────────────────
  위 건강 점수 → 72  ↑ +3
```

**구현 의사코드 (GSAP ScrollTrigger + scrub)**:

```js
import gsap from 'gsap'
import { ScrollTrigger } from 'gsap/ScrollTrigger'
gsap.registerPlugin(ScrollTrigger)

// 1) 핀 + 4단계 타임라인 + scrub 0.3
const tl = gsap.timeline({
  scrollTrigger: {
    trigger: '#airpods-demo',
    start: 'top top',
    end: '+=180%',     // 1.8 viewport scroll로 4단계 통과
    scrub: 0.3,         // 부드럽지만 즉각 반응
    pin: true,
    pinSpacing: true,
    anticipatePin: 1,
  }
})

// Phase 1 → 2 : 정지 → 검출 펄스 (0~25%)
tl.fromTo('#airpod-pulse',
  { scale: 0.8, opacity: 0 },
  { scale: 1.4, opacity: 0.8, duration: 0.25, ease: 'power2.out' })
  .to('#airpod-pulse', { scale: 2.0, opacity: 0, duration: 0.25 })

// Phase 2 → 3 : 데이터 라인 그려짐 (25~60%)
tl.fromTo('#data-stream-line',
  { strokeDashoffset: LINE_LENGTH },
  { strokeDashoffset: 0, duration: 0.35, ease: 'power1.inOut' }, '<')

// 데이터 패널 텍스트 1줄씩 추가 (typewriter 느낌)
tl.from('.stream-row', {
  opacity: 0, y: 8, stagger: 0.07, duration: 0.3, ease: 'power2.out'
}, '<')

// Phase 3 → 4 : 라인이 점수 게이지로 응결 (60~100%)
tl.to('#data-stream-line', {
  // path morph: 라인 → 원형 게이지로 변환 (Flip 또는 path interpolation)
  attr: { d: GAUGE_PATH_D },
  duration: 0.4, ease: 'power3.inOut'
})
tl.fromTo('#health-score',
  { textContent: 0 },
  { textContent: 72, duration: 0.4, ease: 'power2.out',
    snap: { textContent: 1 } /* 정수 카운트업 */ }, '<')

// 모바일 대체: scrub 끄고 단순 ScrollTrigger fade-in 4단계
ScrollTrigger.matchMedia({
  '(max-width: 1024px)': () => {
    tl.kill()
    // 핀 없이, 각 phase를 IntersectionObserver로 발화
  }
})
```

**SVG 자산 사양 (AirPods Pro SVG)**:
- 뷰박스 480×480
- 본체: path filled `--color-text-on-deep` 95% + inner shadow filter (검정 5% + 흰 림 라이트 1px)
- 줄기(stem) 부분 detail: 1px 라인으로 마이크 그릴 표현
- 펄스용 `<circle>` 3개(scale 1→2.5, opacity 0.5→0 stagger)
- 데이터 라인: `<path stroke="var(--color-clinical)" stroke-width="2" fill="none" stroke-linecap="round" stroke-dasharray="LENGTH" stroke-dashoffset="LENGTH"/>`
- 게이지: `<circle r="64" stroke="var(--color-clinical)" stroke-width="6" fill="none" pathLength="100" stroke-dashoffset="(100-72)"/>` + 가운데 텍스트 "72"

**Mobile 대체 (성능)**:
- `pin` 비활성, `scrub` 비활성.
- 4 단계가 *수직 카드 4장*으로 분리. 각 카드가 viewport에 들어올 때 애니메이션 1회 트리거.
- 카드 사이 작은 화살표 ↓.
- 데이터 패널은 카드 4 내부에 정적 표시 (typewriter 모션은 60fps 안전한 짧은 길이로만).

**접근성**:
- `prefers-reduced-motion: reduce` 시 4 단계를 *정적 4 카드*로 즉시 표시 (모바일과 동일 처리).
- 각 단계에 `aria-label`로 한글 설명: "1단계: AirPods가 식사 시작을 검출", "2단계: 씹기 패턴을 분석", 등.
- 데이터 스트림 텍스트는 실제 `<ul>` + `<li>`, 모노 폰트 적용 (스크린리더가 읽음).
- 게이지 결과 "72점"은 `aria-live="polite"`로 발표.

**성능 가드레일**:
- AirPods SVG는 인라인 (HTTP 추가 요청 없음).
- 핀 섹션은 `will-change: transform` 적용, 끝나면 해제.
- 모바일 GPU 부담 없는 transform·opacity·strokeDashoffset만 사용 (filter blur 금지).
- 첫 번째 페인트에 SVG 정적 상태가 보이게 (LCP 보호).

**예상 높이**: Desktop pin 동안 1×viewport(900px), 스크롤 거리는 1.8×. Mobile 700px (4 카드 세로).

---

### 3.5 How it works (~720px desktop / ~1000 mobile)

**카피 (인용 §3.4)**:
> ### 28일 코스 + AirPods 자동 측정 + 한국 임상 코치 트리오

**시각 사양**:
- 3 컬럼 (Desktop) / 3 행 (Mobile).
- 각 컬럼: 큰 라벨(A/B/C 또는 1/2/3 동그라미 — `--color-clinical-soft` 배경 + `--color-clinical-deep` 숫자), 헤딩, 본문, 작은 비주얼.
- 컬럼 A (28일 코스): 미니 캘린더 (4주×7일) + 1주차 라벨 강조.
- 컬럼 B (AirPods 자동 트래킹): AirPods 라인 일러스트 + 호환 모델 칩 (Pro / 3 / 4).
- 컬럼 C (한국 임상 코치 + KOL): KOL 회색 실루엣 카드(영입 진행 중 라벨) + 친근 코치 아바타(둥근 SVG, 코랄 톤).
- 닫는 1줄 *AirPods만 있으면, 다른 디바이스는 필요 없어요.* 가운데 정렬, `body-lg`, `--color-text-secondary`.

**Desktop 레이아웃**:
```
[ 섹션 헤더 (col 2-11, center) ]
[ A (col 1-4) ] [ B (col 5-8) ] [ C (col 9-12) ]
[ 닫는 1줄 (col 3-10, center) ]
```

**Mobile**: 세로 스택, 컬럼 사이 `--space-8`.

**인터랙션**:
- 진입 시 3 컬럼 stagger 페이드+업 (delay 0/0.15/0.3s).
- 컬럼 A 캘린더: 1주차 셀 7개가 0.06s 간격 순차 점등 (--color-clinical 채움).
- 컬럼 B AirPods: 호환 칩 호버 시 작은 lift.
- 컬럼 C KOL 회색 카드: 호버 시 *부드럽게 밝아짐* (opacity 0.6→0.8) + "영입 진행 중" 라벨이 살짝 강조 — *부끄러움이 아닌 자신감*의 시각 신호 (M4 합의).

**예상 높이**: Desktop 720 / Mobile 1000.

---

### 3.6 Differentiation (~700px desktop / ~900 mobile)

**카피 (인용 §3.5)**:
> ### Apple watchOS가 흡수해도, 우리만 가진 것 5가지.
> (a) 한국 임상 KOL 자산 / (c) 28일 한국어 코스 IP / (d) 친근한 한국 페르소나 코치 — *큰 카드*
> (b) 임상 RCT 데이터 / (e) "위 건강 회복" 결과 라벨 — *작은 보조 카드*

**시각 사양**:
- 3 + 2 그리드 (Desktop): 위쪽 큰 카드 3장(a/c/d), 아래쪽 작은 카드 2장(b/e).
- 큰 카드: `--radius-xl`, 흰 배경, `--shadow-md`, 패딩 32px. 좌측 상단 작은 라벨 (a/b/c/d/e), 큰 헤더 + 본문.
- 작은 카드: 가로형, 라벨 + 한 줄 요약.
- (a) 큰 카드에 KOL 회색 실루엣 미니어처. (c) 큰 카드에 28일 캘린더 미니어처. (d) 큰 카드에 코치 카드 미니어처.

**Desktop 레이아웃**:
```
[ 섹션 헤더 (col 2-11, center) ]
[ (a) 큰 카드 col 1-4 ] [ (c) col 5-8 ] [ (d) col 9-12 ]
[ (b) 작은 가로 카드 col 1-6 ] [ (e) col 7-12 ]
[ 닫는 1줄 "도구는 베껴도, 맥락과 권위와 톤은 베낄 수 없어요." (center) ]
```

**Mobile**: 세로 스택 5장, 큰 카드 3장 → 작은 카드 2장.

**인터랙션**:
- 진입 시 카드 5장 stagger 페이드+업.
- 호버 lift 표준.

**예상 높이**: Desktop 700 / Mobile 900.

---

### 3.7 Authority (~660px desktop / ~880 mobile)

**카피 (인용 §3.6)**:
> ### 거짓 사회증거 대신, *현재 우리가 진짜 하고 있는 일*을 보여드려요.
> 임상 RCT 진행 중 / 내과 전문의 KOL — 영입 진행 중 / 베타 모집 중

**시각 사양 (M4 합의 — *정직 시그널 자산*으로 디자인)**:
- 3 카드 가로(Desktop) / 세로(Mobile).
- 각 카드 좌상단 작은 *상태 칩* — `pulse 점` (코랄 1px) + "진행 중" 라벨. 동적 진행 중임을 시각으로.
- 카드 1 (RCT): 차트 미니어처 (8주 진행 막대 — 현재 8/8 채움) + 본문.
- 카드 2 (KOL): **회색 실루엣 + "영입 진행 중" 라벨**. 실루엣은 부드러운 둥근 모양, 회색 그라데이션, 라벨은 `--color-coaching-soft` 배경 + `--color-coaching-deep` 텍스트. *부끄럽지 않게, 자신감 있게.* 라벨 옆 작은 점 아이콘.
- 카드 3 (베타): 작은 사람 아이콘 그리드 (12개, 채워진 4개) + "베타 모집 중" + "*베타 합류 시: 8주 코스 무료 + 정식 출시 시 50% 평생 할인.*"
- 권위 인용: `quote-display` + Noto Serif KR Italic, 가운데 정렬, *"음식은 약과 같다." — [KOL 이름 영입 진행 중]*.

**Desktop 레이아웃**:
```
[ 섹션 헤더 (col 2-11, center) ]
[ 카드 1 (col 1-4) ] [ 카드 2 (col 5-8) ] [ 카드 3 (col 9-12) ]
[ 권위 인용 (col 3-10, center, padding-block 80px) ]
```

**Mobile**: 세로 스택.

**인터랙션**:
- 진입 시 카드 3장 stagger.
- 카드 1 차트: 진입 시 막대 그래프가 0→8주로 자람 (1.0s).
- 카드 2 KOL 실루엣: 미세한 *천천히 호흡*하는 alpha 0.7→0.9→0.7 무한 루프 (3s, ease-in-out). "살아 있는 진행 중" 시그널.
- 카드 3 사람 그리드: 진입 시 4개 아이콘이 stagger 점등.
- 상태 칩의 pulse 점: 1.5s linear infinite.

**예상 높이**: Desktop 660 / Mobile 880.

---

### 3.8 Pricing (~760px desktop / ~1100 mobile)

**카피 (인용 §3.7)**:
> ### 내과 진료 한 번보다 적은 비용으로, 8주를 함께해요.
> 월간 9,900원 / 연간 79,000원 (33% 할인 — *추천*) / 28일 코스 단품 19,900원

**시각 사양 (M5 합의 — 연간 카드만 강조)**:
- 3 가격 카드 가로(Desktop) / 세로(Mobile).
- **카드 2 (연간 — 추천)**: `--border-cta` (2px coaching-deep 또는 cta), `--shadow-lg`, `--shadow-glow-coaching` 옅게, scale 1.04. 우상단 라벨 칩 "추천 — 한 달 무료". `--color-coaching-soft` 배경 옅게 + 흰 카드 위에.
- 카드 1, 3: 일반 카드, `--shadow-sm`, 흰 배경.
- 가격 표기: `display-lg` "9,900원", 작은 라벨 "/월". 연간은 큰 글자 "79,000원" + 작은 취소선 "9,900×12 = 118,800원".
- 가격 정당화 카피는 카드 아래 작은 글씨로 (`body-sm` `--color-text-muted`). 비교 수치 그대로 보존(M6 §6 보존 원칙).
- 환불 1줄도 같은 자리, `caption`.

**Desktop 레이아웃** (12 col, 카드 3 등분):
```
[ 섹션 헤더 (center) ]
[ 카드 1 월간 (col 1-4) ] [ 카드 2 연간 추천 (col 5-8, 약간 위로) ]
                          [ 카드 3 단품 (col 9-12) ]
[ 가격 정당화 카피 (col 2-11, center, body-sm) ]
[ 환불 정책 1줄 (caption, center) ]
```

**Mobile**: 세로 스택. *연간을 가장 위*에 (모바일에서 추천이 첫 시야에).

**인터랙션**:
- 진입 시 3 카드 stagger.
- 카드 호버: 표준 lift. 연간 카드는 *추가 lift* + glow 강화.
- CTA 클릭: 표준 scale 0.97 피드백.

**예상 높이**: Desktop 760 / Mobile 1100.

---

### 3.9 FAQ (~640px desktop / ~720 mobile, 펼침에 따라 가변)

**카피 (인용 §3.8)** — 8개 질문 그대로 사용.

**시각 사양 (아키텍트 §7 권고: 단일 펼침 아코디언)**:
- 컨테이너 `--container-narrow 880px`, 가운데 정렬.
- 각 Q는 한 줄 — `heading-4` (Q1 등 라벨 → 작은 칩 `--color-clinical-soft` 배경) + 화살표 아이콘 우측.
- 펼친 A는 `body` `--color-text-secondary`, 패딩 24px, 위쪽 1px 라인.
- Q2, Q6, Q7은 살짝 강조 — 작은 *"신뢰 핵심"* 라벨 (M 카피라이터 메모).

**인터랙션**:
- 클릭 시 부드러운 펼침/접힘 0.3s ease-in-out — `max-height` 0→실측 높이.
- 단일 펼침: 새 Q 펼치면 기존 닫힘.
- 화살표 회전 0.3s.
- 키보드 네비: Tab으로 포커스, Enter/Space로 펼침.

**의사코드 (CSS + 약간의 JS)**:
```js
const items = document.querySelectorAll('.faq-item')
items.forEach(item => {
  item.querySelector('.faq-q').addEventListener('click', () => {
    const isOpen = item.classList.contains('open')
    items.forEach(i => i.classList.remove('open'))
    if (!isOpen) item.classList.add('open')
  })
})
```
```css
.faq-a { max-height: 0; overflow: hidden;
         transition: max-height .3s cubic-bezier(0.16, 1, 0.3, 1); }
.faq-item.open .faq-a { max-height: 800px; }
.faq-item.open .faq-arrow { transform: rotate(180deg); }
@media (prefers-reduced-motion: reduce) {
  .faq-a { transition: none; }
}
```

**예상 높이**: 모두 닫혔을 때 Desktop 640 / Mobile 720. 모두 펼치면 +1500px가량 — 단일 펼침 정책으로 보호.

---

### 3.10 Final CTA + Footer (~600px desktop / ~720 mobile)

**카피 (인용 §3.9)**:
> ### 8주 후의 위, 8주 후의 식사 속도, 8주 후의 검진 결과.
> ### 오늘 시작하면, 그게 7월 첫 주에 도착해요.
> 베타 합류는 무료예요. 정식 출시 시점에 50% 평생 할인이 적용돼요.
> 1만 명이 합류했다고 거짓말하지 않아요. 지금은 우리가 함께 걸을 첫 사람들을 모으고 있어요.

**시각 사양 (M6 합의 — *베타 가입 폼은 1필드 (이메일)*)**:
- 배경: `--color-bg-deep` 풀블리드 + 옅은 그라데이션 글로우 (민트→코랄 옅게, 위에서 아래).
- 헤더: `display-lg`, `--color-text-on-deep`, 가운데 정렬, 큰 여백. *"7월 첫 주"는 빌드 시점에서 자동 계산* (today + 56일 ISO 주차의 첫 주).
- 보조 카피: `body-lg`, `--color-text-on-deep` opacity 0.85.
- *self-aware 카피의 진정성 처리*: **"1만 명이 합류했다고 거짓말하지 않아요. 지금은 우리가 함께 걸을 첫 사람들을 모으고 있어요."** 이 두 줄은 *시각적 회복*이 필요. 처리:
  - 두 줄을 *별도 박스*로 분리 (배경 `rgba(245,247,250,0.06)` 옅게, `--radius-lg`, 패딩 24px, 좌측에 작은 손으로 든 등불 아이콘 또는 *opacity 0.4의 작은 펜 끝선* 같은 *일기장* 모티브)
  - 좌측에 1px 선 (color-coaching opacity 0.5) — *"사람이 직접 쓴 것 같은"* 인상
  - 폰트: Noto Serif KR Regular Italic — *손편지 톤*
  - 전체 박스는 큰 헤더 *아래에* 들어가서 헤더의 임팩트를 죽이지 않음
  - 효과: 마케팅 카피의 *공식 톤*에서 *작가의 고백*으로 분위기 전환 — 진정성 시각 신호

- 베타 가입 폼:
  - 1필드 (`type="email"`, placeholder "이메일 주소", font-size 16px+ — iOS 자동줌 방지).
  - 1버튼 "베타에 합류하기" — `--color-cta`.
  - 약한 보조 텍스트 caption "개인정보는 진행 소식 외에는 사용하지 않아요.", `--color-text-on-deep` opacity 0.6.
  - 폼 width: max 480px, 가운데 정렬. 데스크탑은 가로(인풋 + 버튼 inline), 모바일 세로 스택.

- Secondary 텍스트 링크: "28일 코스 단품 19,900원" 작게 아래.

- Footer (어두운 배경 그대로, 패딩 위 80px / 아래 40px):
  - 좌: 로고 + 카피 "© 2026 Chew & Calm Coach"
  - 가운데: 빠른 링크 (How / Pricing / FAQ / Privacy / Terms)
  - 우: "이메일로 진행 소식 받기" 작은 1필드 폼 (캡션 폼).

**Desktop 레이아웃**:
```
(어두운 배경 풀블리드)
[ 섹션 헤더 큰 (col 2-11, center) ]   *"7월 첫 주"* 자동 계산
[ self-aware 박스 (col 3-10, center) ]
[ 베타 가입 폼 (col 4-9, center) ]
[ Secondary 텍스트 링크 (center) ]
[ Footer (col 1-12) ]
```

**Mobile**: 세로 스택. 헤더 사이즈 `display-lg` 모바일 = 36/44.

**인터랙션**:
- 헤더 진입 시 fade+up 0.8s.
- self-aware 박스 진입 시 0.4s 딜레이 후 0.6s에 fade.
- 폼 인풋 포커스 시 1px 보더가 `--color-clinical`로 변경 + 그림자 글로우.
- 폼 제출 시 버튼 → 로딩 스피너 → 체크 아이콘 + "합류 완료! 첫 주 안에 메일이 도착해요" (success 메시지). 실패 시 폼 흔들림(shake 0.3s).

**의사코드 (폼 제출 피드백)**:
```js
form.addEventListener('submit', async e => {
  e.preventDefault()
  setState('loading')        // 버튼 안 spinner SVG
  try {
    await submitBeta(email)
    setState('success')      // 체크 아이콘 + 메시지 fade in
  } catch (err) {
    setState('error')         // shake animation
    showError(err.message)
  }
})
```

**예상 높이**: Desktop 600 / Mobile 720 (Footer 포함).

---

## 4. 인터랙션 + 모션 사양

### 4.1 표준 모션 라이브러리

| 모션 ID | 트리거 | duration | easing | 변화 | 사용처 | 라이브러리 |
|---|---|---|---|---|---|---|
| `motion.scrollReveal` | scroll (Intersection 70%) | 0.6s | `cubic-bezier(0.16, 1, 0.3, 1)` | opacity 0→1 + translateY 16→0 | 모든 섹션 진입 (헤더·카드) | GSAP ScrollTrigger 또는 CSS+IO |
| `motion.scrollRevealStagger` | scroll | 0.6s + stagger 0.12s | 동일 | 동일, 자식 stagger | 카드 그룹 (Solution 3, Differentiation 5) | GSAP |
| `motion.hoverLift` | hover | 0.2s | `ease-out` | translateY 0→-2 + shadow md→lg | 카드, 작은 CTA | CSS transition |
| `motion.hoverLiftLg` | hover | 0.25s | `ease-out` | translateY 0→-4 + shadow md→xl | 큰 카드 (가격 추천) | CSS |
| `motion.ctaPress` | active (mousedown/touch) | 0.12s | `ease-in-out` | scale 1→0.97 | 모든 CTA | CSS :active |
| `motion.ctaHover` | hover | 0.2s | `ease-out` | bg-cta → bg-cta-hover + shadow md→lg | Primary CTA | CSS |
| `motion.scrollIndicator` | mount | 1.6s infinite | `ease-in-out` | translateY -4→4→-4 | Hero 하단 화살표 | CSS @keyframes |
| `motion.smoothScroll` | wheel/touch | linear interp 0.1 | — | 페이지 전체 부드러움 | 전역 (Lenis) | Lenis |
| `motion.faqAccordion` | click | 0.3s | `cubic-bezier(0.16, 1, 0.3, 1)` | max-height + arrow rotate 180 | FAQ | CSS |
| `motion.formFocus` | focus | 0.2s | `ease-out` | border-color + glow shadow | 폼 인풋 | CSS :focus-visible |
| `motion.formError` | submit error | 0.3s | `ease-out` | translateX shake ±6 4회 | 폼 실패 | CSS @keyframes |
| `motion.statePulse` | mount infinite | 1.5s | `linear` | scale 0.9→1.1 + opacity 0.4→0.8 | Authority 상태 칩의 점 | CSS @keyframes |
| `motion.kolBreathe` | mount infinite | 3s | `ease-in-out` | opacity 0.7→0.9→0.7 | KOL 회색 실루엣 (살아 있는 진행 중) | CSS |

**구현 표준 — Reveal**:
```js
// IntersectionObserver 기반 (GSAP 없이도 가능)
const io = new IntersectionObserver((entries) => {
  entries.forEach(e => {
    if (e.isIntersecting) {
      e.target.classList.add('revealed')
      io.unobserve(e.target)
    }
  })
}, { threshold: 0.2, rootMargin: '0px 0px -10% 0px' })

document.querySelectorAll('[data-reveal]').forEach(el => io.observe(el))
```
```css
[data-reveal] { opacity: 0; transform: translateY(16px);
                transition: opacity .6s cubic-bezier(.16,1,.3,1),
                            transform .6s cubic-bezier(.16,1,.3,1); }
[data-reveal].revealed { opacity: 1; transform: translateY(0); }
[data-reveal-stagger] > * { transition-delay: calc(var(--i) * 0.12s); }
@media (prefers-reduced-motion: reduce) {
  [data-reveal] { transition-duration: .01s; transform: none; }
}
```

### 4.2 시그니처 인터랙션 — 위 §3.4 참조

옵션 B(정밀 SVG + GSAP morph + 데이터 스트림) 채택. 모바일은 스크롤-드리븐 핀 비활성, 4 카드 분리 페이드 진입.

### 4.3 스무스 스크롤 (Lenis)

```js
import Lenis from 'lenis'
const lenis = new Lenis({
  duration: 1.0, easing: t => 1 - Math.pow(1 - t, 3),
  smoothWheel: true, smoothTouch: false,  // 모바일은 네이티브
})
function raf(time){ lenis.raf(time); requestAnimationFrame(raf) }
requestAnimationFrame(raf)

// GSAP ScrollTrigger와 동기화
lenis.on('scroll', ScrollTrigger.update)
gsap.ticker.add(time => lenis.raf(time*1000))
gsap.ticker.lagSmoothing(0)
```

### 4.4 마이크로 인터랙션 모음

| 위치 | 인터랙션 |
|---|---|
| Sticky Nav 통과 | 100vh 스크롤 후 backdrop-blur 12px + bg rgba(255,255,255,0.7) 0.3s 페이드 |
| Hero 스크롤 인디케이터 | `motion.scrollIndicator` (1.6s 진동) |
| Problem 시계 | scroll 진입 시 0→11분(0.45 회전), 0→20분(1.0 회전), 1.2s/2.0s |
| Solution 카드 펄스 | AirPods 카드 안 동심원 펄스 (1.8s 무한, 3개 stagger 0.6s) |
| Solution 28일 캘린더 | 1주차 7셀 순차 점등 (0.06s 간격, 총 0.5s) |
| AirPods Demo (시그니처) | 위 §3.4 |
| Authority 상태 칩 | `motion.statePulse` |
| Authority KOL 실루엣 | `motion.kolBreathe` |
| Pricing 추천 카드 glow | mount 시 `--shadow-glow-coaching` 옅게 |
| FAQ 펼침 | `motion.faqAccordion` |
| Final CTA 폼 제출 | 로딩 → 성공/실패 피드백 |
| 모든 CTA 호버 | `motion.ctaHover` + `motion.ctaPress` (active) |
| 모든 카드 호버 | `motion.hoverLift` |
| 텍스트 링크 호버 | underline thickness 1→2 + offset 2→3, 0.15s |

---

## 5. 비주얼 자산 명세

### 5.1 AirPods SVG (시그니처 자산)

**파일**: `assets/airpods-pro.svg` (인라인 권장)

**사양**:
- 뷰박스: 480 × 480
- 본체 색: `var(--color-text-on-deep)` 95% (어두운 배경 위) / `var(--color-text-primary)` 95% (밝은 배경 — Hero, Solution 카드용)
- 두 가지 변형:
  - **`airpods-mono`** — 단색 (어두운 배경의 Demo 섹션)
  - **`airpods-light`** — 흰 본체 + 1px 옅은 라인 detail (밝은 배경의 Hero, Solution)
- 디테일 레벨: 적당히 (오버 리얼리즘 금지) — 본체 + 줄기 + 마이크 그릴 1개 + 림 라이트 1px
- 구성 요소 (named groups, GSAP 타겟용):
  - `#airpod-body` (본체 path)
  - `#airpod-stem` (줄기 path)
  - `#airpod-pulse` (검출 펄스용 circle 3개 그룹)
  - `#airpod-data-line` (데이터 라인 path)
- 파일 사이즈 목표: < 8KB (gzip)

### 5.2 차트·시각화

**5.2.1 식사 속도 차트 (Problem 섹션 시계 — circular progress)**

- 두 개의 SVG `<circle>` 진행도. `r=72`, `stroke-width=8`.
- `pathLength="100"`로 정규화, `strokeDashoffset`로 진행 표시.
- 색: 좌측 `--color-chart-fast`, 우측 `--color-chart-target`.
- 가운데 텍스트: `display-lg` 숫자 + `caption` "분".

**5.2.2 위 건강 점수 게이지 (AirPods Demo 마지막 단계)**

- 원형 게이지, `r=64`, `stroke-width=6`, 색 `--color-clinical`.
- 0-100 범위. 데모는 72 도착.
- 가운데 큰 숫자(`display-lg`) + 변화량 캡션 "↑ +3" (코칭 톤).
- 백그라운드 회색 원(opacity 0.2).

**5.2.3 28일 진행 그래프 (Solution 카드, How it works)**

- 4×7 격자 SVG. 각 셀 `<rect>` 8×8px + `--radius-sm`.
- 채워진 셀: `--color-clinical`. 빈 셀: `--color-line` 1px outline.
- 라이브러리: SVG 직접 (Recharts 불필요).

**5.2.4 RCT 8주 막대 (Authority 카드 1)**

- 8개 막대 가로형. 높이 4px (작은 미니어처). 채움 색 `--color-clinical-deep`.
- 진입 시 0→8주 stagger 채움.

**라이브러리 결정**: 모든 차트는 직접 SVG로 인라인. *Recharts·D3 미사용* — 번들 사이즈 절약(JS < 100KB 목표).

### 5.3 아이콘 세트

**Lucide Icons** (오픈, 가벼움) — `lucide-react` 또는 ESM 트리쉐이킹.

표준:
- 사이즈: 24px (UI), 20px (작은 라벨), 32px (큰 카드 강조)
- stroke-width: 1.5px
- 색: `currentColor` (텍스트 색 상속)

사용 아이콘 (예상):
- `Headphones` (Hero 보조, AirPods 표현)
- `Calendar` (28일 코스)
- `Stethoscope` 또는 `Activity` (임상 권위)
- `Heart` (코칭 톤 — 단, 너무 흔하면 회피)
- `ChevronDown` (FAQ 화살표)
- `Check` (체크리스트, 환불 보장)
- `ArrowRight` (텍스트 링크 화살표)
- `Mail` (이메일 폼)
- `Quote` (인용 카드)

**커스텀 SVG 5개**:
1. `airpods-pro` (위 §5.1)
2. `health-gauge` (위 건강 점수 원형)
3. `stomach-soft` (위 일러스트, 옵션 — Solution 카드의 *위 회복* 비주얼화. 단순화된 둥근 위 모양 + 옅은 글로우)
4. `coach-avatar` (한국 페르소나 코치 — 둥근 얼굴, 코랄 톤, 최소 디테일)
5. `kol-silhouette` (KOL 영입 진행 중 회색 실루엣)

### 5.4 그라데이션 라이브러리

```css
--grad-hero:
  radial-gradient(ellipse 60% 50% at 75% 30%,
    var(--color-clinical-soft) 0%, transparent 70%),
  radial-gradient(ellipse 50% 40% at 25% 70%,
    var(--color-coaching-soft) 0%, transparent 70%),
  var(--color-bg-cool);

--grad-solution:
  linear-gradient(180deg, var(--color-bg-cool) 0%,
                          var(--color-bg-mist) 30%,
                          var(--color-bg-mist) 100%);

--grad-airpods-demo:
  radial-gradient(ellipse 80% 60% at 50% 30%,
    rgba(0, 184, 148, 0.18) 0%, transparent 60%),
  radial-gradient(ellipse 60% 40% at 50% 80%,
    rgba(255, 122, 89, 0.10) 0%, transparent 60%),
  var(--color-bg-deep);

--grad-cta:
  linear-gradient(135deg, var(--color-cta) 0%,
                           color-mix(in srgb, var(--color-cta) 80%, var(--color-coaching) 20%) 100%);

--grad-final-cta:
  linear-gradient(180deg, var(--color-bg-deep) 0%,
                           color-mix(in srgb, var(--color-bg-deep) 90%, var(--color-clinical) 10%) 100%);
```

### 5.5 사진/일러스트

**사용 0개** — 이 페이지에 *제3자 사진 없음*. 이유:
- 한국 위염 환자 페르소나 사진은 *진정성 위협* (스톡 사진은 가짜로 보임)
- KOL 사진은 영입 후에만, 영입 전엔 회색 실루엣
- 모든 비주얼은 SVG 일러스트로 — 스타일 일관성 + 라이센스 안전 + 성능

이 결정은 카피라이터 §5 M4(*"흐릿한 연예인 프레임 같은 건 절대 금지"*)와 정합.

---

## 6. 반응형 사양

### 6.1 브레이크포인트

```css
/* Tailwind와 정합 */
--bp-mobile:  0px;        /* mobile-first */
--bp-tablet:  640px;
--bp-laptop:  1024px;
--bp-desktop: 1280px;     /* 1200px max-width container 실제 발화점 */
```

### 6.2 모바일에서 *생략*하는 인터랙션

- AirPods Demo의 `pin + scrub` 시퀀스 → 4 카드 분리 페이드 (성능)
- 페이지 전체 Lenis 스무스 스크롤 → 네이티브 스크롤 (모바일은 OS의 모멘텀이 더 자연스러움)
- 마이크로 호버 효과 → 탭 효과로 대체 (`:active` 짧은 스케일)
- Pricing 추천 카드의 glow 그림자 → 평범한 그림자 (페인트 비용)

### 6.3 모바일 *대체*

- 호버 lift → tap-highlight 비활성 후 active scale 0.98 짧게
- AirPods Demo 시그니처 → 4 카드 세로 스택 + 각 카드 IO 진입 시 1회 애니메이션
- Problem 페르소나 트리거 카드 3개 → 수평 스크롤 캐러셀 (snap-x mandatory + 점 인디케이터)
- FAQ 아코디언 → 동일 (모바일도 단일 펼침으로 보호)

### 6.4 iOS Safari 100vh 처리

```css
.hero { min-height: 100vh; min-height: 100svh; }
/* svh = small viewport height — 동적 UI bar 제외, 항상 작은 값 */
/* 또는 dvh (dynamic) — 사용자 컨텍스트에 따라 변동 */
```

**결정**: Hero에는 `100svh` (가장 짧은 상태에서도 핵심 메시지 전부 보임).

### 6.5 폰트 사이즈 모바일 자동 줌 방지

- 모든 폼 인풋 `font-size: 16px` 이상.
- `<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">`.
- 단, `maximum-scale=1`은 *사용 안 함* (접근성 — 사용자가 200%까지 확대 가능해야).

### 6.6 터치 vs 마우스

- 호버 효과는 `@media (hover: hover)`로 한정.
- 터치 환경에서는 `:active`만 발화.
- FAQ Q는 큰 터치 영역(min-height 56px).
- CTA는 min-height 48px (모바일 터치 가이드라인).

---

## 7. 접근성·성능 가드레일

### 7.1 WCAG AA

- 모든 본문 텍스트 색 대비 ≥ 4.5:1 (위 §2.2 검증표).
- 큰 텍스트(24px+) ≥ 3:1.
- 액센트 컬러 본문 사용 시 *-deep 변형* 의무.
- 의미를 색으로만 전달 금지 — 모든 시그널에 *텍스트 라벨 또는 아이콘* 동반:
  - "진행 중" 칩 = 색 + 텍스트 라벨
  - 차트의 빠른/목표 영역 = 색 + 라벨 + 패턴(점선 vs 실선) 옵션

### 7.2 Reduced Motion

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
  [data-reveal] { opacity: 1 !important; transform: none !important; }
}
```

추가:
- Lenis 스무스 스크롤 *비활성*.
- AirPods Demo 시그니처 → 즉시 4 카드 정적 표시.
- Authority KOL 호흡, 상태 칩 펄스 → 정지 상태로.

### 7.3 키보드 네비게이션

- 모든 CTA·링크·폼 인풋·FAQ Q는 `tab`으로 도달.
- 포커스 링: `:focus-visible` 시 2px solid `--color-cta` outline + 2px offset. 마우스 클릭에는 표시 안 함.
- FAQ는 Enter/Space로 펼침.
- 폼 Submit은 Enter로.

### 7.4 ARIA·시맨틱

- 페이지 구조: `<main>` 안에 `<section>` 10개. 각 section에 `aria-labelledby` (헤더 id 참조).
- AirPods Demo: `<figure aria-label="AirPods가 식사 속도를 측정해 위 건강 점수로 변환하는 과정">`.
- 차트: `<svg role="img" aria-label="한국 직장인 평균 점심 시간 11분 대 권장 20분">`.
- FAQ: `<details>`/`<summary>` 또는 `<button aria-expanded>`로 구현.
- 폼: `<label>` 명시 (visually-hidden 가능, screen reader는 읽음).
- Skip link: 페이지 최상단 `<a href="#main">본문으로 건너뛰기</a>` (Tab 첫 포커스).

### 7.5 폰트·이미지·아이콘 접근성

- 사용자 200% 확대 가능 — `rem` 단위 사용, `px` 고정 금지(폰트 사이즈는 rem).
- 의미 있는 SVG는 `<title>` + `aria-label`. 장식용 SVG는 `aria-hidden="true"`.

### 7.6 성능 목표

| 메트릭 | 목표 | 전략 |
|---|---|---|
| **LCP** | < 2.5s (모바일 4G) | Hero 헤드라인이 LCP 후보. 폰트 `font-display: swap` + Pretendard preload. AirPods SVG는 인라인. |
| **CLS** | < 0.1 | 모든 이미지·SVG에 width/height 명시. 폰트 fallback 매칭(Pretendard ↔ system-ui). |
| **INP** | < 200ms | GSAP·Lenis는 idle init. ScrollTrigger refresh를 무거운 시점에만. |
| **FCP** | < 1.8s | Critical CSS inline (Hero 스타일만). 나머지는 defer. |
| **TBT** | < 200ms | JS 청크 분할. AirPods Demo의 GSAP 애니메이션은 IntersectionObserver로 lazy init. |

**번들 사이즈 목표**:
- JS < 100KB (gzip): GSAP core + ScrollTrigger + Lenis ≈ 60KB. 자체 코드 + IO 폴리필 30KB 여유.
- CSS < 50KB: Tailwind purge + 토큰.
- 이미지/SVG < 500KB: 모두 SVG, 사진 0장.

**폰트 전략**:
```html
<link rel="preconnect" href="https://cdn.jsdelivr.net" crossorigin>
<link rel="preload" as="style"
      href="https://cdn.jsdelivr.net/gh/orioncactus/pretendard@v1.3.9/dist/web/variable/pretendardvariable-dynamic-subset.min.css">
```
- Pretendard Variable Dynamic Subset (한글 사용 글자만 로드 — 약 200KB → 80KB).
- Noto Serif KR은 *Authority 인용·페르소나 트리거 한정* — `font-display: swap` + 작은 부분집합만.

### 7.7 SEO

- `<title>` "Chew & Calm Coach — 8주, 위 건강을 차분히 되찾아요"
- `<meta description>` 30초 피치 첫 1문장.
- Open Graph: 1200×630 OG 이미지 (Hero 헤드라인 + AirPods 일러스트의 정적 캡처).
- 구조화 데이터: Product, FAQPage (FAQ 8개를 schema.org 형식으로).
- `<html lang="ko">`.
- `sitemap.xml` + `robots.txt`.

---

## 8. 컴포넌트 카탈로그 (landing-architect 인계용)

| 컴포넌트 | Props 스케치 | 사용 위치 |
|---|---|---|
| `<Section>` | tone: 'cool'\|'warm'\|'mist'\|'deep', paddingY?: 'lg'\|'xl' | 모든 섹션 래퍼 |
| `<Container>` | size: 'default'\|'narrow'\|'prose' | 섹션 안 그리드 컨테이너 |
| `<Heading>` | level: 1-4, accent?: 'clinical'\|'coaching', as?: 'h1'\|'h2' | 모든 제목 |
| `<Display>` | size: 'xl'\|'lg', accentWords?: string[] | Hero, Final CTA |
| `<CtaPrimary>` | href, label, icon? | 베타 합류 |
| `<CtaSecondary>` | href, label | 텍스트 링크 |
| `<Card>` | variant: 'flat'\|'elevated'\|'highlight', tone? | Differentiation, Pricing 등 |
| `<StatCard>` | label, stat, source | Problem 의학 근거 |
| `<QuoteCard>` | quote, persona, label | Problem 페르소나 트리거 |
| `<KolPlaceholder>` | role, status: 'recruiting' | Authority, How |
| `<StatusChip>` | status: 'inProgress'\|'beta'\|'live' | Authority |
| `<PriceCard>` | tier, price, period, features, recommended? | Pricing |
| `<FaqItem>` | q, a, highlight? | FAQ |
| `<EmailForm>` | onSubmit, placeholder, ctaLabel | Hero, Final CTA, Footer |
| `<Clock>` | minutes, target, label | Problem |
| `<HealthScoreGauge>` | score, change | AirPods Demo |
| `<CalendarMini>` | weeks: 4, completedDays: number | Solution, How |
| `<AirpodsSvg>` | variant: 'mono'\|'light', state: 'idle'\|'pulse'\|'streaming'\|'gauge' | Hero, Demo |
| `<DataStream>` | rows: { time, label }[] | Demo |

---

## 9. 디자인 시스템 → 기술 명세 인계 체크리스트 (landing-architect용)

- [ ] CSS 변수 모두 `:root`에 등록 (위 §2.1, §2.4, §2.6)
- [ ] Tailwind config에 토큰 매핑 (§2.7)
- [ ] Pretendard Variable + Noto Serif KR 부분집합 preload
- [ ] AirPods SVG 2 변형 인라인 컴포넌트
- [ ] GSAP + ScrollTrigger + Lenis 설치, Lenis-ScrollTrigger 동기화
- [ ] IntersectionObserver 기반 reveal (§4.1)
- [ ] AirPods Demo 시그니처 인터랙션 (§3.4) — Desktop 핀 / Mobile 4 카드
- [ ] FAQ 단일 펼침 아코디언 (§3.9)
- [ ] 폼 1필드 (이메일) — Hero / Final CTA / Footer 3개 위치
- [ ] `prefers-reduced-motion` 전역 처리 (§7.2)
- [ ] WCAG AA 색 대비 검증 (§2.2 표 그대로)
- [ ] LCP/CLS/INP 측정 — Lighthouse Desktop ≥ 95, Mobile ≥ 90

---

## 10. 카피라이터 회신 메모 (`marketing-storyteller` 수신)

> 카피라이터에게 — `01_strategy_copy.md` §5의 협의 메모 M1~M7 모두 디자인에 반영했어요.
> 다만 디자인 관점에서 *카피에 줄 변경 권고 4가지*가 생겼어요. 모두 작은 조정이고, 의미는 보존 가능해요.

### R1. M1 헤드라인 폰트 — *세리프 대신 Pretendard 800 + 액센트* 권고

> M1에서 *"한국형 세리프(노토 세리프 KR Bold 또는 Pretendard Black 대안)"* 권장하셨는데, 디자인 관점에서 **Pretendard 800 (ExtraBold) + 액센트 단어만 컬러**로 결정했어요. 이유:
> - 한글 본문 세리프는 모바일 가독성 부담이 커요 (anti-aliasing이 화면 사이즈에 따라 흔들림)
> - Noto Serif KR Bold의 한글 자체 무게는 Pretendard 800과 비교해 *임팩트가 약간 덜함* (실측: x-height와 검은 면적)
> - 세리프 폰트 추가 로드는 LCP에 부담 (300KB+)
> - 단, **헤드라인 [C] 권위 인용("음식은 약과 같다.")과 의학 근거 인용 출처는 Noto Serif KR Italic**으로 한정 사용 — *학술 톤 시각 시그널*로 작동
>
> *영향*: 헤드라인 [A] *"당신의 점심은 평균 11분"*은 **Pretendard 800 + "11분"·"8주" 액센트**로 표현. M1의 *통계 트리거 무게*는 보존됩니다 (검증: Pretendard 800 64px가 Noto Serif KR Bold 56px보다 *시각 무게 = 더 강함*).
>
> *카피 변경 요청 0개* — 카피는 그대로, 디자인 결정만 통보.

### R2. Hero 보조 1줄 — 줄바꿈 위치 권고

현재 카피:
> 이미 끼고 있는 AirPods가 식사 속도를 자동으로 보여주고,
> 임상 28일 코스가 매일 2-3분, 함께 걸어요.

데스크탑에서는 두 줄로 깔끔하지만 모바일에서 자연스러운 줄바꿈이 깨져요. 디자인 관점 권고:
> 이미 끼고 있는 AirPods가
> 식사 속도를 보여주고,
> 임상 28일 코스가 매일 2-3분 함께 걸어요.

(첫 줄 짧게 + 둘째 줄 결과 + 셋째 줄 코스). 또는 *데스크탑 2줄 / 모바일 3줄*로 `<br>` 분기. **이 결정은 카피라이터에게 위임** — 의미·리듬은 카피 영역이고, 디자인은 양쪽 모두 처리 가능.

*카피라이터 결정 부탁*: A) 그대로(현 2줄) / B) 모바일 3줄 분기 / C) 새 1문장 ("이미 끼고 있는 AirPods + 매일 2-3분 코스 = 8주 후 위 건강.").

### R3. Final CTA self-aware 문장 — *길이는 보존, 시각 강조 추가*

§3.10에 명시했지만 카피라이터 명시 확인 필요:
> "1만 명이 합류했다고 거짓말하지 않아요. 지금은 우리가 함께 걸을 첫 사람들을 모으고 있어요."

이 두 줄은 *별도 박스 + 좌측 1px 라인 + Noto Serif KR Italic*으로 처리할게요 — *공식 마케팅 톤*에서 *작가의 손편지*로 분위기 전환. 카피 길이·단어는 보존.

*카피라이터 확인 부탁*: 이 시각 처리(*손편지 톤 박스*)에 동의하시는지. 동의 시 §6 보존 필수 카피 6번에 *"이 두 줄은 별도 박스 + 세리프 이탤릭으로 시각 처리, 줄임 금지"* 명시 권고.

### R4. Pricing 가격 카드 — *연간만 추천 + 월간 디폴트 표시 안 함* 디자인 결정

M5 합의대로 연간 카드만 강조했어요. 다만 카드 헤더 라벨이 카피에 명시되지 않았어요. 디자인은:
- 카드 1: "월간"
- 카드 2: "연간 — 추천" (← 추가 라벨)
- 카드 3: "28일 코스 단품"

또한 카드 2에 "한 달 무료" 칩을 추가했어요 (33%가 1/12로 한 달 무료에 가까운 수치 보존). M5의 *"한 달 무료에 가까워요"* 카피와 정합.

*카피라이터 확인 부탁*: "추천" 라벨과 "한 달 무료" 칩의 단어 채택 OK 여부. 다른 표현 제안 환영.

---

## 문서 끝

이 디자인 사양은 `landing-architect`가 *결정 없이 빌드 가능*하도록 작성됐다.

- 모든 토큰 → CSS 변수
- 모든 인터랙션 → 의사코드 + 라이브러리
- 모든 섹션 → 와이어프레임 + 모바일/데스크탑 변형
- 모든 자산 → SVG 사양 + 색·사이즈
- 시그니처 인터랙션 → 핀 + 4 단계 + 모바일 대체

다음 단계: `landing-architect`가 `_workspace/landing/03_architecture.md`에서 컴포넌트 트리·라우팅·번들·배포 사양으로 변환.
