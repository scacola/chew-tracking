---
name: chew-coach-landing
description: 옵션 G "Chew & Calm Coach"의 인터랙티브 마케팅 랜딩 페이지를 6명+ 전문 에이전트(카피라이터·디자이너·아키텍트·구현자·QA폴리셔·데이터수집자·분석엔지니어)로 빌드·운영하는 오케스트레이터. "랜딩 페이지 만들어줘", "마케팅 사이트 제작", "옵션 G 웹페이지", "Chew Coach 랜딩", "인터랙티브 사이트 빌드", "디스커버리 결과를 웹으로", "Apple급 랜딩" 같은 요청 시 반드시 사용. 후속 작업: "다시 빌드", "재실행", "카피만 수정", "디자인만 수정", "특정 섹션 다시", "QA만 다시", "폴리시 더", "이전 결과 기반 개선", "옵션 G 페이지 업데이트", "이메일 수집", "폼 백엔드", "Supabase 연결", "데이터베이스 연결", "PostHog 붙여줘", "사용자 분석", "이벤트 트래킹", "funnel 만들어줘", "다이어트 위염 분류", "사용자 목적 수집", "마케팅 컨센트", "출시 시 연락 동의", "옵트인 추가" 같은 표현에서도 트리거.
---

# Chew Coach Landing Orchestrator

옵션 G "Chew & Calm Coach"의 마케팅 랜딩 페이지 빌드 워크플로우를 5명의 전문 에이전트로 조율한다. 이 하네스는 *디스커버리 하네스(`chew-tracking-discovery`)와 별개* — 전자는 의사결정 보고서, 후자는 실제 웹사이트.

## 실행 모드 — 하이브리드

Phase별 특성이 다르므로 하이브리드:

| Phase | 모드 | 이유 |
|-------|-----|------|
| **Phase 1: 콘셉트 (팀)** | 에이전트 팀 (3명) | 카피·디자인·아키텍처는 *상호 영향* — 팀 통신으로 합의 |
| **Phase 2: 구현** | 서브 (1명) | 단일 집중 작업, 팀 통신 불필요 |
| **Phase 3: QA·폴리시** | 서브 (1명) | 독립 검증, 발견 시 재호출 트리거 |
| **Phase 4: 데이터 수집 (가벼운)** | 서브 (1명) | 단순 폼 통합, 단독 트리거 |
| **Phase 5: 분석·데이터 v2 인프라** | 페어 (2명) → 서브 다중 | 분석/데이터 모델 *합의* 필요 → UX/카피/구현/QA 단발 호출 |

모든 Agent 호출은 **`model: "opus"`** 명시 필수.

## Phase 0: 컨텍스트 확인

오케스트레이터 진입 즉시:

```
1. _workspace/landing/ 디렉토리 존재 여부 확인
2. landing/ 디렉토리 (사이트 본체) 존재 여부 확인
3. discovery_report.md + _workspace/04_product_ideation.md 존재 확인 (옵션 G 정보 입력)
   - 디스커버리 산출물이 없으면 사용자에게 보고 후 chew-tracking-discovery 우선 실행 권고
4. 사용자 요청에서 의도 분류:
   - "다시 빌드", "재실행" → 새 실행 (기존 _workspace/landing, landing/을 _workspace_prev_*로 백업)
   - "카피만 수정" → marketing-storyteller 재호출 → frontend-implementer (영향 부분) → landing-qa-polisher
   - "디자인만 수정" → visual-experience-designer + landing-architect → frontend-implementer → QA
   - "QA만 다시" → landing-qa-polisher만
   - "특정 섹션 다시" → 해당 섹션 카피·디자인·구현 재호출
   - "이메일 수집", "폼 백엔드", "데이터 수집 추가", "노션/구글시트 연결" → Phase 4 (가벼운 데이터 수집 통합) 단독 실행
   - "PostHog 붙여줘", "사용자 분석", "이벤트 트래킹", "funnel" → Phase 5 (분석·데이터 v2 인프라) — analytics 단독 또는 페어
   - "Supabase 연결", "데이터베이스로 받기", "옵트인 동의", "출시 시 연락 동의", "마케팅 컨센트", "다이어트 위염 분류", "사용자 목적 수집" → Phase 5 (분석·데이터 v2 인프라) — 페어 (analytics + data-collector) + 디자인·카피·구현·QA 단발 호출
   - 기존 산출물 미존재 → 초기 실행
```

**부분 재실행 매트릭스:**
| 사용자 의도 | 실행할 에이전트 |
|------------|---------------|
| "카피만 수정" | marketing-storyteller → landing-architect (브리프 갱신) → frontend-implementer (영향 섹션) → landing-qa-polisher |
| "디자인만 수정" | visual-experience-designer → landing-architect → frontend-implementer → landing-qa-polisher |
| "특정 섹션 다시" | 3명 팀 모두 (해당 섹션만) → frontend-implementer → landing-qa-polisher |
| "QA·폴리시 더" | landing-qa-polisher만 (필요 시 frontend-implementer 재호출) |
| "성능만" | landing-architect (예산 재검토) → frontend-implementer (최적화) → landing-qa-polisher |
| "이메일 수집·폼 백엔드 추가" | landing-data-collector (단독, Phase 4 모드) → 필요 시 marketing-storyteller (성공 메시지 카피) → landing-qa-polisher (폼 종단간 검수) |
| "PostHog만 추가·이벤트 트래킹만" | landing-analytics-engineer (단독, Phase 5-A 모드) → frontend-implementer (영향 부분) → landing-qa-polisher (이벤트 발화 검증) |
| "Supabase·옵트인·목적 수집 풀세트" | landing-analytics-engineer + landing-data-collector (페어, Phase 5-B 모드) → visual-experience-designer + marketing-storyteller (목적 UI + 컨센트 카피 단발) → frontend-implementer → landing-qa-polisher |
| "옵트인 카피만 다듬기" | marketing-storyteller (단독) → frontend-implementer (ConsentDialog 부분) → landing-qa-polisher |

새 실행 시:
```bash
mv _workspace/landing _workspace/_landing_prev_$(date +%Y%m%d_%H%M%S)
mv landing _workspace/_landing_code_prev_$(date +%Y%m%d_%H%M%S)
mkdir -p _workspace/landing
```

`_workspace/landing/_brief.md`에 사용자 원본 요청 + 디스커버리 옵션 G 발췌 + 실행 모드를 기록.

## Phase 1: 콘셉트 — 에이전트 팀 (3명)

**실행 모드: 에이전트 팀**

3명의 팀 구성:
- `marketing-storyteller` (카피·메시지)
- `visual-experience-designer` (비주얼·UX·모션)
- `landing-architect` (기술 명세 통합)

팀 워크플로우:
1. 오케스트레이터가 `TeamCreate`로 팀 생성, 각 멤버를 `general-purpose`로 추가
2. 모두에게 공통 입력(`_workspace/landing/_brief.md`, `discovery_report.md`, `_workspace/04_product_ideation.md`)을 알림
3. 각자 *초안* 작성:
   - storyteller → `_workspace/landing/01_strategy_copy.md`
   - designer → `_workspace/landing/02_visual_ux.md`
   - architect → `_workspace/landing/03_architecture.md` (팀이 합의 단계 들어가기 전 stub만)
4. 팀 통신 (`SendMessage`)으로 *상호 영향 검토*:
   - storyteller가 헤드라인 후보 → designer에게 시각 임팩트 평가 요청
   - designer가 시그니처 인터랙션 → architect에게 기술 가능성 검토
   - architect가 성능 예산 위반 → designer에게 단순화 협상
5. 합의 후 architect가 `_workspace/landing/04_brief_consolidated.md` 최종 통합 (카피 + 디자인 토큰 + 컴포넌트 명세 + 빌드 단계 모두 포함)
6. 오케스트레이터가 04_brief 파일 존재·완결성 확인 후 팀 정리 (`TeamDelete`)

### 팀 합의 게이트 (Phase 1 종료 조건)

다음 모두 충족해야 Phase 2로:
- 01_strategy_copy.md: 헤드라인 1개 + 후보 2개, 모든 섹션 카피, FAQ 6개+, CTA 매트릭스 ✓
- 02_visual_ux.md: 디자인 시스템 (색·폰트·간격), 정보 흐름, 인터랙션 사양, 접근성 가드 ✓
- 03_architecture.md: 기술 스택, 파일 구조, 컴포넌트 명세, 빌드 단계, 성능 예산 ✓
- 04_brief_consolidated.md: 위 셋을 *frontend-implementer가 그대로 빌드 가능한* 형태로 통합 ✓

미충족 시 해당 에이전트 1회 재호출. 재실패 시 사용자에게 보고하고 누락 부분 명시.

## Phase 2: 구현 — 서브 에이전트

**실행 모드: 서브 에이전트**

```
Agent({
  description: "랜딩 페이지 빌드",
  subagent_type: "general-purpose",
  model: "opus",
  prompt: "당신은 .claude/agents/frontend-implementer.md에 정의된 에이전트다. .claude/skills/frontend-craft/SKILL.md의 6단계 빌드 방법론을 따른다. 입력: _workspace/landing/04_brief_consolidated.md. 빌드 산출물: 프로젝트 루트의 landing/ 디렉토리. 빌드 보고: _workspace/landing/05_build_report.md. 6단계 모두 검증 후 종료. 검증 누락 금지."
})
```

(병렬 실행 불필요 — 단일 작업이므로 background 옵션은 사용해도 무방, 결과 받을 때까지 대기.)

## Phase 3: QA·폴리시 — 서브 에이전트

**실행 모드: 서브 에이전트**

```
Agent({
  description: "랜딩 페이지 QA·폴리시",
  subagent_type: "general-purpose",
  model: "opus",
  prompt: "당신은 .claude/agents/landing-qa-polisher.md 에이전트다. .claude/skills/landing-qa-polish/SKILL.md의 3축 검증 방법론(기능·디자인·마케팅)을 따른다. 입력: landing/ + _workspace/landing/04_brief_consolidated.md + _workspace/landing/05_build_report.md. 출력: _workspace/landing/06_qa_report.md + 직접 수정한 코드. 4개 디바이스 사이즈 검증 + 5초 룰 + Lighthouse 측정 필수."
})
```

QA가 Critical 이슈 발견 시:
- 직접 수정 가능 → 직접 수정 후 재검증
- 구현자 재작업 필요 → frontend-implementer 1회 재호출
- 디자인·카피 팀 재작업 필요 → 사용자에게 보고 후 Phase 1 부분 재실행 결정

## Phase 4: 데이터 수집 통합 — 서브 에이전트 (후속·독립 모드)

**실행 모드: 서브 에이전트 (단독)**

랜딩 사이트가 이미 빌드된 후, *백엔드 없이* 사용자 데이터(이메일·웨이트리스트·피드백)를 수집하는 통합을 추가하는 후속 모드. Phase 1~3와 직교하며 단독으로 트리거 가능.

```
Agent({
  description: "백엔드리스 데이터 수집 통합",
  subagent_type: "general-purpose",
  model: "opus",
  prompt: "당신은 .claude/agents/landing-data-collector.md 에이전트다. .claude/skills/landing-data-collection/SKILL.md의 5축 비교 매트릭스(키 노출·CORS·무료 한도·운영 부하·가시성)를 따른다. 입력: landing/src/components/EmailForm.tsx + 사용자 요청(수집 목적·예상 트래픽·통지 채널·수신처 선호: 노션/구글시트/Formspree 등). 단계: (1) _workspace/landing/07_data_collection_options.md에 옵션 비교·추천 작성 → 사용자 승인 대기 → (2) 선택된 옵션 구현 (EmailForm.tsx + 필요 시 lib/dataCollection.ts + .env.example) → (3) 종단간 1건 제출 검증 + 스크린샷 → (4) _workspace/landing/08_data_collection_runbook.md 운영 가이드. 빌드 통과 + 클라이언트 번들에 비밀 0건 + 옵션 G 톤 카피 필수."
})
```

Phase 4 진입 조건:
- `landing/` 디렉토리와 `EmailForm.tsx`가 이미 존재
- 사용자 요청이 데이터 수집 추가 (`이메일 수집 / 폼 백엔드 / 노션·구글시트 연결 / 웨이트리스트` 등)

Phase 4 종료 후 권장 후속:
- `landing-qa-polisher` 폼 종단간 검수 (Phase 3 부분 재실행)
- 성공 메시지 카피가 변경됐다면 `marketing-storyteller`에게 톤 일관성 검토 요청

## Phase 5: 분석·데이터 v2 인프라 — 페어 + 단발 호출

**실행 모드: 하이브리드 (페어 → 서브 다중)**

PostHog 분석 + Supabase 영구 백엔드 + 사용자 목적(`purpose`) 수집 + 마케팅 옵트인 컨센트를 통합 도입하는 후속 모드. Phase 4의 가벼운 폼 통합과 *상위 호환* — Phase 4 산출물이 있다면 마이그레이션 패스를 따른다.

### Phase 5-A: 분석 단독 (PostHog만 추가)

`landing-analytics-engineer` 단일 호출. 데이터 모델·백엔드 변경 불필요한 케이스 (이벤트 트래킹·funnel만 추가).

```
Agent({
  description: "PostHog 분석 통합",
  subagent_type: "general-purpose",
  model: "opus",
  prompt: "당신은 .claude/agents/landing-analytics-engineer.md 에이전트다. .claude/skills/landing-analytics-instrumentation/SKILL.md를 따른다. 입력: landing/ + 사용자 측정 질문. 단계: (1) _workspace/landing/09_analytics_plan.md 작성 → 사용자 검토 → (2) posthog-js 통합 (lib/posthogClient.ts + lib/analytics.ts + provider) → (3) 발화 지점 통합 (landing_view, cta_click, email_focus, form_submit_*) → (4) 종단간 1건 PostHog Activity 도달 확인. 빌드 통과 + PII 차단(data-ph-no-capture) + 단일 init 필수."
})
```

### Phase 5-B: 풀세트 (분석 + Supabase + 컨센트 + 목적)

페어로 시작 — `landing-analytics-engineer` + `landing-data-collector`가 데이터 모델·식별 정책을 *합의*. 그 후 디자인·카피·구현·QA 단발 호출.

#### Step 5-B-1: 페어 합의 (TeamCreate 2명)
```
TeamCreate({
  team_name: "landing-data-v2",
  members: [
    { name: "analytics", subagent_type: "general-purpose", model: "opus",
      prompt: ".claude/agents/landing-analytics-engineer.md + .claude/skills/landing-analytics-instrumentation/SKILL.md 따름" },
    { name: "collector", subagent_type: "general-purpose", model: "opus",
      prompt: ".claude/agents/landing-data-collector.md + .claude/skills/landing-data-collection/SKILL.md (특히 references/supabase-integration.md) 따름" },
  ],
})
```
TaskCreate로 합의 포인트 명시:
1. PostHog ↔ Supabase 데이터 분리 표 (역할 분담)
2. distinctId hash 정책 + Supabase `posthog_distinct_id` 컬럼 합의
3. `purpose` enum 값 (`diet`/`digestion`/`other`) — *양쪽에서 동일*
4. `consent_*` 컬럼 + 컨센트 거절 시 분기 (identify 미호출)
5. 환경변수 명세 (`VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY`, `VITE_POSTHOG_KEY`, `VITE_POSTHOG_HOST`, `VITE_HASH_SALT`)

산출물:
- `_workspace/landing/09_analytics_plan.md` (analytics)
- `_workspace/landing/10_consent_strategy.md` (analytics)
- `_workspace/landing/11_analytics_dashboard.md` (analytics)
- `_workspace/landing/12_supabase_schema.md` (collector)
- `_workspace/landing/13_data_v2_consolidated.md` ← *합의 통합* — 두 산출물의 매칭 표·환경변수·코드 진입점 명세

합의 후 `TeamDelete`.

#### Step 5-B-2: 사용자 의사결정 게이트
- Supabase 프로젝트 생성·anon key 받기 (사용자 액션 필요)
- 컨센트 다이얼로그 카피·목적 라벨 사용자 검토
- 13_data_v2_consolidated.md를 사용자에게 보고 + 승인 받기

승인 후 다음 단계.

#### Step 5-B-3: UX·카피 단발 호출 (병렬 가능)
```
Agent({ description: "목적 선택 UI", subagent_type: "general-purpose", model: "opus",
  prompt: ".claude/agents/visual-experience-designer.md 에이전트로서, 13_data_v2_consolidated.md의 purpose enum을 EmailForm 위 라디오/세그먼트로 디자인. 컨센트 다이얼로그 인터랙션 사양도 함께. 출력: _workspace/landing/14_purpose_consent_ux.md" })

Agent({ description: "컨센트·목적 카피", subagent_type: "general-purpose", model: "opus",
  prompt: ".claude/agents/marketing-storyteller.md 에이전트로서, 13_data_v2_consolidated.md의 purpose 라벨 + 컨센트 다이얼로그 카피 + 성공 메시지 작성. 옵션 G 톤. 출력: _workspace/landing/15_consent_copy.md" })
```

#### Step 5-B-4: 구현 단독
```
Agent({ description: "분석·Supabase·컨센트·목적 통합 빌드",
  subagent_type: "general-purpose", model: "opus",
  prompt: ".claude/agents/frontend-implementer.md 에이전트. 입력: landing/ + 13/14/15. 변경: lib/supabaseClient.ts 신규 + lib/posthogClient.ts 신규 + lib/analytics.ts 신규 + lib/hashId.ts 신규 + lib/dataCollection.ts 갱신(Supabase 호출) + components/EmailForm.tsx (목적 UI + 컨센트 흐름) + components/ConsentDialog.tsx 신규 + .env.example 갱신 + main.tsx에 PostHog init. 빌드 통과 + TS strict 통과. 검증: 종단간 1건 → Supabase row + PostHog Activity 모두 확인. 출력: _workspace/landing/16_data_v2_build_report.md" })
```

#### Step 5-B-5: QA·폴리시
```
Agent({ description: "분석·데이터 v2 QA",
  subagent_type: "general-purpose", model: "opus",
  prompt: ".claude/agents/landing-qa-polisher.md 에이전트. 검증: (a) 폼 종단간 success/fail/duplicate 분기 (b) 컨센트 거절 시 identify 미호출 (c) PostHog autocapture가 이메일 input 캡처 안 함 (d) Supabase RLS — anon SELECT 차단 (e) 목적 3개 값 모두 발화 가능 (f) 5초 룰 + 4 디바이스. 출력: _workspace/landing/17_data_v2_qa_report.md + 직접 폴리시" })
```

### Phase 5 진입 조건
- `landing/` 디렉토리 + `EmailForm.tsx` 이미 존재
- 디스커버리 산출물 (`discovery_report.md`, `_workspace/04_product_ideation.md`) 존재 — `purpose` enum의 도메인 정합성 확인용
- 사용자가 PostHog/Supabase 계정을 만들 수 있음 (혹은 만들 의사가 있음)

### Phase 5 종료 후
- 사용자에게 PostHog Insights URL + Supabase Dashboard URL 안내
- 베타 첫 1주 후 funnel·purpose 분포 보고 + 카피·UX 조정 제안 (피드백 라운드)

## 데이터 전달 프로토콜

**파일 기반** 전달:
- 작업 디렉토리: `_workspace/landing/`
- 사이트 본체: `landing/` (프로젝트 루트)
- 파일명 컨벤션:
  - `_workspace/landing/_brief.md`
  - `_workspace/landing/01_strategy_copy.md`
  - `_workspace/landing/02_visual_ux.md`
  - `_workspace/landing/03_architecture.md`
  - `_workspace/landing/04_brief_consolidated.md` ← Phase 2 입력 핵심
  - `_workspace/landing/05_build_report.md`
  - `_workspace/landing/06_qa_report.md`
  - `_workspace/landing/07_data_collection_options.md` (Phase 4)
  - `_workspace/landing/08_data_collection_runbook.md` (Phase 4)
  - `_workspace/landing/09_analytics_plan.md` (Phase 5 — analytics)
  - `_workspace/landing/10_consent_strategy.md` (Phase 5 — analytics)
  - `_workspace/landing/11_analytics_dashboard.md` (Phase 5 — analytics)
  - `_workspace/landing/12_supabase_schema.md` (Phase 5 — collector)
  - `_workspace/landing/13_data_v2_consolidated.md` (Phase 5 — 페어 합의)
  - `_workspace/landing/14_purpose_consent_ux.md` (Phase 5 — designer)
  - `_workspace/landing/15_consent_copy.md` (Phase 5 — storyteller)
  - `_workspace/landing/16_data_v2_build_report.md` (Phase 5 — implementer)
  - `_workspace/landing/17_data_v2_qa_report.md` (Phase 5 — QA)
  - `_workspace/landing/screenshots/` (디바이스별 캡처)
- 이전 실행 보존: `_workspace/_landing_prev_YYYYMMDD_HHMMSS/`

Phase 1 팀 모드에서는 추가로:
- **메시지 기반** (`SendMessage`) — 카피·디자인·아키텍처 상호 검토
- **태스크 기반** (`TaskCreate`/`TaskUpdate`) — 합의 게이트 체크리스트

## 에러 핸들링

| 에러 유형 | 대응 |
|----------|------|
| 디스커버리 산출물 부재 | 즉시 보고, `chew-tracking-discovery` 선행 실행 권고 |
| Phase 1 팀원 1명 실패 | 1회 재시도. 재실패 시 사용자 보고 후 누락된 입력 표시 |
| 04_brief 미완결 (빠진 섹션) | architect에 1회 재호출 + 빠진 섹션 명시 |
| Phase 2 빌드 실패 (빌드 에러) | 구현자에 에러 로그 전달하여 재시도. 2회 실패 시 사용자 보고 |
| Phase 3 Critical 이슈 | QA가 직접 수정 시도 → 실패 시 구현자 재호출 |
| 성능 예산 미달 | designer에게 단순화 협상 요청 (Phase 1 부분 재실행) |
| 사용자가 수동으로 사이트 수정 후 다시 호출 | landing/ 변경 사항을 `git status` 류로 감지, 무시 또는 통합 결정 |

핵심 원칙: 자동 진행보다 *사용자 의사결정 포인트*를 먼저. 빌드는 시간이 들고, 잘못된 방향으로 가면 매몰비용 큼.

## 진행 보고

각 Phase 시작·완료 시 사용자에게 짧은 업데이트:
- "Phase 1 시작 — 카피·디자인·아키텍처 3명 팀이 통합 브리프 작성 (예상 ~10-15분)"
- "Phase 1 완료 — 04_brief_consolidated.md 작성됨. 핵심 결정: [기술 스택], [시그니처 인터랙션 종류]"
- "Phase 2 시작 — 빌드 (예상 30-45분)"
- "Phase 2 완료 — Lighthouse 점수: P/A/SEO=N/N/N. 다음 QA로 이동"
- "Phase 3 완료 — 종합 점수 N/5. Critical 이슈 N개 (수정됨/대기)"

## 최종 출력 — 사용자에게

전 라운드 완료 후:
1. `landing/` 디렉토리에 작동하는 사이트
2. `_workspace/landing/06_qa_report.md`의 종합 평가 + 5초 룰 결과 인용
3. 로컬 미리보기 명령 안내: `cd landing && npm run dev` 또는 `npm run preview`
4. 배포 옵션 제시: Vercel 배포 (`vercel:deploy` 스킬 활용)
5. **피드백 요청**: "특정 섹션을 수정하거나, 카피·디자인 톤을 바꾸고 싶으면 말씀해주세요. 부분 재실행으로 영향받는 부분만 다시 만들 수 있습니다."

## 테스트 시나리오

**정상 흐름:**
1. 사용자: "옵션 G 랜딩 페이지 만들어줘"
2. Phase 0: discovery 산출물 확인 + landing/ 미존재 → 초기 실행
3. _brief.md 작성
4. Phase 1: 팀 3명 합의 → 04_brief_consolidated.md
5. Phase 2: 빌드 → landing/ 디렉토리 생성, Lighthouse 통과
6. Phase 3: QA 검수 → Critical 0개, High 2개 직접 수정 후 재검증
7. 최종 보고 + 미리보기 명령 + 배포 옵션 + 피드백 요청

**부분 재실행 흐름:**
1. 사용자: "Hero 카피만 좀 더 강하게"
2. Phase 0: 기존 _workspace/landing 존재 확인 → 부분 재실행
3. marketing-storyteller만 재호출 (Hero 부분만 수정)
4. landing-architect 재호출 (04_brief 갱신, Hero 섹션만)
5. frontend-implementer 재호출 (Hero.tsx만 수정)
6. landing-qa-polisher 재호출 (Hero 부분 검수)
7. 변경 요약 + 비교 스크린샷 보고

**에러 흐름:**
1. Phase 2 빌드에서 의존성 설치 실패
2. 1회 재시도
3. 재실패 시 사용자에게 에러 로그 보고 + 옵션 제시: (a) 다른 패키지 매니저 시도 (b) 의존성 변경 (c) 중단

## 후속 작업 키워드 검출

| 키워드 | 의도 | 동작 |
|-------|------|------|
| "다시 빌드", "재실행" | 전체 새로 | Phase 0 새 실행 분기 |
| "카피만 수정" | 카피 부분 갱신 | 매트릭스 행 |
| "디자인만 수정" | 디자인 부분 갱신 | 매트릭스 행 |
| "Hero만 다시" / "Pricing 다시" | 섹션 한정 | 3명 팀 (해당 섹션) |
| "QA만 다시", "폴리시 더" | 검수만 | landing-qa-polisher만 |
| "성능 개선", "Lighthouse 통과" | 성능 라운드 | architect → implementer → QA |
| "옵션 F로 피벗" | 컨셉 자체 변경 | 디스커버리 결과 변경 — 큰 변경 안내 후 진행 |
| "이메일 수집", "폼 백엔드", "노션 연결", "구글시트 연결", "웨이트리스트", "Formspree" | 가벼운 데이터 수집 통합 | Phase 4 단독 (landing-data-collector) |
| "PostHog 붙여줘", "사용자 분석", "이벤트 트래킹", "funnel" | 분석 단독 | Phase 5-A (landing-analytics-engineer) |
| "Supabase", "데이터베이스로 받기", "옵트인 동의", "출시 시 연락 동의", "마케팅 컨센트", "다이어트 위염 분류", "사용자 목적 수집" | 분석·데이터 v2 풀세트 | Phase 5-B (페어 + 단발 호출) |
| "Web3Forms에서 Supabase로 마이그" | 마이그레이션 | Phase 5-B (collector가 마이그 패스 책임) |
| "배포해줘", "Vercel 올려줘" | 배포 | vercel:deploy 스킬로 위임 (이 오케스트레이터 외) |

오케스트레이터 우회하여 개별 에이전트를 직접 호출하지 않는다. 사용자가 그렇게 요청해도, 이 오케스트레이터가 적절한 모드로 분기하는 게 맞다.
