# 14 — 목적 선택 UI + 컨센트 다이얼로그 인터랙션 사양

> Phase 5-B-3 (UX 단발 호출). 입력 = `13_data_v2_consolidated.md` (합의 5 + enum + 흐름) + `02_visual_ux.md` (디자인 시스템·모션 토큰) + `10_consent_strategy.md` §3 (카피 디폴트). 산출물 소비자 = `frontend-implementer` (16 라운드) + `marketing-storyteller` (15 라운드, 카피 슬롯).

## 0. 라운드 헌법 — 결정 5개

1. **목적 선택 UI 매트릭스**: `stacked` = 라디오 카드 3개 (디폴트 라운드의 핵심 변형) / `inline` = 세그먼트 / `caption` = 드롭다운. 폼 variant마다 다른 UI를 끼워 넣는다.
2. **컨센트 디폴트 = OFF** — `10_consent_strategy.md` §3.3과 일치 (PIPA 명시적 옵트인). 작업 지시서의 "기본 ON" 표현은 본 라운드에서 *OFF로 정정*. 이유: 디폴트 ON은 dark pattern로 옵션 G 톤 위반 + GDPR/PIPA 위반 가능성. autoFocus는 *체크박스가 아니라 [확인] 버튼*에 둔다 (확인 가속).
3. **시그니처 모션 0개** — 본 라운드의 UI는 *기능 전달*만 한다. 새 모션 토큰을 추가하지 않고 `02_visual_ux.md` §6의 `motion.scrollReveal`·`motion.formFocus`·`motion.ctaPress` 토큰을 *그대로 재사용*. 다이얼로그 등장만 신규 모션 *조합* (기존 토큰 재활용).
4. **신규 색·반경 토큰 0개** — `bg-cool` / `bg-warm` / `cta` / `cta-soft` / `coaching-soft` / `clinical-soft` / `line` / `text-*` / `border-radius xl` 모두 기존 사용. 라디오 카드 *선택 상태*만 `border-cta + bg-cta-soft + ring`으로 강조.
5. **5초 룰**: 폼 → 다이얼로그 → 성공까지 *3 탭 이내* (목적 선택 1탭 + 이메일 입력 후 [확인] 버튼 1탭 + 다이얼로그 [확인하고 신청] 1탭 = 3탭). 4 디바이스 모두 통과. 실패 시 디폴트 UI(stacked variant)는 자동으로 sticky bottom으로 빠지지 않는다 — 본 라운드 범위 외.

---

## 1. 목적 선택 UI 매트릭스

### 1.1 폼 variant × 목적 UI 결정 표

| 폼 variant | 위치 (현재 사용처) | 목적 UI | 이유 |
|-----------|-------------------|---------|------|
| `stacked` | (현재 `Hero`·`FinalCTA`가 *inline*임 — 본 라운드에서 `FinalCTA`를 `stacked`로 바꿈) | **라디오 카드 3개** | 가장 풍부한 시각·터치 영역. Final CTA의 *깊은 결정 모먼트*에 충분한 공간이 있음 |
| `inline` | `Hero` 잔존 시 | **세그먼트** (pill toggle 3개) | 좁은 1행 폼에 들어가면서도 3 옵션 명시. 한 화면 안에 inline 폼이 1개일 때만 사용 |
| `caption` | (현재 미사용 — 향후 `Footer` 미니 폼 후보) | **드롭다운** | 가장 컴팩트. 캡션 사이즈 폼에는 라디오 3개·세그먼트는 가독성 부족 |

**디폴트 권장 = stacked + 라디오 카드.** `Hero.tsx`의 EmailForm은 *유지*하되 향후 라운드에서 inline → stacked로 통일하는 옵션을 architect와 상의 (이번 라운드는 `FinalCTA`만 변경 — 가장 큰 신청 전환 지점이므로 우선순위 1).

### 1.2 라디오 카드 3개 (변형 1 — 디폴트)

#### 레이아웃

```
Desktop (≥640px) — horizontal grid 3-col
┌───────────────────┐  ┌───────────────────┐  ┌───────────────────┐
│  [icon]           │  │  [icon]           │  │  [icon]           │
│  체중·식습관 관리  │  │  소화 문제 개선    │  │  기타 / 둘 다     │
│  체중을 천천히 조  │  │  속쓰림·역류·위염  │  │  마음챙김 식사 등 │
│  절하고 싶어요    │  │  같은 위장 부담    │  │                   │
│         ◯         │  │         ◯         │  │         ◯         │
└───────────────────┘  └───────────────────┘  └───────────────────┘

Mobile (<640px) — vertical stack
┌─────────────────────────────────────┐
│ [icon] 체중·식습관 관리          ◯  │  (선택 시 색 채움)
│        체중을 천천히 조절하고…       │
├─────────────────────────────────────┤
│ [icon] 소화 문제 개선            ◯  │
│        속쓰림·역류·위염 같은…        │
├─────────────────────────────────────┤
│ [icon] 기타 / 둘 다              ◯  │
│        마음챙김 식사 등 그 외        │
└─────────────────────────────────────┘
```

#### Tailwind 클래스 (구현자가 그대로 받음)

```tsx
// 컨테이너
<div
  role="radiogroup"
  aria-labelledby="purpose-legend"
  className="grid grid-cols-1 gap-3 sm:grid-cols-3 sm:gap-4"
>
  {/* 각 카드 */}
</div>

// 카드 1개 (선택 상태에 따라 클래스 분기)
<label
  className={cn(
    'group relative flex cursor-pointer flex-col gap-2 rounded-xl border bg-bg-cool p-4 sm:p-5',
    'transition-all duration-200 ease-out',
    'hover:border-line-strong hover:shadow-sm',
    'has-[:focus-visible]:outline-2 has-[:focus-visible]:outline-cta has-[:focus-visible]:outline-offset-2',
    isSelected
      ? 'border-cta bg-cta-soft/40 shadow-sm ring-2 ring-cta/20'
      : 'border-line',
  )}
>
  <input
    type="radio"
    name="purpose"
    value="diet" // | "digestion" | "other"
    checked={isSelected}
    onChange={() => setPurpose('diet')}
    className="peer sr-only"
    data-ph-no-capture={false} // purpose는 PostHog 캡처 OK
  />
  {/* 아이콘 + 라벨 */}
  <div className="flex items-start justify-between gap-3">
    <div className="flex flex-col gap-1">
      <div className="flex items-center gap-2">
        <Icon size={18} strokeWidth={1.75} className="text-clinical-deep" />
        <span className="text-body font-semibold text-text-primary">
          {{LABEL}}
        </span>
      </div>
      <p className="text-body-sm text-text-muted">{{HELPER}}</p>
    </div>
    {/* 체크 인디케이터 */}
    <div
      className={cn(
        'mt-1 flex h-5 w-5 shrink-0 items-center justify-center rounded-full border-2 transition-colors duration-150',
        isSelected ? 'border-cta bg-cta' : 'border-line-strong bg-transparent',
      )}
      aria-hidden="true"
    >
      {isSelected && <Check size={12} strokeWidth={3} className="text-white" />}
    </div>
  </div>
</label>
```

#### 카피 슬롯 (storyteller 입력)

| 키 | 디폴트 (placeholder) | 한도 |
|----|----------------------|------|
| `purpose.legend` | "어떤 목적으로 시작하시나요?" | ≤ 16자 |
| `purpose.diet.label` | "체중·식습관 관리" | ≤ 12자 |
| `purpose.diet.helper` | "체중을 천천히 조절하고 싶어요" | ≤ 22자 |
| `purpose.digestion.label` | "소화 문제 개선" | ≤ 12자 |
| `purpose.digestion.helper` | "속쓰림·역류·위염 같은 위장 부담" | ≤ 22자 |
| `purpose.other.label` | "기타 / 둘 다" | ≤ 12자 |
| `purpose.other.helper` | "마음챙김 식사 등 그 외" | ≤ 22자 |

#### 아이콘 매핑 (lucide-react 사용 — 신규 의존성 0)

| purpose | 아이콘 | 의도 |
|---------|--------|------|
| `diet` | `Scale` | 무게·균형 (체중 관리 메타포) |
| `digestion` | `Sparkles` (or `HeartPulse`) | 위 편안함 — `Stomach` 없음, `Sparkles`로 부드러움 |
| `other` | `MoreHorizontal` | 그 외 |

> *대안*: `digestion`은 `HeartPulse`도 가능 — storyteller·디자이너 협의 후 결정. 본 라운드 디폴트는 `Sparkles` (의료 시그널 회피).

### 1.3 세그먼트 컨트롤 (변형 2 — inline variant)

```tsx
// pill 3개를 가로로 — 좁은 폼에 적합
<div
  role="radiogroup"
  aria-labelledby="purpose-legend"
  className="inline-flex w-full rounded-full border border-line bg-bg-cool p-1"
>
  {options.map((opt) => (
    <button
      key={opt.value}
      type="button"
      role="radio"
      aria-checked={purpose === opt.value}
      onClick={() => setPurpose(opt.value)}
      className={cn(
        'flex-1 rounded-full px-3 py-2 text-body-sm transition-all duration-200 ease-out',
        'focus-visible:outline-2 focus-visible:outline-cta focus-visible:outline-offset-2',
        purpose === opt.value
          ? 'bg-cta text-white shadow-sm'
          : 'text-text-muted hover:bg-bg-mist hover:text-text-primary',
      )}
    >
      {opt.shortLabel}
    </button>
  ))}
</div>
```

shortLabel은 12자 이내, 라디오 카드 라벨과 같은 카피 토큰을 *축약형*으로 제공한다.

| 키 | 디폴트 |
|----|--------|
| `purpose.diet.shortLabel` | "체중·식습관" |
| `purpose.digestion.shortLabel` | "소화 문제" |
| `purpose.other.shortLabel` | "그 외" |

### 1.4 드롭다운 (변형 3 — caption variant)

```tsx
<select
  value={purpose}
  onChange={(e) => setPurpose(e.target.value as Purpose)}
  className={cn(
    'h-10 w-full rounded-full border border-line bg-bg-cool px-4 text-body-sm text-text-primary',
    'focus:border-cta focus:outline-none focus:ring-4 focus:ring-cta-soft',
    'transition-all duration-200',
  )}
  aria-label="목적 선택"
>
  <option value="">목적을 선택해주세요</option>
  <option value="diet">체중·식습관 관리</option>
  <option value="digestion">소화 문제 개선</option>
  <option value="other">기타 / 둘 다</option>
</select>
```

- 네이티브 `<select>` 사용 — 모바일 OS의 picker UX가 가장 자연스러움.
- caption variant 폼은 *5초 룰 지키기 어려움 → 향후 보조용*. 본 라운드 자체는 미사용 가능성 높음.

---

## 2. ConsentDialog — 인터랙션·레이아웃·모션 사양

### 2.1 진입·종료 흐름

```
[EmailForm 사용자가 이메일 + purpose 입력 후 "베타에 합류하기" 클릭]
   ↓
   track('form_submit_try', { source, purpose, has_email: true })
   ↓
[ConsentDialog 등장 — backdrop fade 200ms + dialog scale 0.96→1 + fade 250ms]
   ↓
   track('consent_view', { consent_version: '2026-05-04' })
   ↓ (autoFocus = [확인하고 신청] 버튼)
   ↓
사용자 인터랙션:
  - 체크박스 토글 (100ms ease)
  - [취소] 클릭 / ESC / backdrop 클릭 → reverse 모션 (200ms)
  - [확인하고 신청] 클릭 → reverse 모션 (200ms) + submit 진행
   ↓
[성공 메시지 — EmailForm 같은 자리에 인라인 치환]
```

### 2.2 모달 카드 레이아웃

#### Desktop (≥768px) — width 480px, side-by-side 버튼

```
┌──────────────────────────────────────────────────────┐
│                                                  ✕    │ ← 닫기 (선택, ESC와 동일)
│   {{HEAD_COPY}}                                       │
│   (text-heading-3 · text-text-primary · 마진 하단 8) │
│                                                       │
│   {{BODY_COPY 2-3 문장}}                              │
│   (text-body · text-text-secondary · 마진 하단 24)   │
│                                                       │
│   ┌─────────────────────────────────────────────┐    │
│   │ ☐  출시 소식 받기 (선택)                    │    │ ← 체크박스 (디폴트 OFF)
│   │    (text-body · text-text-primary)          │    │
│   └─────────────────────────────────────────────┘    │
│                                                       │
│   [개인정보 처리방침] · [수신거부 안내]               │ ← 작은 글씨, underline-offset
│   (text-caption · text-text-muted)                   │
│                                                       │
│   ┌─────────────┐  ┌────────────────────────────┐   │
│   │   취소      │  │      확인하고 신청          │   │ ← Primary autoFocus
│   │ (secondary) │  │       (primary cta)         │   │
│   └─────────────┘  └────────────────────────────┘   │
│                                                       │
│                           약관 버전: 2026-05-04 ◌   │ ← 작게 우측 하단
└──────────────────────────────────────────────────────┘
```

#### Mobile (<640px) — width 96vw (max 480px), stacked 버튼

```
┌──────────────────────────────────┐
│                              ✕   │
│ {{HEAD_COPY}}                    │
│                                  │
│ {{BODY_COPY}}                    │
│                                  │
│ ┌──────────────────────────────┐ │
│ │ ☐ 출시 소식 받기 (선택)       │ │
│ └──────────────────────────────┘ │
│                                  │
│ [개인정보 처리방침] · [수신거부]  │
│                                  │
│ ┌──────────────────────────────┐ │
│ │      확인하고 신청            │ │ ← full-width primary
│ └──────────────────────────────┘ │
│ ┌──────────────────────────────┐ │
│ │           취소                │ │ ← full-width secondary, 아래
│ └──────────────────────────────┘ │
│                                  │
│              약관 버전: 2026-05-04│
└──────────────────────────────────┘
```

#### Tailwind 사양 — 카드 컨테이너

```tsx
// Backdrop
<div
  className={cn(
    'fixed inset-0 z-50 bg-bg-deep/60 backdrop-blur-sm',
    'transition-opacity duration-200 ease-out',
    isOpen ? 'opacity-100' : 'pointer-events-none opacity-0',
  )}
  aria-hidden="true"
  onClick={onCancel}
/>

// Dialog 카드 (centered)
<div
  role="dialog"
  aria-modal="true"
  aria-labelledby="consent-dialog-title"
  aria-describedby="consent-dialog-body"
  className={cn(
    'fixed left-1/2 top-1/2 z-50 w-[96vw] max-w-[480px] -translate-x-1/2 -translate-y-1/2',
    'rounded-xl border border-line bg-bg-cool p-6 sm:p-8',
    'shadow-xl',
    'transition-all duration-250 ease-[cubic-bezier(0.16,1,0.3,1)]',
    isOpen
      ? 'scale-100 opacity-100'
      : 'pointer-events-none scale-[0.96] opacity-0',
  )}
>
  {/* ... */}
</div>
```

### 2.3 체크박스 — Apple SF-style + 토큰 일관

```tsx
<label
  htmlFor="consent-marketing-checkbox"
  className="flex cursor-pointer items-start gap-3 rounded-md p-2 -m-2 hover:bg-bg-mist/60 transition-colors"
>
  <input
    id="consent-marketing-checkbox"
    type="checkbox"
    checked={consentMarketing}
    onChange={(e) => setConsentMarketing(e.target.checked)}
    className="peer sr-only"
  />
  {/* 비주얼 박스 */}
  <span
    aria-hidden="true"
    className={cn(
      'mt-[2px] flex h-5 w-5 shrink-0 items-center justify-center rounded-md border-2 transition-all duration-100 ease-out',
      consentMarketing
        ? 'border-cta bg-cta'
        : 'border-line-strong bg-bg-cool peer-hover:border-text-muted',
      'peer-focus-visible:outline-2 peer-focus-visible:outline-cta peer-focus-visible:outline-offset-2',
    )}
  >
    {consentMarketing && (
      <Check size={14} strokeWidth={3} className="text-white" />
    )}
  </span>
  <span className="text-body text-text-primary">
    {{CONSENT_CHECKBOX_LABEL}}
  </span>
</label>
```

| 픽셀 사양 | 값 |
|----------|---|
| 박스 크기 | 20×20 (`h-5 w-5`) |
| 박스 반경 | `rounded-md` = 12px → 6px override 시 `rounded-[6px]` (디폴트는 12 너무 큼) |
| 토글 duration | 100ms ease-out |
| 체크 아이콘 크기 | 14×14, strokeWidth 3 |
| 디폴트 상태 | **OFF (unchecked)** — `10_consent_strategy.md` §3.3 PIPA 준수 |
| Hit area | 라벨 전체 클릭 가능 (`<label>` wrapping) — 라벨 padding 8 + 박스 20 → 36px+ hit area |

> **수정 권장**: 위 코드의 `rounded-md`를 `rounded-[6px]`로 명시. 12px는 체크박스에 너무 큼.

### 2.4 약관·정책 링크 (subtle)

```tsx
<div className="flex flex-wrap items-center gap-x-3 gap-y-1 text-caption text-text-muted">
  <a
    href="/privacy"
    target="_blank"
    rel="noopener noreferrer"
    className="underline underline-offset-2 decoration-line-strong hover:text-text-primary hover:decoration-text-primary transition-colors"
  >
    개인정보 처리방침
  </a>
  <span aria-hidden="true">·</span>
  <a
    href="/unsubscribe"
    target="_blank"
    rel="noopener noreferrer"
    className="underline underline-offset-2 decoration-line-strong hover:text-text-primary hover:decoration-text-primary transition-colors"
  >
    수신거부 안내
  </a>
</div>
```

- Hit area는 a 태그 자체 — 모바일에서 px 부족 시 부모 div에 `py-2 -my-2`로 확장.
- 외부 링크는 새 탭 (다이얼로그 컨텍스트 유지).

### 2.5 버튼 2개

```tsx
{/* Desktop side-by-side / Mobile stacked */}
<div className="flex flex-col-reverse gap-2 sm:flex-row sm:justify-end sm:gap-3">
  <button
    type="button"
    onClick={onCancel}
    className={cn(
      'inline-flex h-12 items-center justify-center rounded-full border border-line bg-bg-cool px-6 text-body font-medium text-text-primary',
      'transition-all duration-200 ease-out hover:bg-bg-mist',
      'active:scale-[0.97]',
      'focus-visible:outline-2 focus-visible:outline-cta focus-visible:outline-offset-2',
    )}
  >
    {{CANCEL_LABEL}}
  </button>
  <button
    ref={primaryButtonRef}
    type="button"
    onClick={onConfirm}
    className={cn(
      'inline-flex h-12 items-center justify-center rounded-full bg-cta px-6 text-body font-medium text-white',
      'transition-all duration-200 ease-out hover:bg-cta-hover hover:shadow-lg',
      'active:scale-[0.97]',
      'focus-visible:outline-2 focus-visible:outline-cta focus-visible:outline-offset-2',
    )}
  >
    {{CONFIRM_LABEL}}
  </button>
</div>
```

- Primary 버튼이 *시각적으로 우측*. 모바일에서는 `flex-col-reverse`로 *위*에 위치 — 엄지 닿기 좋음.
- height 48px → WCAG 2.5.5 (target size) 통과.

### 2.6 약관 버전 배지

```tsx
<p className="mt-4 text-right text-[11px] text-text-subtle">
  약관 버전: {{CONSENT_VERSION}} {/* env.VITE_CONSENT_VERSION */}
</p>
```

매우 작게 — 법적 의무 표시이지 시각 강조 아님.

### 2.7 모션 사양 — 정량

| 모션 | 트리거 | duration | easing | 변화 | 토큰 출처 |
|------|--------|----------|--------|------|----------|
| `motion.dialogBackdrop` | open/close | 200ms | `ease-out` | opacity 0↔1 | 신규 (간단 토큰) |
| `motion.dialogCard` | open/close | 250ms | `cubic-bezier(0.16, 1, 0.3, 1)` | scale 0.96↔1 + opacity 0↔1 | `02_visual_ux.md` §6 reveal easing 재사용 |
| `motion.checkboxToggle` | onChange | 100ms | `ease-out` | border + bg 색 전환 | `motion.formFocus` 변형 |
| `motion.ctaPress` | active | 120ms | `ease-in-out` | scale 1→0.97 | 기존 `motion.ctaPress` |
| `motion.linkUnderline` | hover | 200ms | `ease-out` | decoration 색 전환 | 기존 `motion.hoverLift` 변형 |

**reduced-motion 대응**:
```css
@media (prefers-reduced-motion: reduce) {
  /* dialog 등장은 즉시 표시 — 0.01s로 사실상 즉시 */
  [data-consent-dialog],
  [data-consent-backdrop] {
    transition-duration: 0.01s !important;
    transform: none !important;
  }
}
```

기존 `index.css`에 *이미 prefers-reduced-motion 전역 처리*가 있으므로(`02_visual_ux.md` §7.2) `[data-consent-dialog]` selector만 추가하면 됨.

### 2.8 키보드·접근성 인터랙션

| 행위 | 결과 |
|------|------|
| 다이얼로그 open | autoFocus = primary button (`[확인하고 신청]`) — 가장 자주 누르는 액션 |
| ESC 키 | onCancel 발동 |
| Backdrop 클릭 | onCancel 발동 |
| Tab | focus 순서: `[X 닫기]` → `체크박스` → `개인정보 처리방침` → `수신거부 안내` → `[취소]` → `[확인하고 신청]` → (loop) |
| Shift+Tab | 역순환 |
| Enter (체크박스 focus 시) | 토글 |
| Space | 체크박스 focus 시 토글, 버튼 focus 시 클릭 |

**focus trap**: 다이얼로그 오픈 시 외부 페이지 요소는 `inert` 속성 부여 (브라우저 호환 95%+, 폴리필 불요).

```tsx
useEffect(() => {
  const root = document.getElementById('root') // Vite 디폴트
  if (!root) return
  if (isOpen) {
    root.setAttribute('inert', '')
  } else {
    root.removeAttribute('inert')
  }
  return () => root.removeAttribute('inert')
}, [isOpen])
```

대안: `focus-trap-react` 라이브러리 (기존 의존성 검토 필요 — 추가 ~3KB). **본 라운드 권장 = `inert` + 수동 focus 관리** (의존성 0).

**aria 속성 명세**:
- `role="dialog"` + `aria-modal="true"`
- `aria-labelledby="consent-dialog-title"` (헤드 H2의 id)
- `aria-describedby="consent-dialog-body"` (본문 p의 id)
- 체크박스: `<label>` wrapping → screen reader가 "출시 소식 받기 선택, 체크박스, 체크 안 됨" 식으로 읽음

### 2.9 거절 분기 — 시각 변화 (subtle)

사용자가 체크박스 *해제 상태*에서 [확인하고 신청] 클릭 시:

- **버튼 라벨은 변하지 않음** — `10_consent_strategy.md` §3.5 "확인하고 신청"이 옵트인 무관하게 동일.
- **체크박스 아래 helper note 미세 변화** (선택 사양):
  ```tsx
  {!consentMarketing && (
    <p
      className="mt-2 text-caption text-text-muted opacity-70"
      role="status"
    >
      {{REJECT_HINT_COPY}} {/* 디폴트 placeholder: "출시 소식은 보내지 않아요. 신청은 그대로 처리돼요." */}
    </p>
  )}
  ```
- **이유**: 사용자가 "거절해도 신청 처리됨"을 *명시적으로 보고* 버튼 누름 → 다크 패턴 회피.
- storyteller에게 "거절 시 숨김 hint 카피 1줄" 슬롯 요청.

---

## 3. 성공 메시지 — 옵트인 분기 디자인

`10_consent_strategy.md` §3.6 카피 *디폴트 그대로* 사용 (storyteller가 다듬을 가능성 높음). 시각 변화는 *없음* — 같은 success layout, 카피만 분기.

```tsx
// EmailForm.tsx success 분기
if (status === 'success') {
  return (
    <div className={cn('flex items-start gap-2', isCaption ? 'text-caption' : 'text-body')}>
      <Check
        size={isCaption ? 16 : 20}
        strokeWidth={2}
        className="mt-0.5 shrink-0 text-success"
      />
      <span className="text-text-secondary">
        {consentMarketing
          ? {{SUCCESS_OPTIN_COPY}}
          : {{SUCCESS_REJECT_COPY}}}
      </span>
    </div>
  )
}
```

| 키 | 디폴트 (10 §3.6) |
|----|-----------------|
| `success.optin` | "합류해주셔서 감사해요. 출시 소식이 준비되면 가장 먼저 보내드릴게요." |
| `success.reject` | "신청을 받았어요. 진행 소식은 보내지 않지만, 출시되면 사이트에서 만나요." |

**디자인 결정**: 두 분기 모두 *같은 success 시각 톤* (Check + text-success + text-secondary 카피). 거절자에게 *시각적으로 차가운 표시 0건* — 옵션 G 톤(친근함 유지) 핵심.

---

## 4. 4 디바이스 사양

| 디바이스 | 폭 | 라디오 카드 | 다이얼로그 폭 | 다이얼로그 padding | 버튼 stack |
|---------|---|-----------|--------------|------------------|-----------|
| iPhone SE | 375 | vertical stack 3개 | 96vw (~360) | `p-6` (24) | vertical (col-reverse) |
| iPhone 15 | 393 | vertical stack 3개 | 96vw (~377) | `p-6` (24) | vertical (col-reverse) |
| iPad portrait | 768 | horizontal grid 3-col | 480px fixed | `p-8` (32) | horizontal |
| Desktop | 1280 | horizontal grid 3-col | 480px fixed | `p-8` (32) | horizontal |

**iPhone SE 검증 (가장 좁은 디바이스)**:
- 다이얼로그 폭: 96vw = 360px
- padding `p-6` = 24px → 콘텐츠 폭 = 312px
- 헤드라인 `text-heading-3` = 24px / lineHeight 32px → 한 줄 헤드라인은 *15자 이내*여야 안전 (storyteller 입력 제약)
- 체크박스 라벨 `text-body` = 16px → 한 줄 16자 이내, 2줄 OK
- 본문 3문장 시 *세로 길이 ~ 250px* + 헤드 + 체크박스 + 링크 + 버튼 2개 = *~ 480px* → SE 세로 667px의 72% 사용. backdrop 안에서 vertical center OK.
- **5초 룰 통과**: 라디오 탭 1 + [확인] 1 + [확인하고 신청] 1 = **3 탭** ✓

**vertical center 안전성**: 다이얼로그 높이가 viewport 90% 초과 시 `overflow-y: auto` + `max-h-[90vh]` 처리.

```tsx
className="... max-h-[90vh] overflow-y-auto ..."
```

---

## 5. 접근성 체크리스트

- [ ] 모든 인터랙티브 요소 키보드 도달 가능 (Tab/Shift+Tab/Space/Enter/ESC)
- [ ] focus visible — 2px solid `--color-cta` outline + 2px offset (기존 토큰 그대로)
- [ ] 색 대비 WCAG AA — `02_visual_ux.md` §2.2 표 그대로 (모든 토큰 통과 검증됨)
- [ ] 라디오 카드 선택 상태는 *색만으로 전달 X* — 체크 인디케이터(원형 fill + Check 아이콘)와 ring 동시 사용
- [ ] aria 속성: `role="dialog"`, `aria-modal`, `aria-labelledby`, `aria-describedby`, `role="radiogroup"`, `role="radio"`, `aria-checked`
- [ ] 체크박스: `<label>` wrapping → 스크린리더 "출시 소식 받기 선택, 체크박스, 체크 안 됨"
- [ ] 다이얼로그 open 시 `<body>`(또는 `#root`) `inert` 처리 — 백그라운드 요소 focus 차단
- [ ] reduced-motion 시 dialog 등장 0.01s — 즉시 표시
- [ ] 다이얼로그 close 시 *원래 트리거 버튼*에 focus 복원 (`primaryButtonRef.current?.focus()` 또는 외부 ref)

---

## 6. 컴포넌트 명세 (구현자 입력)

```
landing/src/components/
├── PurposeSelector.tsx
│   ├── PurposeRadioCards (variant: 'cards')
│   ├── PurposeSegmented (variant: 'segmented')
│   └── PurposeDropdown (variant: 'dropdown')
├── ConsentDialog.tsx
│   ├── (내부) ConsentDialogBackdrop
│   ├── (내부) ConsentDialogCard
│   ├── (내부) ConsentMarketingToggle
│   ├── (내부) ConsentLinks
│   └── (내부) ConsentDialogActions
└── EmailForm.tsx (수정 — §7 참조)
```

### 6.1 `PurposeSelector` props

```typescript
type Purpose = 'diet' | 'digestion' | 'other'

export interface PurposeSelectorProps {
  variant?: 'cards' | 'segmented' | 'dropdown'
  value: Purpose | null
  onChange: (next: Purpose) => void
  /** legend / 라벨 / helper 카피 — storyteller가 채움 */
  copy: {
    legend: string
    diet: { label: string; helper: string; shortLabel: string }
    digestion: { label: string; helper: string; shortLabel: string }
    other: { label: string; helper: string; shortLabel: string }
  }
  /** 미선택 + 제출 시도 시 강조 */
  hasError?: boolean
  className?: string
}
```

aria 속성: 컴포넌트 내부에서 `role="radiogroup"`, `aria-labelledby`, `aria-invalid`, 각 옵션 `role="radio"` + `aria-checked` 자동 부여.

### 6.2 `ConsentDialog` props

```typescript
export interface ConsentDialogProps {
  isOpen: boolean
  onCancel: () => void
  onConfirm: (consentMarketing: boolean) => void
  /** 카피 슬롯 — storyteller가 채움 */
  copy: {
    head: string
    body: string // 줄바꿈 \n 허용 (3문장 → 3줄)
    checkboxLabel: string
    rejectHint?: string // 체크 해제 시 표시 (옵션)
    cancelLabel: string
    confirmLabel: string
    privacyLinkLabel: string
    unsubscribeLinkLabel: string
  }
  /** env.VITE_CONSENT_VERSION 주입 */
  consentVersion: string
}
```

aria 속성: `role="dialog"`, `aria-modal="true"`, `aria-labelledby="consent-dialog-title"`, `aria-describedby="consent-dialog-body"`, focus trap (inert) 자동 관리.

---

## 7. EmailForm.tsx 변경 가이드 (구현자 패치)

현재 `landing/src/components/EmailForm.tsx` (170 줄) 변경 지점.

### 7.1 import 추가 (5번 줄)

```diff
 import { useState, type FormEvent } from 'react'
 import { Mail, ArrowRight, Check } from 'lucide-react'
 import { cn } from '../lib/cn'
 import { submitEmail, type SubmitReason } from '../lib/dataCollection'
+import { PurposeSelector, type Purpose } from './PurposeSelector'
+import { ConsentDialog } from './ConsentDialog'
+import { env } from '../lib/env'
+import { track } from '../lib/analytics'
```

### 7.2 props 확장 (15-25번 줄 인터페이스)

```diff
 export function EmailForm({
   variant = 'inline',
   placeholder = '이메일 주소',
   ctaLabel = '베타에 합류하기',
   helperText = '개인정보는 진행 소식 외에는 사용하지 않아요.',
+  source, // 'hero' | 'final_cta' | 'pricing' | 'footer' — track용
+  purposeCopy, // PurposeSelector copy slot
+  consentCopy, // ConsentDialog copy slot
 }: {
   variant?: Variant
   placeholder?: string
   ctaLabel?: string
   helperText?: string
+  source: 'hero' | 'final_cta' | 'pricing' | 'footer'
+  purposeCopy: PurposeSelectorProps['copy']
+  consentCopy: ConsentDialogProps['copy']
 }) {
```

### 7.3 state 추가 (26-30번 줄 useState 블록)

```diff
   const [email, setEmail] = useState('')
   const [gotcha, setGotcha] = useState('')
+  const [purpose, setPurpose] = useState<Purpose | null>(null)
+  const [purposeError, setPurposeError] = useState(false)
+  const [showConsentDialog, setShowConsentDialog] = useState(false)
   const [status, setStatus] = useState<'idle' | 'submitting' | 'success' | 'error'>('idle')
   const [errorReason, setErrorReason] = useState<SubmitReason>('invalid')
   const [shake, setShake] = useState(false)
+  // 옵트인 결과 (성공 메시지 분기용)
+  const [consentMarketing, setConsentMarketing] = useState(false)
```

### 7.4 handleSubmit 분리 (34-61번 줄 → 2단계 흐름)

```tsx
async function handleFormSubmit(e: FormEvent) {
  e.preventDefault()
  // 1차 검증
  if (!email.includes('@') || !email.includes('.')) {
    setErrorReason('invalid')
    setStatus('error')
    setShake(true)
    setTimeout(() => setShake(false), 400)
    return
  }
  if (!purpose) {
    setPurposeError(true)
    setShake(true)
    setTimeout(() => setShake(false), 400)
    return
  }
  // 2단계: ConsentDialog 띄우기
  track('form_submit_try', { source, purpose, has_email: true })
  track('consent_view', { consent_version: env.VITE_CONSENT_VERSION })
  setShowConsentDialog(true)
}

async function handleConsentConfirm(optin: boolean) {
  setShowConsentDialog(false)
  setConsentMarketing(optin)
  setStatus('submitting')

  const result = await submitEmail({
    email,
    source,
    purpose: purpose!,
    consentMarketing: optin,
    consentAt: optin ? new Date().toISOString() : null,
    consentVersion: env.VITE_CONSENT_VERSION,
    _gotcha: gotcha,
  })

  if (result.ok) {
    setStatus('success')
    track('form_submit_success', {
      source,
      purpose: purpose!,
      consent_marketing: optin,
    })
    return
  }

  setErrorReason(result.reason)
  setStatus('error')
  track('form_submit_error', { source, reason: result.reason })
  setShake(true)
  setTimeout(() => setShake(false), 400)
}

function handleConsentCancel() {
  setShowConsentDialog(false)
  track('consent_dismiss', { source })
  // 폼 유지 — 사용자가 재제출 가능 (10 §1.5)
}
```

### 7.5 success 메시지 분기 (63-70번 줄)

```diff
   if (status === 'success') {
     return (
-      <div className={cn('flex items-center gap-2', isCaption ? 'text-caption' : 'text-body')}>
-        <Check size={isCaption ? 16 : 20} strokeWidth={2} className="text-success" />
-        <span className="text-text-secondary">합류해주셔서 감사해요. 진행 소식을 보내드릴게요.</span>
+      <div className={cn('flex items-start gap-2', isCaption ? 'text-caption' : 'text-body')}>
+        <Check
+          size={isCaption ? 16 : 20}
+          strokeWidth={2}
+          className="mt-0.5 shrink-0 text-success"
+        />
+        <span className="text-text-secondary">
+          {consentMarketing ? consentCopy.successOptin : consentCopy.successReject}
+        </span>
       </div>
     )
   }
```

> *주의*: `consentCopy`에 `successOptin`·`successReject` 슬롯 2개 추가 — `ConsentDialogProps['copy']` 정의 확장 또는 `EmailForm` props에 별도 객체. 권장: 별도 `successCopy` prop으로 분리 (다이얼로그 외 카피이므로).

### 7.6 PurposeSelector 삽입 위치 (form 내부, 이메일 input 위)

```tsx
<form onSubmit={handleFormSubmit} ...>
  {/* honeypot — 기존 그대로 */}
  <input ... name="_gotcha" ... />

  {/* 신규: 목적 선택 */}
  <PurposeSelector
    variant={
      variant === 'caption' ? 'dropdown'
      : variant === 'inline' ? 'segmented'
      : 'cards' // stacked
    }
    value={purpose}
    onChange={(p) => {
      setPurpose(p)
      setPurposeError(false)
      track('purpose_select', { source, purpose: p })
    }}
    copy={purposeCopy}
    hasError={purposeError}
    className="mb-3"
  />

  {/* 기존: 이메일 input + 버튼 */}
  <div className={...}>
    {/* ... */}
  </div>

  {/* helperText, error message — 기존 그대로 */}
</form>

{/* form 바깥, portal 권장: */}
<ConsentDialog
  isOpen={showConsentDialog}
  onCancel={handleConsentCancel}
  onConfirm={handleConsentConfirm}
  copy={consentCopy}
  consentVersion={env.VITE_CONSENT_VERSION}
/>
```

### 7.7 email input onFocus 추적 추가 (122번 줄 `onChange` 옆)

```diff
       <input
         type="email"
         ...
         value={email}
+        onFocus={() => track('email_focus', { source })}
         onChange={(e) => {
           setEmail(e.target.value)
           if (status === 'error') setStatus('idle')
         }}
+        data-ph-no-capture="true"
```

`data-ph-no-capture` = `09_analytics_plan.md` §5.4 PII 차단.

---

## 8. FinalCTA·Hero·Pricing·Footer 변경 가이드 (추가 source prop)

`FinalCTA.tsx` (47-52번 줄):

```diff
       <EmailForm
         variant="inline"
         ctaLabel="베타에 합류하기"
         placeholder="이메일 주소"
         helperText="개인정보는 진행 소식 외에는 사용하지 않아요."
+        source="final_cta"
+        purposeCopy={purposeCopyDefault} // 또는 props로 주입
+        consentCopy={consentCopyDefault}
       />
```

`Hero.tsx`, `Pricing.tsx` (현재 EmailForm 미포함이면 무관), `Footer.tsx` 동일 패턴. **권장**: `landing/src/data/copy/purpose.ts` + `landing/src/data/copy/consent.ts` 단일 소스로 관리. storyteller(15 라운드)가 그 파일에 카피 채움.

---

## 9. 자체 검증

| 검증 항목 | 결과 |
|----------|------|
| `02_visual_ux.md` 디자인 토큰 재사용 | ✓ 신규 색·반경·폰트·spacing 토큰 0건. CSS 변수 그대로 |
| 신규 모션 토큰 | ✓ 0개. 기존 `formFocus`·`ctaPress`·`hoverLift` + reveal easing 재조합 |
| focus trap 구현 가능 | ✓ `inert` attribute (95%+ 브라우저) + 수동 focus 관리. 폴리필 0 |
| 4 디바이스 5초 룰 | ✓ iPhone SE (360 폭) 검증 — 3 탭 시퀀스 통과 |
| reduced-motion 대응 | ✓ 기존 전역 처리에 `[data-consent-dialog]` selector 추가만 |
| WCAG AA 색 대비 | ✓ 기존 표(02 §2.2) 모든 토큰 통과 |
| `13_data_v2_consolidated.md` 합의 5 정합성 | ✓ enum 3값 / 거절 분기 / consent_version 표시 / hash 호출 시점(옵트인 직후) 모두 반영 |
| 옵션 G 톤 — 의료 약속·과장 0건 | ✓ 카피 자체는 storyteller 입력이지만 placeholder 디폴트 모두 정직 톤 |

---

## 10. storyteller(15 라운드)에게 넘길 카피 슬롯 — 합본

| 키 | 한도 | 디폴트 (10 §3 또는 placeholder) | 노트 |
|----|------|--------------------------------|------|
| `purpose.legend` | ≤16자 | "어떤 목적으로 시작하시나요?" | 의문문 |
| `purpose.diet.label` | ≤12자 | "체중·식습관 관리" | enum `diet` |
| `purpose.diet.helper` | ≤22자 | "체중을 천천히 조절하고 싶어요" | 1인칭 |
| `purpose.diet.shortLabel` | ≤8자 | "체중·식습관" | segmented variant 용 |
| `purpose.digestion.label` | ≤12자 | "소화 문제 개선" | enum `digestion` |
| `purpose.digestion.helper` | ≤22자 | "속쓰림·역류·위염 같은 위장 부담" | 의료 약속 X |
| `purpose.digestion.shortLabel` | ≤8자 | "소화 문제" | |
| `purpose.other.label` | ≤12자 | "기타 / 둘 다" | enum `other` |
| `purpose.other.helper` | ≤22자 | "마음챙김 식사 등 그 외" | |
| `purpose.other.shortLabel` | ≤8자 | "그 외" | |
| `purpose.error` | ≤24자 | "목적을 하나 선택해주세요" | hasError 시 |
| `consent.head` | ≤15자 (모바일 한 줄) | "출시되면 이메일로 알려드릴게요" | 10 §3.1 |
| `consent.body` | 3문장, 각 ≤30자 | 10 §3.2 그대로 | |
| `consent.checkboxLabel` | ≤16자 | "출시 소식 받기 (선택)" | "(선택)" 명시 — 다크 패턴 회피 |
| `consent.rejectHint` | ≤30자, 옵션 | "출시 소식은 보내지 않아요. 신청은 그대로 처리돼요." | 거절 분기 시 표시 |
| `consent.privacyLinkLabel` | ≤12자 | "개인정보 처리방침" | |
| `consent.unsubscribeLinkLabel` | ≤12자 | "수신거부 안내" | |
| `consent.cancelLabel` | ≤6자 | "취소" | |
| `consent.confirmLabel` | ≤10자 | "확인하고 신청" | 10 §3.5 |
| `success.optin` | ≤45자 | "합류해주셔서 감사해요. 출시 소식이 준비되면 가장 먼저 보내드릴게요." | 10 §3.6 |
| `success.reject` | ≤45자 | "신청을 받았어요. 진행 소식은 보내지 않지만, 출시되면 사이트에서 만나요." | 거절자에게도 친근 톤 |

`landing/src/data/copy/purpose.ts` + `consent.ts` 2 파일에 *상수* export — storyteller가 본 라운드 후 이 2 파일만 수정해도 됨.

---

## 끝.
