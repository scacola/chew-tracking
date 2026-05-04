# 10 — Consent Strategy (GDPR / PIPA 호환)

작성: `landing-analytics-engineer` 에이전트
작성일: 2026-05-04
대상 라운드: Phase 5-B 분석/데이터 v2 인프라
관련: `_workspace/landing/09_analytics_plan.md` (이벤트 카탈로그·식별 정책), `landing-data-collector` Supabase 스키마

## 본 라운드 컨텍스트

옵션 G "Chew & Calm Coach" 베타 신청 폼에 *마케팅 옵트인 동의*를 받는다. 사용자 요구: "출시되면 다시 연락드린다는 동의를 받아야 한다." GDPR + 한국 정보통신망법(이하 PIPA·정통망법) 호환 + 옵션 G 톤(의료 약속 0건·정직성 우선)을 모두 충족한다. 본 라운드는 *수집*만 책임지고 *발송*은 별도 에이전트·라운드의 책임이다 — 경계를 분명히.

## ToC
1. 다이얼로그 흐름 (ASCII 다이어그램)
2. 컨센트 분리 — 익명 분석 vs 마케팅 식별
3. 카피 디폴트 (옵션 G 톤)
4. 약관 버전 관리
5. 컨센트 회수 절차 (SOP)
6. 법적 호환 — GDPR / PIPA / 정통망법
7. 옵트인률을 funnel KPI로 추적
8. 합의 포인트 (collector와)

---

## 1. 다이얼로그 흐름 — ASCII 다이어그램

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. 사용자가 EmailForm에 도착                                      │
│    track('email_focus', { source })  ← 첫 focus 시 1회           │
│    autocapture: { dom_event_allowlist: ['click'] } 로 input X    │
└────────────────────────────┬────────────────────────────────────┘
                             ↓
┌─────────────────────────────────────────────────────────────────┐
│ 2. 사용자가 이메일 + 목적(다이어트/소화/기타) 입력                  │
│    [purpose 라디오 변경 시] track('purpose_select', { purpose })  │
└────────────────────────────┬────────────────────────────────────┘
                             ↓
┌─────────────────────────────────────────────────────────────────┐
│ 3. 사용자가 [베타에 합류하기] 버튼 클릭                             │
│    → 클라이언트 검증 (email, purpose 둘 다 있는지)                  │
│       NG → 인라인 에러 표시 (다이얼로그 X)                          │
│       OK → 다음 단계                                               │
└────────────────────────────┬────────────────────────────────────┘
                             ↓
┌─────────────────────────────────────────────────────────────────┐
│ 4. ConsentDialog 표시                                            │
│    track('consent_view', { consent_version: '2026-05-04' })     │
│                                                                  │
│    ┌──────────────────────────────────────────────────────┐    │
│    │  출시되면 이메일로 알려드릴게요                         │    │
│    │                                                       │    │
│    │  베타 빌드가 준비되면 가장 먼저 소식을 보내드려요.       │    │
│    │  진행 외 광고는 보내지 않고, 언제든 [수신거부]로         │    │
│    │  그만두실 수 있어요.                                   │    │
│    │                                                       │    │
│    │  ☑ 출시 소식 받기 (선택)                              │    │
│    │     → 체크 시: marketing 옵트인 동의                   │    │
│    │     → 미체크 시: 익명 분석만, 마케팅 발송 X              │    │
│    │                                                       │    │
│    │  [개인정보 처리방침] [수신거부 안내]                     │    │
│    │                                                       │    │
│    │  [취소]                            [확인하고 신청]      │    │
│    └──────────────────────────────────────────────────────┘    │
└──────────────┬──────────────────────────────────┬──────────────┘
               │                                  │
       [취소]  ↓                                  ↓  [확인하고 신청]
┌──────────────────────────┐    ┌─────────────────────────────────┐
│ 다이얼로그 닫힘             │    │ 5. Supabase에 row 저장          │
│ 폼은 그대로 유지 (재시도 OK) │    │   { email, purpose, source,    │
│ 이벤트 발화 안 함            │    │     consent_marketing,         │
│                          │    │     consent_at, consent_version, │
└──────────────────────────┘    │     posthog_distinct_id }        │
                                │                                  │
                                │   track('form_submit_try',       │
                                │     { source, purpose })          │
                                └────────────┬─────────────────────┘
                                             ↓
                              ┌──────────────────────────────┐
                              │ Supabase 응답 분기              │
                              └──┬─────────────────┬──────────┘
                                 │                 │
                          [4xx/5xx]         [200 OK]
                                 ↓                 ↓
                  ┌──────────────────────┐  ┌─────────────────────────┐
                  │ track('form_submit_  │  │ 6. (옵트인=true 시만)    │
                  │   fail',             │  │   posthog.identify(      │
                  │   { error_reason })  │  │     hashEmail(email),    │
                  │ 인라인 에러 표시       │  │     { purpose,           │
                  └──────────────────────┘  │       consent_marketing, │
                                            │       consent_at,        │
                                            │       consent_version,   │
                                            │       persona })         │
                                            │                         │
                                            │   (옵트인=false 시:       │
                                            │    identify 호출 X,      │
                                            │    anonymous 유지)        │
                                            └────────────┬────────────┘
                                                         ↓
                                       ┌────────────────────────────────┐
                                       │ track('form_submit_success',    │
                                       │   { source, purpose,            │
                                       │     consent_marketing,          │
                                       │     consent_version })          │
                                       │                                 │
                                       │ UI: 성공 메시지 표시              │
                                       │ "합류해주셔서 감사해요. 진행      │
                                       │  소식을 보내드릴게요."            │
                                       └────────────────────────────────┘
```

### 흐름의 5가지 강제 사항

1. **다이얼로그는 검증 통과 후에만 표시** — 빈 폼/잘못된 이메일에는 인라인 에러, 다이얼로그 X (사용자 마찰 최소화)
2. **체크박스는 *선택* (기본 체크 OFF)** — GDPR/PIPA의 *명시적 옵트인* 원칙. 디폴트 체크는 dark pattern.
3. **거절해도 신청은 처리** — 사용자가 "마케팅은 싫지만 신청은 하고 싶다"는 분기를 분명히 지원. 거절자는 Supabase에는 저장되지만 마케팅 발송 대상에서 제외.
4. **옵트인 시만 PostHog identify** — 거절자는 anonymous 유지. distinctId hash가 PostHog에 식별 연결되는 시점은 *명시적 동의 직후만*.
5. **취소 버튼은 폼을 유지** — 다이얼로그를 닫고 폼은 그대로. 사용자가 "다시 생각하고 옵트인 체크 후 재제출"할 수 있게.

---

## 2. 컨센트 분리 — 익명 분석 vs 마케팅 식별

GDPR/PIPA는 *목적별 동의 분리*를 요구한다. 본 프로젝트는 두 가지 동의를 구분한다:

| 동의 종류 | 필수 여부 | 거절 가능 | 영향 |
|---------|---------|---------|------|
| **익명 분석** (페이지뷰·클릭·funnel) | 필수 (기능 동작에 필요) | 불가 — 단 `respect_dnt: true`로 DNT 헤더 사용자는 자동 차단 | 거절 시 페이지 작동은 가능하나 분석 0 |
| **마케팅 식별·발송 동의** | 선택 | 가능 — 거절해도 신청은 처리 | 거절 시 PostHog identify X, 마케팅 메일 X |

### 2.1 익명 분석은 왜 "필수"라 부르는가

PostHog가 발화하는 `landing_view`, `cta_click`, `form_submit_success` 같은 이벤트는 *기기 식별 가능 정보가 없는 anonymous 행동 분석*이다. PIPA는 익명·통계 처리를 광범위하게 허용한다 (개인정보보호법 제3장 제17조의2). 단:
- IP 주소 raw 저장은 X (PostHog 자동 geo 추정만)
- session replay는 OFF (PII 위험)
- DNT 헤더 사용자는 자동 차단 (`respect_dnt: true`)

이 조건 하에서 *별도 동의 다이얼로그 없이* 익명 분석을 진행한다. 단 개인정보 처리방침에 명시 (§6.2).

### 2.2 마케팅 식별·발송은 왜 "선택"인가

이메일 + 마케팅 동의 = 정통망법 제50조의 광고성 정보 수신 동의. *명시적 사전 동의* 필수. 거절 가능해야 함.

코드 분기:

```typescript
// 옵트인 시
if (consent_marketing === true) {
  const distinctId = await hashEmail(email, env.VITE_HASH_SALT)
  identify(distinctId, {
    purpose,
    consent_marketing: true,
    consent_at: new Date().toISOString(),
    consent_version: env.VITE_CONSENT_VERSION,
    persona,
  })
}
// consent_marketing === false: identify 호출 안 함 (anonymous 유지)

// 양쪽 모두 form_submit_success는 발화
track('form_submit_success', {
  source,
  purpose,
  consent_marketing, // boolean
  consent_version: env.VITE_CONSENT_VERSION,
})
```

### 2.3 Session Replay는 별도 컨센트

본 라운드는 session replay OFF. 향후 켤 경우 *별도 컨센트 다이얼로그*를 띄워야 한다 (마케팅 옵트인과 분리). 현재 라운드 범위 외.

---

## 3. 카피 디폴트 (옵션 G 톤)

옵션 G 톤 가이드 위반 0건 — 의료 약속 / 과장 / 가짜 권위 / KOL 영입 표현 0건. 친근한 한국어, 정직한 약속.

### 3.1 다이얼로그 헤드 (제목)

> **출시되면 이메일로 알려드릴게요**

대안 (A/B 테스트 시도 가능):
- "베타 신청을 마무리할게요"
- "진행 소식, 어떻게 받으시겠어요?"

핵심: *결과 약속(체중 감량·치유)이 아닌 행동 약속(소식 발송)*을 헤드에 배치.

### 3.2 본문 (2-3문장)

```
베타 빌드가 준비되면 가장 먼저 소식을 보내드려요.
진행 외 광고는 보내지 않고, 언제든 [수신거부]로 그만두실 수 있어요.
1만 명이 합류했다고 거짓말하지 않아요. 함께 걸을 첫 사람들을 모으고 있어요.
```

세 문장의 의도:
1. **약속 명확화**: 무엇을 보낼지 *구체적으로* — "진행 소식". 광고/판촉/제휴는 X.
2. **거부 권한 보장**: 수신거부 링크가 *모든* 발송 메일에 들어간다는 약속.
3. **정직성**: "1만 명 합류" 같은 가짜 사회 증거를 *의도적으로 거부*한다는 시그널 — 옵션 G 톤의 핵심.

### 3.3 체크박스 라벨

> ☐ **출시 소식 받기 (선택)**

대안:
- "출시되면 이메일 알림 받기"
- "진행 소식 받아보기"

핵심:
- *기본 체크 OFF* — GDPR/PIPA의 명시적 동의 원칙. 디폴트 체크는 dark pattern.
- "(선택)" 명시 — 거절해도 신청 처리됨을 헤드라인에서 알림
- 짧음 — 클릭 결정에 5초 이내

### 3.4 약관·정책 링크

체크박스 아래 작은 글씨:
> [개인정보 처리방침] [수신거부 안내] · 약관 버전 2026-05-04

링크 디자인은 `visual-experience-designer` 검토. 회색 underline-offset, 클릭 가능 충분 크기 (48×48 hit area).

### 3.5 버튼 라벨

| 버튼 | 라벨 | 의미 |
|------|------|----|
| Primary | **확인하고 신청** | 옵트인 여부와 무관하게 신청 진행 |
| Secondary | **취소** | 다이얼로그 닫고 폼 유지 |

### 3.6 성공 토스트 (form_submit_success)

옵트인 분기:

```
[옵트인=true]
✓ 합류해주셔서 감사해요. 출시 소식이 준비되면 가장 먼저 보내드릴게요.

[옵트인=false]
✓ 신청을 받았어요. 진행 소식은 보내지 않지만, 출시되면 사이트에서 만나요.
```

거절자에게도 *친근하게* — 거절했다는 이유로 톤이 차가워지지 않게.

### 3.7 수신거부 안내 페이지 카피

`/unsubscribe` 또는 모든 마케팅 메일의 footer:
```
구독을 취소하려면 [여기를 누르세요].
또는 1213sam0@gmail.com로 "구독 취소"라고 보내주세요.
24시간 안에 처리하고, 처리 완료 시 마지막 메일 1건을 보내드려요.
```

### 3.8 옵션 G 톤 검증

작성된 카피에 다음이 *없어야* 함:
- ❌ "효과 보장", "체중 감량", "위염 치료", "다이어트 성공" — 의료/효과 약속
- ❌ "AI 기반", "혁신적인", "차세대", "스마트한" — 과장 마케팅 표현
- ❌ "전문가 추천", "의사 인증" (실제 의료 전문가 영입 전) — 가짜 권위
- ❌ "한정 1000명", "오늘만 무료" (사실이 아니면) — 가짜 희소성
- ❌ "독점 베타" (사실이 아니면) — 가짜 차별화

검증: 본 §3 카피를 `marketing-storyteller`가 검토. 변경 시 §4 약관 버전 갱신.

---

## 4. 약관 버전 관리

### 4.1 본 라운드 도입 버전

| 항목 | 값 |
|------|---|
| `consent_version` | `'2026-05-04'` (ISO date) |
| 본 버전의 효력 발생 | 2026-05-04 본 라운드 배포 시점 |
| 이전 버전 | 없음 (본 라운드가 컨센트 도입 첫 라운드) |

### 4.2 버전 변경 트리거

다음 변경 시 `consent_version` 갱신 필수 (날짜를 새 ISO date로):
1. 다이얼로그 본문 카피 *의미* 변경 (단순 오타 수정은 X)
2. 마케팅 발송 범위 변경 (예: "진행 소식만" → "진행 소식 + 신제품 안내")
3. 데이터 처리 항목 변경 (예: 새 PostHog property, 새 Supabase 컬럼)
4. 위탁 처리자 변경 (예: PostHog → Mixpanel 마이그레이션)

### 4.3 버전 변경 시 이전 동의자 처리

**원칙**: 이전 버전 동의는 *새 버전에 자동 전이되지 않는다*. PIPA 원칙: 동의는 시점 + 약관 버전과 묶임.

| 상황 | 처리 |
|------|----|
| 단순 카피 다듬기 (의미 동일) | 버전 그대로 유지, 이전 동의자 영향 없음 |
| 의미 있는 변경 | 새 버전 부여. 이전 동의자에게 *재동의 요청 메일* 발송. 응답 없으면 발송 보류 (단, 응답 *없음*은 거절로 간주하지 않음 — 단순 미응답은 보수적으로 *발송 중지* 처리) |
| 처리 항목 추가 (예: 새 컬럼) | 새 버전 + 재동의 요청 |

이는 본 라운드 범위 외 (미래 라운드의 마케팅 발송 에이전트 책임).

---

## 5. 컨센트 회수 절차 (SOP)

사용자가 "내 데이터를 지워주세요" 요청 시 SOP. PIPA 제36조 (개인정보 정정·삭제)에 따라 30일 이내 처리 의무.

### 5.1 접수 채널

- 이메일: `1213sam0@gmail.com` (현재 운영자 컨택)
- 향후: 사이트 내 `/unsubscribe` 페이지 + Supabase Edge Function

### 5.2 접수 시 처리 순서

```
[1] 사용자 이메일 수신 → 본인 확인 (가입 시 이메일과 일치 확인)
                       ↓
[2] hash 계산: distinctId = sha256(email.lower() + SALT)
                       ↓
[3] Supabase 처리:
    옵션 A (soft-delete, 권장): UPDATE signups
                                SET deleted_at = NOW(),
                                    email = NULL,           -- PII 즉시 삭제
                                    consent_marketing = false
                                WHERE email_normalized = lower(trim($1))
    옵션 B (hard-delete): DELETE FROM signups WHERE email_normalized = ...
                       ↓
[4] PostHog 처리:
    a. opt_out_capturing 처리 (이미 발화한 이벤트는 그대로)
    b. delete_person API 호출 — distinctId의 모든 person property + future capture 차단
       POST https://us.i.posthog.com/api/projects/<id>/persons/<distinctId>/delete/
       Authorization: Bearer <PERSONAL_API_KEY>  ← server-side only
                       ↓
[5] 사용자에게 처리 완료 메일 1건 발송 (마지막 메일):
    "요청하신 데이터 삭제를 처리했어요. 더 이상 메일을 보내드리지 않을게요. 감사했어요."
                       ↓
[6] 처리 로그 저장 (별도 audit 테이블 — Supabase `deletion_audit`)
    { requested_at, processed_at, distinct_id_hash, processed_by }
```

### 5.3 PostHog `delete_person` API

PostHog Personal API Key는 *서버 사이드*에서만 사용. 클라이언트 번들에 절대 X.

운영 옵션:
- **A) 수동**: 운영자가 PostHog 콘솔에서 직접 person 검색 → delete (현재 베타 단계 적합)
- **B) Supabase Edge Function**: hash를 받아 PostHog API 호출 (트래픽 증가 시)

본 라운드는 옵션 A — 수동. 월 100건 미만 트래픽에서는 충분.

### 5.4 처리 시한

| 채널 | SLA | 사유 |
|------|----|------|
| Supabase row 처리 | 24시간 | 운영자 수동 처리 가능 범위 |
| PostHog person 처리 | 72시간 | API 처리 + 검증 시간 |
| 사용자 회신 메일 | 7일 | 처리 완료 후 발송 |
| PIPA 법정 시한 | 30일 | 위 SLA보다 보수적 |

### 5.5 회수 후 재가입

같은 사용자가 재가입할 경우: hash가 같으므로 PostHog 재식별. Supabase soft-delete row를 *복구*하지 않고 *새 row* 생성 (deleted_at IS NOT NULL 유지). 새 row의 `consent_at`은 재가입 시점.

---

## 6. 법적 호환 — GDPR / PIPA / 정통망법

### 6.1 GDPR (EU 사용자)

| 요구사항 | 본 설계 충족 |
|---------|----------|
| Lawful basis (Art. 6) | Consent (Art. 6.1.a) — 명시적 옵트인 |
| Explicit consent | 체크박스 default OFF + 명시적 클릭 |
| Specific purpose | "출시 소식 발송"이라는 *구체* 목적 |
| Right to withdraw (Art. 7.3) | 모든 메일 footer에 수신거부 링크 + `/unsubscribe` |
| Data portability (Art. 20) | Supabase row export 가능 (요청 시 JSON 제공) |
| Right to erasure (Art. 17) | §5 SOP |
| Data minimization (Art. 5.1.c) | 이메일 + purpose + consent_* 외 수집 X |
| 14-day cookie consent (UK) | DNT 자동 + 분석은 no-cookie 옵션 시 검토 (현재는 PostHog cookie 사용) |

### 6.2 PIPA (한국 개인정보보호법)

| 요구사항 | 본 설계 충족 |
|---------|----------|
| 수집·이용 동의 (제15조) | 다이얼로그 + 처리방침 링크 |
| 목적 외 이용 금지 (제18조) | "진행 소식만" 명시. 광고/판촉 X. |
| 처리방침 게시 (제30조) | `/privacy` 페이지 + Footer 링크 |
| 위탁 처리 고지 (제26조) | "PostHog Inc. (미국) 위탁" 명시 (§9 09_analytics_plan.md PIPA 약관 문구) |
| 정정·삭제권 (제36조) | §5 SOP, 30일 이내 처리 |
| 자동 결정 거부권 | 본 프로젝트는 자동 의사결정 없음 |
| 보호위 신고 의무 (대규모 유출) | Supabase + PostHog SOC 2 보안 + 로깅 |

### 6.3 정통망법 (정보통신망 이용촉진 및 정보보호 등에 관한 법률)

본 라운드는 *수집*만 책임진다. 발송은 별도 라운드. 발송 라운드에서 충족해야 할 의무:

| 요구사항 (제50조 광고성 정보 전송) | 발송 라운드 책임 |
|------|----------|
| 사전 동의 | 본 라운드 컨센트 다이얼로그가 충족 |
| **메일 제목 "(광고)" 표기** | 마케팅 메일 발송 시 필수 |
| **본문에 발송자 정보 명시** | "Chew & Calm Coach 운영자 / 1213sam0@gmail.com" |
| **수신거부 의사표시 처리** | `/unsubscribe` + 24시간 내 처리 |
| **야간(21시-08시) 발송 별도 동의** | 본 라운드는 야간 동의 X — 발송은 주간만 |
| 동의 기록 보관 | Supabase `signups.consent_at`, `consent_version` |

**경계 명시**: 본 라운드는 위 요구사항 중 "사전 동의" + "동의 기록 보관" 2개를 책임진다. 나머지 (광고 표기·수신거부 처리·야간 동의)는 미래의 발송 라운드 에이전트 책임이다.

### 6.4 수집 항목 최소화 (본 라운드)

본 라운드 수집 항목:
- 이메일 (필수, Supabase에만)
- `purpose` (필수)
- `source` (자동 — 어느 폼에서 신청했는지)
- `persona` (선택 — URL `?p=` 라우팅 시)
- `consent_marketing`, `consent_at`, `consent_version` (필수)
- `posthog_distinct_id` (자동 — hash)
- 최초 가입 timestamp (Supabase 자동)

수집 *안 하는* 항목 (PIPA 최소화 원칙):
- 이름, 전화번호, 생년월일, 성별
- 의료 정보 ("위염이 얼마나 심한지" 같은 자유 입력)
- 거주 지역, 직업
- IP 주소 raw (PostHog geo 추정만)

향후 추가 수집 시 *재동의* 필수.

---

## 7. 옵트인률을 funnel KPI로 추적

### 7.1 KPI 정의

| KPI | 정의 | 측정 |
|-----|----|------|
| **옵트인률** | `form_submit_success`의 `consent_marketing=true` 비율 | PostHog Insights — Cohort + Ratio |
| **거절자 신청 비율** | `consent_marketing=false`이지만 신청 완료된 사용자 비율 | 동일 데이터의 inverse |
| **다이얼로그 이탈률** | `consent_view` 발화 후 `form_submit_success` 미도달 비율 | Funnel: `consent_view` → `form_submit_success` |

### 7.2 베이스라인 측정 후 목표

배포 후 30일 베이스라인 수집. 예상 베이스라인:
- 옵트인률 60-80% (베타 신청자는 동기 강함, 거절 적음)
- 다이얼로그 이탈률 5-15% (다이얼로그가 너무 무거우면 이탈 증가)

목표 (베이스라인 기반으로 추후 설정):
- 옵트인률 +10%p 개선 → 카피 A/B 테스트
- 다이얼로그 이탈률 < 10% 유지

### 7.3 컨센트 카피 A/B 테스트 baseline

본 라운드 카피(§3)가 A안. 향후 B안 (예: 헤드 변경, 본문 길이 변경) 테스트 시:
- PostHog Feature Flags로 50/50 split
- `consent_view` 이벤트에 `consent_variant: 'A' | 'B'` property 추가
- 30일 후 옵트인률 비교

이 분석을 위한 인프라는 본 라운드에서 *지원만 하고 활성은 미래*. 카피 변경 시 `consent_version` 갱신.

---

## 합의 포인트 (collector와)

본 라운드의 컨센트 정책은 `landing-data-collector`의 Supabase 스키마와 *완전 일치*해야 한다.

### 합의 #1 — 데이터 분리 (재확인)

`consent_at`, `consent_version`은 **Supabase가 source of truth**. PostHog는 event property + identify trait로 *복제 저장*하지만 법적 증빙은 Supabase row.

### 합의 #2 — distinctId hash 정책

`hashEmail(email, VITE_HASH_SALT)` 결과가 Supabase `signups.posthog_distinct_id`와 PostHog distinct_id에 동일 저장. 컨센트 회수 시 양쪽 시스템에서 hash로 lookup.

### 합의 #3 — `purpose` enum

다이얼로그·라디오 UI 라벨은 `marketing-storyteller`가 결정. 분석 enum은 `diet`/`digestion`/`other` 고정.

### 합의 #4 — `consent_*` 컬럼 + 거절 분기

| 분기 | Supabase | PostHog |
|------|---------|---------|
| 옵트인=true | row 저장 + `consent_marketing=true` + `consent_at=NOW()` | identify 호출 + `form_submit_success` |
| 옵트인=false | row 저장 + `consent_marketing=false` + `consent_at=NULL`(또는 거절 시각) | identify 호출 X + `form_submit_success`만 |
| 신청 자체 취소 (다이얼로그 [취소]) | row 저장 X | 이벤트 발화 X |

거절자도 Supabase에 저장하는 이유: "신청은 했지만 마케팅 거부"라는 의도를 *명시적*으로 기록 (= 추후 재가입 시 동의 상태 추적 가능).

### 합의 #5 — 환경변수

`VITE_CONSENT_VERSION='2026-05-04'`이 양 산출물의 `.env.example`에 일치.

---

## 검증 체크리스트 (오케스트레이터 통합 전)

- [ ] 다이얼로그 본문에 의료 약속 / 과장 / 가짜 권위 / KOL 영입 표현 0건
- [ ] 체크박스 default OFF
- [ ] 거절 시 identify 호출 안 함, 단 form_submit_success는 발화
- [ ] `consent_version='2026-05-04'`이 09_analytics_plan.md와 일치
- [ ] 처리방침에 PostHog 위탁 처리 고지 문구 포함 (09_analytics_plan.md §9.3)
- [ ] 회수 SOP가 Supabase + PostHog 양쪽 처리 포함
- [ ] `marketing-storyteller`가 §3 카피 검토 완료
