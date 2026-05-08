# Supabase 통합 — 스키마·RLS·코드·운영 참조

`landing-data-collection` 스킬의 Tier B+ Supabase 옵션을 채택했을 때 따르는 상세 패턴.

## 목차

1. 프로젝트 셋업 + anon/service_role 분리
2. 테이블 스키마 (DDL)
3. RLS 정책 (필수)
4. supabase-js 클라이언트 통합 코드
5. 컨센트 다이얼로그 + 폼 흐름
6. 중복 이메일 처리 (upsert)
7. 알림 채널 (Database Webhook / Edge Function)
8. 사용자 데이터 삭제 처리
9. Web3Forms → Supabase 마이그레이션
10. 검증 SQL (배포 전 확인)

---

## 1. 프로젝트 셋업 + 키 분리

Supabase Dashboard → New Project → 리전: 한국 사용자 기준 `Northeast Asia (Seoul)` 또는 `Northeast Asia (Tokyo)` (Seoul 미제공 시).

키 3종 위치 (Settings → API):
- `Project URL` (예: `https://xxx.supabase.co`) — 클라이언트 OK
- `anon` `public` 키 — 클라이언트 OK (단 RLS 필수)
- `service_role` 키 — **절대 클라이언트 X**, *서버·백오피스에서만*

```bash
# landing/.env (gitignore됨)
VITE_SUPABASE_URL=https://xxx.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbG...

# .env.example (커밋됨)
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=public-anon-key
# Note: service_role key는 절대 커밋 X. 백오피스 작업은 Supabase Dashboard SQL Editor 또는 별도 secret 환경에서.
```

GitHub Pages 배포 시 GitHub Repo Secrets 또는 빌드 워크플로 environment variable로 주입.

## 2. 테이블 스키마 (DDL)

`signups` 테이블 — 단일 테이블로 시작, 베타에서는 충분.

```sql
-- enum: 사용자 목적
create type purpose as enum ('diet', 'digestion', 'other');

-- enum: 페르소나 (URL ?p= 라우팅 또는 자체 답변)
create type persona as enum ('office_worker', 'student', 'senior', 'unknown');

-- 메인 테이블
create table signups (
  id              uuid primary key default gen_random_uuid(),
  email           text not null,
  email_lower     text generated always as (lower(email)) stored,  -- unique 키
  purpose         purpose not null,
  persona         persona not null default 'unknown',
  consent_marketing  boolean not null default false,
  consent_at         timestamptz,
  consent_version    text,                                          -- 예: '2026-05-04'
  source             text,                                          -- 'hero' | 'final_cta' | 'footer'
  utm_source         text,
  utm_medium         text,
  utm_campaign       text,
  user_agent         text,
  posthog_distinct_id text,                                         -- hash(email + salt)
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now(),
  deleted_at         timestamptz                                    -- soft delete
);

-- email_lower 유니크 — 같은 이메일 중복 방지 (대소문자 무관)
create unique index signups_email_lower_unique
  on signups (email_lower)
  where deleted_at is null;

-- created_at 인덱스 — 일별 분석
create index signups_created_at_idx on signups (created_at desc);

-- updated_at 자동 갱신 트리거
create or replace function set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger signups_updated_at
  before update on signups
  for each row execute function set_updated_at();
```

DDL 실행: Supabase Dashboard → SQL Editor → 위 스크립트 붙여넣고 Run.

### 컬럼 설계 메모
- `email_lower`: `email`을 `lower()`로 정규화한 generated column. 유니크 제약을 *여기*에 — `User@gmail.com`과 `user@gmail.com`을 같은 사용자로 취급.
- `purpose` enum: 본 프로젝트 핵심 차원. 라벨 변경은 자유, *값(`diet`/`digestion`/`other`)은 고정*.
- `consent_*` 3종: GDPR/PIPA 호환. 거절도 row 저장 (`consent_marketing=false`)되, 마케팅 발송에서 제외.
- `posthog_distinct_id`: `landing-analytics-engineer`의 `hash(email + salt)`와 동일. 두 시스템 연결.
- `deleted_at`: soft delete. 회수 요청 시 즉시 `deleted_at` 채우고 30일 후 cron으로 hard delete.

## 3. RLS 정책 (필수)

**RLS 없이 anon 키 사용 시 누구나 모든 row를 SELECT/UPDATE/DELETE 가능.** 반드시 활성화.

```sql
-- RLS 활성화
alter table signups enable row level security;

-- INSERT — anon 허용 (이메일 신청 가능)
create policy signups_insert_anon
  on signups for insert
  to anon
  with check (
    -- 검증: 이메일 형식·길이
    email is not null
    and length(email) between 5 and 200
    and email like '%@%.%'
    -- consent_at은 본인이 동의한 시점이므로 클라이언트가 보낸 값을 신뢰
    -- (단 consent_at이 미래/과거 너무 멀면 ban — 별도 트리거)
  );

-- SELECT — anon 차단
-- (관리자는 service_role 키로 Supabase Dashboard에서 조회)
create policy signups_select_authenticated
  on signups for select
  to authenticated
  using (false);  -- 익명/일반 사용자 모두 차단. 필요 시 admin role 만들어 허용

-- UPDATE / DELETE — anon 차단
-- (회수 요청은 별도 RPC 또는 Dashboard에서 service_role로 처리)
-- 정책 미정의 시 기본 deny — 별도 UPDATE/DELETE policy 만들지 않으면 자동 차단
```

검증 SQL (RLS 동작 확인):
```sql
-- service_role로 실행 시 모두 허용 (Dashboard SQL editor는 default service_role)
-- 익명 키로 실행 시:
--   INSERT: 통과
--   SELECT: 0행 반환 또는 권한 에러
```

### consent_at sanity 체크 (선택)

```sql
-- 클라이언트가 보낸 consent_at이 너무 미래·과거면 거부
create or replace function validate_consent_at()
returns trigger language plpgsql as $$
begin
  if new.consent_at is not null and (
    new.consent_at > now() + interval '5 minutes'
    or new.consent_at < now() - interval '5 minutes'
  ) then
    raise exception 'consent_at out of allowed window';
  end if;
  return new;
end;
$$;

create trigger signups_consent_at_validate
  before insert or update on signups
  for each row execute function validate_consent_at();
```

(서버 시각 신뢰. 클라이언트 시계는 신뢰하지 않음.)

## 4. supabase-js 클라이언트 통합 코드

```bash
npm install @supabase/supabase-js
```

```typescript
// landing/src/lib/supabaseClient.ts
import { createClient } from '@supabase/supabase-js'

const url = import.meta.env.VITE_SUPABASE_URL
const anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

if (!url || !anonKey) {
  console.warn('[supabase] env missing — submissions disabled')
}

export const supabase = url && anonKey
  ? createClient(url, anonKey, {
      auth: { persistSession: false },  // 익명 폼 — 세션 불필요
    })
  : null
```

```typescript
// landing/src/lib/dataCollection.ts
import { supabase } from './supabaseClient'

export type Purpose = 'diet' | 'digestion' | 'other'

export type SubmitReason =
  | 'invalid' | 'rate-limit' | 'network' | 'config' | 'duplicate'

export type SubmitResult =
  | { ok: true }
  | { ok: false; reason: SubmitReason }

export interface SubmitPayload {
  email: string
  purpose: Purpose
  consent_marketing: boolean
  consent_version: string                  // 예: '2026-05-04'
  source: string                            // 'hero' | 'final_cta' | 'footer'
  posthog_distinct_id?: string              // hash(email + salt)
  _gotcha?: string                          // honeypot
}

export async function submitSignup(payload: SubmitPayload): Promise<SubmitResult> {
  // 봇 차단
  if (payload._gotcha) return { ok: true }

  // 클라이언트 검증
  const email = payload.email.trim()
  if (email.length < 5 || email.length > 200 || !email.includes('@')) {
    return { ok: false, reason: 'invalid' }
  }

  if (!supabase) return { ok: false, reason: 'config' }

  const { error } = await supabase
    .from('signups')
    .upsert(
      {
        email,
        purpose: payload.purpose,
        consent_marketing: payload.consent_marketing,
        consent_at: payload.consent_marketing ? new Date().toISOString() : null,
        consent_version: payload.consent_version,
        source: payload.source,
        posthog_distinct_id: payload.posthog_distinct_id ?? null,
        user_agent: navigator.userAgent.slice(0, 500),
      },
      {
        // 같은 이메일이면 갱신 — 중복 시 사용자에게는 success
        onConflict: 'email_lower',
        ignoreDuplicates: false,
      },
    )

  if (error) {
    // PostgREST 에러 코드 매핑
    if (error.code === '23505') return { ok: false, reason: 'duplicate' }  // unique violation (혹시 race 시)
    if (error.code === '42501') return { ok: false, reason: 'config' }     // RLS 차단 — 정책 누락
    return { ok: false, reason: 'network' }
  }

  return { ok: true }
}
```

## 5. 컨센트 다이얼로그 + 폼 흐름

```
[이메일 + 목적 선택]
   ↓
[제출 버튼]
   ↓
[ConsentDialog 표시] ← analytics: track('consent_view', { consent_version })
   ├─ ✓ 출시되면 이메일로 알려드릴게요  (체크박스 — 기본 ON)
   ├─ "출시 외 광고는 보내지 않으며, 언제든 답장으로 수신거부할 수 있어요."
   ├─ [개인정보 처리 안내] 링크
   └─ [확인] [취소]
   ↓
[사용자 확인]
   ↓
submitSignup({ email, purpose, consent_marketing, consent_version, source, posthog_distinct_id })
   ↓ ok
[성공 메시지 표시] ← analytics: track('form_submit_success', { purpose, consent_marketing, source })
   ↓ (consent_marketing=true 시만)
[posthog.identify(distinct_id, { purpose, consent_marketing, consent_at })]
```

### ConsentDialog.tsx (스켈레톤)

```tsx
interface Props {
  open: boolean
  onConfirm: (consentMarketing: boolean) => void
  onCancel: () => void
  consentVersion: string
}

export function ConsentDialog({ open, onConfirm, onCancel, consentVersion }: Props) {
  const [agreed, setAgreed] = useState(true)
  // ... dialog, focus trap, ESC handling ...
  return (
    <dialog open={open} onClose={onCancel}>
      <h2>출시되면 이메일로 알려드릴게요</h2>
      <p>베타가 준비되면 가장 먼저 소식을 보내드립니다. 출시 외 광고는 보내지 않고, 언제든 [수신거부]로 그만두실 수 있어요.</p>
      <label>
        <input type="checkbox" checked={agreed} onChange={(e) => setAgreed(e.target.checked)} />
        출시 소식 받기 (선택)
      </label>
      <a href="/privacy" target="_blank">개인정보 처리 안내</a>
      <button onClick={onCancel}>취소</button>
      <button onClick={() => onConfirm(agreed)}>확인</button>
      <small>약관 버전: {consentVersion}</small>
    </dialog>
  )
}
```

EmailForm은 제출 직전 ConsentDialog를 띄우고, 사용자 확인 후 `submitSignup`을 호출.

## 6. 중복 이메일 처리

`upsert` 사용 — 같은 `email_lower`가 있으면 *갱신*. 사용자가 같은 이메일로 *목적·컨센트를 바꿔* 다시 제출했을 가능성을 자연스럽게 처리.

```typescript
.upsert({...}, { onConflict: 'email_lower', ignoreDuplicates: false })
```

`ignoreDuplicates: true`로 바꾸면 *기존 row 유지* (첫 신청 우선). 정책 결정 — 베타 단계는 보통 *갱신*이 좋다 (사용자가 마음을 바꿨을 수 있음).

## 7. 알림 채널

옵션 A: **Database Webhook** (가장 가벼움)
- Supabase Dashboard → Database → Webhooks → `INSERT on signups` → POST to Slack incoming webhook
- 페이로드는 `record` 객체. Slack에서 사람이 읽기 좋게 transform 필요 시 옵션 B로.

옵션 B: **Edge Function** (커스텀 포맷)
```typescript
// supabase/functions/notify-signup/index.ts
import { serve } from "https://deno.land/std/http/server.ts"

serve(async (req) => {
  const { record } = await req.json()
  await fetch(Deno.env.get('SLACK_WEBHOOK')!, {
    method: 'POST',
    body: JSON.stringify({
      text: `[Chew Coach] 새 베타 신청\n📧 ${record.email}\n🎯 ${record.purpose}\n✓ marketing: ${record.consent_marketing}`,
    }),
  })
  return new Response('ok')
})
```

배포: `supabase functions deploy notify-signup`. Database Webhook이 이 함수로 POST.

옵션 C: **일일 digest 메일** (저트래픽 베타용)
- pg_cron + Resend/SendGrid 호출 또는 Edge Function scheduled trigger
- 매일 아침 8시 KST: `select count(*), purpose from signups where created_at > now() - interval '1 day' group by purpose`

## 8. 사용자 데이터 삭제 처리

사용자가 "내 데이터 지워주세요"라고 메일·폼으로 요청 시:

### 즉시 처리 (soft delete)
```sql
update signups
set deleted_at = now()
where email_lower = lower('user@example.com');
```

### 30일 후 hard delete (pg_cron)
```sql
-- pg_cron 활성화 (Supabase Dashboard에서 한 번만)
create extension if not exists pg_cron;

-- 매일 새벽 3시 KST: 30일 지난 soft-deleted row 영구 삭제
select cron.schedule(
  'purge-old-signups',
  '0 18 * * *',  -- UTC 기준 18시 = KST 03시
  $$ delete from signups where deleted_at < now() - interval '30 days' $$
);
```

### PostHog 측 삭제
```bash
# PostHog API — 해당 distinctId의 person + 이벤트 삭제
curl -X DELETE \
  -H "Authorization: Bearer $POSTHOG_PERSONAL_API_KEY" \
  https://app.posthog.com/api/projects/$PROJECT_ID/persons/?distinct_id=$HASH
```

운영 가이드(`08_data_collection_runbook.md`)에 이 두 절차를 명시.

## 9. Web3Forms → Supabase 마이그레이션

기존 `lib/dataCollection.ts`가 Web3Forms 호출 중이면:

### 패스 A: 점진 (병행 발송 한 주, 그 후 컷오버)
- `submitSignup`에서 Supabase 먼저 호출, 성공 시 Web3Forms도 호출 (백업).
- 1주일 운영 후 모든 row가 Supabase에 들어왔는지 확인 → Web3Forms 호출 제거.

### 패스 B: 즉시 컷오버 (베타 단계 트래픽 적을 때)
- Web3Forms 호출 제거 → Supabase만.
- 기존 Web3Forms 받은편지함의 이메일은 *수동* CSV로 export → Supabase Dashboard `Insert from CSV`.
- Web3Forms 받은편지함은 보존 (감사 추적).

### 데이터 매핑
| Web3Forms 받은편지함 | Supabase signups |
|--------------------|------------------|
| email | email |
| variant (`'inline'`/`'stacked'`) | source |
| 시각 | created_at (이메일 발송 시각으로 추정) |
| (없음) | purpose → 'other' default + 운영자가 *수동 분류* 필요하면 |
| (없음) | consent_marketing → false default (명시 동의 받지 않은 사용자) |
| (없음) | consent_version → 'pre-2026-05-04' 또는 NULL |

기존 사용자에게 *재동의 메일*을 보낼지 결정 — 보낼 경우 톤은 "더 정확한 진행 소식을 보내드리려고 동의를 다시 한 번 받습니다" + 옵트인 링크.

## 10. 검증 SQL (배포 전 확인)

```sql
-- 1) RLS 활성화 확인
select tablename, rowsecurity
from pg_tables where tablename = 'signups';
-- expected: rowsecurity=true

-- 2) 정책 확인
select policyname, cmd, roles
from pg_policies where tablename = 'signups';
-- expected: signups_insert_anon (INSERT, anon), signups_select_authenticated (SELECT, ...)

-- 3) anon으로 SELECT 시도 (Supabase Dashboard에서 'anon' role 선택 후)
select * from signups limit 1;
-- expected: 0 rows OR permission denied

-- 4) 1건 INSERT 후 확인 (랜딩에서 1건 제출 후)
select email, purpose, consent_marketing, consent_at, consent_version, source, created_at
from signups
order by created_at desc limit 5;
-- expected: 모든 컬럼 채워짐 (consent_marketing=false 거절 케이스도 포함)

-- 5) email_lower 유니크 동작 확인 — 같은 이메일 두 번 INSERT 후
select email_lower, count(*) from signups group by email_lower having count(*) > 1;
-- expected: 0 rows (upsert로 한 row만 유지)
```

---

## 운영 핸드오프 체크리스트

- [ ] Supabase 프로젝트 URL과 anon key를 GitHub Repo Secrets에 등록
- [ ] DDL 실행 + RLS 정책 + 트리거 모두 적용
- [ ] 검증 SQL 5개 모두 통과
- [ ] Database Webhook 또는 Edge Function 알림 채널 1개 동작
- [ ] 운영 가이드(`08_data_collection_runbook.md`)에 다음 모두 기록:
  - Supabase Dashboard URL + Table Editor 위치
  - SQL editor 사용법 (간단 통계 쿼리 예시 3개)
  - 사용자 데이터 삭제 요청 SOP
  - 알림 채널 위치 + 한도 신호
  - 백업 정책 (Supabase 자동 백업 보존 기간 + 수동 export 주기)
