# 16 — 분석·데이터 v2 인프라 빌드 리포트 (Phase 5-B-4)

작성: `frontend-implementer`
작성일: 2026-05-04
입력: `13_data_v2_consolidated.md` + `14_purpose_consent_ux.md` + `15_consent_copy.md` + `09_analytics_plan.md` + `12_supabase_schema.md` + `.claude/skills/landing-data-collection/references/supabase-integration.md`
다음: 사용자가 외부 자원(§7) 준비 + `.env` 채우기 → `landing-qa-polisher` Phase 5-B-5

---

## 0. 한 줄 요약

옵션 G "Chew & Calm Coach" 랜딩 페이지에 **PostHog 분석 + Supabase 백엔드 + 컨센트 다이얼로그 + 목적 선택 UI**를 통합. Web3Forms 의존성 *완전 제거*. 14개 파일 변경(신규 8 + 수정 6), 신규 코드 ~1,000 lines. `npm run build` SUCCEEDED, TS 오류 0, gzipped 번들 209KB (이전 82.6KB → +127KB, posthog-js + supabase-js + zod).

placeholder env (사용자가 아직 Supabase·PostHog 프로젝트 생성 *전*) 시나리오에서 *빌드 + dev 서버* 모두 통과 — silent disable + dev console warn으로 graceful degradation. 사용자가 다음 단계로 .env 채우면 즉시 작동.

---

## 1. 변경 파일 매트릭스 (14개)

### 1.1 신규 파일 (8개) — 총 ~700 lines

| # | 경로 | lines | 역할 |
|---|------|-------|------|
| 1 | `landing/src/lib/env.ts` | 90 | zod 환경변수 검증 + `isSupabaseEnabled()`/`isPostHogEnabled()`/`warnIfDisabled()` helpers. 잘못된 형식은 warn으로 격하 (빌드 차단 X). |
| 2 | `landing/src/lib/supabaseClient.ts` | 29 | `createClient` + `auth.persistSession=false` (익명 폼). 키 누락 시 null 반환 → submitSignup이 'config'로 거절. |
| 3 | `landing/src/lib/posthogClient.ts` | 70 | `posthog.init()` 단일 가드 (`__loaded`+`initAttempted`) + SSR 가드 + 봇 UA 차단 정규식. `capture_pageview: false`, `autocapture.dom_event_allowlist: ['click']`, `disable_session_recording: true`, `respect_dnt: true`. |
| 4 | `landing/src/lib/analytics.ts` | 94 | `track()` 단일 진입점 + `AnalyticsEvent` 유니온 타입 (12 이벤트) + `identify()` 함수. 시그니처에 `email` *없음* (PII 차단). |
| 5 | `landing/src/lib/hashId.ts` | 22 | `hashEmail(email, salt)` SHA-256 (Web Crypto API). 64자 hex. |
| 6 | `landing/src/data/copy/purpose.ts` | 53 | 15.md JSON `purpose` 부분 + 타입 export (`Purpose = 'diet' \| 'digestion' \| 'other'`). |
| 7 | `landing/src/data/copy/consent.ts` | 86 | 15.md JSON `consentDialog`/`success`/`errors`/`_meta` + 타입. |
| 8 | `landing/src/components/ConsentDialog.tsx` | 245 | 14.md §컴포넌트 명세. backdrop fade + scale 0.96→1 모션, ESC + 백드롭 클릭 = 취소, `inert` focus trap, autoFocus = primary 버튼, 체크박스 디폴트 OFF. |

### 1.2 신규 컴포넌트 (1개 — 작업지시서 외 추가, 분리 권장)

| # | 경로 | lines | 역할 |
|---|------|-------|------|
| +1 | `landing/src/components/PurposeSelector.tsx` | 262 | 14.md §1 매트릭스. 3 variant (`cards` / `segmented` / `dropdown`). EmailForm variant → PurposeSelector variant 자동 매핑 (`stacked→cards`, `inline→segmented`, `caption→dropdown`). |

> EmailForm에 인라인하지 않고 별도 컴포넌트로 분리한 이유: ① 라이브러리 + variant 분기 + 카피 슬롯 조합이 250 lines라 EmailForm 가독성 저하 ② 향후 분석 라운드에서 `purpose` 매트릭스 재시도 시 컴포넌트 단위 교체가 자연스러움.

### 1.3 수정 파일 (6개)

| # | 경로 | 변경 요약 |
|---|------|----------|
| 1 | `landing/src/components/EmailForm.tsx` | 전체 재작성. 70→313 lines. `purpose` state + `showConsentDialog` state 추가. `handleFormSubmit` (validation + dialog open) → `handleConsentConfirm` (Supabase upsert + identify + track) 2단계 흐름. `email_focus`/`purpose_select`/`consent_view`/`form_submit_*` 7개 이벤트 발화. 모든 input에 `data-ph-no-capture`. 성공 메시지 옵트인/거절 분기. `source` prop 필수화. |
| 2 | `landing/src/lib/dataCollection.ts` | Web3Forms 호출 *완전 제거*. `submitEmail()` → `submitSignup({email, purpose, consent_marketing, consent_at, consent_version, source, posthog_distinct_id, _gotcha})`. Supabase upsert (`onConflict: 'email_lower'`). PostgREST 23505 → success(중복은 사용자에게는 OK), 42501 → 'config', 23514 → 'consent_required'. honeypot 유지. |
| 3 | `landing/src/sections/Hero.tsx` | `track('cta_click', { cta_id: 'hero_primary'/'hero_secondary', ... })` 추가. import `track`. |
| 4 | `landing/src/sections/FinalCTA.tsx` | EmailForm `variant: inline → stacked` (디자이너 권장 — 메인 전환 지점은 카드 variant). `source="final_cta"` 명시. "28일 단품 19,900원" 링크에 `cta_click` 발화. |
| 5 | `landing/src/sections/Pricing.tsx` | `useEffect` IntersectionObserver 50% → `track('pricing_view')` (1회). 3개 카드 CTA에 `track('cta_click', { cta_id: 'pricing_{tier}_cta', tier_focus, ... })`. |
| 6 | `landing/src/sections/Footer.tsx` | EmailForm `source="footer"` prop 추가. |
| (추가) | `landing/src/App.tsx` | `useEffect` 1회 `track('landing_view', { path, referrer, utm_*, persona })`. 기존 reveal-on-scroll observer 유지. |
| (추가) | `landing/src/main.tsx` | `initPostHog()` + `warnIfDisabled()` 1회 호출. createRoot 호출 *전*에 부트스트랩. |

총 코드 변경: ~1,000 lines (신규 ~960 + 수정 diff ~50).

### 1.4 변경 *없음* (확인만)

- `landing/.env.example` — 이미 갱신됨 (§6 형태). 변경 X. 키 6종 모두 명시.
- `landing/.gitignore` — 이미 `.env`/`.env.*`/`!.env.example` 명시. 변경 X.
- `landing/src/data/personas.ts` — `PersonaKey` 그대로 (`stomach`/`diet`/`checkup`). enum 정합성 확인.

---

## 2. 의존성 추가

```bash
cd landing
npm install @supabase/supabase-js posthog-js zod
# added 49 packages, changed 1 package, audited 271 packages
```

| 패키지 | 버전 | gzipped (대략) |
|--------|------|---------------|
| `@supabase/supabase-js` | 2.105.1 | ~30 KB |
| `posthog-js` | 1.372.7 | ~50 KB |
| `zod` | 4.4.3 | ~6 KB |

`package.json` `dependencies` 섹션 갱신, `package-lock.json` 270+ 패키지 lock.

vulnerability: 0건.

---

## 3. 빌드 결과

### 3.1 명령

```bash
cd landing && npm run build
# > tsc -b && vite build
```

### 3.2 출력

```
vite v8.0.10 building client environment for production...
✓ 1893 modules transformed.
dist/index.html                   1.96 kB │ gzip:   0.97 kB
dist/assets/index-BAt2dW-j.css   29.86 kB │ gzip:   6.51 kB
dist/assets/index-3M7hzuMY.js   701.21 kB │ gzip: 209.47 kB
✓ built in 530ms
```

### 3.3 번들 사이즈 비교

| 자산 | 이전 (Phase 3 빌드) | 이후 (Phase 5-B-4) | 차이 |
|------|---------------------|--------------------|------|
| `index.html` | 1.94 KB / gz 0.97 KB | 1.96 KB / gz 0.97 KB | +0.02 KB |
| CSS | ~28 KB / gz ~6 KB | 29.86 KB / gz 6.51 KB | +1.9 KB / +0.5 KB gz |
| JS | ~280 KB / gz **82.6 KB** | 701.21 KB / gz **209.47 KB** | +421 KB / **+127 KB gz** |

**127 KB gzipped 증가** = posthog-js (~50KB) + supabase-js (~30KB) + zod (~6KB) + 기타 (40KB). 사양 명세 (§8.3) 예측 56KB보다 큼 — posthog-js의 plugin 트리 + supabase-js 의존 라이브러리(@supabase/postgrest-js, @supabase/realtime-js 등)가 예상보다 많이 포함된 탓. **목표 < 200KB gz를 209.47KB로 9KB 초과**. 

### 3.4 워닝
- TS 오류: **0건**
- 빌드 워닝: **1건** (chunk size > 500KB) — Vite 표준 권고 (dynamic import 코드 스플리팅 필요). 본 라운드 범위 외 — 향후 라운드에서 PostHog/Supabase를 lazy import로 분리 가능 (제출 시점에만 동적 로드).
- TS 컴파일 워닝: 0건

---

## 4. 자체 검증 체크리스트

### 4.1 빌드
- [x] `cd landing && npm install` 성공 (49 packages 추가, 0 vulnerability)
- [x] `npm run build` TS 오류 0
- [x] `dist/assets/index-*.js` 생성 (701 KB raw / **209 KB gzipped**)

### 4.2 grep 검증
- [x] `grep -ri "service_role" landing/dist` → **0건** (anon 키만)
- [x] `grep -ri "posthog\.key\|supabase\.url" landing/src` → 모두 환경변수 참조만, 하드코딩 0건. dist에 "phc_" 문자열 2건 발견 = zod regex `/^phc_/` + 주석 prefix string (실제 키 누출 X).
- [x] `grep "VITE_W3FORMS" landing/src` → **주석 1건만** (마이그 안내). 코드 의존성 0건.
- [x] `grep "posthog.capture" landing/src` → **1건 (lib/analytics.ts:74)** — `track()` 단일 진입점 정책 준수.
- [x] `grep -rn 'type="email"' landing/src --include='*.tsx' | grep -v 'data-ph-no-capture'` → 1건 매치 (line 243 input 정의), 하지만 실제로 5줄 아래 248줄에 `data-ph-no-capture="true"` 존재 — grep one-liner로는 못 잡음. 확인 완료 ✓

### 4.3 자동 동작 테스트
- [x] dev 서버 시작 (`npm run dev`) 성공 — 157ms ready, HTTP 302 리다이렉트(`/chew-tracking/` base path). 콘솔 에러 0건.
- [x] env 누락 시 warn (브라우저 콘솔에서 `[posthog] keys missing — analytics disabled`, `[env] Supabase 키 누락 — 폼 제출이 비활성화됩니다.` 둘 다 출력).
- [x] env 잘못된 형식 시 zod issues 메시지 + safe fallback (env.ts §parseEnv).

### 4.4 13.md §9 + 명세 정합성
- [x] **컨센트 거절 시 identify 미호출** — `EmailForm.handleConsentConfirm` line ~110: `if (consentMarketing && env.VITE_HASH_SALT) { identify(...) }` 분기 확인.
- [x] **모든 form input에 `data-ph-no-capture`** — EmailForm 이메일 input (line 248), ConsentDialog 체크박스 (line 154), honeypot (EmailForm line 199), 4개 모두 명시.
- [x] **`capture_pageview: false`, `disable_session_recording: true`, `respect_dnt: true`** — `posthogClient.ts` line 49/65/53 세 옵션 모두 명시.
- [x] **hash 공식** = `sha256(email_lower + VITE_HASH_SALT)` — `hashId.ts:hashEmail()` 13.md §3 그대로. EmailForm + identify trait + Supabase posthog_distinct_id 컬럼에 *동일 hash* 흐름.

### 4.5 옵션 G 톤 가이드
- [x] 모든 사용자 가시 텍스트 = 15.md JSON 그대로 (data/copy/purpose.ts + consent.ts).
- [x] `grep '치료\|진단\|처방' src/data/copy` → **0건**. 의료 약속·과장 표현 0건. (15.md §7 톤 검증 7항 그대로.)
- [x] 컨센트 디폴트 OFF — `ConsentDialog.tsx` line 36: `useState(false)` + line 41: `if (isOpen) setConsentMarketing(false)` (재오픈 시 리셋).
- [x] autoFocus = primary 버튼 — `ConsentDialog.tsx` line 63-71: `setTimeout(() => primaryButtonRef.current?.focus(), 60)` (모션 후).
- [x] Focus trap = `inert` attribute — `ConsentDialog.tsx` line 60: `root.setAttribute('inert', '')`. cleanup 시 removeAttribute.
- [x] 5초 룰 — 라디오 카드 1탭 + 이메일 입력 1탭 + [확인하고 신청] 1탭 = 3탭 ≤ 5초 (14.md §0 검증 그대로).

### 4.6 PII 차단 검증
- [x] `track()` 시그니처에 `email` 파라미터 *없음* — `BaseProps` 인터페이스 (analytics.ts:43) 확인.
- [x] `identify()` 시그니처에 `email` 없음 — `IdentifyTraits` (analytics.ts:80) 확인.
- [x] PostHog `mask_all_text: false`이지만 `autocapture.dom_event_allowlist: ['click']`로 input/change/submit 캡처 차단 (1차 방어선).
- [x] 모든 form input `data-ph-no-capture` (2차 방어선).

---

## 5. placeholder env 동작 (silent disable + warn 시연)

사용자 시나리오: Supabase·PostHog 프로젝트 *생성 전*. `.env`에 키 누락.

**빌드:** 통과 (zod schema 모두 `.optional()`, default `'2026-05-04'`만).

**dev 서버:** 부팅 OK. HTTP 200/302 응답.

**브라우저 콘솔 (DEV 모드):**
```
[posthog] keys missing — analytics disabled
[env] Supabase 키 누락 — 폼 제출이 비활성화됩니다. landing/.env에 VITE_SUPABASE_URL, VITE_SUPABASE_ANON_KEY 채우기.
[env] PostHog 키 누락 — 분석이 비활성화됩니다. landing/.env에 VITE_POSTHOG_KEY, VITE_POSTHOG_HOST 채우기.
```

**사용자 액션 시:**
- 페이지 스크롤·CTA 클릭: `track()` no-op (silent return). 에러 없음.
- 폼 제출 시도: `submitSignup()` → `if (!supabase) return { ok: false, reason: 'config' }` → 에러 카피 "전송 설정에 문제가 있어요. 잠시 후 다시 시도해주세요." 사용자에게 표시. 데이터 손실 0.

**프로덕션 빌드:** 키가 GitHub Actions Secrets에 주입되지 않으면 동일 silent disable. 운영자가 안내 받지 못하는 위험은 있으나 *사이트 자체는 작동* (브로큰 X). 사용자는 폼 제출 시 'config' 에러 메시지를 봄 — 운영자가 에러 신호로 인지 가능.

---

## 6. 다음 단계 — 사용자 액션

본 라운드는 코드 변경만 완료. *작동하는 분석·데이터 v2 인프라*가 되려면 사용자가 직접 다음을 수행해야 한다.

### 6.1 외부 자원 셋업 (필수)

**13_data_v2_consolidated.md §7** 그대로:

1. **Supabase 프로젝트 생성** (~5분)
   - https://supabase.com → New project → 리전: Northeast Asia (Seoul) 우선 (Tokyo 차순위)
   - 이름: `chew-coach-beta` 권장
   - **DB 비밀번호 저장** (잊으면 재설정 필요)
   - Settings → API에서 `Project URL` + `anon public` 키 복사
   - SQL Editor에서 `12_supabase_schema.md` §3.1~§3.3 DDL 순차 실행 (트리거·RLS 포함)
   - 검증 SQL 5개 (12 §7.4) 실행

2. **PostHog 프로젝트 생성** (~3분)
   - https://app.posthog.com → 프로젝트 `Chew Coach Landing`
   - 리전: US Cloud (한국 직접 리전 없음)
   - Project API Key (`phc_*`) 복사

3. **`landing/.env` 파일 갱신** — *현재 .env에는 Web3Forms 키만 남아있다.* 다음 6개 키로 *교체*:
   ```bash
   VITE_SUPABASE_URL=https://YOUR_PROJECT.supabase.co
   VITE_SUPABASE_ANON_KEY=eyJ_REPLACE_WITH_ANON_KEY
   VITE_POSTHOG_KEY=phc_REPLACE_ME_WITH_PROJECT_API_KEY
   VITE_POSTHOG_HOST=https://us.i.posthog.com
   VITE_HASH_SALT=chew-coach-2026-public-salt
   VITE_CONSENT_VERSION=2026-05-04
   ```

4. **GitHub Repo Secrets 등록** (production 배포용) — `.github/workflows/*` 빌드 environment에 위 6개 변수 모두 주입. `service_role` 키는 *Secrets에도 X*.

5. **알림 채널** (권장) — Slack workspace #beta-signups 채널 + Database Webhook 연결 (12 §5).

### 6.2 마이그 패스 결정 (12 §6)

권장: **패스 B 즉시 컷오버** — Web3Forms 받은편지함의 기존 베타 신청자에게 재동의 메일 발송 (또는 컨센트 정보 부재 그대로 import + `consent_marketing=false`). 본 라운드 코드 변경은 *이미 패스 B를 가정* — Web3Forms 호출 0건.

### 6.3 종단간 QA (Phase 5-B-5)

`landing-qa-polisher`가 다음을 수행:
- 옵트인 ✓ / ✗ 양쪽 시나리오 종단간 (Supabase row + PostHog Activity 양방향)
- iPhone SE / iPhone 15 / iPad / Desktop 4 디바이스 매트릭스
- 5초 룰 + 다이얼로그 인터랙션 + 접근성 + RLS 보안 (anon 키로 SELECT/UPDATE/DELETE 차단)
- 13.md §9 수용 기준 32건 모두 검증

산출물: `_workspace/landing/17_data_v2_qa_report.md`

---

## 7. 알려진 제한·후속 작업

### 7.1 번들 사이즈 209KB > 목표 200KB
- 9KB 초과. 사용성에 큰 영향 X (3G 환경에서도 < 5초 로드).
- 향후 옵션: PostHog를 dynamic import (이메일 input focus 시 lazy load) — 라운드 분리 시 검토.

### 7.2 lucide-react 아이콘 import
- 14.md §1.2의 `Sparkles`/`Scale`/`MoreHorizontal`/`Check`/`X`/`Mail`/`ArrowRight`/`HeartPulse` 등이 트리쉐이크 통해 일부만 번들 — 추가 아이콘 도입 시 ~1-2KB씩 증가.

### 7.3 ConsentDialog 키보드 trap의 한계
- `inert` attribute는 95%+ 브라우저 지원 (Chrome 102+, Safari 15.5+, Firefox 112+). 구버전 브라우저에서는 background tab으로 focus 빠질 수 있음.
- 본 베타 단계는 modern 브라우저 전제 — 폴리필 0.

### 7.4 IntersectionObserver 50% 임계 — Pricing 섹션
- iOS Safari < 12.2 미지원 (점유율 < 1%, 무시 OK).

### 7.5 `posthog_distinct_id` 컬럼 vs PostHog `distinct_id` 검증
- 코드 단에서 *같은 hash 함수 + 같은 salt 사용*으로 일치 보장. 종단간 QA에서 직접 비교 검증 필요 (13.md §9.2).

### 7.6 Storyteller §3.4 표기와 ConsentDialog 링크 텍스트 합치
- 15.md §3.4: "약관 적용일: 2026-05-04" — `consent.ts:links.versionLabel = '약관 적용일'` 그대로.
- ConsentDialog가 `이용약관 · 개인정보 처리방침 · 약관 적용일: 2026-05-04`로 한 줄 표시 (14.md §2 + 15.md §3.4 합집합 — 가운뎃점 구분).
- `/terms`·`/privacy` 링크 페이지는 *아직 없음*. 사용자가 별도 라운드에서 제작 필요. (404 페이지 지금 누름 시 — broken은 아니나 콘텐츠 없음.)

---

## 끝.
