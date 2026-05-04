# 분석·데이터 v2 인프라 — 통합 합의 문서

> Phase 5-B 페어 합의 결과. `09_analytics_plan.md` (PostHog 측) + `12_supabase_schema.md` (Supabase 측)의 *합의 포인트 5개*를 단일 문서로 통합한다. 본 문서는 다음 단계(UX·카피·구현·QA)의 *입력 핵심*이다.
>
> **본 라운드 컨텍스트:** 사용자 요구 = (a) 다이어트/소화불량/위염/기타 *목적 분류* + (b) 출시 시 다시 연락드린다는 *마케팅 옵트인 동의* + (c) 백엔드를 *Supabase*로. PostHog는 *행동·전환 분석*, Supabase는 *컨택 source of truth*.

## 목차

1. 합의 5개 포인트
2. PostHog ↔ Supabase 데이터 분리 (역할 분담)
3. 식별 정책 — distinctId hash 공식
4. `purpose` / `persona` / `consent_*` enum 표준
5. 컨센트 거절 분기 정책
6. 환경변수 통합 명세
7. 사용자가 만들어야 할 외부 자원 (의사결정 게이트)
8. 구현 진입점 (frontend-implementer 입력)
9. 수용 기준 (QA 게이트)
10. 참조 (상세 문서 위치)

---

## 1. 합의 5개 포인트

| # | 합의 | 검증 |
|---|------|------|
| **1** | PostHog ↔ Supabase 데이터 분리 — 같은 데이터 중복 X. PostHog = 이벤트 ledger, Supabase = 컨택 source of truth. | 09 §5 + 12 §1.2 |
| **2** | distinctId = `sha256(email.trim().toLowerCase() + VITE_HASH_SALT)` — 양 시스템 동일 hash. Supabase `posthog_distinct_id` 컬럼 = PostHog `distinct_id`. | 09 §4.2 + 12 §3.2 |
| **3** | `purpose` enum 3값 고정 = `diet` / `digestion` / `other`. UI 라벨은 카피라이터 재량(다음 Step), enum 값은 historical 분석 위해 *불변*. | 09 §3 + 12 §3.2 + `personas.ts` 확인 |
| **4** | 컨센트 거절 시: Supabase에 `consent_marketing=false`로 row 저장 + `posthog.identify()` *미호출*. `form_submit_success`는 양쪽 모두 발화 (분모 일관성). | 09 §4.4 + 12 §3.2 |
| **5** | 환경변수 통합 — `.env.example` 1개 파일에 PostHog + Supabase + hash salt 모두. zod 검증. | 아래 §6 |

---

## 2. PostHog ↔ Supabase 데이터 분리

| 데이터 | PostHog | Supabase | 비고 |
|--------|---------|----------|------|
| `email` 본문 (PII) | ❌ 절대 X | ✅ source of truth | 사용자 회수 시 Supabase에서 즉시 삭제 |
| `posthog_distinct_id` (hash) | ✅ (자동, identify 시) | ✅ (컬럼) | 양방향 lookup 용 |
| `purpose` (`diet`/`digestion`/`other`) | ✅ (event property + identify trait) | ✅ (영구 row) | 분석·세그멘테이션 |
| `persona` | ✅ (property) | ✅ (영구 row) | URL `?p=` 라우팅에서 자동 |
| `consent_marketing` boolean | ✅ (`form_submit_success` property) | ✅ (`signups.consent_marketing`) | source of truth = Supabase |
| `consent_at`, `consent_version` | property로 OK | ✅ (영구) | 법적 호환 — Supabase가 권위 |
| `source` (`hero`/`final_cta`/`footer`) | ✅ (property) | ✅ (영구) | utm_*도 동일 |
| 페이지뷰·세션·CTA 클릭·funnel 이탈 | ✅ | ❌ | PostHog 단독 |
| `user_agent` | ✅ (자동) | ✅ (500자 자르기) | bot 필터·운영 |

**원칙:** 한쪽이 source, 다른 쪽이 분석 보조. 사용자 데이터 삭제 요청은 *양쪽에서 동시*. (Supabase soft-delete + PostHog `delete_person` API.)

---

## 3. 식별 정책 — distinctId hash 공식

```typescript
// landing/src/lib/hashId.ts (신규 — implementer가 만든다)
export async function hashEmail(email: string, salt: string): Promise<string> {
  const normalized = email.trim().toLowerCase()
  const data = new TextEncoder().encode(normalized + salt)
  const buf = await crypto.subtle.digest('SHA-256', data)
  return Array.from(new Uint8Array(buf))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('')
}
```

- **호출 시점**: 컨센트 옵트인 직후. 거절 시 호출 *안 함*.
- **PostHog 측**: `posthog.identify(distinctId, { purpose, consent_marketing: true, consent_at })`
- **Supabase 측**: `INSERT … posthog_distinct_id = <같은 hash>`
- **Salt**: `VITE_HASH_SALT` — 빌드 시 번들에 인라인. 보안 가치는 약하지만 rainbow table 회피용. 공개돼도 무방하나 *Supabase와 동일 salt 사용 필수*.

---

## 4. enum 표준 — 코드와 *일치 검증된* 값

### 4.1 `purpose` (사용자 비즈니스 질문 핵심)

| 값 | 의미 | UI 라벨 (예시 — `marketing-storyteller`가 결정) |
|----|------|-------------------------------------------|
| `diet` | 체중 관리·식사 속도 줄이기 | "체중·식습관 관리" |
| `digestion` | 소화불량·위염·역류 등 위장 문제 | "소화 문제 개선" |
| `other` | 그 외 (마음챙김 식사·호기심) | "기타 / 둘 다" |

### 4.2 `persona` (URL `?p=` 라우팅 — `landing/src/data/personas.ts`와 일치)

```
stomach | diet | checkup | unknown
```

> **주의:** 하네스 스킬 본문의 예시(`office_worker`/`student`/`senior`)는 *일반화 예시*였다. 본 프로젝트는 *코드값(`stomach`/`diet`/`checkup`/`unknown`)*을 사용한다. 두 산출물(09, 12) 모두 이 값으로 일치 확인됨.

### 4.3 `consent_*` 3컬럼 표준

| 컬럼 | 타입 | 값 |
|------|------|-----|
| `consent_marketing` | `boolean` | 출시 시 연락 동의 여부 |
| `consent_at` | `timestamptz` | 동의한 시각 (UTC). 거절 시 `null`. |
| `consent_version` | `text` | `'2026-05-04'` (본 라운드 약관 버전 시작값) |

CI 검증: `consent_marketing=true`이면 `consent_at` 필수 (12 §3.2 INSERT 정책 + `validate_consent_at` 트리거 ±5분 sanity).

---

## 5. 컨센트 거절 분기 정책

```
[제출 클릭]
  ↓
[ConsentDialog 표시] ← track('consent_view', { consent_version })
  ↓
사용자 [확인]    ┌───────[옵트인 ✓]──────┐    [거절 ✗]
                ↓                          ↓
       Supabase: row 저장              Supabase: row 저장
       (consent_marketing=true,        (consent_marketing=false,
        consent_at=now,                 consent_at=null,
        consent_version='2026-05-04')   consent_version='2026-05-04')
                ↓                          ↓
       hash = sha256(email+salt)      identify() 호출 X
       posthog.identify(hash, traits) ↓
                ↓                          ↓
       track('form_submit_success',   track('form_submit_success',
              { consent_marketing:           { consent_marketing:
                true, purpose, source })      false, purpose, source })
                ↓                          ↓
       성공 메시지 표시 (양쪽 동일)
```

**핵심:** 거절도 *성공한 신청*이다. `form_submit_success`는 양쪽 모두 발화. `consent_marketing` property로 분포 분리. 마케팅 발송 시 항상 `WHERE consent_marketing = true AND deleted_at IS NULL` 필터.

---

## 6. 환경변수 통합 명세

`landing/.env.example` 최종 형태:

```bash
# === Supabase (영구 백엔드) ===
VITE_SUPABASE_URL=https://YOUR_PROJECT.supabase.co
VITE_SUPABASE_ANON_KEY=eyJ_REPLACE_WITH_ANON_KEY

# === PostHog (분석) ===
VITE_POSTHOG_KEY=phc_REPLACE_ME_WITH_PROJECT_API_KEY
VITE_POSTHOG_HOST=https://us.i.posthog.com  # PostHog Cloud US (한국 직접 리전 없음)

# === 공통 (양 시스템에서 같은 값 사용) ===
VITE_HASH_SALT=chew-coach-2026-public-salt
VITE_CONSENT_VERSION=2026-05-04

# === 마이그 패스 결정 (12.md §6 참조) ===
# 패스 B 즉시 컷오버 권장 → Web3Forms 키는 1주일 후 제거
# VITE_W3FORMS_KEY=...  (제거 예정)
```

**zod 검증** (구현자가 `lib/env.ts`에 추가):

```typescript
import { z } from 'zod'
const EnvSchema = z.object({
  VITE_SUPABASE_URL: z.string().url(),
  VITE_SUPABASE_ANON_KEY: z.string().min(20),
  VITE_POSTHOG_KEY: z.string().regex(/^phc_/),
  VITE_POSTHOG_HOST: z.string().url(),
  VITE_HASH_SALT: z.string().min(8),
  VITE_CONSENT_VERSION: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
})
export const env = EnvSchema.parse(import.meta.env)
```

**GitHub Repo Secrets 등록 변수 6개** — 모두 `VITE_*` (빌드 워크플로 environment에 주입). `service_role` 키는 *Secrets에도 X*.

---

## 7. 사용자가 만들어야 할 외부 자원 (의사결정 게이트)

다음 단계로 가기 전 *사용자가 직접* 해야 할 일. 본 문서를 보고 정확히 무엇을 만들어야 하는지 알 수 있도록 정리.

### 7.1 Supabase 프로젝트 (필수)

1. https://supabase.com → New Project
2. **리전**: `Northeast Asia (Seoul)` 우선, 미제공 시 `Tokyo`
3. 프로젝트 이름 권장: `chew-coach-beta`
4. DB 비밀번호 생성 (저장)
5. 생성 후 Settings → API에서 다음 2개 복사:
   - `Project URL` → `VITE_SUPABASE_URL`
   - `anon` `public` 키 → `VITE_SUPABASE_ANON_KEY`
6. SQL Editor에서 `12_supabase_schema.md`의 §3.1 ~ §3.3 DDL 순차 실행 (트리거·RLS 포함)
7. 검증 SQL 5개 (12 §7.4) 실행 — 모두 통과 확인

⚠️ **Free 플랜 7일 비활성 일시정지** — UptimeRobot(무료)에 5분 ping 등록 (12 §8 참조).

### 7.2 PostHog 프로젝트 (필수)

1. https://app.posthog.com → Create Account → Project: `Chew Coach Landing`
2. **리전**: US Cloud (한국 직접 리전 없음. 베타 트래픽 < 1M events/월 무료. PIPA 위탁처리 고지 필요 — 약관에 표기 예정)
3. Project API Key (`phc_*`) 복사 → `VITE_POSTHOG_KEY`
4. Host: `https://us.i.posthog.com` (Cloud US 표준)
5. Project settings → Test accounts filtering: 본인 IP 또는 distinctId `internal_*` 패턴 등록

### 7.3 Slack workspace (권장 — 알림용)

12 §5의 옵션 A (Database Webhook → Slack incoming webhook):
1. 본인 Slack workspace의 #beta-signups 채널
2. https://api.slack.com → Create App → Incoming Webhooks ON
3. Webhook URL 복사 → Supabase Database Webhook 설정에 붙여넣기

대안: 메일 알림(옵션 B Edge Function + Resend) 또는 일일 digest(옵션 C pg_cron).

### 7.4 카피·UX 검토 (선택 — Step 5-B-3에서 다시 확인)

10_consent_strategy.md의 컨센트 다이얼로그 카피 디폴트가 마음에 드는지 검토. 안 들면 다음 단계에서 `marketing-storyteller`가 다듬는다.

### 7.5 마이그 패스 확인

12 §6 — **패스 B 즉시 컷오버 + 기존 Web3Forms 가입자에게 재동의 메일 발송**이 권장.
- Web3Forms 받은편지함의 기존 베타 신청자 수 확인
- 재동의 메일 발송 의사 확인 (또는 컨센트 정보 부재 그대로 import + `consent_marketing=false`)

---

## 8. 구현 진입점 (Step 5-B-4 frontend-implementer 입력)

다음 코드 변경이 필요하다 (구현자가 그대로 받아서 빌드):

### 8.1 신규 파일

| 경로 | 역할 | 참조 |
|------|------|------|
| `landing/src/lib/supabaseClient.ts` | Supabase JS init | 12 §3.4, references/supabase-integration.md §4 |
| `landing/src/lib/posthogClient.ts` | PostHog init + provider 게이트 | 09 §6.1 |
| `landing/src/lib/analytics.ts` | `track()` 단일 진입점 + 유니온 타입 | 09 §3 + analytics-instrumentation SKILL §구현 패턴 |
| `landing/src/lib/hashId.ts` | distinctId hash 공식 | §3 |
| `landing/src/lib/env.ts` | zod 환경변수 검증 | §6 |
| `landing/src/components/ConsentDialog.tsx` | 컨센트 다이얼로그 (Step 5-B-3 카피 입력) | 10 §3 + 14 (다음 단계) |

### 8.2 수정 파일

| 경로 | 변경 |
|------|------|
| `landing/src/lib/dataCollection.ts` | Web3Forms 호출 → Supabase upsert로 교체. `purpose`, `consent_marketing`, `consent_at`, `consent_version`, `posthog_distinct_id` 모두 페이로드에 포함 |
| `landing/src/components/EmailForm.tsx` | 목적 선택 UI (라디오/세그먼트) 추가 + 제출 직전 ConsentDialog 호출 + analytics `track()` 발화 (`email_focus`, `purpose_select`, `form_submit_*`) |
| `landing/src/sections/Hero.tsx`, `FinalCTA.tsx`, `Pricing.tsx`, `Footer.tsx` | CTA 클릭에 `track('cta_click', { cta_id, source })` 추가 |
| `landing/src/App.tsx` 또는 `landing/src/main.tsx` | `initPostHog()` 호출 + `landing_view` 발화 useEffect |
| `landing/.env.example` | §6 변수 6개 추가, `VITE_W3FORMS_KEY` 제거 표시 |
| `landing/.gitignore` | `.env` 확인 (이미 있을 가능성) |

### 8.3 의존성

```bash
cd landing
npm install @supabase/supabase-js posthog-js zod
```

번들 영향: posthog-js gzipped ~20KB, supabase-js gzipped ~30KB, zod gzipped ~6KB. 합 ~56KB 추가 — 기존 82.6KB → 약 138KB. Lighthouse 통과 가능 범위 (`landing-architect`와 사후 검증).

---

## 9. 수용 기준 (QA 게이트 — Step 5-B-5 입력)

다음 *모두* 통과해야 본 라운드 종료:

### 9.1 빌드·기본
- [ ] `npm run build` TS 오류 0
- [ ] `dist/` 번들에 `service_role` 키워드 0건 (`grep -ri "service_role" landing/dist`)
- [ ] `dist/` 번들에 실제 이메일 주소 텍스트 0건

### 9.2 종단간 — 옵트인 ✓ 시나리오
- [ ] 폼 제출 1건 → Supabase `signups`에 row 1개 + 모든 컬럼 채워짐 (스크린샷)
- [ ] PostHog Activity 탭에 `landing_view` → `cta_click` → `email_focus` → `purpose_select` → `consent_view` → `form_submit_try` → `form_submit_success` 7개 이벤트 모두 도달 (스크린샷)
- [ ] PostHog Persons 탭에 distinctId 1개 생성, traits에 `purpose`, `consent_marketing: true`, `consent_at` 존재 (이메일 본문 X 확인)
- [ ] Supabase의 `posthog_distinct_id`와 PostHog `distinct_id`가 *같은 값* (직접 비교)

### 9.3 종단간 — 옵트인 ✗ 시나리오
- [ ] Supabase row 저장됨, `consent_marketing=false`, `consent_at=null`
- [ ] PostHog Persons 탭에 distinctId *생성 안 됨* (anonymous 유지)
- [ ] `form_submit_success` 이벤트는 발화됨 (분모 일관성)

### 9.4 RLS 보안
- [ ] anon 키로 `select * from signups` → 0행 또는 권한 에러
- [ ] anon 키로 `INSERT` → 통과
- [ ] anon 키로 `UPDATE`/`DELETE` → 차단
- [ ] 검증 SQL 5개 (12 §7.4) 모두 통과

### 9.5 PII 차단 검증
- [ ] PostHog Activity의 어떤 이벤트 property에도 `email`, `name`, `phone` *없음*
- [ ] EmailForm input에 `data-ph-no-capture` 존재
- [ ] PostHog `disable_session_recording: true` 활성

### 9.6 중복·에러 처리
- [ ] 같은 이메일 2회 제출 → 사용자에게 success → DB는 1 row (upsert)
- [ ] 잘못된 이메일 형식 → "이메일 주소 형식을 확인해주세요"
- [ ] Supabase 503 (네트워크 실패) → "전송에 실패했어요"
- [ ] consent 거절 시도 → 정상 처리 (성공 메시지)

### 9.7 옵션 G 톤 가이드
- [ ] 컨센트 다이얼로그 카피, 성공 메시지, 에러 메시지 — 의료 약속·KOL·"전문가 추천" 0건
- [ ] 약관 버전 = `'2026-05-04'`로 통일

### 9.8 5초 룰 + 4 디바이스
- [ ] iPhone SE / iPhone 15 / iPad / Desktop 4 사이즈에서 컨센트 다이얼로그 정상 동작 (스크린샷)
- [ ] 5초 안에 폼 → 다이얼로그 → 성공 메시지까지 완료 가능

### 9.9 알림 채널
- [ ] Supabase Database Webhook → Slack에 메시지 1건 도달 (스크린샷)

---

## 10. 참조 (상세 문서)

| 문서 | 위치 | 활용 |
|------|------|------|
| 분석 계획 + 이벤트 카탈로그 | `_workspace/landing/09_analytics_plan.md` (486줄) | 구현 시 이벤트 발화 정확한 위치·페이로드 |
| 컨센트 전략 + 카피 디폴트 | `_workspace/landing/10_consent_strategy.md` (492줄) | Step 5-B-3 카피 입력 |
| PostHog 대시보드 청사진 | `_workspace/landing/11_analytics_dashboard.md` (392줄) | QA 후 사용자가 PostHog Insights 셋업 |
| Supabase 스키마 + RLS + 마이그 | `_workspace/landing/12_supabase_schema.md` (799줄) | 사용자 셋업 + 구현 시 SDK 호출 |
| Supabase 통합 references | `.claude/skills/landing-data-collection/references/supabase-integration.md` (453줄) | 구현 패턴 (DDL·supabase-js·webhook) |
| Analytics 통합 SKILL | `.claude/skills/landing-analytics-instrumentation/SKILL.md` (465줄) | 구현 패턴 (PostHog init·track 진입점) |

---

## 다음 단계

본 문서를 사용자가 검토 + 외부 자원(§7) 준비 + 마이그 패스 결정 후:

- **Step 5-B-3** (UX·카피 단발 호출, 병렬):
  - `visual-experience-designer` → `_workspace/landing/14_purpose_consent_ux.md` (목적 선택 UI + 컨센트 다이얼로그 인터랙션)
  - `marketing-storyteller` → `_workspace/landing/15_consent_copy.md` (다이얼로그 본문·체크박스 라벨·성공 메시지)
- **Step 5-B-4** (구현):
  - `frontend-implementer` → `_workspace/landing/16_data_v2_build_report.md` + `landing/` 코드 변경
- **Step 5-B-5** (QA·폴리시):
  - `landing-qa-polisher` → `_workspace/landing/17_data_v2_qa_report.md` + 폴리시
