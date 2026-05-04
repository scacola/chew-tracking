# 09 — Analytics Plan (PostHog v2)

작성: `landing-analytics-engineer` 에이전트
작성일: 2026-05-04
대상 라운드: Phase 5-B 분석/데이터 v2 인프라
관련: `_workspace/landing/07_data_collection_options.md` (Web3Forms → Supabase 마이그레이션 동시 진행), `landing-data-collector`의 Supabase 스키마 산출물

## 본 라운드 컨텍스트

옵션 G "Chew & Calm Coach" 랜딩 페이지에 PostHog 기반 *제품 분석*을 도입한다. 사용자 비즈니스 질문은 (a) "다이어트 / 위염·소화불량 / 기타 중 어느 목적이 더 많이 신청하는가" (b) "출시되면 다시 연락드린다는 *마케팅 옵트인 동의*를 받아야 한다" 두 가지. PostHog는 *행동·전환 분석*, Supabase는 *컨택 source of truth* — 두 시스템은 distinctId hash로만 연결한다.

## ToC
1. 측정 질문 → 답할 형태 매핑
2. 이벤트 카탈로그
3. 세그멘테이션 property 표준
4. 식별 정책 (anonymous → identify)
5. PostHog ↔ Supabase 데이터 분리
6. autocapture 정책
7. 봇·내부 트래픽 필터
8. 환경변수 명세
9. PostHog 호스팅 결정
10. 합의 포인트 (collector와)

---

## 1. 측정 질문 → 답할 형태 매핑

비즈니스 질문이 *집계 가능한 형태*로 번역되지 않으면 KPI가 아니다. 본 라운드의 모든 측정 질문은 다음 표의 어느 한 항목으로 답할 수 있어야 한다.

| # | 비즈니스 질문 | 측정 형태 | PostHog 기준 |
|---|--------------|----------|------------|
| Q1 | 신청자가 다이어트 / 위염·소화불량 / 기타 중 어느 목적인가? | `form_submit_success` × `purpose` breakdown | Insight: stacked bar over time |
| Q2 | 페르소나 (URL `?p=` 라우팅)별 전환률은? | `form_submit_success` ÷ `landing_view` by `persona` | Insight: ratio breakdown |
| Q3 | 어디서 들어와서 어디서 떨어지는가? | `landing_view` → `cta_click` → `email_focus` → `form_submit_try` → `form_submit_success` | Insight: funnel (30분 윈도우) |
| Q4 | 마케팅 옵트인 동의률은? | `form_submit_success`의 `consent_marketing=true` 비율 | Insight: cohort + ratio |
| Q5 | 신청 시간 분포는? (영상 시청 후 vs 출근길 vs 점심 후) | `form_submit_success` timestamp histogram by hour-of-day, day-of-week | Insight: trends with breakdown |
| Q6 | 어느 *섹션*까지 스크롤하는가? | `section_view` × `section_id` | Insight: trends |
| Q7 | 어느 *CTA*가 가장 많이 눌리는가? | `cta_click` × `cta_id` | Insight: trends breakdown |
| Q8 | 폼 깔때기에서 어디서 가장 많이 떨어지는가? | `email_focus` → `form_submit_try` → `form_submit_success` 단계별 drop | Funnel 후반부 |

이 8개 질문이 본 라운드의 *측정 가능 KPI 후보*다. 베이스라인 측정 후 목표 수치 설정.

---

## 2. 이벤트 카탈로그

이벤트 이름은 `object_action` snake_case 컨벤션 (`landing-analytics-instrumentation` 스킬 표준 카탈로그 준수). 이름은 한 번 정하면 바꾸기 어렵다.

### 발견 단계

| 이벤트 | 발화 위치 | 필수 property | 선택 property | 페이로드 예시 |
|-------|----------|--------------|--------------|----|
| `landing_view` | `App.tsx` mount + `useEffect` 1회 | `path` | `referrer`, `utm_source`, `utm_medium`, `utm_campaign`, `persona` | `{ "path": "/", "referrer": "https://t.co/...", "persona": "stomach" }` |
| `section_view` | 각 `<section>` IntersectionObserver 50% 임계 (1회만) | `section_id` (`hero` / `problem` / `solution` / `airpods_demo` / `how_it_works` / `differentiation` / `authority` / `pricing` / `faq` / `final_cta`) | `scroll_depth_pct` | `{ "section_id": "pricing", "scroll_depth_pct": 72 }` |

### 의도 표현 단계

| 이벤트 | 발화 위치 | 필수 property | 선택 property | 페이로드 예시 |
|-------|----------|--------------|--------------|----|
| `cta_click` | 모든 주요 CTA `onClick` | `cta_id` (표준 ID 표 §3 참조), `target` (`scroll` / `form` / `external`) | `section_id`, `persona` | `{ "cta_id": "hero_primary", "target": "scroll", "section_id": "hero" }` |
| `faq_open` | FAQ `<details>` open 또는 클릭 | `faq_id` (`q1` / `q2` ... 또는 슬러그) | - | `{ "faq_id": "q3_safety" }` |
| `pricing_view` | Pricing 섹션 진입 (별도 이벤트 — `section_view`보다 strict) | - | `tier_focus` (hover된 카드 — `monthly` / `yearly` / `single`) | `{ "tier_focus": "yearly" }` |

### 폼 깔때기 단계

| 이벤트 | 발화 위치 | 필수 property | 선택 property | 페이로드 예시 |
|-------|----------|--------------|--------------|----|
| `email_focus` | `EmailForm` `<input type="email">` 첫 focus (1회만 — `useRef` flag) | `source` (`hero` / `final_cta` / `footer` / `pricing_card_*`) | - | `{ "source": "final_cta" }` |
| `purpose_select` | 목적 라디오/세그먼트 컨트롤 변경 시 | `purpose` (`diet` / `digestion` / `other`), `source` | - | `{ "purpose": "digestion", "source": "final_cta" }` |
| `consent_view` | `ConsentDialog` 표시 첫 1회 | `consent_version` (ISO date string, 예: `'2026-05-04'`) | `source` | `{ "consent_version": "2026-05-04", "source": "final_cta" }` |
| `form_submit_try` | submit 버튼 클릭 + 클라이언트 검증 통과 직후 (네트워크 호출 *전*) | `source`, `purpose` | - | `{ "source": "final_cta", "purpose": "digestion" }` |
| `form_submit_success` | Supabase 200 응답 + (옵트인 시) PostHog identify 후 | `source`, `purpose`, `consent_marketing` (boolean) | `consent_version` | `{ "source": "final_cta", "purpose": "digestion", "consent_marketing": true, "consent_version": "2026-05-04" }` |
| `form_submit_fail` | 4xx / 5xx / network error / duplicate (Supabase unique constraint 위반) | `source`, `error_reason` (`invalid` / `rate-limit` / `network` / `config` / `duplicate`) | `purpose` | `{ "source": "final_cta", "error_reason": "duplicate" }` |

**주의 — PII 절대 금지**: 위 이벤트 어디에도 `email`, `name`, `phone` property가 들어가서는 안 된다. 코드 리뷰 시 grep으로 확인 (§ 검증 체크리스트).

---

## 3. 세그멘테이션 property 표준

### 3.1 표준 property 표

| Property | 타입 | 값 범위 | 어디서 발화 | 비고 |
|----------|------|--------|-----------|----|
| `purpose` | enum | `diet` / `digestion` / `other` | `form_submit_*` + `purpose_select` + identify trait | 본 프로젝트 핵심 차원 |
| `persona` | enum | `stomach` / `diet` / `checkup` / `unknown` | URL `?p=` 라우팅 또는 unknown | `landing/src/data/personas.ts`의 `PersonaKey`와 *완전 일치* |
| `source` | enum | `hero` / `final_cta` / `footer` / `pricing_card_monthly` / `pricing_card_yearly` / `pricing_card_single` | EmailForm variant + CTA 위치 | `EmailForm` 컴포넌트의 `variant` prop과 매핑 — 단 의미는 "어디서 폼이 노출되었나" |
| `cta_id` | string | `hero_primary` / `hero_secondary` / `final_cta_main` / `pricing_monthly_cta` / `pricing_yearly_cta` / `pricing_single_cta` / `footer_cta` | 모든 CTA 클릭 | 표준 ID 고정 (§3.2 표) |
| `target` | enum | `scroll` / `form` / `external` | CTA 클릭 | "이 클릭의 의도" — 스크롤 이동 / 폼으로 이동 / 외부 링크 |
| `consent_marketing` | boolean | `true` / `false` | `form_submit_success` + identify trait | 옵트인 거절 시 `false` |
| `consent_version` | string | `'2026-05-04'` (ISO date) | `consent_view` + `form_submit_success` + identify trait | 약관 변경 시 갱신 |
| `device_type` | enum | `mobile` / `tablet` / `desktop` | autocapture (PostHog 자동 부여) | UA-derived |
| `section_id` | string | `hero` / `problem` / `solution` / `airpods_demo` / `how_it_works` / `differentiation` / `authority` / `pricing` / `faq` / `final_cta` | `section_view`, `cta_click`(선택) | App.tsx의 `<section id>` 속성과 일치 |

### 3.2 `cta_id` 표준 ID 표

| `cta_id` | 위치 | 컴포넌트 | 의도 |
|---------|------|---------|------|
| `hero_primary` | Hero "베타에 합류하기" | `Hero.tsx` `CtaPrimary` | scroll → final_cta |
| `hero_secondary` | Hero "어떻게 작동하는지 보기" | `Hero.tsx` `CtaSecondary` | scroll → airpods_demo |
| `pricing_monthly_cta` | Pricing 월간 카드 "월간 시작하기" | `Pricing.tsx` | scroll → final_cta |
| `pricing_yearly_cta` | Pricing 연간 카드 "연간 합류하기" (recommended) | `Pricing.tsx` | scroll → final_cta |
| `pricing_single_cta` | Pricing 단품 "코스만 구매" | `Pricing.tsx` | scroll → final_cta |
| `final_cta_main` | FinalCTA EmailForm submit 버튼 | `FinalCTA.tsx` `EmailForm` | form |
| `final_cta_single_link` | FinalCTA "28일 코스 단품 19,900원" 링크 | `FinalCTA.tsx` | scroll → pricing |
| `footer_cta` | Footer EmailForm submit 버튼 | `Footer.tsx` `EmailForm` | form |
| `nav_pricing` / `nav_how` / `nav_faq` | StickyNav | `StickyNav.tsx` | scroll |

### 3.3 `purpose` enum 의미 (UI 카피 vs 분석 값 분리)

| 분석 값 (고정) | 의미 | UI 라벨 (변경 가능) |
|-------------|------|------------------|
| `diet` | 체중 관리·식사 속도 줄이기 | "체중·다이어트" |
| `digestion` | 소화불량·위염·역류 등 위장 문제 개선 | "소화 문제 개선" |
| `other` | 기타 (마음챙김 식사, 검진 결과, 단순 호기심 등) | "기타 / 둘 다" |

UI 라벨은 `marketing-storyteller`와 합의하여 변경 가능. **enum 값(`diet` / `digestion` / `other`)은 historical 비교를 위해 고정.**

### 3.4 `persona` enum — 코드와 일치 검증

`landing/src/data/personas.ts` 정의:

```typescript
export type PersonaKey = 'stomach' | 'diet' | 'checkup'
```

분석 표준 값:
- `stomach` — 위염 직장인 (한지원형, 디스커버리 1차)
- `diet` — 다이어트 정체기 (박소연형, 2차)
- `checkup` — 검진 결과 후 식사 속도 개선 권고 (김상훈형/대사증후군 경계, 3차)
- `unknown` — URL `?p=` 없이 접근

**중요**: `persona`는 *URL 라우팅에 의해 부여된 시각/메시지 컨텍스트*다. `purpose`는 *사용자가 폼에서 직접 선택한 목적*이다. 둘은 다른 차원이며 **상관관계 분석이 핵심 인사이트**다 (예: `persona=stomach`로 들어왔지만 `purpose=diet` 선택한 사용자 비율).

---

## 4. 식별 정책 (anonymous → identify)

### 4.1 원칙

- 페이지 방문 ~ 폼 제출 직전까지: **anonymous** (PostHog 자동 generated `distinct_id`)
- 옵트인 거절: **anonymous 유지** — `posthog.identify()` 호출 *안 함*. Supabase에는 `consent_marketing=false`로 row 저장 (이메일은 저장하되 마케팅 발송 X).
- 옵트인 동의: **`identify(distinctId, traits)` 호출** — 단 `distinctId`는 hash, traits는 PII 없는 항목만.

### 4.2 distinctId 생성

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

- 입력: `email.trim().toLowerCase() + VITE_HASH_SALT`
- 출력: 64자 hex SHA-256
- 같은 hash 값이 PostHog `distinct_id`와 Supabase `posthog_distinct_id` 컬럼에 들어간다 → **양 시스템 hash 정책 합의 (collector와 합의 포인트 #2)**.

### 4.3 identify trait 화이트리스트

`posthog.identify(distinctId, traits)`에서 traits에 보내는 것은 **PII가 아닌 분석 차원만**:

| trait | 값 | 사유 |
|-------|---|------|
| `purpose` | `diet` / `digestion` / `other` | 분석 차원 |
| `consent_marketing` | `true` (옵트인 시점) | identify는 옵트인 시만 호출되므로 항상 true |
| `consent_at` | ISO 8601 timestamp (예: `'2026-05-04T03:21:00.000Z'`) | 동의 시각 |
| `consent_version` | `'2026-05-04'` | 약관 버전 |
| `persona` (선택) | `stomach` / `diet` / `checkup` / `unknown` | URL 라우팅 컨텍스트 |

**금지 trait**: `email`, `name`, `phone`, IP, full UA, address, raw timestamp 외 식별 가능 정보. 이메일은 *Supabase에만*.

### 4.4 코드 흐름

```typescript
// EmailForm submit 핸들러 내부
async function onSubmit() {
  track('form_submit_try', { source, purpose })
  const result = await submitToSupabase({ email, purpose, consent_marketing })

  if (!result.ok) {
    track('form_submit_fail', { source, purpose, error_reason: result.reason })
    return
  }

  // 옵트인 시만 identify 호출
  if (consent_marketing) {
    const distinctId = await hashEmail(email, import.meta.env.VITE_HASH_SALT)
    identify(distinctId, {
      purpose,
      consent_marketing: true,
      consent_at: new Date().toISOString(),
      consent_version: CONSENT_VERSION,
      persona, // URL 라우팅에서 가져온 값
    })
  }

  track('form_submit_success', {
    source,
    purpose,
    consent_marketing,
    consent_version: CONSENT_VERSION,
  })
}
```

거절 분기에서도 `form_submit_success`는 발화한다 (성공한 신청은 성공) — 단 `consent_marketing: false` property로 구분.

---

## 5. PostHog ↔ Supabase 데이터 분리 표

| 데이터 | PostHog | Supabase | 사유 |
|--------|---------|----------|----|
| 이메일 본문 (`foo@bar.com`) | ❌ | ✅ | Supabase가 컨택 source of truth, PostHog는 PII 저장 X |
| `posthog_distinct_id` (= `sha256(email + SALT)`) | ✅ (자동) | ✅ (컬럼) | 양방향 lookup 가능 |
| `purpose` 선택값 | ✅ (event property + identify trait) | ✅ (`signups.purpose` 컬럼) | 분석 + 영구 저장 양쪽 필요 |
| `consent_marketing` boolean | ✅ (`form_submit_success` property) | ✅ (`signups.consent_marketing`) | 동의 시점 + source of truth |
| `consent_at`, `consent_version` | identify trait | ✅ (`signups.consent_at`, `consent_version`) | 법적 증빙은 Supabase |
| `source` (hero / final_cta / ...) | ✅ (event property) | ✅ (`signups.source`) | 어느 위치에서 신청했는지 |
| `persona` (URL 라우팅) | ✅ (event property + identify trait) | ✅ (`signups.persona` 컬럼 — 선택) | breakdown용 |
| 페이지뷰·세션·funnel 단계 | ✅ | ❌ | 이벤트 ledger는 PostHog 전담 |
| 클릭·hover·section_view | ✅ (autocapture + manual) | ❌ | 행동 분석 |
| 사용자 IP | PostHog 자동 (geo only, raw IP는 정책 따라) | ❌ (저장 안 함) | 최소 수집 원칙 |
| User-Agent | PostHog 자동 (parsed) | ❌ | autocapture |
| UTM 파라미터 | ✅ (`landing_view` property) | ❌ (선택 — 마케팅 ROI 추적 시) | 분석 영역 |
| 삭제 요청 처리 시 | `posthog.opt_out_capturing()` + `delete_person` API | row soft-delete (`deleted_at`) 또는 hard-delete | 두 시스템 모두 처리 필요 |

**중복 저장 금지 원칙**: 같은 row를 양쪽 시스템에 *동기화*하지 않는다. PostHog의 `purpose`는 *event 시점에 capture된 값*이고, Supabase의 `purpose`는 *영구 컨택 레코드*다. 둘은 같은 사용자의 같은 신청 시점이면 같아야 하지만 *하나가 source*임을 분명히 한다 — Supabase가 source.

---

## 6. autocapture 정책

PostHog autocapture는 모든 클릭·input change를 자동 수집한다. PII 입력이 자동 수집되면 안 된다.

### 6.1 init 옵션

```typescript
posthog.init(key, {
  api_host: host,
  capture_pageview: false,                          // 직접 발화 (SPA 라우팅 안전)
  capture_pageleave: true,                          // 이탈은 자동
  autocapture: { dom_event_allowlist: ['click'] },  // input/change 이벤트 캡처 제외 — PII 차단
  persistence: 'localStorage+cookie',
  respect_dnt: true,                                // Do Not Track 헤더 존중
  mask_all_text: false,                             // 라벨 가독성 위해 OFF — input은 별도 차단
  session_recording: { maskAllInputs: true },       // 켤 때 안전 디폴트
  disable_session_recording: true,                  // 베타 단계 OFF
  loaded: (ph) => {
    if (import.meta.env.DEV) ph.debug()
  },
})
```

핵심:
- `dom_event_allowlist: ['click']` — `change`, `input`, `submit` 이벤트는 캡처하지 않음. **이메일 입력 값이 PostHog에 절대 가지 않게** 하는 1차 방어선.
- `disable_session_recording: true` — 베타 단계 OFF. 켤 때 별도 컨센트 받기.
- `respect_dnt: true` — DNT 헤더 보내는 사용자는 자동 opt-out.

### 6.2 모든 form input에 `data-ph-no-capture`

2차 방어선. 코드:

```tsx
<input
  type="email"
  data-ph-no-capture                                   // ← 이게 핵심
  inputMode="email"
  autoComplete="email"
  ...
/>
```

EmailForm `<input type="email">`, ConsentDialog `<input type="checkbox">`, 목적 라디오 `<input type="radio">` 등 *모든 form input*에 추가.

### 6.3 검증

빌드 후 grep:
```bash
grep -rn 'type="email"' landing/src --include='*.tsx' | grep -v 'data-ph-no-capture'
# 출력 0건이어야 함
```

---

## 7. 봇·내부 트래픽 필터

### 7.1 PostHog Project settings (UI)

배포 후 PostHog 콘솔에서 설정:
- **Project settings → Filtered events**: 정규식 `/(bot|crawler|spider|headless|lighthouse|gtmetrix|pingdom|uptimerobot)/i` 매칭 UA 차단
- **Project settings → Internal IPs**: 사용자 사무실 IP / VPN IP 추가
- **Project settings → Test accounts**: distinctId가 `internal_*`로 시작하면 분석 대시보드에서 제외
- **Project settings → Domain allowlist**: 본 프로젝트 도메인만 (예: `<user>.github.io`, future custom domain)

### 7.2 코드 단 사전 필터

```typescript
// landing/src/lib/posthogClient.ts (init 호출 전)
const BOT_UA = /(bot|crawler|spider|headless|lighthouse|gtmetrix|pingdom)/i
function isBot(): boolean {
  if (typeof navigator === 'undefined') return false
  return BOT_UA.test(navigator.userAgent)
}

export function initPostHog() {
  if (typeof window === 'undefined') return
  if (inited) return
  if (isBot()) return                               // 봇은 init 자체 안 함
  // ... 정상 init
}
```

### 7.3 GitHub Pages 헬스체크

GitHub Pages는 별도 헬스체크가 없다. Lighthouse·GTmetrix·Pingdom 같은 외부 측정 봇은 §7.1 정규식으로 차단된다.

---

## 8. 환경변수 명세

### 8.1 `.env.example` 추가 항목

```bash
# PostHog (public key — 빌드 시 클라이언트 번들에 인라인됨, 노출 안전)
# 키 prefix: phc_*
VITE_POSTHOG_KEY=phc_REPLACE_ME_WITH_PROJECT_API_KEY

# PostHog Cloud 호스트 — 한국 사용자는 US Cloud 권장 (EU도 가능)
# US: https://us.i.posthog.com
# EU: https://eu.i.posthog.com
VITE_POSTHOG_HOST=https://us.i.posthog.com

# distinctId hash salt — 빌드 시 번들에 인라인되므로 보안 가치 약하지만 rainbow table 회피용
# 공개돼도 무방, 단 Supabase가 같은 salt를 사용해야 distinctId 일치
VITE_HASH_SALT=chew-coach-2026-public-salt

# Supabase (collector와 합의 — `landing-data-collector` 산출물 참조)
VITE_SUPABASE_URL=https://YOUR_PROJECT.supabase.co
VITE_SUPABASE_ANON_KEY=eyJ_REPLACE_WITH_ANON_KEY

# 컨센트 버전 (약관 변경 시 갱신)
VITE_CONSENT_VERSION=2026-05-04
```

### 8.2 zod 검증 스키마

```typescript
// landing/src/lib/env.ts
import { z } from 'zod'

const EnvSchema = z.object({
  VITE_POSTHOG_KEY: z.string().regex(/^phc_/, 'PostHog public key must start with phc_').optional(),
  VITE_POSTHOG_HOST: z.string().url().optional(),
  VITE_HASH_SALT: z.string().min(8, 'Salt must be at least 8 chars').optional(),
  VITE_SUPABASE_URL: z.string().url().optional(),
  VITE_SUPABASE_ANON_KEY: z.string().min(20).optional(),
  VITE_CONSENT_VERSION: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).default('2026-05-04'),
})

export const env = EnvSchema.parse({
  VITE_POSTHOG_KEY: import.meta.env.VITE_POSTHOG_KEY,
  VITE_POSTHOG_HOST: import.meta.env.VITE_POSTHOG_HOST,
  VITE_HASH_SALT: import.meta.env.VITE_HASH_SALT,
  VITE_SUPABASE_URL: import.meta.env.VITE_SUPABASE_URL,
  VITE_SUPABASE_ANON_KEY: import.meta.env.VITE_SUPABASE_ANON_KEY,
  VITE_CONSENT_VERSION: import.meta.env.VITE_CONSENT_VERSION,
})

// PostHog/Supabase 키 누락 시 경고만 — graceful degradation (배포 차단 X)
if (import.meta.env.PROD && !env.VITE_POSTHOG_KEY) {
  console.warn('[env] VITE_POSTHOG_KEY missing — analytics disabled in production')
}
```

`optional()`로 선언한 이유: 키 없이도 *빌드는 통과해야* 한다 (개발자 첫 clone, 키 설정 전 로컬 dev). 운영 빌드는 GitHub Actions Secrets로 주입.

### 8.3 GitHub Actions Secrets 키 명단

`.github/workflows/deploy.yml`에서 빌드 단계에 환경변수로 주입:
- `VITE_POSTHOG_KEY` — PostHog Project Settings → Project API Key
- `VITE_POSTHOG_HOST` — `https://us.i.posthog.com` (또는 EU)
- `VITE_HASH_SALT` — repo Secrets에 임의 문자열 (변경 시 historical hash 분단됨 — 신중히)
- `VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY` — collector 산출물 참조
- `VITE_CONSENT_VERSION` — `2026-05-04`

---

## 9. PostHog 호스팅 결정

### 9.1 옵션 비교

| 항목 | PostHog Cloud (US) | PostHog Cloud (EU) | Self-hosted |
|------|-------------------|-------------------|-----------|
| 한국 직접 리전 | 없음 | 없음 | (자체 인프라) |
| 한국 사용자 latency | ~150-180ms (round-trip) | ~250-300ms | 한국 호스팅 시 ~10-20ms |
| 무료 한도 | 1M events/월 + 5K replay/월 | 동일 | 인프라 비용 |
| 유료 시작 | $0.00031/event 초과분 | 동일 | EC2/Fly/등 자체 비용 |
| 데이터 거주지 | US | EU (GDPR 친화) | 통제 |
| 운영 부담 | 0 (PostHog 관리) | 0 | 높음 (ClickHouse·Kafka·Redis 운영) |
| 한국 PIPA 호환 | 약관 고지 + 사용자 동의 시 OK | 동일 | 통제 |
| 추천 | **베타 단계 1순위** | 옵션 (EU 사업 시) | 본 프로젝트 부적합 |

### 9.2 추천: PostHog Cloud US

**근거**:
1. **베타 트래픽 < 1M events/월** — 무료 한도 내 충분 (현재 가정: 월 100건 신청 + 페이지뷰 < 10K/월).
2. **한국 직접 리전 없음** — Cloud US/EU 어느 쪽이든 cross-border. US가 PostHog 본진이라 기능 출시 빠름.
3. **PIPA 호환** — 개인정보 처리방침에 "PostHog Inc. (미국)에 분석 데이터를 위탁 처리한다" 고지하면 OK. PostHog는 SOC 2 Type II + GDPR 적합.
4. **Self-hosted 부적합** — ClickHouse + Kafka + MinIO + Redis 스택을 1인 운영자가 관리하는 비용이 분석 가치보다 크다. 트래픽 폭증 시 (수십 만 events/일 이상) 재검토.

### 9.3 PIPA 호환 약관 문구 (개인정보 처리방침에 추가)

```
[해외 위탁 처리]
- 수탁자: PostHog Inc. (미국)
- 처리 목적: 웹사이트 방문 행동 분석 (페이지뷰, 클릭, 폼 제출 시점 등)
- 처리 항목: 익명 기기 ID (브라우저 쿠키), IP 주소(geo 추정용), User-Agent, 클릭·스크롤 행동
- 보유 기간: PostHog 정책에 따름 (기본 7년, 사용자 요청 시 즉시 삭제)
- 거부 권리: 브라우저 Do Not Track 활성 또는 [수신거부 페이지]에서 옵트아웃 가능
```

`marketing-storyteller` 검토 필요.

---

## 합의 포인트 (collector와)

본 라운드는 `landing-data-collector`와 *동시 작업*이다. 13_data_v2_consolidated.md (오케스트레이터 통합) 시점에 다음 5개 합의 포인트가 일치해야 한다.

### 합의 #1 — PostHog ↔ Supabase 데이터 분리 표 (역할 분담)

§5의 표가 양 에이전트 산출물에서 일치. 핵심:
- **이메일 본문은 Supabase에만**. PostHog property로 절대 X.
- **`purpose`는 양쪽 저장**. PostHog는 분석, Supabase는 source of truth.
- **삭제 요청 시 양쪽 모두 처리**: Supabase row 삭제 + `posthog.delete_person`.

### 합의 #2 — distinctId hash 정책 + Supabase `posthog_distinct_id` 컬럼

- 알고리즘: `sha256(email.trim().toLowerCase() + VITE_HASH_SALT)` 64자 hex
- Supabase `signups` 테이블에 `posthog_distinct_id text` 컬럼 추가
- 같은 salt 사용 (collector 산출물의 `.env.example`과 통합)
- salt 변경 시 historical hash 분단 — 변경 신중히

### 합의 #3 — `purpose` enum 값 (`diet` / `digestion` / `other`)

- 양 시스템 동일 enum 값. UI 라벨은 `marketing-storyteller`가 결정.
- Supabase: `signups.purpose text check (purpose in ('diet','digestion','other'))`
- PostHog: event property + identify trait

### 합의 #4 — `consent_*` 컬럼 + 컨센트 거절 시 분기

| 컬럼 / property | Supabase | PostHog |
|---------------|---------|---------|
| `consent_marketing` boolean | `signups.consent_marketing` | `form_submit_success` property |
| `consent_at` timestamp | `signups.consent_at` (nullable) | identify trait (옵트인 시만) |
| `consent_version` text | `signups.consent_version` | event property |

거절 분기:
- Supabase: row 저장 (`consent_marketing=false`, `consent_at=null` 또는 거절 시각)
- PostHog: `identify` 호출 *안 함*, 단 `form_submit_success`는 발화 (`consent_marketing: false`)
- 결과: 거절자도 익명 funnel 분석에는 카운트되지만 마케팅 발송 대상은 아님

### 합의 #5 — 환경변수 명세 (`.env.example` 통합)

`.env.example`에 PostHog + Supabase 키가 *함께* 나열. §8.1 참조. 키:
- `VITE_POSTHOG_KEY`, `VITE_POSTHOG_HOST`, `VITE_HASH_SALT`
- `VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY`
- `VITE_CONSENT_VERSION`

GitHub Actions Secrets에 동일 키. zod 검증은 `landing/src/lib/env.ts` 한 파일에서 통합.

---

## 검증 체크리스트 (오케스트레이터 통합 전)

- [ ] `landing/src/data/personas.ts`의 `PersonaKey`와 본 문서 `persona` enum 값 일치 — `stomach`/`diet`/`checkup`
- [ ] 이벤트 이름이 `landing-analytics-instrumentation` 표준 카탈로그와 일치 (이름 변경 0건)
- [ ] PII (`email`, `name`, `phone`) 가 어느 이벤트 property에도 등장하지 않음
- [ ] `purpose` enum 3값 (`diet`/`digestion`/`other`) collector 산출물과 일치
- [ ] `posthog_distinct_id` 컬럼이 collector의 Supabase 스키마에 존재
- [ ] `.env.example`이 collector 산출물과 통합 (충돌 키 0건)
