-- ============================================================
-- Chew Coach Landing — signups 스키마 + RLS v1 (2026-05-04)
-- ============================================================
-- 사용법:
--   1. Supabase Dashboard → SQL Editor → New query
--   2. 이 파일 전체를 복사해서 붙여넣기
--   3. 우측 하단 [Run] 버튼 클릭
--   4. 끝에 "Success. No rows returned" 보이면 성공
--
-- 멱등성: 한 번 실행 후 재실행 시 'already exists' 에러 — 정상.
-- ============================================================

-- ───────────────────────────────────────────────
-- §2. 테이블 스키마
-- ───────────────────────────────────────────────

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
  source               text,
  utm_source           text,
  utm_medium           text,
  utm_campaign         text,
  user_agent           text,
  posthog_distinct_id  text,
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now(),
  deleted_at           timestamptz
);

-- 3. 인덱스
create unique index signups_email_lower_unique
  on signups (email_lower)
  where deleted_at is null;

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

-- 6. 코멘트
comment on table signups is 'Chew Coach 베타 랜딩 가입자. RLS 활성, anon INSERT만 허용.';
comment on column signups.email_lower is 'lower(email) generated stored — unique 키. 대소문자 무관 중복 방지.';
comment on column signups.purpose is '사용자가 폼에서 고른 목적: 다이어트/소화/기타.';
comment on column signups.persona is '방문자가 본 랜딩 variant. landing/src/data/personas.ts와 일치.';
comment on column signups.consent_marketing is '출시 알림 동의. false면 row는 저장하되 마케팅 발송 X.';
comment on column signups.posthog_distinct_id is 'sha256(email_lower + VITE_HASH_SALT). PostHog 동일 hash와 매칭.';

-- ───────────────────────────────────────────────
-- §3. RLS 정책 — 반드시 위 DDL 직후 같은 SQL Editor에서 이어 실행
-- ───────────────────────────────────────────────

alter table signups enable row level security;

-- INSERT: anon 허용. 검증을 정책에 박아 클라이언트 trust 최소화.
create policy signups_insert_anon
  on signups for insert
  to anon
  with check (
    email is not null
    and length(email) between 5 and 200
    and email like '%@%.%'
    and (consent_marketing = false or consent_at is not null)
  );

-- SELECT: 모든 비-service_role 차단.
create policy signups_select_block
  on signups for select
  to anon, authenticated
  using (false);

-- UPDATE/DELETE는 정책 미정의 = 자동 deny. service_role(Dashboard)만 통과.

-- ───────────────────────────────────────────────
-- §3.1. 검증 — 위 DDL이 끝난 후 별도 쿼리로 실행해서 통과 확인
-- ───────────────────────────────────────────────

-- 검증 1: RLS 활성 확인 (rowsecurity = true 기대)
-- select tablename, rowsecurity from pg_tables where schemaname='public' and tablename='signups';

-- 검증 2: 정책 목록 (insert_anon + select_block 2개)
-- select policyname, cmd, roles from pg_policies where tablename='signups';

-- 검증 3: anon으로 SELECT 시도 (0행 또는 권한 거부 기대)
-- set role anon;
-- select * from signups;
-- reset role;

-- 검증 4: anon으로 정상 INSERT (성공 기대)
-- set role anon;
-- insert into signups (email, purpose, source) values ('test@example.com', 'diet', 'qa_check');
-- reset role;
-- select count(*) from signups;  -- 1 기대

-- 검증 5: anon으로 잘못된 enum INSERT (에러 기대)
-- set role anon;
-- insert into signups (email, purpose) values ('bad@example.com', 'wrong_value');  -- enum 에러
-- reset role;
