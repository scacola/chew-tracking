---
name: landing-analytics-instrumentation
description: 정적/SPA 랜딩 페이지에 PostHog(또는 동등 도구)를 통합하여 *제품 분석(product analytics)*을 운영하는 방법론. 이벤트 taxonomy 표준·세그멘테이션 property 설계·식별/익명 정책·마케팅 컨센트 트래킹·autocapture·session_replay·봇 필터·PII 차단·funnel 정의까지. "PostHog 붙여줘", "사용자 분석", "이벤트 트래킹", "funnel 만들어줘", "다이어트/위염 분포 보고 싶다", "어떤 사람들이 가입하는지", "전환율 측정", "세그멘테이션", "마케팅 옵트인 트래킹", "옵트인 동의" 같은 요청에서 반드시 사용. 후속: "이벤트 추가", "funnel 추가", "대시보드 만들어줘", "purpose 분포 보여줘", "컨센트 추가" 같은 표현에서도 트리거.
---

# Landing Analytics Instrumentation — PostHog 통합 표준

랜딩 페이지에 *측정 시스템*을 통합하기 위한 이벤트 taxonomy·SDK 통합·식별·컨센트·대시보드 가이드.

이 스킬의 단일 사용 도구는 **PostHog**다 — Vercel Analytics·Mixpanel·Amplitude로의 일반화 패턴은 references/에 분리. 본문은 PostHog 기준.

## 핵심 원칙 (왜 이 룰이 있는가)

### 1. "측정 가능한 질문"으로 번역되지 않는 KPI는 KPI가 아니다

"어떤 사람들이 우리 서비스에 관심 갖는지 알고 싶다"는 *질문*이지 KPI가 아니다. 답할 수 있는 형태로 번역:

| 비즈니스 질문 | 측정 형태 |
|--------------|----------|
| 어떤 *목적*으로 가입하는가 | `email_submit_success` 이벤트의 `purpose` property breakdown |
| 어떤 *페르소나*가 더 전환되는가 | `purpose` × `email_submit_success` cohort 비교 |
| 어디서 들어와서 *어디서 떨어지는가* | page_view → cta_click → email_focus → email_submit_success funnel |
| 마케팅 옵트인 *동의률*은? | `email_submit_success`의 `consent_marketing=true` 비율 |
| 가입 *시간 분포*는? | timestamp histogram by hour/day-of-week |

이 매핑을 *먼저* 그린 뒤 SDK를 붙여라. 거꾸로 가면 "데이터는 쌓이는데 답을 못 함" 함정에 빠진다.

### 2. PostHog와 영구 백엔드의 역할은 다르다

PostHog는 **이벤트 ledger** — 행동·시간·세션·funnel 분석용. 데이터 보존은 정책 기반(기본 7년 plan-dependent), PII는 위험.

영구 백엔드(Supabase 등)는 **컨택 source of truth** — 이메일·동의·삭제 요청 처리용. 마케팅 발송·CRM·법적 의무.

| 데이터 | PostHog | Supabase |
|--------|---------|----------|
| 이메일 본문 | ❌ | ✅ |
| distinctId (hash) | ✅ | ✅ (연결용) |
| `purpose` 선택값 | ✅ (분석) | ✅ (영구) |
| `consent_marketing` boolean | ✅ (이벤트 시점) | ✅ (source of truth) |
| `consent_at`, `consent_version` | property로 OK | ✅ |
| 페이지뷰·세션·funnel | ✅ | ❌ |
| 사용자 클릭·hover | ✅ (autocapture) | ❌ |

**중복 저장 금지**. 한쪽이 source, 다른 쪽이 분석 보조. 사용자 데이터 삭제 요청은 *Supabase row 삭제* + PostHog `posthog.opt_out_capturing()` + 해당 distinctId의 `delete_person`.

### 3. PII는 PostHog에 들어가면 안 된다

`posthog.capture('email_submit_success', { email: 'foo@bar.com' })` — 이건 위반. GDPR·PIPA 위험 + PostHog 데이터 보존 정책과 충돌.

옳은 방법:
```typescript
// ✅ 이메일 자체는 보내지 않고, identify로 연결만
posthog.identify(hash(email), { /* 안전한 속성만 */ purpose, persona })
posthog.capture('email_submit_success', { purpose, source }) // 이메일 X
```

`hash()`는 SHA-256 + secret salt 권장. Supabase `users` 테이블에 `posthog_distinct_id` 컬럼을 두어 양방향 lookup 가능하게.

### 4. autocapture는 양날의 검 — PII input은 반드시 차단

PostHog의 autocapture는 *모든 클릭·input change*를 자동 수집한다. 좋은 점: 코드 변경 없이 UI 인터랙션 수집. 위험: `<input type="email">`의 값이 캡처될 수 있다.

차단 방법:
1. 전역: `mask_all_text: true` (모든 텍스트 마스킹) — 가장 안전, 라벨 가독성 손실
2. 선택: `<input data-ph-no-capture />` (해당 element만)
3. 추천: 전역은 끄지 말되, *모든 form input에* `data-ph-no-capture` 추가

### 5. Session Replay는 기본 OFF

세션 녹화는 강력하지만 PII 누출 위험이 크다. 본 프로젝트 베타 단계에서는 **OFF가 디폴트**. 켤 때:
- `maskAllInputs: true` 필수
- `recordCrossOriginIframes: false`
- 사용자 컨센트 다이얼로그에서 *명시적 옵트인* 받은 후만

### 6. 컨센트는 트래킹 자체에도 적용

GDPR/PIPA: "마케팅 동의"와 "분석 트래킹 동의"는 분리될 수 있다. 우리 정책:

| 사용자 상태 | 가능 | 불가 |
|-------------|------|------|
| 페이지 방문 (anonymous) | 익명 페이지뷰·CTA 클릭·funnel | 식별·session replay |
| 이메일 제출 + 마케팅 거절 | 익명 분석 + Supabase 저장 (소식 발송 X) | 식별 연결·마케팅 발송 |
| 이메일 제출 + 마케팅 옵트인 | 식별 연결 + 마케팅 발송 + 분석 | (없음) |

코드:
```typescript
if (!consentMarketing) {
  // 거절 시: 익명 행동만 추적, identify 안 함
  posthog.capture('email_submit_success', { consent_marketing: false, purpose })
  // posthog.identify(...) 호출 안 함
} else {
  posthog.identify(hash(email), { purpose })
  posthog.capture('email_submit_success', { consent_marketing: true, purpose })
}
```

### 7. 이벤트 이름은 한 번에 잘

이름 바꾸면 historical 데이터 분단. 컨벤션:
- `object_action` snake_case
- 동사는 과거형 X, 단순 명사형 O (`form_submit_success`, NOT `submitted_form`)
- `landing_view` (page_view보다 명확 — 어느 페이지인지 도메인 안에서)
- 동일 객체에 여러 동작이면 일관: `form_focus`, `form_submit_try`, `form_submit_success`, `form_submit_fail`

신규 이벤트 추가는 자유, 이름 변경은 주저. *정말로* 잘못 지었으면 deprecate + 신규 이벤트 + alias 패턴.

---

## 이벤트 Taxonomy 표준 (랜딩 페이지)

본 프로젝트의 표준 이벤트 카탈로그. 신규 추가 시 이 표를 먼저 갱신.

### 발견 단계
| 이벤트 | 발화 위치 | 필수 property | 선택 property |
|-------|----------|--------------|--------------|
| `landing_view` | App mount + route 변경 | `path`, `referrer` | `utm_*`, `persona` (URL `?p=` 라우팅 시) |
| `section_view` | IntersectionObserver 50% | `section_id` (`hero`, `problem`, `pricing`, etc.) | `scroll_depth_pct` |

### 의도 표현 단계
| 이벤트 | 발화 위치 | 필수 property | 선택 property |
|-------|----------|--------------|--------------|
| `cta_click` | 모든 주요 CTA 클릭 | `cta_id` (`hero_primary`, `final_cta`, `footer_cta`), `target` (`scroll`/`form`/`external`) | `section_id` |
| `faq_open` | FAQ 항목 펼침 | `faq_id` | - |
| `pricing_view` | Pricing 섹션 진입 | - | `tier_focus` (어떤 카드에 hover) |

### 폼 깔때기 단계
| 이벤트 | 발화 위치 | 필수 property | 선택 property |
|-------|----------|--------------|--------------|
| `email_focus` | EmailForm input focus 첫 회 | `source` (`hero`, `final_cta`, `footer`) | - |
| `purpose_select` | 목적 라디오/세그먼트 선택 | `purpose` (`diet`/`digestion`/`other`) | `source` |
| `consent_view` | 컨센트 다이얼로그 표시 | `consent_version` | - |
| `form_submit_try` | submit 직후 (검증 통과) | `source`, `purpose` | - |
| `form_submit_success` | 200 응답 + Supabase 저장 성공 | `source`, `purpose`, `consent_marketing` (boolean) | - |
| `form_submit_fail` | 4xx/5xx/network | `source`, `error_reason` (`invalid`/`rate-limit`/`network`/`config`/`duplicate`) | - |

### 식별 (이메일 제출 + 옵트인 시)
- `posthog.identify(distinctId, { purpose, persona, consent_marketing: true, consent_at })`
- distinctId = `sha256(email + SALT)` (Supabase의 `posthog_distinct_id`와 동일)

---

## 세그멘테이션 Property 표준

이름·값을 표준화 — 다른 곳에서 다른 이름으로 보내면 분석 시 합치기 어렵다.

| Property | 타입 | 값 범위 | 어디서 발화 |
|----------|------|--------|-----------|
| `purpose` | enum | `diet` / `digestion` / `other` | EmailForm 제출 시 |
| `persona` | enum | `office_worker` / `student` / `senior` / `unknown` | URL `?p=` 라우팅 또는 unknown |
| `source` | enum | `hero` / `final_cta` / `footer` / `pricing_card_*` | EmailForm variant |
| `consent_marketing` | boolean | `true` / `false` | 컨센트 다이얼로그 옵트인 |
| `consent_version` | string | `'2026-05-04'` 같은 ISO date | 옵트인 시점의 약관 버전 |
| `device_type` | enum | `mobile` / `tablet` / `desktop` | autocapture |
| `cta_id` | string | `hero_primary` / `final_cta_main` 등 표준 ID | CTA 클릭 |

### `purpose` enum의 의미

본 프로젝트 핵심 차원. 디스커버리에서 *옵션 G*가 다이어트와 위염·소화불량 양쪽을 다룬다는 점을 측정 가능하게:

| 값 | 의미 | UI 라벨 (예시) |
|----|------|--------------|
| `diet` | 체중 관리·식사 속도 줄이기 목적 | "체중·식습관 관리" |
| `digestion` | 소화불량·위염·역류 등 위장 문제 개선 | "소화 문제 개선" |
| `other` | 그 외 (마음챙김 식사, 단순 호기심) | "기타 / 둘 다" |

UI 카피는 `marketing-storyteller`와 합의. 라벨 표기는 바뀔 수 있으나 *enum 값(`diet`, `digestion`, `other`)은 고정* — historical 비교 가능성.

---

## 구현 패턴

### 1) Provider 셋업 — `lib/posthog.ts` + Provider 컴포넌트

```typescript
// landing/src/lib/posthogClient.ts
import posthog from 'posthog-js'

let inited = false

export function initPostHog() {
  if (typeof window === 'undefined') return
  if (inited) return
  const key = import.meta.env.VITE_POSTHOG_KEY as string | undefined
  const host = import.meta.env.VITE_POSTHOG_HOST as string | undefined
  if (!key || !host) {
    if (import.meta.env.DEV) {
      console.warn('[posthog] keys missing — analytics disabled')
    }
    return
  }
  posthog.init(key, {
    api_host: host,
    capture_pageview: false,        // 직접 발화 (SPA 라우팅 누락 방지)
    capture_pageleave: true,         // 이탈은 자동
    autocapture: { dom_event_allowlist: ['click'] },  // input 캡처 제외
    persistence: 'localStorage+cookie',
    respect_dnt: true,
    mask_all_text: false,            // 라벨 가독성 — 단 input은 data-ph-no-capture
    session_recording: { maskAllInputs: true }, // 켤 때 안전
    disable_session_recording: true, // 베타 단계 OFF
    loaded: (ph) => {
      if (import.meta.env.DEV) ph.debug()
    },
  })
  inited = true
}

export { posthog }
```

```typescript
// landing/src/main.tsx (또는 App 진입점)
import { initPostHog } from './lib/posthogClient'
initPostHog()
```

### 2) `track()` 단일 진입점 — 유니온 타입으로 오타 방지

```typescript
// landing/src/lib/analytics.ts
import { posthog } from './posthogClient'

export type AnalyticsEvent =
  | 'landing_view'
  | 'section_view'
  | 'cta_click'
  | 'faq_open'
  | 'pricing_view'
  | 'email_focus'
  | 'purpose_select'
  | 'consent_view'
  | 'form_submit_try'
  | 'form_submit_success'
  | 'form_submit_fail'

export type Purpose = 'diet' | 'digestion' | 'other'
export type Source = 'hero' | 'final_cta' | 'footer' | string

export interface BaseProps {
  source?: Source
  purpose?: Purpose
  consent_marketing?: boolean
  // 그 외 자유 — but 새 차원은 표준에 등록 후 사용
  [k: string]: unknown
}

export function track(event: AnalyticsEvent, props: BaseProps = {}): void {
  if (typeof window === 'undefined') return
  posthog.capture(event, props)
}

export function identify(
  distinctId: string,
  traits: { purpose?: Purpose; consent_marketing?: boolean; consent_at?: string },
): void {
  if (typeof window === 'undefined') return
  posthog.identify(distinctId, traits)
}
```

### 3) hash distinctId — PII 회피

```typescript
// landing/src/lib/hashId.ts
export async function hashEmail(email: string, salt: string): Promise<string> {
  const data = new TextEncoder().encode(email.trim().toLowerCase() + salt)
  const buf = await crypto.subtle.digest('SHA-256', data)
  return Array.from(new Uint8Array(buf))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('')
}
```

`SALT`는 빌드 시 `import.meta.env.VITE_HASH_SALT`로 주입. 노출돼도 무방 (rainbow table 회피용 일반 salt — 진짜 보안은 Supabase RLS).

### 4) 발화 지점 통합

#### `landing_view` — App 진입
```typescript
// App.tsx
useEffect(() => {
  track('landing_view', {
    path: window.location.pathname,
    referrer: document.referrer || undefined,
  })
}, [])
```

#### `section_view` — IntersectionObserver
```typescript
// hooks/useSectionView.ts (간단 패턴)
const ref = useRef<HTMLElement>(null)
useEffect(() => {
  if (!ref.current) return
  const obs = new IntersectionObserver(
    ([entry]) => {
      if (entry.isIntersecting) {
        track('section_view', { section_id: id })
        obs.disconnect()
      }
    },
    { threshold: 0.5 },
  )
  obs.observe(ref.current)
  return () => obs.disconnect()
}, [id])
```

#### `cta_click`
```tsx
<button onClick={() => track('cta_click', { cta_id: 'hero_primary', section_id: 'hero', target: 'scroll' })}>
  지금 시작하기
</button>
```

#### `email_focus` + 폼 깔때기 (EmailForm.tsx 통합)
```tsx
<input
  type="email"
  data-ph-no-capture  // PII 자동수집 차단
  onFocus={() => {
    if (!focusFiredOnce.current) {
      track('email_focus', { source: variant })
      focusFiredOnce.current = true
    }
  }}
  ...
/>
```

#### 제출 흐름 (success/fail 분기)
```typescript
async function handleSubmit() {
  track('form_submit_try', { source: variant, purpose })
  const result = await submitToSupabase({ email, purpose, consent_marketing })

  if (!result.ok) {
    track('form_submit_fail', { source: variant, purpose, error_reason: result.reason })
    return
  }

  if (consent_marketing) {
    const distinctId = await hashEmail(email, SALT)
    identify(distinctId, { purpose, consent_marketing: true, consent_at: new Date().toISOString() })
  }
  track('form_submit_success', { source: variant, purpose, consent_marketing })
}
```

---

## 컨센트 다이얼로그 흐름

폼 제출 직전(또는 직후) 다음 흐름:

```
[폼 입력]
   ↓
[제출 버튼 클릭]
   ↓
[컨센트 다이얼로그 표시] ← track('consent_view', { consent_version })
   ├─ "출시되면 이메일로 알려드릴게요" 체크박스 (기본: 체크됨)
   ├─ 약관·개인정보 처리 안내 링크
   └─ [확인] [취소]
   ↓
사용자 [확인] 클릭
   ↓
[Supabase에 저장] (email + purpose + consent_marketing + consent_at + consent_version)
   ↓
[성공 메시지 표시] ← track('form_submit_success', { ..., consent_marketing })
   ↓ (consent_marketing=true 시만)
[posthog.identify(hash(email), { purpose, ... })]
```

다이얼로그 카피 디폴트 (옵션 G 톤):
- 헤드: "출시되면 이메일로 알려드릴게요"
- 본문: "베타가 준비되면 가장 먼저 소식을 보내드립니다. 진행 외 광고는 보내지 않고, 언제든 [수신거부]로 그만두실 수 있어요."
- 체크박스: "출시 소식 받기 (선택)"
- 거절도 OK — 거절해도 신청은 처리되며 익명으로만 저장.

`marketing-storyteller`에게 라벨/카피 검토 요청.

---

## 대시보드 청사진 (PostHog Insights)

배포 후 *바로* 만들어둘 4개 대시보드:

### 1. Funnel — Conversion
- 단계: `landing_view` → `cta_click` → `email_focus` → `form_submit_try` → `form_submit_success`
- Breakdown: `purpose`, `source`, `device_type`
- 윈도우: 30분
- KPI: 최종 단계 도달률 (베이스라인 측정 후 목표 설정)

### 2. Breakdown — Purpose 분포
- 이벤트: `form_submit_success`
- Breakdown: `purpose`
- 차트: pie 또는 stacked bar over time
- KPI: `diet` vs `digestion` vs `other` 비율 — 어느 메시지가 더 통하는지

### 3. Breakdown — 페르소나 × 전환률
- 이벤트: `form_submit_success`
- Breakdown: `persona` (URL 라우팅 데이터)
- 차트: ratio (success / landing_view by persona)
- KPI: 가장 전환되는 페르소나 → 마케팅 채널 우선순위

### 4. Cohort — 옵트인률
- 이벤트: `form_submit_success`
- Breakdown: `consent_marketing` (true/false)
- KPI: 옵트인률 — 컨센트 카피 A/B 테스트 baseline

---

## 봇·내부 트래픽 필터

PostHog Project settings에서:
- **Internal IPs**: 사용자 사무실 IP, VPN IP 추가
- **Discard ingested events**: bot UA 필터 (정규식)
- **Test accounts filtering**: distinctId가 `internal_*`로 시작하면 제외

코드에서:
```typescript
// botUA 간단 필터 — 더 엄격한 건 PostHog 측에서
const botUA = /(bot|crawler|spider|headless)/i.test(navigator.userAgent)
if (!botUA) initPostHog()
```

---

## 보안·운영 체크리스트

배포 전 (각 항목 통과 시 ☑):

- [ ] PostHog public key (`phc_*`)만 클라이언트에 — secret key 절대 X
- [ ] `respect_dnt: true`
- [ ] `disable_session_recording: true` (베타 단계)
- [ ] 모든 form input에 `data-ph-no-capture` 또는 `mask_all_text` 적용
- [ ] PII (이메일·이름)을 event property로 보내지 않음 (grep으로 확인)
- [ ] distinctId는 hash(email + salt) — 이메일 그대로 사용 X
- [ ] `capture_pageview: false` + 직접 `landing_view` 발화 (SPA 라우팅 안전)
- [ ] 이벤트 이름이 표준 taxonomy 표와 일치 (오타 없음 — 유니온 타입으로 강제)
- [ ] 컨센트 거절 시 `posthog.identify` 미호출 + `consent_marketing: false` 함께 보냄
- [ ] PostHog Activity 탭에서 종단간 1건 도달 확인 (스크린샷)
- [ ] funnel 1개가 PostHog Insights에 정의되고 1건 통과
- [ ] purpose breakdown — 세 값 모두 발화 가능 (UI에서 클릭 후 PostHog에서 확인)
- [ ] 옵션 G 톤 — 컨센트 카피·이벤트 이름·success 메시지 위반 0건

---

## 최종 산출물 체크리스트

이 스킬 사용 종료 시 다음이 *모두* 존재해야 한다:

- [ ] `_workspace/landing/09_analytics_plan.md` — 측정 질문 매핑·이벤트 카탈로그·세그멘테이션 표준
- [ ] `_workspace/landing/10_consent_strategy.md` — 컨센트 흐름·카피·법적 호환
- [ ] `_workspace/landing/11_analytics_dashboard.md` — funnel·breakdown·cohort 정의
- [ ] `landing/src/lib/posthogClient.ts` (또는 동등) — SDK init
- [ ] `landing/src/lib/analytics.ts` — `track()` 유니온 타입 진입점
- [ ] `landing/src/lib/hashId.ts` — distinctId hash
- [ ] `landing/src/components/EmailForm.tsx` — purpose 선택 UI + 컨센트 흐름 + track 호출
- [ ] `landing/src/components/ConsentDialog.tsx` (신규) — 컨센트 다이얼로그
- [ ] 그 외 CTA 발화 지점 (Hero·FinalCTA·Pricing) `track('cta_click', ...)` 추가
- [ ] `landing/.env.example` — `VITE_POSTHOG_KEY`, `VITE_POSTHOG_HOST`, `VITE_HASH_SALT`
- [ ] PostHog 인스턴스에 funnel·breakdown·cohort 4개 정의 (또는 정의 가이드)
- [ ] 종단간 테스트 스크린샷 (PostHog Activity 탭에서 이벤트 도달 확인)
