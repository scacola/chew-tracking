# Supabase 스키마 + RLS + 마이그레이션 가이드 — Chew Coach 랜딩

작성: landing-data-collector 에이전트
작성일: 2026-05-04
스코프: 옵션 G 베타 랜딩의 *분석/데이터 v2 인프라* — Web3Forms → Supabase 마이그. 사용자가 Supabase 프로젝트를 *아직 만들기 전* 단계에서, 본 문서를 따라가면 프로젝트 생성 → DDL 실행 → RLS → 알림 → 코드 통합 → 운영까지 한 사이클 완결.
관련: `_workspace/landing/07_data_collection_options.md` (선행 옵션 비교) · `_workspace/landing/08_data_collection_runbook.md` (마이그 후 갱신 대상) · `landing/src/lib/dataCollection.ts` (마이그 출발점)
참조: `.claude/skills/landing-data-collection/references/supabase-integration.md`

> **클라이언트 키 정책 (절대 규칙):**
> 정적 GitHub Pages 호스팅이므로 `VITE_*` 환경변수는 빌드 시 클라이언트 번들에 인라인된다. 따라서 **`anon` 키만** 클라이언트에서 사용한다. **`service_role` 키는 *오직* Supabase Dashboard SQL Editor + 백오피스 환경에서만** — `landing/.env`·GitHub Actions·코드 어디에도 넣지 않는다.

---

## 0. 변경 요약 (한 페이지)

| 영역 | Before | After |
|---|---|---|
| 백엔드 | Web3Forms (이메일 1줄, 데이터 영속화 없음) | Supabase Postgres (`signups` 1테이블, RLS 활성, 영속화) |
| 폼 필드 | `email` 1개 | `email` + `purpose`(다이어트/소화/기타) + `consent_marketing`(출시 알림 동의) |
| 컬럼 수 | 0 | 18 (PK·email·email_lower·purpose·persona·consent 3종·source·utm 3종·user_agent·posthog_distinct_id·created/updated/deleted_at) |
| RLS 정책 수 | — | 3 (anon INSERT 허용 + authenticated SELECT 차단 + UPDATE/DELETE 자동 deny) |
| 트리거 수 | — | 2 (`set_updated_at` + `validate_consent_at` ±5분) |
| 알림 | Web3Forms → Gmail | 옵션 A/B/C 중 사용자 선택 (권장: A Slack webhook) |
| 마이그 권장 | — | **패스 B (즉시 컷오버) + 기존 가입자 재동의 메일** (베타 트래픽 적음) |
| 환경변수 | `VITE_W3FORMS_KEY` | `VITE_SUPABASE_URL` + `VITE_SUPABASE_ANON_KEY` (+ 분석 합의 시 `VITE_POSTHOG_KEY` 등) |

---

## 1. 프로젝트 셋업 가이드 (사용자가 따라할 단계)

### 1-1. 프로젝트 생성

1. <https://supabase.com/dashboard> 접속 → 우상단 **New project** 클릭 (조직이 없으면 먼저 organization 생성, 무료 플랜 선택).
2. 입력값:
   - **Name**: `chew-coach-prod` (또는 베타 단계만 운영 시 `chew-coach-beta`)
   - **Database Password**: 강력한 password 생성 후 1Password/메모장 등 *어딘가에 보관* — 잊으면 DB 직접 접속 시 재설정 필요
   - **Region**: 한국 사용자 우선 → **Northeast Asia (Seoul) `ap-northeast-2`**. Seoul 옵션이 안 보이면 **Northeast Asia (Tokyo) `ap-northeast-1`** 차순위 (지연 차이 ~10ms).
   - **Pricing Plan**: Free (월 500MB DB, 5GB egress, 50k MAU — 베타 충분)
3. **Create new project** → 프로비저닝 ~2분.

### 1-2. URL + anon key 위치 확인

좌측 메뉴 **Settings → API** → 다음 3종 표시:

| 항목 | 위치 | 클라이언트 사용 |
|---|---|---|
| **Project URL** | `https://xxx.supabase.co` | OK (공개해도 안전) |
| **`anon` `public` key** | `eyJhbG...` 매우 긴 JWT | OK (단 RLS 활성 필수) |
| **`service_role` `secret` key** | `eyJhbG...` 다른 JWT | **절대 X — Dashboard 외 어디에도 넣지 말 것** |

→ 위 2개(`Project URL`, `anon public`)만 §9 환경변수에 등록.

### 1-3. SQL Editor 위치

좌측 메뉴 **SQL Editor**. Dashboard에서 SQL을 실행할 때는 *기본 `service_role` 권한*으로 동작 — 따라서 §3 RLS 정책은 자동 통과. RLS 동작 검증(§3 검증 SQL #3·#4)은 `set role anon;`을 명시적으로 호출하거나 클라이언트 측 supabase-js로 검증해야 정확.

### 1-4. (선택) 도메인 + 데이터 보존 정책 설정

**Settings → Database → Extensions** — `pg_cron` 확장 1번만 켜두면 §6 hard delete cron이 작동. 베타 초기에는 켜지 않고 수동 운영도 가능.

---

## 2. 테이블 스키마 (DDL)

> ⚠️ **persona enum 값은 `landing/src/data/personas.ts`와 정확히 일치한다.** 현재 코드에서 사용 중인 값은 `stomach` / `diet` / `checkup` 3종. 새 페르소나가 추가되면 `alter type persona add value '...';`를 별도 마이그레이션으로 실행.

> ⚠️ **`purpose`와 `persona`는 다른 차원.** `purpose`는 *사용자가 폼에서 직접 고른 목적* (다이어트/소화/기타 — 사용자 요구). `persona`는 *방문자가 본 랜딩 variant* (URL `?p=stomach` 라우팅 또는 미설정 시 `unknown`).

Supabase Dashboard → **SQL Editor** → New query → 아래 전체를 그대로 붙여넣고 **Run**:

```sql
-- ============================================================
-- Chew Coach signups schema — v1 (2026-05-04)
-- 실행 권한: service_role (Supabase Dashboard SQL Editor 기본)
-- 멱등성: 한 번 실행 후 재실행 시 'already exists' 에러 — 정상.
--   재실행이 필요하면 §9 마이그레이션 또는 drop 후 재생성.
-- ============================================================

-- 1. enum 타입
create type purpose as enum ('diet', 'digestion', 'other');
create type persona as enum ('stomach', 'diet', 'checkup', 'unknown');

-- 2. 메인 테이블
create table signups (
  id                   uuid        primary key default gen_random_uuid(),
  email                text        not null,
  email_lower          text        generated always as (lower(email)) stored,
  purpose              purpose     not null,
  persona              persona     not null default 'unknown',
  consent_marketing    boolean     not null default false,
  consent_at           timestamptz,
  consent_version      text        not null default '2026-05-04',
  source               text,                          -- 'hero' | 'final_cta' | 'footer' | 'pricing_card_*'
  utm_source           text,
  utm_medium           text,
  utm_campaign         text,
  user_agent           text,                          -- 클라에서 .slice(0, 500)
  posthog_distinct_id  text,                          -- sha256(email_lower + VITE_HASH_SALT)
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now(),
  deleted_at           timestamptz                    -- soft delete
);

-- 3. 인덱스
-- 3-1. 같은 이메일은 살아있는 row 1개만 (대소문자 무관)
create unique index signups_email_lower_unique
  on signups (email_lower)
  where deleted_at is null;

-- 3-2. 일별 리포트용 (created_at 내림차순)
create index signups_created_at_idx on signups (created_at desc);

-- 4. updated_at 자동 갱신 함수 + 트리거
create or replace function set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger signups_set_updated_at
  before update on signups
  for each row execute function set_updated_at();

-- 5. consent_at sanity 체크 — 클라이언트 시각이 ±5분 밖이면 거부
create or replace function validate_consent_at()
returns trigger language plpgsql as $$
begin
  if new.consent_at is not null and (
    new.consent_at > now() + interval '5 minutes'
    or new.consent_at < now() - interval '5 minutes'
  ) then
    raise exception 'consent_at out of allowed window (server time vs client time skew > 5min)';
  end if;
  return new;
end;
$$;

create trigger signups_validate_consent_at
  before insert or update on signups
  for each row execute function validate_consent_at();

-- 6. 친절한 코멘트 (Dashboard에서 hover 시 노출)
comment on table signups is 'Chew Coach 베타 랜딩 가입자. RLS 활성, anon INSERT만 허용.';
comment on column signups.email_lower is 'lower(email) generated stored — unique 키. 대소문자 무관 중복 방지.';
comment on column signups.purpose is '사용자가 폼에서 고른 목적: 다이어트/소화/기타.';
comment on column signups.persona is '방문자가 본 랜딩 variant (URL ?p= 또는 unknown). landing/src/data/personas.ts와 일치.';
comment on column signups.consent_marketing is '출시 알림 동의. false면 row는 저장하되 마케팅 발송 X.';
comment on column signups.posthog_distinct_id is 'sha256(email_lower + VITE_HASH_SALT). PostHog 동일 hash와 매칭.';
```

### 컬럼 설계 메모

- **`email_lower`** = generated stored. 유니크는 *여기*에 — `User@gmail.com`과 `user@gmail.com`을 같은 사용자로.
- **`purpose`** = 사용자 요구 핵심 컬럼. *값(`diet`/`digestion`/`other`)은 고정* — UI 라벨은 자유.
- **`persona`** = `landing/src/data/personas.ts`와 일치하는 4값(`stomach`/`diet`/`checkup`/`unknown`). 페르소나가 늘면 `alter type persona add value 'newkey';`.
- **`consent_marketing`** = 거절도 row 저장. 마케팅 발송 시 항상 `where consent_marketing = true and deleted_at is null`로 필터.
- **`consent_version`** = `'2026-05-04'` 디폴트. 약관 문구가 바뀌면 새 버전 문자열로 (`'2026-08-15'` 등) → 어떤 사용자가 어떤 버전에 동의했는지 추적.
- **`posthog_distinct_id`** = analytics 에이전트 합의: `sha256(email_lower + VITE_HASH_SALT)`. 양 시스템이 같은 hash 사용.
- **`user_agent`** = 클라에서 `navigator.userAgent.slice(0, 500)` — 너무 긴 UA 끊기.
- **`deleted_at`** = soft delete. §6 SOP대로 30일 후 hard delete.

---

## 3. RLS 정책 (SQL)

> **반드시 §2 DDL 직후 같은 SQL Editor에서 이어 실행한다. RLS 활성화 *전* 한 줄이라도 INSERT가 들어오면 그 row는 보호 없이 anon에 노출된 상태로 저장된 것.**

```sql
-- ============================================================
-- RLS 활성화 + 정책
-- ============================================================

alter table signups enable row level security;

-- 1) INSERT: anon 허용. 검증을 정책에 박아 클라이언트 trust 최소화.
create policy signups_insert_anon
  on signups for insert
  to anon
  with check (
    email is not null
    and length(email) between 5 and 200
    and email like '%@%.%'
    and (consent_marketing = false or consent_at is not null)
    -- consent_marketing=true면 consent_at 필수
  );

-- 2) SELECT: 모든 비-service_role 차단.
--    관리자 조회는 Dashboard SQL Editor (service_role)에서.
create policy signups_select_block
  on signups for select
  to anon, authenticated
  using (false);

-- 3) UPDATE/DELETE는 정책 미정의 = 자동 deny.
--    데이터 회수·관리는 Dashboard에서 service_role로 §6 SOP 따라.
```

### 정책 검증 SQL 5개 (배포 전 필수)

```sql
-- (모두 SQL Editor에서 실행. 일부는 'set role anon;'로 anon 시뮬레이션)

-- 검증 1: RLS 활성 확인
select tablename, rowsecurity
from pg_tables
where schemaname = 'public' and tablename = 'signups';
-- expected: rowsecurity = true

-- 검증 2: 정책 목록 확인
select policyname, cmd, roles, qual, with_check
from pg_policies
where schemaname = 'public' and tablename = 'signups'
order by policyname;
-- expected: 2개 정책
--   signups_insert_anon (INSERT, {anon}, with_check=...)
--   signups_select_block (SELECT, {anon,authenticated}, qual=false)

-- 검증 3: anon으로 SELECT 시도 → 0행
set role anon;
select count(*) from signups;
-- expected: 0 (RLS가 모든 row를 가린다)
reset role;

-- 검증 4: anon으로 INSERT 정상 통과
set role anon;
insert into signups (email, purpose, consent_marketing, consent_at, consent_version, source)
values ('rls.test@example.com', 'other', true, now(), '2026-05-04', 'verification');
-- expected: INSERT 1
reset role;

-- 검증 5: 같은 email_lower 두 번째 INSERT → unique violation
set role anon;
insert into signups (email, purpose, consent_marketing, source)
values ('RLS.Test@example.com', 'diet', false, 'verification-dup');
-- expected: ERROR: duplicate key value violates unique constraint "signups_email_lower_unique"
reset role;

-- 정리: 검증용 row 삭제 (service_role 권한 필요)
delete from signups where source like 'verification%';
```

5개 모두 expected와 일치하면 RLS는 안전. 어긋나면 §10 트러블슈팅.

---

## 4. 알림 채널 — 3개 옵션 비교

| 옵션 | 셋업 시간 | 외부 자원 | 커스터마이즈 | 베타 권장 |
|---|---|---|---|---|
| **A: Database Webhook → Slack** | ~10분 | Slack workspace + incoming webhook URL | 낮음 (raw record JSON) | **★ 권장** |
| **B: Edge Function `notify-signup`** | ~30분 | Slack 또는 Resend(메일) | 높음 (한국어 포맷, 분기) | 트래픽 늘면 전환 |
| **C: pg_cron + 일일 digest** | ~25분 | Resend/SendGrid | 중간 | 알림 피로 줄이고 싶을 때 |

### 옵션 A — Database Webhook → Slack (권장)

**셋업:**

1. Slack workspace에서 채널 생성 (예: `#chew-coach-signups`)
2. <https://api.slack.com/apps> → **Create New App** → From scratch → 워크스페이스 선택
3. 좌측 **Incoming Webhooks** → On으로 토글 → **Add New Webhook to Workspace** → 채널 선택 → URL 복사 (`https://hooks.slack.com/services/T.../B.../...`)
4. Supabase Dashboard → **Database → Webhooks** → **Create a new hook**
   - Name: `notify-signup-slack`
   - Table: `signups`
   - Events: ✓ `Insert`
   - Type: `HTTP Request`
   - HTTP Method: `POST`
   - URL: 위 Slack webhook URL
   - HTTP Headers: `Content-Type: application/json`
   - HTTP Params: 빈칸
   - HTTP Body: 아래 그대로 (Slack이 `text` 필드만 있으면 표시)

```json
{
  "text": ":wave: *새 베타 신청* — Chew Coach\n• email: {{record.email}}\n• purpose: {{record.purpose}}\n• marketing: {{record.consent_marketing}}\n• source: {{record.source}}\n• at: {{record.created_at}}"
}
```

> Supabase Webhooks는 `{{record.field}}` 템플릿 미지원 — 위 형식 대신 옵션 B Edge Function이 필요할 수도. 2026-05-04 시점 Webhooks UI는 raw payload만 전송. Slack에서 raw JSON을 그대로 보여주는 게 괜찮으면 옵션 A 그대로, 한국어 포맷이 필요하면 옵션 B로.

5. **Save** → 다음 INSERT부터 Slack 채널에 도착.

**검증:** 위 §3 검증 4의 INSERT가 Slack 채널에 1줄 도착해야 통과.

### 옵션 B — Edge Function `notify-signup`

raw JSON이 아닌 한국어 포맷이 필요하거나, 분기(예: `consent_marketing=true`만 알림)가 필요하면.

**셋업:**

1. 로컬에서 Supabase CLI 설치 (1번만): `brew install supabase/tap/supabase`
2. 프로젝트 디렉토리에서: `supabase login` → 토큰 입력
3. `supabase init` (이미 있으면 skip)
4. `supabase functions new notify-signup` → `supabase/functions/notify-signup/index.ts` 생성

```typescript
// supabase/functions/notify-signup/index.ts
import { serve } from 'https://deno.land/std@0.224.0/http/server.ts'

const SLACK_WEBHOOK = Deno.env.get('SLACK_WEBHOOK')!

interface SignupRecord {
  email: string
  purpose: 'diet' | 'digestion' | 'other'
  persona: string
  consent_marketing: boolean
  source: string | null
  created_at: string
}

const PURPOSE_LABEL: Record<string, string> = {
  diet: '다이어트',
  digestion: '소화/위장',
  other: '기타',
}

serve(async (req) => {
  try {
    const body = await req.json()
    const record: SignupRecord = body.record

    const lines = [
      `:wave: *새 베타 신청* — Chew Coach`,
      `• 이메일: \`${record.email}\``,
      `• 목적: ${PURPOSE_LABEL[record.purpose] ?? record.purpose}`,
      `• 페르소나: ${record.persona}`,
      `• 출시 알림 동의: ${record.consent_marketing ? '✅' : '❌'}`,
      `• 진입점: ${record.source ?? '미상'}`,
      `• 시각: ${record.created_at}`,
    ]

    await fetch(SLACK_WEBHOOK, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ text: lines.join('\n') }),
    })

    return new Response('ok', { status: 200 })
  } catch (e) {
    console.error('notify-signup failed', e)
    return new Response('error', { status: 500 })
  }
})
```

5. Slack webhook URL을 함수 secret으로:
   ```bash
   supabase secrets set SLACK_WEBHOOK="https://hooks.slack.com/services/..."
   ```
6. 배포: `supabase functions deploy notify-signup --project-ref <your-ref>`
7. Dashboard → Database → Webhooks → 옵션 A와 같은 절차, URL만 Edge Function URL로 (`https://<ref>.functions.supabase.co/notify-signup`).

**메일 알림으로 갈아끼우기 (Resend):** 위 fetch 블록을 아래로 교체.

```typescript
await fetch('https://api.resend.com/emails', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${Deno.env.get('RESEND_API_KEY')!}`,
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    from: 'Chew Coach <noreply@your-verified-domain>',
    to: '1213sam0@gmail.com',
    subject: '[Chew Coach] 새 베타 신청',
    text: lines.join('\n'),
  }),
})
```

(Resend 가입 + 도메인 verify 필요. 베타 단계에는 Slack이 빠름.)

### 옵션 C — pg_cron 일일 digest

**용도:** 베타 트래픽이 더 늘어 "신청 1건마다 알림이 시끄럽다" 단계.

```sql
-- pg_cron 활성화 (Dashboard → Database → Extensions에서 ON)
create extension if not exists pg_cron;

-- 매일 KST 09시 (UTC 00시) 어제 신청 수 + purpose 분포를 Edge Function으로
select cron.schedule(
  'daily-signup-digest',
  '0 0 * * *',
  $$
  select net.http_post(
    url := 'https://<your-ref>.functions.supabase.co/digest-signup',
    headers := '{"Content-Type": "application/json"}'::jsonb,
    body := jsonb_build_object(
      'date', (now() - interval '1 day')::date,
      'total', (select count(*) from signups
                where created_at >= now() - interval '1 day' and deleted_at is null),
      'by_purpose', (select jsonb_object_agg(purpose, c)
                     from (select purpose, count(*) c from signups
                           where created_at >= now() - interval '1 day' and deleted_at is null
                           group by purpose) t)
    )::text
  );
  $$
);
```

`digest-signup` Edge Function을 옵션 B와 같은 패턴으로 만들고 Slack/메일 발송.

---

## 5. Web3Forms → Supabase 마이그레이션 패스

현재 Web3Forms 받은편지함에 베타 신청자가 있을 수 있음 (운영 중). 두 가지 패스:

### 패스 A — 점진 (1주일 병행 발송 → 컷오버)

**용도:** 트래픽이 이미 일 단위 N건 이상이거나 *데이터 손실이 절대 0이어야* 할 때.

코드 패치 (`landing/src/lib/dataCollection.ts`):

```typescript
import { submitSignupToSupabase } from './dataCollectionSupabase' // 새 함수
import { submitEmail as submitEmailWeb3Forms } from './dataCollectionWeb3Forms' // 기존 이름변경

export async function submitSignup(payload: SubmitPayload): Promise<SubmitResult> {
  // 1차: Supabase가 source-of-truth
  const supabaseResult = await submitSignupToSupabase(payload)
  if (!supabaseResult.ok) return supabaseResult

  // 2차: Web3Forms 백업 발송 — 실패해도 사용자에게는 success
  void submitEmailWeb3Forms({
    email: payload.email,
    source: `${payload.source}+supabase`,
  }).catch(() => {})

  return { ok: true }
}
```

운영:
- Day 1~7: 두 시스템 모두 row 들어옴. 매일 받은편지함 vs `select count(*) from signups where created_at > '...'` 비교.
- Day 8: Web3Forms 호출 제거 + `VITE_W3FORMS_KEY` 시크릿 삭제.

### 패스 B — 즉시 컷오버 (★ 권장)

**용도:** 베타 트래픽이 적어 데이터 손실 risk가 낮음 + 코드를 깨끗히 유지.

1. Web3Forms 호출 코드 제거 (`dataCollection.ts`를 `supabase`만 호출하도록 §아래 통합 코드로 치환).
2. 기존 Web3Forms 받은편지함의 이메일 → 수동 CSV export → Supabase Insert from CSV:
   - 받은편지함 검색: `from:noreply@web3forms.com`
   - 각 메일에서 이메일 주소 + 시각 추출 (또는 Web3Forms Dashboard CSV export 기능 사용 — 무료 플랜은 미지원이라 수동)
   - CSV 만들기 (UTF-8):
     ```csv
     email,purpose,persona,consent_marketing,consent_version,source,created_at
     existing1@example.com,other,unknown,false,pre-2026-05-04,migration,2026-04-15T10:00:00Z
     existing2@example.com,other,unknown,false,pre-2026-05-04,migration,2026-04-20T14:30:00Z
     ```
   - Supabase Dashboard → Table Editor → `signups` → **Import data from CSV** → 위 파일 업로드.
3. 기존 가입자에게 **재동의 메일** 발송 (수동, ~10명 이내):
   - 제목: "[Chew Coach] 베타 진행 안내 — 알림 받기 다시 한 번 확인 부탁드려요"
   - 본문 톤 (옵션 G):
     > 안녕하세요. 며칠 전 Chew Coach 베타에 신청해주셔서 감사합니다.
     > 진행 소식을 더 잘 정리해서 보내드리려고, 알림 동의를 다시 한 번 받습니다.
     > [출시되면 알림 받기 →] (링크)
     > 만약 그만 받고 싶으시면 이 메일에 답장만 주시면 즉시 삭제 처리할게요.
   - 응답한 사람만 SQL로 갱신:
     ```sql
     update signups
     set consent_marketing = true,
         consent_at = now(),
         consent_version = '2026-05-04'
     where email_lower = lower('user@example.com');
     ```

> 베타 단계 트래픽이 적으면 **패스 B + 재동의 메일이 가장 깨끗**. 동의 추적이 명확하고 코드 base가 단순.

---

## 6. 사용자 데이터 삭제 SOP

사용자가 "내 데이터 지워주세요"라고 메일 등으로 요청 시:

### 6-1. 즉시 처리 (soft delete)

Supabase Dashboard → SQL Editor:

```sql
update signups
set deleted_at = now()
where email_lower = lower('user@example.com')
returning id, email, deleted_at;
-- 1행 반환 확인 후 사용자에게 "처리되었습니다" 회신
```

### 6-2. 30일 후 hard delete (pg_cron)

```sql
-- 1번만 활성화
create extension if not exists pg_cron;

-- 매일 KST 03시 (UTC 18시) 30일 지난 soft-deleted row 영구 삭제
select cron.schedule(
  'purge-old-signups',
  '0 18 * * *',
  $$ delete from signups where deleted_at < now() - interval '30 days' $$
);

-- 등록 확인
select * from cron.job where jobname = 'purge-old-signups';
```

### 6-3. PostHog 측 동시 삭제

distinct_id를 알아야 함:

```sql
select posthog_distinct_id from signups where email_lower = lower('user@example.com');
```

```bash
# PostHog API — 해당 distinctId의 person + 모든 이벤트 삭제
curl -X DELETE \
  -H "Authorization: Bearer $POSTHOG_PERSONAL_API_KEY" \
  "https://app.posthog.com/api/projects/$POSTHOG_PROJECT_ID/persons/?distinct_id=$DISTINCT_ID"
```

(Personal API Key는 PostHog → Personal API keys에서 발급. `delete_person`은 사용자 + 이벤트를 30일 후 영구 삭제.)

---

## 7. 검증 SQL 5개 (배포 전 최종)

§3 정책 검증과는 별개, *통합 시점* 점검용:

```sql
-- 7-1. 프로덕션 빌드의 첫 실 INSERT 확인
select id, email, purpose, persona, consent_marketing, consent_at, consent_version, source, created_at
from signups
order by created_at desc
limit 5;
-- expected: 모든 컬럼 채워짐. consent_marketing=true면 consent_at not null.

-- 7-2. utm 트래킹이 살아있는가
select utm_source, utm_medium, utm_campaign, count(*)
from signups
where created_at > now() - interval '1 day'
group by utm_source, utm_medium, utm_campaign
order by count(*) desc;

-- 7-3. user_agent가 끊겼는가 (>500자가 없어야)
select max(length(user_agent)) as max_ua_len
from signups;
-- expected: <= 500

-- 7-4. posthog_distinct_id 일관성 (분석 합의 hash 양식)
-- VITE_HASH_SALT를 알면 직접 검증 — 모르면 클라 콘솔에서 같은 이메일을 두 번 sha256 돌려 비교
select email_lower, posthog_distinct_id
from signups
where created_at > now() - interval '1 day'
order by created_at desc
limit 5;

-- 7-5. RLS 우회 시도 — anon 로 SELECT
set role anon;
select count(*) from signups;
-- expected: 0
reset role;
```

---

## 8. 운영 가이드 — `08_data_collection_runbook.md` 갱신 변경분

**갱신 대상:** `_workspace/landing/08_data_collection_runbook.md`. 마이그 후 Web3Forms 절을 Supabase 절로 교체.

### 8-1. Dashboard 위치

| 작업 | URL | 메모 |
|---|---|---|
| 프로젝트 홈 | `https://supabase.com/dashboard/project/<your-ref>` | bookmark |
| Table Editor | 좌측 **Table Editor** → `signups` | row 직접 보기/편집 (service_role) |
| SQL Editor | 좌측 **SQL Editor** | 통계 쿼리·삭제·관리 |
| Webhooks | 좌측 **Database → Webhooks** | 알림 채널 점검 |
| API Settings | 좌측 **Settings → API** | URL + anon key 확인 |
| Logs | 좌측 **Logs Explorer** | RLS 차단 로그·에러 추적 |

### 8-2. 자주 쓸 SQL 3개

```sql
-- 쿼리 1: 일별 신규 + purpose 분포 (지난 14일)
select
  date_trunc('day', created_at)::date as day,
  count(*) as total,
  count(*) filter (where purpose = 'diet')      as diet,
  count(*) filter (where purpose = 'digestion') as digestion,
  count(*) filter (where purpose = 'other')     as other
from signups
where deleted_at is null
  and created_at > now() - interval '14 days'
group by 1
order by 1 desc;

-- 쿼리 2: 옵트인률 (출시 알림 동의 비율)
select
  count(*) as total,
  count(*) filter (where consent_marketing) as opted_in,
  round(100.0 * count(*) filter (where consent_marketing) / nullif(count(*), 0), 1) as opt_in_rate_pct
from signups
where deleted_at is null;

-- 쿼리 3: 페르소나 × purpose 교차표
select persona, purpose, count(*)
from signups
where deleted_at is null
group by 1, 2
order by 1, 2;
```

### 8-3. 한도 모니터링

Free 플랜 한도 (2026-05-04 확인):

| 항목 | 한도 | 베타 위험도 | 대응 |
|---|---|---|---|
| DB storage | 500 MB | 낮음 (signups 1행 ~1KB → 500k 가입 가능) | 거의 무관 |
| Egress (월) | 5 GB | 매우 낮음 (signups read는 운영자만) | 거의 무관 |
| MAU (auth) | 50k | 무관 (auth 사용 안 함) | — |
| Edge Function 호출 | 월 500k | 옵션 B 사용 시 — 신청 1건당 1회 → 매우 안전 | 거의 무관 |
| **7일 비활성 → 자동 일시정지** | — | **★ 베타 핵심 위험** | §8-4 |

### 8-4. 7일 비활성 일시정지 대응

Free 플랜은 **7일 동안 API 호출이 0이면 프로젝트가 자동 일시정지**된다 (Supabase 정책 2026-05-04 확인). 일시정지 시 anon INSERT가 502/504로 실패 → 사용자 폼 제출 실패.

대응 (택 1):
- (★ 권장) 외부 무료 cron(<https://uptimerobot.com>)으로 5분마다 `<project-url>/rest/v1/signups?select=count&head=true` 헤드 요청. 1요청/5분 → 월 8,640요청 → free 한도 안.
- Supabase Dashboard에 매주 1회 직접 들어가 SQL 1줄 실행.
- 베타 후 paid 플랜($25/mo) 전환 → 자동 일시정지 없음.

### 8-5. 백업 정책

- **Supabase 자동 백업:** Free 플랜은 *PITR 미제공*, 매일 1회 백업 *7일 보존* (확인 2026-05-04).
- **수동 export:** 매주 일요일 23시 KST에 SQL Editor에서 실행:
  ```sql
  copy (select * from signups where deleted_at is null order by created_at) to stdout with csv header;
  ```
  결과 텍스트를 `_workspace/landing/backups/signups-YYYYMMDD.csv`로 저장 (gitignore에 `_workspace/landing/backups/` 추가). 한 달치 누적 보관.
- **장애 복구 시뮬레이션:** 분기 1회, 별도 Supabase 프로젝트(`chew-coach-restore-test`)에 위 CSV를 import → row count 일치 확인.

### 8-6. 알림 채널 점검

- 매주 옵션 A/B/C 채널에 *지난 7일 신청 수 = Slack/메일 도착 수* 비교.
- 어긋나면 Database → Webhooks → 로그 확인.

---

## 9. 환경변수 명세

### 9-1. `landing/.env.example` 갱신

```bash
# ============================================================
# Supabase (signups 수집)
# Settings → API에서 복사. anon key는 클라 노출 안전 (RLS 활성).
# service_role key는 *절대* 여기에 넣지 말 것 — Dashboard에서만.
# ============================================================
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=public-anon-key

# ============================================================
# PostHog (제품 분석) — landing-analytics-engineer가 추가
# ============================================================
VITE_POSTHOG_KEY=phc_...
VITE_POSTHOG_HOST=https://us.i.posthog.com

# ============================================================
# Hash Salt — 이메일 → posthog_distinct_id 양 시스템 공통 hash
# 변경 시 모든 기존 매칭이 끊긴다. 한 번 정하면 고정.
# ============================================================
VITE_HASH_SALT=replace-with-random-32-byte-string

# ============================================================
# (이전) Web3Forms — §5 마이그 패스에 따라 결정
#   - 패스 A 점진: 1주일 유지 후 제거
#   - 패스 B 즉시: 지금 제거 (행 전체 삭제)
# ============================================================
# VITE_W3FORMS_KEY=
```

### 9-2. GitHub Repo Secrets 등록

GitHub repo `chew_tracking` → **Settings → Secrets and variables → Actions** → **New repository secret**:

| Name | 값 출처 | 용도 |
|---|---|---|
| `VITE_SUPABASE_URL` | Supabase Settings → API → Project URL | 빌드 인라인 |
| `VITE_SUPABASE_ANON_KEY` | Supabase Settings → API → anon public | 빌드 인라인 |
| `VITE_POSTHOG_KEY` | PostHog → Project settings | (analytics 라운드) |
| `VITE_POSTHOG_HOST` | PostHog → Project settings | (analytics 라운드) |
| `VITE_HASH_SALT` | 로컬에서 `openssl rand -hex 32` | (analytics 라운드) |
| ~~`VITE_W3FORMS_KEY`~~ | 패스 B 컷오버 시 **삭제** | — |

`.github/workflows/deploy-landing.yml`의 build 스텝에서 `env:` 블록에 위 secret을 매핑 (analytics 에이전트와 합의).

---

## 10. 트러블슈팅 — 자주 만나는 에러

| 증상 | 원인 | 대응 |
|---|---|---|
| 클라 콘솔 `[supabase] env missing — submissions disabled` | `.env` 또는 GitHub Secret 미등록 | §9 등록 후 빌드 재실행 |
| INSERT 시 PostgREST `42501` (RLS denied) | `signups_insert_anon` 정책 누락 또는 `with check` 위반 | §3 정책 재실행 + payload의 email 형식 확인 |
| INSERT 시 `23505` (duplicate key) | 같은 email_lower로 살아있는 row가 이미 존재 | UI는 "이미 신청해주셨어요" 안내, 또는 `.upsert()`로 갱신 |
| Webhook이 Slack에 안 옴 | Database → Webhooks → 해당 hook → Recent deliveries 로그 확인 | URL 오타 or Slack webhook 만료. Slack 측 재발급. |
| `consent_at out of allowed window` 에러 | 클라 시계 5분 이상 어긋남 | §2 트리거 의도된 거부. 클라이언트가 `new Date().toISOString()`로 보내면 정상 |
| 갑자기 모든 INSERT 502 | 7일 비활성 일시정지 | Dashboard 들어가 unpause + §8-4 cron 설정 |

---

## 합의 포인트 (analytics-engineer와)

본 라운드에서 PostHog 통합을 별도 설계 중인 `landing-analytics-engineer` 에이전트와 다음 5가지를 *동일 값*으로 맞춘다.

### 1) PostHog ↔ Supabase 데이터 분리

| 데이터 | Supabase | PostHog | 비고 |
|---|---|---|---|
| 이메일 (PII) | ✅ `email`, `email_lower` | ❌ 절대 X (PII 차단) | PostHog는 hash만 |
| 식별 hash | ✅ `posthog_distinct_id` | ✅ `distinct_id` | 양쪽 동일 값 |
| 가입 의도 (`purpose`) | ✅ `purpose` | ✅ `properties.purpose` | enum 값 동일 |
| 출시 알림 동의 | ✅ `consent_marketing` + `consent_at` + `consent_version` | ✅ `properties.consent_marketing` (true일 때만 identify) | 거절 시 PostHog identify 미호출 |
| utm 파라미터 | ✅ `utm_source/medium/campaign` | ✅ `$initial_utm_*` (PostHog 자동) | 두 쪽 다 보관 |
| 페이지 방문·스크롤 | ❌ | ✅ | PostHog 책임 |
| 영구 보관 (회수 요청 후 30일 hard delete) | ✅ `deleted_at` SOP | ✅ `delete_person` API | §6 SOP 동시 호출 |

### 2) distinctId hash 공식

```typescript
// 양 시스템 동일 — landing/src/lib/identity.ts에 단일 함수로 export
import { sha256 } from 'js-sha256' // 또는 web crypto subtle

export async function distinctIdFromEmail(email: string): Promise<string> {
  const salt = import.meta.env.VITE_HASH_SALT
  const normalized = email.trim().toLowerCase()
  // Web Crypto subtle.digest 사용 (외부 라이브러리 불필요):
  const data = new TextEncoder().encode(normalized + salt)
  const hashBuffer = await crypto.subtle.digest('SHA-256', data)
  return Array.from(new Uint8Array(hashBuffer))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('')
}
```

→ `submitSignup`은 이 함수의 결과를 `posthog_distinct_id` 컬럼에 저장 + PostHog `identify(distinctId, {...})`도 동일 값으로 호출.

### 3) `purpose` enum 값 — 고정

| 값 | UI 라벨 (한국어) | 두 시스템 공통 |
|---|---|---|
| `diet` | 다이어트 | ✅ |
| `digestion` | 소화/위장 | ✅ |
| `other` | 기타 | ✅ |

라벨은 자유롭게 바뀌어도 enum 값은 절대 변경 X (`alter type`로 추가만 가능).

### 4) 컨센트 거절 시 분기

| 사용자 액션 | Supabase | PostHog |
|---|---|---|
| ConsentDialog → 동의 ✅ | INSERT (`consent_marketing=true`, `consent_at=now()`) | `posthog.identify(distinctId, {purpose, consent_at})` 호출 |
| ConsentDialog → 거절 (제출은 함) | INSERT (`consent_marketing=false`, `consent_at=null`) | `posthog.identify` 미호출. anonymous 이벤트만 |
| ConsentDialog → 취소 (제출 X) | INSERT 없음 | `track('consent_dismissed')` (anonymous) |

### 5) 환경변수 통합

§9-1 `.env.example` 1개 파일에 Supabase + PostHog + hash salt 모두 모음. 두 에이전트가 같은 `.env.example`을 갱신 (중복 없이).

---

## 자체 검증 체크리스트

작성자 셀프 통과:
- [x] DDL이 Postgres 15+ syntactically valid (`gen_random_uuid()` Supabase 기본 제공, `generated always as ... stored` 지원, enum 문법 정상)
- [x] RLS `alter table signups enable row level security;` 1줄 + INSERT 정책 + SELECT 차단 정책 명시 — 누락 0
- [x] persona enum = `landing/src/data/personas.ts`의 `stomach`/`diet`/`checkup` 정확히 일치 (+ `unknown` 디폴트)
- [x] "service_role" 키워드는 *오직* "절대 클라이언트 X" 또는 "Dashboard에서만" 맥락에서 등장. 클라이언트 코드/`.env.example`/GitHub Secrets 표에 `service_role` 0건
- [x] purpose enum 값 = `diet`/`digestion`/`other` (사용자 요구 명세 그대로)
- [x] 옵션 G 톤 — 의료 약속·과장 0건. 카피 예시("출시되면 알려드릴게요", "그만 받고 싶으시면 답장만") 정직 어조
- [x] 마이그 권장 = 패스 B + 재동의 메일 (베타 트래픽 적음 가정)
- [x] 알림 채널 권장 = 옵션 A Database Webhook → Slack (셋업 ~10분, 외부 자원 1개)

---

## 핵심 결정 요약 (한 줄)

- **테이블:** 단일 `signups` 18컬럼 (PK + email + email_lower + purpose + persona + consent 3종 + source + utm 3종 + user_agent + posthog_distinct_id + created/updated/deleted_at).
- **enum 2종:** `purpose(diet/digestion/other)` + `persona(stomach/diet/checkup/unknown)` — `personas.ts`와 정합.
- **RLS:** 활성, 정책 2개(anon INSERT + 모든 SELECT 차단), UPDATE/DELETE 자동 deny.
- **마이그 권장:** 패스 B (즉시 컷오버) + 기존 가입자 재동의 메일.
- **알림 권장:** 옵션 A Database Webhook → Slack.
- **클라 코드:** `lib/dataCollection.ts`를 supabase-js로 갈아끼움 + `lib/identity.ts`로 hash 단일화.
- **운영 위험 1순위:** Free 플랜 7일 비활성 일시정지 → UptimeRobot 5분 핑으로 회피.
