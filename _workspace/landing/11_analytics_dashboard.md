# 11 — Analytics Dashboard 청사진 (PostHog Insights)

작성: `landing-analytics-engineer` 에이전트
작성일: 2026-05-04
대상 라운드: Phase 5-B 분석/데이터 v2 인프라
관련: `_workspace/landing/09_analytics_plan.md` (이벤트 카탈로그·세그멘테이션), `_workspace/landing/10_consent_strategy.md` (컨센트 흐름)

## 본 라운드 컨텍스트

PostHog Insights에 *배포 직후 바로 만들어둘* 4개 핵심 대시보드를 정의한다. UI 클릭 단계 + HogQL 쿼리(고급 사용 시) + 베이스라인 측정 후 목표 설정 절차 포함. 본 문서를 따라 4개 Insight를 생성하고 PostHog Dashboard 1개에 묶으면 운영 시작.

## ToC
1. 대시보드 묶음 구조
2. Insight #1 — Funnel: Conversion
3. Insight #2 — Breakdown: Purpose 분포
4. Insight #3 — Breakdown: 페르소나 × 전환률
5. Insight #4 — Cohort: 옵트인률
6. 대시보드 운영 — 베이스라인·알림·리포트
7. 합의 포인트 (collector와)

---

## 1. 대시보드 묶음 구조

### 1.1 PostHog 대시보드 1개 + Insight 4개

PostHog Cloud 콘솔 → **Dashboards** → "+ New dashboard"
- 이름: `Chew Coach Landing — v1`
- 설명: `랜딩 베타 가입 funnel + purpose 분포 + persona 전환률 + 옵트인률. 4개 Insight.`
- Pinned: ✓ (즐겨찾기)
- 대시보드 필터 (선택):
  - `device_type` 드롭다운 (mobile/tablet/desktop/all)
  - 기본 시간 범위 — 최근 30일

### 1.2 4개 Insight 요약

| # | 이름 | 타입 | 답할 질문 (09_analytics_plan §1) |
|---|------|-----|---------------------------|
| 1 | Funnel — Conversion | Funnel | Q3 (어디서 떨어지는가) + Q8 (폼 깔때기 단계별 drop) |
| 2 | Breakdown — Purpose 분포 | Trends (stacked bar) | Q1 (다이어트/위염/기타 분포) |
| 3 | Breakdown — 페르소나 × 전환률 | Trends (ratio) | Q2 (페르소나별 전환률) |
| 4 | Cohort — 옵트인률 | Trends (ratio) | Q4 (마케팅 옵트인 동의률) |

추가 (선택):
- Insight #5 — `cta_click` × `cta_id` Trends → Q7 (어느 CTA가 가장 많이 눌리는가)
- Insight #6 — `form_submit_success` time-of-day histogram → Q5

---

## 2. Insight #1 — Funnel: Conversion

### 2.1 답할 질문
- Q3: 사용자가 어디서 들어와 어디서 떨어지는가?
- Q8: 폼 깔때기 단계별 drop은 어디인가?

### 2.2 Funnel 정의

| 단계 | 이벤트 | 의미 |
|-----|------|------|
| 1 | `landing_view` | 랜딩 페이지 진입 |
| 2 | `cta_click` | 임의 CTA 클릭 (의도 표현) |
| 3 | `email_focus` | 이메일 입력란 첫 focus (입력 시작) |
| 4 | `form_submit_try` | submit 버튼 클릭 + 클라이언트 검증 통과 |
| 5 | `form_submit_success` | Supabase 200 응답 (최종 전환) |

- **Conversion window**: 30분 (한 세션 내 전환)
- **Step ordering**: Sequential (순서대로 발화)

### 2.3 Breakdown 차원
- `purpose` — 목적별 깔때기 차이
- `source` — 어느 폼 위치(hero/final_cta/footer)에서 시작된 funnel인지
- `device_type` — 모바일 vs 데스크탑 차이

### 2.4 PostHog UI 클릭 단계

1. PostHog Cloud → **Insights** → "+ New insight"
2. Insight type: **Funnel**
3. Steps 추가 (순서대로):
   - Step 1: Event = `landing_view`
   - Step 2: Event = `cta_click`
   - Step 3: Event = `email_focus`
   - Step 4: Event = `form_submit_try`
   - Step 5: Event = `form_submit_success`
4. **Conversion window**: 30 minutes
5. **Breakdown**: Properties → `purpose` (또는 토글로 `source`/`device_type`)
6. Date range: Last 30 days
7. Save → name: `Funnel — Conversion`
8. Add to dashboard `Chew Coach Landing — v1`

### 2.5 HogQL 쿼리 (고급 — UI에서 export 또는 직접 실행)

```sql
-- 30일 funnel 수치 (PostHog HogQL)
SELECT
    countIf(event = 'landing_view') AS step1_landing_view,
    countIf(event = 'cta_click') AS step2_cta_click,
    countIf(event = 'email_focus') AS step3_email_focus,
    countIf(event = 'form_submit_try') AS step4_submit_try,
    countIf(event = 'form_submit_success') AS step5_submit_success,
    round(step5_submit_success * 100.0 / nullIf(step1_landing_view, 0), 2) AS conversion_pct
FROM events
WHERE timestamp >= now() - INTERVAL 30 DAY
```

Breakdown 추가 시 `GROUP BY properties.purpose` 등.

### 2.6 KPI

- **최종 단계 도달률** (`form_submit_success` ÷ `landing_view`)
- 베이스라인 측정 후 목표 설정 (§6).

---

## 3. Insight #2 — Breakdown: Purpose 분포

### 3.1 답할 질문
- Q1: 신청자가 다이어트 / 위염·소화불량 / 기타 중 어느 목적인가?
- 핵심 비즈니스 인사이트 — *어느 메시지·페르소나에 더 투자할지* 결정

### 3.2 Insight 정의

- 이벤트: `form_submit_success`
- Breakdown: `purpose` (`diet` / `digestion` / `other`)
- 차트 타입: **Stacked bar over time** (또는 Pie chart for snapshot)
- 시간 단위: weekly (베타 단계는 주 단위가 노이즈 적음)

### 3.3 PostHog UI 클릭 단계

1. **Insights** → "+ New insight"
2. Insight type: **Trends**
3. Series: Event = `form_submit_success`, Math = Total count
4. Breakdown: `purpose`
5. Chart type: **Stacked bar**
6. Date range: Last 30 days
7. Interval: **Week**
8. Save → name: `Breakdown — Purpose 분포`
9. Add to dashboard

### 3.4 HogQL 쿼리

```sql
SELECT
    toStartOfWeek(timestamp) AS week,
    properties.purpose AS purpose,
    count() AS signups
FROM events
WHERE event = 'form_submit_success'
  AND timestamp >= now() - INTERVAL 90 DAY
GROUP BY week, purpose
ORDER BY week DESC, signups DESC
```

### 3.5 KPI

- **`diet` vs `digestion` vs `other` 비율** — 어느 목적이 가장 큰 세그먼트인가
- *디스커버리 1순위 페르소나(위염 직장인)* 가설 검증: `digestion` 비율이 30%+ 이면 가설 강화, 10% 이하이면 약화 → 카피·페르소나 재검토.

### 3.6 의사결정 트리거

- `digestion` ≥ 50%: 위염 페르소나 가설 강 — 의료 KOL 영입 우선
- `diet` ≥ 50%: 다이어트 페르소나 강 — 다노형 친근 코칭 우선
- `other` ≥ 30%: 메시지 모호 — 폼 위 헤드라인 명확화 필요

---

## 4. Insight #3 — Breakdown: 페르소나 × 전환률

### 4.1 답할 질문
- Q2: URL `?p=` 라우팅으로 들어온 페르소나(stomach/diet/checkup)별 전환률은?
- *어느 페르소나 카피가 가장 잘 통하는가* → 마케팅 채널·광고 카피 우선순위

### 4.2 Insight 정의

- **분자**: `form_submit_success` count by `persona`
- **분모**: `landing_view` count by `persona`
- 차트 타입: **Trends with formula** — `A / B * 100` (전환률 %)
- Breakdown: `persona` (`stomach` / `diet` / `checkup` / `unknown`)

### 4.3 PostHog UI 클릭 단계

1. **Insights** → "+ New insight"
2. Insight type: **Trends**
3. Series A: `form_submit_success` (Math = Total count)
4. Series B: `landing_view` (Math = Total count)
5. **Formula**: `A / B * 100`
6. Breakdown: `persona`
7. Chart type: **Bar (stacked = OFF)** 또는 Line
8. Date range: Last 30 days
9. Interval: Week
10. Save → name: `Breakdown — Persona × 전환률`

### 4.4 HogQL 쿼리

```sql
WITH
  views AS (
    SELECT
      coalesce(properties.persona, 'unknown') AS persona,
      count() AS view_count
    FROM events
    WHERE event = 'landing_view'
      AND timestamp >= now() - INTERVAL 30 DAY
    GROUP BY persona
  ),
  successes AS (
    SELECT
      coalesce(properties.persona, 'unknown') AS persona,
      count() AS success_count
    FROM events
    WHERE event = 'form_submit_success'
      AND timestamp >= now() - INTERVAL 30 DAY
    GROUP BY persona
  )
SELECT
  v.persona AS persona,
  v.view_count,
  coalesce(s.success_count, 0) AS success_count,
  round(coalesce(s.success_count, 0) * 100.0 / nullIf(v.view_count, 0), 2) AS conversion_pct
FROM views v
LEFT JOIN successes s ON v.persona = s.persona
ORDER BY conversion_pct DESC
```

### 4.5 KPI

- **가장 전환되는 페르소나** — 광고 채널·카피 우선순위
- **`unknown` 비율** — URL 라우팅 없이 들어오는 비율. 높으면 외부 채널이 페르소나 컨텍스트 없이 보내는 것 → 광고 URL에 `?p=` 추가 권장

### 4.6 주의 — 작은 표본 한계

베타 초기 (월 100건 미만)에는 페르소나당 표본이 부족해 *통계적으로 유의*하지 않을 수 있다. 30건 이하 페르소나는 인사이트 도출 보류, 90일 누적 후 재평가.

---

## 5. Insight #4 — Cohort: 옵트인률

### 5.1 답할 질문
- Q4: 신청자 중 마케팅 옵트인 동의률은?
- *컨센트 카피 A/B 테스트의 baseline* — 향후 카피 개선 측정

### 5.2 Insight 정의

- 이벤트: `form_submit_success`
- Breakdown: `consent_marketing` (boolean — `true` / `false`)
- 차트 타입: **Trends with formula** (옵트인률 = true / total)

### 5.3 PostHog UI 클릭 단계

1. **Insights** → "+ New insight"
2. Insight type: **Trends**
3. Series A: `form_submit_success` filtered by `consent_marketing = true`
4. Series B: `form_submit_success` (filter 없음 — total)
5. **Formula**: `A / B * 100`
6. Chart type: **Line** (시간 추세)
7. Date range: Last 90 days
8. Interval: Week
9. Save → name: `Cohort — 옵트인률`

또한 별도 Insight로 절대 수치도 추적:
- Series 1: `form_submit_success` filtered `consent_marketing=true`
- Series 2: `form_submit_success` filtered `consent_marketing=false`
- Stacked bar — 시간별 옵트인 vs 거절 절대 카운트

### 5.4 HogQL 쿼리

```sql
SELECT
    toStartOfWeek(timestamp) AS week,
    countIf(properties.consent_marketing = true) AS opt_in_count,
    countIf(properties.consent_marketing = false) AS opt_out_count,
    count() AS total,
    round(opt_in_count * 100.0 / nullIf(total, 0), 2) AS opt_in_pct
FROM events
WHERE event = 'form_submit_success'
  AND timestamp >= now() - INTERVAL 90 DAY
GROUP BY week
ORDER BY week DESC
```

### 5.5 KPI

- **옵트인률**: 베이스라인 60-80% 예상 (베타 신청자는 동기 강함)
- **카피 A/B 테스트 baseline** — 컨센트 카피 변경 시 비교

### 5.6 의사결정 트리거

- 옵트인률 < 50%: 다이얼로그 카피·체크박스 위치 재검토. 사용자가 *마케팅 발송을 두려워하는* 시그널.
- 옵트인률 > 90%: 다이얼로그가 *너무 약함* — 사용자가 의미를 인지하지 않고 클릭하는지 검토 (UI 문법 검증).

---

## 6. 대시보드 운영 — 베이스라인·알림·리포트

### 6.1 베이스라인 측정 절차

1. **D+0 ~ D+7**: 배포 후 7일은 *데이터 검증*만 — funnel 발화 정상, breakdown 값 분포 확인. 실측 KPI는 *목표 설정 안 함* (표본 부족).
2. **D+7 ~ D+30**: 30일 누적. 4개 Insight의 베이스라인 수치 기록 → `_workspace/landing/12_analytics_baseline.md` (별도 파일, 운영 단계에서 작성).
3. **D+30 이후**: 베이스라인 ± 표준편차로 목표 설정. 예:
   - Funnel 최종 단계 도달률 베이스라인 4% → 목표 +2%p (6%)
   - 옵트인률 베이스라인 70% → 목표 +5%p (75%)

### 6.2 알림 (PostHog Subscriptions)

배포 후 1-2주 데이터 안정화되면 알림 설정:
- **Slack 또는 이메일 일일 리포트**: 4개 Insight를 매일 09:00 KST 운영자에게 발송
  - PostHog Cloud → Dashboard → **Subscribe**
  - Frequency: Daily 09:00 (KST = UTC+09:00)
  - Recipients: `1213sam0@gmail.com`
- **Anomaly alert**: `form_submit_fail` count가 일일 평균의 3배 초과 시 즉시 알림 (Web3Forms→Supabase 마이그 후 안정성 모니터링)

### 6.3 주간 리포트 템플릿

운영자가 매주 월요일 09:00에 작성하는 1페이지 리포트 (옵션):
```
# Chew Coach Landing — 주간 리포트 (W{YYYY-WW})

## 핵심 수치 (지난 7일)
- 페이지뷰: ___
- CTA 클릭: ___
- 이메일 focus: ___
- 신청 시도: ___
- 신청 성공: ___ (전환률 ___%)
- 신청 실패: ___ (사유 분포: invalid ___ / network ___ / duplicate ___)

## Purpose 분포
- diet: ___% (___건)
- digestion: ___% (___건)
- other: ___% (___건)

## Persona 전환률
- stomach: ___%
- diet: ___%
- checkup: ___%
- unknown: ___%

## 옵트인률
- 옵트인: ___%
- 거절: ___%
- 전주 대비 변화: ___

## 의사결정
- [무엇을 발견했는지]
- [다음 주 시도할 것]
```

### 6.4 1단계 트래픽 가정 + 표본 충분성

베타 초기 가정:
- 월 페이지뷰 ~5,000 (디스커버리 가정 기반, 보수적)
- 월 신청 ~50-100건 (전환률 1-2% 가정)
- 페르소나당 신청 ~15-30건 → **30일 단기 인사이트 보류, 90일 누적 권장**
- 옵트인률 분석은 *총 신청 50건+ 시점*부터 의미 있음

표본 부족 시 분석은 *방향성*만 보고 의사결정 보류. 90일 누적 후 본격 의사결정.

---

## 합의 포인트 (collector와)

대시보드는 PostHog 단독 영역이지만 다음 4개 합의 포인트와 정합해야 함:

### 합의 #1 — 데이터 분리

대시보드의 모든 수치는 **PostHog event**에서만 계산. Supabase row count는 PostHog `form_submit_success` count와 *근사 일치*해야 함 (네트워크 실패 등으로 약간 차이 — 이 차이도 모니터링 항목).

### 합의 #2 — distinctId hash

PostHog의 unique user 카운트가 Supabase row 수와 일치하려면 distinctId hash 정책이 양쪽 동일해야 함. 같은 사용자가 두 번 신청 시 PostHog는 1 unique person, Supabase는 2 row (또는 unique constraint으로 1 row + 409) → 이 차이를 운영자가 알아야 함.

### 합의 #3 — `purpose` enum

Insight #2의 breakdown 값(`diet`/`digestion`/`other`)이 Supabase `signups.purpose` check 제약과 *완전 일치*. enum 추가 시 양쪽 동시 갱신.

### 합의 #4 — `consent_marketing` 거절 분기

Insight #4의 분모는 `form_submit_success` 전체, 분자는 `consent_marketing=true`. *거절자도 분모에 포함*되어야 옵트인률이 의미 있음 → 거절자도 `form_submit_success` 발화 정책(09 + 10 산출물 합의 #4) 준수 필수.

### 합의 #5 — 환경변수

대시보드는 PostHog 콘솔에서 생성하므로 환경변수 직접 의존 X. 단 `VITE_POSTHOG_KEY`가 같은 PostHog 프로젝트를 가리켜야 함 (collector도 Supabase Edge Function에서 PostHog API 호출 시 같은 프로젝트 ID).

---

## 검증 체크리스트 (대시보드 생성 후)

- [ ] Insight #1 Funnel 5단계 모두 정의됨, 30분 윈도우
- [ ] Insight #2 Purpose 3값(`diet`/`digestion`/`other`) 모두 발화 가능 — 실제 테스트 신청으로 확인
- [ ] Insight #3 Persona 4값(`stomach`/`diet`/`checkup`/`unknown`) 모두 발화 가능 — URL `?p=stomach`/`?p=diet`/`?p=checkup`/`?p=`(없음) 4가지 시나리오 테스트
- [ ] Insight #4 옵트인 true/false 양쪽 발화 — 다이얼로그 옵트인 시·거절 시 두 시나리오 테스트
- [ ] 4개 Insight 모두 dashboard `Chew Coach Landing — v1`에 추가됨
- [ ] 운영자(`1213sam0@gmail.com`) Daily Subscription 활성
- [ ] 베이스라인 측정 시작 시점(D+7) 캘린더에 표시
