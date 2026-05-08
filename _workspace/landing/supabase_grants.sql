-- ============================================================
-- Chew Coach — anon role grants 보강 (2026-05-04)
-- ============================================================
-- 사유:
--   PostgreSQL은 RLS와 별도로 *table-level GRANT*가 필요하다.
--   Supabase가 SQL로 직접 만든 테이블에는 자동 grant를 안 한다.
--   → anon이 INSERT를 시도하면 RLS 정책 평가 전에 권한 단계에서 막힌다.
--
-- 사용법:
--   Supabase Dashboard → SQL Editor → New query → 아래 전체 붙여넣고 Run
-- ============================================================

-- 1. schema 사용 권한
grant usage on schema public to anon, authenticated;

-- 2. signups 테이블 권한
--    - anon: INSERT만 (RLS의 with check가 추가 검증)
--    - authenticated: INSERT만 (현재 미사용이지만 미래 확장용)
--    - SELECT/UPDATE/DELETE는 grant 안 함 → service_role만 가능
grant insert on signups to anon, authenticated;

-- 3. enum 타입 사용 권한
grant usage on type purpose to anon, authenticated;
grant usage on type persona to anon, authenticated;

-- 4. (옵션) 기본 권한 — 이후 새 테이블에 자동 적용 (선택)
-- alter default privileges in schema public
--   grant insert on tables to anon, authenticated;

-- ============================================================
-- 검증 — 실행 후 메인 에이전트가 anon 키로 다시 9-step 검증
-- ============================================================
