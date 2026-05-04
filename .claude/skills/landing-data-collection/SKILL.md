---
name: landing-data-collection
description: 정적 호스팅(GitHub Pages·Vercel·Netlify·Cloudflare Pages 등) 랜딩 페이지에서 *백엔드 없이 또는 BaaS 기반으로* 이메일·웨이트리스트·피드백·사용자 목적·옵트인 컨센트를 수집하는 옵션 비교·스키마 설계·RLS·보안 검토·구현·운영 가이드 방법론. 노션 API, 구글 스프레드시트, Formspree, Web3Forms, Getform, Tally, Basin, Resend, Loops, Buttondown, EmailOctopus, Beehiiv 같은 가벼운 옵션 + Supabase, Firebase, Pocketbase 같은 BaaS 옵션을 모두 다룬다. "이메일 받게 해줘", "폼 백엔드", "웨이트리스트 받기", "백엔드 없이 데이터 수집", "노션으로 폼 받기", "구글시트 폼", "Formspree 연결", "Supabase 연결", "Supabase 백엔드", "데이터베이스로 받기", "옵트인 동의 추가", "마케팅 컨센트", "출시 시 연락 동의", "사용자 목적 수집", "다이어트/위염 분류" 같은 요청에서 반드시 사용. 후속: "수신처 바꿔줘", "Supabase로 마이그", "스팸 막아줘", "폼 운영 가이드 다시", "한도 늘려줘", "RLS 정책", "컨센트 추가" 같은 표현에서도 트리거.
---

# Landing Data Collection — 백엔드리스 데이터 수집

정적 호스팅 환경에서 폼 데이터를 안전하게 받기 위한 옵션 매핑·구현 패턴·운영 가이드를 제공한다.

## 핵심 원칙 (왜 이 룰이 있는가)

### 1. 정적 호스팅에서 비밀은 없다

GitHub Pages·Vercel static·Netlify static·Cloudflare Pages — 이 환경에서 사용하는 모든 환경변수(`VITE_*`, `NEXT_PUBLIC_*`)는 빌드 시 *클라이언트 번들에 인라인된다*. `dist/assets/index-*.js` 안에 텍스트로 박힌다는 뜻이다.

→ 권한이 강한 키(노션 Internal Integration Token, SendGrid API Key, Slack Webhook의 일부)는 절대 클라이언트에서 사용하지 않는다. 이런 키가 필요하면 *경량 서버리스 함수*(Cloudflare Workers free, Vercel Functions, Netlify Functions)를 1개 두어 토큰을 서버에 숨긴다 — 이는 "별도 백엔드"가 아닌 "함수 1개"로 해석한다.

→ 권한이 *제한된* 토큰만 갖는 서비스(Formspree form ID, Web3Forms access key, Tally form ID)는 클라이언트 노출이 안전 — 이 키는 그 폼에 데이터를 넣는 권한만 있고 다른 데이터를 읽지 못한다.

### 2. CORS는 우회하지 않는다

CORS 차단은 의도된 보안 기능이다. 노션 공식 API(`api.notion.com`)는 일반적으로 브라우저 직접 호출을 허용하지 않는다 (`Access-Control-Allow-Origin` 미설정). 이를 보고 "CORS 프록시를 쓰자"고 결론내는 것은 잘못 — 프록시는 토큰 노출을 그대로 둔 채 브라우저 정책만 우회한다. 옳은 결론은 *그 옵션을 포기하거나, 서버리스 함수를 1개 둔다*.

### 3. 무료 한도는 오늘 실측

"Formspree free 50/month", "Tally free unlimited" 같은 숫자는 분기마다 변한다. 추천하기 직전에 공식 가격 페이지를 *반드시* 재확인한다 (지식 컷오프 이후 변경 가능성). 추천안과 보고서에는 *확인 일자*를 적는다.

### 4. 수신 가시성이 없으면 의미가 없다

이메일이 시트나 노션 DB에 떨어지기만 하고 사용자가 일주일 동안 안 보면 베타 피드백 사이클이 깨진다. **수신 → 알림** 경로를 1개 이상 만든다 (Slack webhook, Telegram bot, daily digest mail, 핸드폰 푸시 등). 사용자가 매일 보는 채널을 우선.

### 5. 옵션 G 톤은 폼에서도 지킨다

성공 메시지·확인 메일 카피에서 의료 약속·가짜 권위·KOL 영입 표현 0건. 톤 디폴트:
- 성공: "합류해주셔서 감사해요. 진행 소식을 보내드릴게요."
- 확인 메일 제목: "[Chew Coach] 베타 합류 확인"
- 본문: "지원해주셔서 감사해요. 베타 빌드가 준비되면 가장 먼저 알려드려요. 언제든 답장으로 의견 주셔도 좋아요." (의료 효과 약속 X, 출시 시점 단정 X)

### 6. 컨센트는 데이터 모델로 박는다

마케팅 옵트인은 *카피 한 줄*로 끝나지 않는다. DB에 다음 3개 컬럼이 *반드시* 존재해야 GDPR/PIPA 호환:

| 컬럼 | 타입 | 의미 |
|------|------|------|
| `consent_marketing` | `boolean` | 출시 시 연락 동의 여부 |
| `consent_at` | `timestamptz` | 동의한 시각 (UTC) |
| `consent_version` | `text` | 동의 시점의 약관 버전 (예: `'2026-05-04'`) |

**거절 시에도 row는 저장**하되 `consent_marketing=false`로 — 이유: 같은 사용자가 다시 신청해도 *상태를 알 수 있게*. 단 마케팅 발송 대상에서 제외. 사용자가 회수 요청 시 즉시 row 삭제(또는 `deleted_at` 소프트 삭제 후 30일 cron으로 hard delete) — 정책을 운영 가이드에 명시.

UX 흐름: 폼 제출 직전 컨센트 다이얼로그 표시 → 체크박스 기본 ON ("출시되면 이메일로 알려드릴게요") + 약관·개인정보 처리 안내 링크 → [확인]/[취소]. 거절도 OK — 거절해도 신청은 처리됨을 명시.

### 7. PII는 분석 시스템에 흐르지 않는다 — 역할 분리

영구 백엔드(Supabase)와 분석(PostHog)의 데이터 책임이 다르다:

| 데이터 | 영구 백엔드 (Supabase) | 분석 (PostHog) |
|--------|----------------------|---------------|
| 이메일 본문 | ✅ source of truth | ❌ 절대 X |
| `purpose`, `persona`, `consent_marketing` | ✅ 영구 row | ✅ event property + identify trait |
| 페이지뷰·세션·funnel | ❌ | ✅ |
| distinctId (hash) | ✅ (연결용) | ✅ |

같은 데이터를 양쪽에 *중복 저장하지 않는다*. 분석 시스템은 hash(email + salt)로 식별하고 *원본 이메일은 보내지 않는다*. 사용자 삭제 요청은 두 시스템 *양쪽*에서 — Supabase row 삭제 + PostHog `delete_person` API. 이 합의는 `landing-analytics-engineer`와 함께 만든다.

### 8. 목적 enum은 고정값

다이어트/위염/기타를 구분하려면 컬럼에 enum-style 표준 값을 사용:

| 값 | 의미 | UI 라벨 (예시) |
|----|------|--------------|
| `diet` | 체중 관리·식사 속도 줄이기 | "체중·식습관 관리" |
| `digestion` | 소화불량·위염·역류 등 위장 문제 | "소화 문제 개선" |
| `other` | 그 외 (마음챙김 식사·호기심 등) | "기타 / 둘 다" |

UI 라벨은 카피라이터 재량으로 바뀌어도, *DB 값(`diet`/`digestion`/`other`)은 고정* — historical 분석·세그멘테이션 가능성.

---

## 옵션 카탈로그 (정적 호스팅 적합도)

각 옵션을 5축으로 평가한다. 매트릭스 형식 — 추천 보고서에 그대로 옮겨 쓸 수 있도록 설계.

| 축 | 측정 | 디폴트 임계값 |
|----|------|-----------|
| **키 노출 안전성** | 클라이언트 번들에 노출되는 토큰의 권한 범위 | 타 데이터 읽기 불가 |
| **CORS 호환** | 브라우저에서 fetch 가능 | preflight 통과 |
| **무료 한도** | 월 제출 수 / 저장 한도 / 알림 한도 | 베타 단계 1k/월 충분 |
| **운영 부하** | 가입·세팅·유지보수 시간 | 30분 이내 셋업 |
| **가시성** | 수신 알림/대시보드 옵션 | Slack·메일 알림 가능 |

### Tier A: 권장 디폴트 (단순 이메일 수집·웨이트리스트)

세 개를 표 형태로 비교한 뒤, 해당 프로젝트 맥락에 맞춰 1개 선택.

#### Formspree
- **키 노출**: 폼 ID만 클라이언트에 (안전).
- **CORS**: AJAX 엔드포인트 공식 지원.
- **무료 한도**: 월 50건 (가입 직후 확인 필요 — 지난 분기 공식 가격표). 한도 초과 시 폼이 막힘 (이메일 receipt만 발송).
- **운영**: 폼 생성 → endpoint URL 복사 → fetch 한 번. 30분 이내.
- **가시성**: 즉시 이메일 알림 + 대시보드 + Slack/Zapier 연동.
- **약관 비고**: GDPR/CCPA 처리 가능, 한국 사용자 데이터를 미국 서버에 보관 — 처리위탁 고지 필요.
- **추천 시나리오**: 베타 웨이트리스트 < 50/월. 운영 가시성을 가장 빠르게 얻고 싶을 때.

#### Web3Forms
- **키 노출**: `access_key` (해당 폼만 데이터 push 권한).
- **CORS**: 공식 지원.
- **무료 한도**: 월 250건 (가입 시 확인). 무제한 폼.
- **운영**: 이메일만으로 가입 → access_key 받음 → fetch. 15분.
- **가시성**: 수신 메일 알림(즉시) + JSON webhook 연동.
- **약관 비고**: 데이터를 자기 서버에 저장하지 않는다고 표방 (메일 즉시 forward). 유럽 거주자에게도 적합.
- **추천 시나리오**: Formspree 한도가 빠듯할 때, 이메일 수신만 필요할 때 (DB 대시보드는 없음).

#### Tally
- **키 노출**: 폼 ID만.
- **CORS**: 자체 호스팅 폼은 iframe/popup, REST endpoint도 있음.
- **무료 한도**: 무제한 응답 (지난 분기 공식 — 재확인 필요).
- **운영**: 노션·디자인 친화적 UI. 자체 호스팅 폼이지만 iframe 임베드가 표준 — 커스텀 디자인이 강하면 부적합.
- **가시성**: 대시보드 + 노션·구글시트·Slack 연동 (네이티브).
- **추천 시나리오**: 폼이 *짧지만 여러 필드*가 있을 때. 이메일 1줄만 필요한 본 케이스에는 살짝 무겁다.

### Tier B: 노션 / 구글시트 — *서버리스 함수 1개 필요*

사용자가 노션·구글시트로 받기를 *명시적으로 요청한 경우*. 다음 두 가지 패턴 중 선택.

#### 패턴 B-1: Cloudflare Worker(또는 Vercel/Netlify Function) + 노션 API
- **아키텍처**: 브라우저 → POST `/api/signup` (Worker 엔드포인트) → 서버에서 NOTION_TOKEN으로 노션 DB row 생성 → 응답.
- **키 노출**: NOTION_TOKEN을 Worker secret에 저장. 클라이언트에는 Worker URL만.
- **CORS**: Worker가 `Access-Control-Allow-Origin`을 응답 도메인으로 명시. preflight 처리.
- **무료 한도**: Cloudflare Workers free 100k req/day (충분). 노션 API 사실상 무제한.
- **운영**: 노션 DB 생성 (`Email`, `Source`, `CreatedAt`, `IP` 컬럼) → Internal Integration 생성 → DB에 connect → Worker 배포 (30~60분 셋업).
- **가시성**: 노션 DB가 곧 대시보드. Slack/메일 알림은 노션 자동화 또는 Worker 안에서 추가.
- **추천 시나리오**: 사용자가 노션 워크스페이스 운영 중이고 *문의 분류·태깅·연락 상태 추적*까지 폼 데이터로 하고 싶을 때. 마케팅·CS·세일즈가 노션을 보고 있는 팀.

#### 패턴 B-2: Google Apps Script Web App + 구글 스프레드시트
- **아키텍처**: 브라우저 → POST Apps Script doPost(e) endpoint → 시트 row 추가 → 응답.
- **키 노출**: 비밀 없음. Apps Script URL은 공개이지만 그 시트에 *append만* 가능 (읽기 불가). URL이 노출돼도 스팸 push만 가능 — rate limit과 honeypot으로 방어.
- **CORS**: Apps Script가 자체 CORS 응답 — 단 `Anyone (even anonymous)` 배포 옵션이 필수. preflight 미지원이므로 simple POST(`text/plain` content-type)만 사용 → fetch에서 `body: JSON.stringify(...)` + `Content-Type: 'text/plain;charset=utf-8'` 설정.
- **무료 한도**: 일 트리거 6시간 / 6분 실행, 하지만 폼 1건당 ms 단위 — 사실상 무제한.
- **운영**: 시트 생성 → Extensions > Apps Script → 코드 붙여넣기 → "Web App으로 배포 (anonymous)" → URL 복사 (15분).
- **가시성**: 시트 자체. Apps Script 안에서 `MailApp.sendEmail(...)` 한 줄로 즉시 이메일 알림 추가 가능.
- **추천 시나리오**: 가장 가벼운 노코드 옵션. 사용자가 구글 계정만 있으면 됨. 토큰 관리 0개.

### Tier B+: BaaS — Supabase / Firebase (구조화된 데이터 + 컨센트·목적 컬럼이 필요할 때)

이메일 한 줄이 아니라 *목적·컨센트·페르소나*까지 받아 분석에 쓰려면 BaaS가 적합하다. 단순 폼 옵션은 컬럼 확장·RLS·SQL 쿼리·삭제 요청 처리가 부족하다.

#### Supabase (권장 BaaS)

- **키 노출**: `anon` 키만 클라이언트에. `service_role`은 절대 X. anon은 RLS와 한 세트 — RLS 없이 anon은 위험.
- **CORS**: 공식 지원 (`*.supabase.co`).
- **무료 한도**: DB 500MB, Auth 50k MAU, Edge Functions 500k invocations/월. *7일 비활성 시 일시 정지* (베타에서는 거의 영향 없음 — 가입 트래픽 있으면 active).
- **운영**: 프로젝트 생성 → 테이블 생성 → RLS 정책 → anon 키 받기 → `@supabase/supabase-js` 통합. 30~60분 셋업.
- **가시성**: Table Editor + SQL editor + Database Webhook (Supabase 자체) 또는 Edge Function + Slack webhook으로 즉시 알림.
- **추천 시나리오**: 다음 중 *하나라도* 해당하면 Supabase:
  - 사용자 목적(`diet`/`digestion`/`other`)·페르소나·컨센트 같은 *구조화된 컬럼*이 필요
  - 마케팅 옵트인 동의 시점·버전 트래킹이 필요 (GDPR/PIPA)
  - 사용자 데이터 삭제 요청을 정기적으로 처리해야 함
  - 향후 본 제품의 백엔드도 Supabase를 쓸 계획 (단일 인프라)
  - 베타 → 프로덕션으로 데이터를 가져갈 가능성

→ 상세 스키마·RLS·구현 패턴은 `references/supabase-integration.md` 참조 (스키마 DDL, RLS 정책 SQL, supabase-js 통합 코드, 마이그레이션 가이드 포함).

#### Firebase (대안)
- 거의 동등한 무료 플랜. Firestore document 모델은 SQL이 아니므로 *후속 SQL 분석*이 어렵다. Supabase가 PostgreSQL이라 마이그·분석·CRM 연동에 유리.
- 사용자가 이미 Firebase를 다른 곳에서 쓰고 있다면 자연스러움. 그 외에는 Supabase 권장.

### Tier C: 마케팅 자동화 (확인 메일·시퀀스가 필요할 때)

#### Loops / Buttondown / EmailOctopus / Beehiiv
- 폼 수집 + 자동 확인 메일 + 이후 마케팅 캠페인을 한 번에 운영하고 싶을 때. 베타 단계 < 100명에서는 과한 조합.
- 추천 시나리오: 베타 1k명 이상 + 주간 뉴스레터 발송 의도가 *이미* 있을 때. 본 프로젝트 현재 단계에서는 *부차*.

### Tier D: 안티 패턴 (선택 금지)

- **노션 API 직접 클라이언트 호출** — CORS 차단 + 토큰 노출. 무조건 거른다.
- **구글 폼 임베드 iframe** — 디자인 일관성 0, 옵션 G 톤 위반. 거른다.
- **mailto: 링크** — 메일 클라이언트가 없는 사용자(대부분의 모바일 사용자)에게 작동 안 함. 거른다.
- **Firebase Realtime DB write rules `true`** — 클라이언트가 DB에 직접 쓰기. 인증 없으면 누구나 데이터 dump 가능 — 거른다.

---

## 의사결정 트리

```
구조화된 데이터(목적·페르소나·컨센트·utm)가 필요하다
  → Tier B+ (Supabase 권장)
  → 컬럼 자유, RLS, SQL 분석, 마이그 가능
  → references/supabase-integration.md 따름

사용자가 노션을 매일 보고 있다 + 폼 데이터 분류·태깅을 노션에서 한다
  → 패턴 B-1 (Worker + 노션)
  → 단, 사용자가 Cloudflare/Vercel 계정을 만들 수 있어야 한다

사용자가 구글 계정을 갖고 있고 운영 가시성을 시트로 받고 싶다
  → 패턴 B-2 (Apps Script + 시트)
  → 가장 가벼운 셋업, 토큰 0개

사용자가 가장 빠르게 셋업 + 즉시 이메일 알림이면 충분 (이메일 1줄만)
  → Web3Forms (월 250건)
  또는 Formspree (월 50건 + 대시보드)

월 1k건 이상 + 자동 확인 메일 + 시퀀스
  → Tier C로 이동 (Loops 권장)
```

**선택 기준 요약:**
- *컬럼 1개 (이메일만)* + 운영 가벼움 → Web3Forms / Formspree
- *컬럼 2~3개* + 사용자가 노션·시트 운영 중 → Tier B (Worker+노션 / Apps Script+시트)
- *컬럼 4개+* (목적·컨센트·페르소나·utm) + SQL 분석 + 향후 백엔드도 같은 인프라 → **Supabase**

---

## 구현 패턴

### 패턴 1: 단순 fetch (Tier A 옵션)

```typescript
// landing/src/lib/dataCollection.ts
type SubmitResult = { ok: true } | { ok: false; reason: 'rate-limit' | 'network' | 'invalid' }

export async function submitEmail(payload: {
  email: string
  source: string  // 'hero' | 'final-cta' | 'footer' — 어느 폼에서 들어왔는지
  // honeypot — 봇이 채우면 차단
  _gotcha?: string
}): Promise<SubmitResult> {
  if (payload._gotcha) return { ok: true }  // 봇에는 성공으로 응답 (분석 스파이 차단)
  if (!payload.email.includes('@')) return { ok: false, reason: 'invalid' }

  try {
    const res = await fetch(import.meta.env.VITE_FORM_ENDPOINT, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
      body: JSON.stringify(payload),
    })
    if (res.status === 429) return { ok: false, reason: 'rate-limit' }
    if (!res.ok) return { ok: false, reason: 'network' }
    return { ok: true }
  } catch {
    return { ok: false, reason: 'network' }
  }
}
```

`EmailForm.tsx`에서 `setTimeout` placeholder를 `submitEmail({ email, source: variant })`로 교체. `.env.example`에 `VITE_FORM_ENDPOINT=https://...` 추가.

### 패턴 2: Apps Script + Sheet (B-2)

#### Apps Script 코드 (Apps Script editor에 붙여넣기)

```javascript
// Code.gs
const SHEET_ID = 'PUT_SHEET_ID_HERE'
const NOTIFY_EMAIL = 'PUT_OWNER_EMAIL_HERE'

function doPost(e) {
  try {
    const data = JSON.parse(e.postData.contents)
    if (data._gotcha) return jsonOk()  // 봇 차단

    const email = String(data.email || '').trim()
    if (!email.includes('@') || email.length > 200) return jsonErr('invalid')

    const sheet = SpreadsheetApp.openById(SHEET_ID).getSheetByName('signups')
    sheet.appendRow([new Date(), email, data.source || '', data.userAgent || ''])

    // 즉시 알림 — 매일 1회 digest로 바꾸려면 별도 trigger
    MailApp.sendEmail({
      to: NOTIFY_EMAIL,
      subject: '[Chew Coach] 새 베타 신청 — ' + email,
      body: 'Source: ' + (data.source || '') + '\nTime: ' + new Date().toISOString(),
    })

    return jsonOk()
  } catch (err) {
    return jsonErr('server')
  }
}

function jsonOk() {
  return ContentService.createTextOutput(JSON.stringify({ ok: true })).setMimeType(ContentService.MimeType.JSON)
}
function jsonErr(reason) {
  return ContentService.createTextOutput(JSON.stringify({ ok: false, reason })).setMimeType(ContentService.MimeType.JSON)
}
```

배포: Deploy > New deployment > Web App > Execute as `Me` / Who has access `Anyone`. URL 복사.

#### 클라이언트 fetch — CORS 우회 핵심

Apps Script Web App은 preflight를 보내면 차단된다. simple request 조건을 만족시키기 위해 `Content-Type: text/plain;charset=utf-8`로 보낸다 — body는 JSON 문자열이지만 헤더만 text/plain으로 속이는 표준 트릭.

```typescript
await fetch(import.meta.env.VITE_FORM_ENDPOINT, {
  method: 'POST',
  // ❌ application/json은 preflight 발생 → CORS 차단
  headers: { 'Content-Type': 'text/plain;charset=utf-8' },
  body: JSON.stringify(payload),
  redirect: 'follow',  // Apps Script는 302 응답을 보냄 — follow 필요
})
```

### 패턴 3: Cloudflare Worker + 노션 API (B-1)

```javascript
// worker.js
export default {
  async fetch(request, env) {
    const cors = {
      'Access-Control-Allow-Origin': env.ALLOWED_ORIGIN,  // 'https://chew-coach.com'
      'Access-Control-Allow-Methods': 'POST,OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    }
    if (request.method === 'OPTIONS') return new Response(null, { headers: cors })
    if (request.method !== 'POST') return new Response('Method not allowed', { status: 405, headers: cors })

    const body = await request.json()
    if (body._gotcha) return Response.json({ ok: true }, { headers: cors })

    const email = String(body.email || '').trim()
    if (!email.includes('@') || email.length > 200) {
      return Response.json({ ok: false, reason: 'invalid' }, { status: 400, headers: cors })
    }

    // 노션 API
    const r = await fetch('https://api.notion.com/v1/pages', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${env.NOTION_TOKEN}`,
        'Notion-Version': '2022-06-28',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        parent: { database_id: env.NOTION_DB_ID },
        properties: {
          Email: { title: [{ text: { content: email } }] },
          Source: { rich_text: [{ text: { content: body.source || '' } }] },
          CreatedAt: { date: { start: new Date().toISOString() } },
        },
      }),
    })
    if (!r.ok) return Response.json({ ok: false, reason: 'server' }, { status: 502, headers: cors })
    return Response.json({ ok: true }, { headers: cors })
  },
}
```

Secrets: `NOTION_TOKEN`, `NOTION_DB_ID`, `ALLOWED_ORIGIN`. `wrangler secret put NOTION_TOKEN`으로 설정.

---

## 보안·운영 체크리스트

배포 전 반드시 확인 (각 항목 통과 시 ☑).

- [ ] `git grep -E "secret|service_role|private" landing/src` — 비밀 토큰이 소스에 없는 것 확인
- [ ] (Supabase 채택 시) `service_role` 키는 *어디에도* 없음. anon 키만 클라이언트에.
- [ ] (Supabase 채택 시) RLS 활성화 + anon `SELECT` 거부 — 익명 사용자가 data dump 불가
- [ ] 빌드 후 `grep -ri "<TOKEN_VALUE>" landing/dist` — dist 번들에 비밀 토큰 없음 (B 패턴·Supabase service_role 모두)
- [ ] `.env.example`은 커밋, `.env`는 `.gitignore`에 — 키가 GitHub에 푸시되지 않는다
- [ ] honeypot 필드 (`_gotcha`)가 폼에 *시각적으로 숨김* + `tabindex={-1}` + `aria-hidden="true"`
- [ ] 클라이언트 검증 (이메일 형식, 길이 200자 이하)
- [ ] 종단간 1건 제출 → 수신처 도착 (스크린샷) + 모든 컬럼 채워짐 (`email`, `purpose`, `consent_marketing`, `consent_at`, `consent_version`)
- [ ] 컨센트 거절 시나리오 — `consent_marketing=false`로 row 저장됨 + 분석 측 identify 미호출
- [ ] 중복 이메일 — 동일 이메일 재제출 시 사용자에게 success → DB는 갱신 (또는 dedupe 처리)
- [ ] 폼 에러 시 사용자 메시지 — `rate-limit / network / invalid / duplicate` 각각 친근한 한국어
- [ ] 개인정보 처리 안내 카피: "수집 항목: 이메일·목적·동의 / 목적: 베타 진행 소식 / 보관: 베타 종료 시 또는 회수 요청 시 삭제 / 문의: [메일]"
- [ ] 옵션 G 톤 — 성공 메시지·컨센트 카피에 의료 약속·KOL·"전문가 추천" 0건

---

## 운영 가이드 템플릿 (`08_data_collection_runbook.md`에 채우기)

```markdown
# 데이터 수집 운영 가이드

## 어디서 보나요
[수신처 링크 / 접속 경로]

## 알림은 어디로 오나요
[Slack / 메일 / 핸드폰 — 1개 이상]

## 데이터를 export 하려면
[단계별 절차]

## 한도 모니터링
- 현재 무료 한도: [예: Formspree 50/월]
- 80% 도달 시 어떻게 알게 되나요: [서비스 알림 / 수동 점검 주기]
- 한도 초과 시 폼 동작: [실패 응답 → 사용자에게 보이는 메시지]

## 사용자가 데이터 삭제를 요청하면
[수신처에서 row 삭제 절차 + 응답 SLA]

## 폼이 안 작동할 때 (서비스 장애)
[감지 방법 / fallback 카피 / 임시 우회]
```

---

## 최종 산출물 체크리스트

이 스킬 사용 종료 시 다음이 *모두* 존재해야 한다:

- [ ] `_workspace/landing/07_data_collection_options.md` — 비교표 + 추천 + *오늘 확인한 무료 한도*
- [ ] `_workspace/landing/08_data_collection_runbook.md` — 운영 가이드 (수신처·알림·삭제 요청 절차 포함)
- [ ] (Supabase 채택 시) `_workspace/landing/12_supabase_schema.md` — DDL + RLS + Webhook + 마이그레이션 패스
- [ ] `landing/src/lib/dataCollection.ts` (또는 동등) — 실제 fetch/SDK 호출 코드 + 컨센트·purpose 처리
- [ ] (Supabase 채택 시) `landing/src/lib/supabaseClient.ts` — `@supabase/supabase-js` init
- [ ] `landing/src/components/EmailForm.tsx` — 목적 선택 UI + 컨센트 흐름 + 실제 호출 + 에러 처리
- [ ] `landing/src/components/ConsentDialog.tsx` (신규, 컨센트 도입 시)
- [ ] `landing/.env.example` — 필요 환경변수 + 주석 (Supabase URL/anon key 또는 W3Forms key 등)
- [ ] (옵션 B 사용 시) `landing/server/` 또는 `worker/` 서버리스 함수 코드 + 배포 가이드
- [ ] 종단간 테스트 스크린샷 (수신처 도착 확인 + 모든 컬럼 채워짐)
- [ ] 컨센트 거절 시나리오 검증 (별도 스크린샷 또는 테스트 결과)
