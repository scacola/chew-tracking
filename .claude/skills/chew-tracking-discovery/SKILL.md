---
name: chew-tracking-discovery
description: 저작운동·식습관·AirPods IMU 기반 헬스 서비스의 디스커버리(기술 타당성 + 경쟁 + 시장 + 제품 컨셉 + 종합 보고)를 5명의 전문 에이전트로 수행하는 오케스트레이터. "저작운동 트래킹 디스커버리", "에어팟 IMU 식사 검출 사업성 조사", "이 서비스 만들 만한지 종합 조사", "기술·시장·경쟁 다 같이 조사", "디스커버리 보고서" 같은 요청 시 반드시 사용. 후속 작업: "다시 실행", "재실행", "업데이트", "기술만 다시 조사", "시장 부분 보완", "경쟁사 추가 발견", "이전 결과 기반 개선", "보고서 수정", "특정 페르소나 깊게", "새 옵션 추가" 같은 표현에서도 트리거.
---

# Chew Tracking Discovery Orchestrator

저작운동/AirPods IMU 헬스 서비스의 디스커버리 워크플로우를 5명의 전문 에이전트로 조율한다.

## 실행 모드

**서브 에이전트 + 팬아웃/팬인** 패턴. 리서치 영역들이 본질적으로 독립이고 각자 큰 외부 컨텍스트(웹 검색)를 다루므로, 팀 통신 오버헤드보다 컨텍스트 격리 이득이 크다.

- **Phase 1 (병렬)**: 3명의 리서처를 `run_in_background: true`로 동시 호출
- **Phase 2 (직렬, Phase 1 결과 입력)**: 전략가 1명
- **Phase 3 (직렬, 모두 입력)**: 종합자 1명

모든 Agent 호출은 **`model: "opus"`** 명시 필수.

## Phase 0: 컨텍스트 확인 (반드시 먼저)

오케스트레이터 진입 즉시 다음을 확인:

```
1. _workspace/ 디렉토리 존재 여부 확인 (Bash: ls _workspace/ 2>/dev/null)
2. 사용자 요청에서 의도 분류:
   - 부분 키워드 ("기술만", "시장만", "경쟁사 추가") → 부분 재실행
   - "다시", "재실행", "업데이트" → 새 실행 (기존 _workspace를 _workspace_prev/로 이동)
   - 새 입력/도메인 변경 → 새 실행
   - _workspace 미존재 → 초기 실행
```

**부분 재실행 매트릭스**:
| 사용자 의도 | 실행할 에이전트 |
|------------|---------------|
| "기술 다시" | tech-feasibility-researcher → discovery-synthesizer |
| "시장 다시" | market-demand-analyst → product-ideation-strategist → discovery-synthesizer |
| "경쟁사 추가" | competitive-landscape-researcher → product-ideation-strategist → discovery-synthesizer |
| "옵션만 다시" | product-ideation-strategist → discovery-synthesizer |
| "보고서만 수정" | discovery-synthesizer |

**새 실행** 시:
```bash
mv _workspace _workspace_prev_$(date +%Y%m%d_%H%M%S)
mkdir -p _workspace
```

이전 결과를 *덮어쓰지 않고* 보존한다 — 사용자가 비교하거나 되돌릴 수 있도록.

`_workspace/_brief.md`에 사용자의 원본 요청 + 분류한 실행 모드를 기록한다.

## Phase 1: 병렬 리서치 (3 에이전트)

`run_in_background: true`로 한 메시지에 3개 Agent 호출을 묶어 동시 실행:

```
Agent({
  description: "기술 타당성 조사",
  subagent_type: "general-purpose",
  model: "opus",
  prompt: "당신은 .claude/agents/tech-feasibility-researcher.md에 정의된 에이전트다. 해당 파일을 먼저 읽고 그 역할에 따라 작업하라. 또한 .claude/skills/tech-feasibility-research/SKILL.md를 읽고 그 방법론을 따르라. 도메인 브리프: _workspace/_brief.md. 산출물: _workspace/01_tech_feasibility.md",
  run_in_background: true
})

Agent({
  description: "경쟁 환경 조사",
  subagent_type: "general-purpose",
  model: "opus",
  prompt: "당신은 .claude/agents/competitive-landscape-researcher.md에 정의된 에이전트다. ... 산출물: _workspace/02_competitive_landscape.md",
  run_in_background: true
})

Agent({
  description: "시장 수요 분석",
  subagent_type: "general-purpose",
  model: "opus",
  prompt: "당신은 .claude/agents/market-demand-analyst.md에 정의된 에이전트다. ... 산출물: _workspace/03_market_demand.md",
  run_in_background: true
})
```

세 결과 모두 도착 후 다음 단계.

## Phase 2: 제품 컨셉 합성 (1 에이전트, 직렬)

Phase 1의 3개 산출물 모두 도착 확인 후:

```
Agent({
  description: "제품 컨셉 옵션 설계",
  subagent_type: "general-purpose",
  model: "opus",
  prompt: "당신은 .claude/agents/product-ideation-strategist.md에 정의된 에이전트다. .claude/skills/product-ideation/SKILL.md의 방법론을 따른다. _workspace/01_tech_feasibility.md, 02_competitive_landscape.md, 03_market_demand.md를 모두 읽고 _workspace/04_product_ideation.md를 작성하라."
})
```

## Phase 3: 디스커버리 보고서 (1 에이전트, 직렬)

```
Agent({
  description: "디스커버리 종합 보고서",
  subagent_type: "general-purpose",
  model: "opus",
  prompt: "당신은 .claude/agents/discovery-synthesizer.md에 정의된 에이전트다. .claude/skills/discovery-synthesis/SKILL.md의 방법론을 따른다. _workspace/01-04 모두 읽고 프로젝트 루트에 discovery_report.md를 작성하라."
})
```

산출물은 *프로젝트 루트의 `discovery_report.md`*. `_workspace/`는 중간 산출물 보존용.

## 데이터 전달 프로토콜

**파일 기반** 전달:
- 작업 디렉토리: `_workspace/`
- 파일명 컨벤션: `{phase순서}_{역할}.md`
  - `_workspace/_brief.md` — 사용자 원본 요청 + 컨텍스트
  - `_workspace/01_tech_feasibility.md`
  - `_workspace/02_competitive_landscape.md`
  - `_workspace/03_market_demand.md`
  - `_workspace/04_product_ideation.md`
- 최종 산출물: `discovery_report.md` (프로젝트 루트)
- 이전 실행 보존: `_workspace_prev_YYYYMMDD_HHMMSS/`

## 에러 핸들링

| 에러 유형 | 대응 |
|----------|------|
| Phase 1 에이전트 1개 실패 | 1회 재시도. 재실패 시 다른 2개 결과만으로 진행. 보고서에 누락 영역 명시. |
| Phase 1 모두 실패 | 사용자에게 보고하고 중단. 네트워크 또는 권한 이슈일 가능성 |
| Phase 2 입력 부재 | Phase 1 산출물 파일 검사. 없으면 재시도 또는 사용자 보고 |
| Phase 3 입력 부재 | 마찬가지 |
| 출력 파일이 비정상 (너무 짧음, 형식 오류) | 1회 재시도 후 그대로 진행 + 경고 보고 |
| 상충 데이터 발견 | *삭제하지 않고* 출처 병기하여 양쪽 보고서에 모두 노출 |

핵심 원칙: **에러를 숨기지 말고, 누락된 부분을 명시한 채 진행한다.** 빈 보고서가 잘못된 보고서보다 낫다.

## 진행 보고

각 Phase 시작/완료 시 사용자에게 짧은 업데이트:
- "Phase 1 시작 — 기술/경쟁/시장 3개 영역 병렬 리서치 (예상 소요 ~10분)"
- "Phase 1 완료 — 결과 요약: 기술 [GO/조건부GO/NOGO], 시장 [강/중/약], 경쟁 [n개 사례 발견]"

각 산출물의 한 줄 요약을 사용자에게 보여주면 사용자가 중간 검토 가능.

## 최종 출력 사용자에게

종합 보고서 작성 완료 후:
1. `discovery_report.md`의 Executive Summary 부분만 본문에 인용
2. 핵심 권고와 다음 단계 1순위 강조
3. "전체 보고서: `discovery_report.md`. 중간 산출물: `_workspace/`" 안내
4. **피드백 요청**: "특정 섹션을 깊게 보거나 수정할 부분이 있나요? 예: '시장 페르소나 #1 더 깊게', '경쟁사 추가 조사', '컨셉 옵션 D 추가'"

## 테스트 시나리오

**정상 흐름**:
1. 사용자: "/chew-tracking-discovery" 또는 자연어 요청
2. Phase 0: `_workspace/` 없음 확인 → 초기 실행
3. `_workspace/_brief.md` 작성
4. Phase 1: 3 에이전트 병렬 실행 (~5-10분)
5. Phase 1 완료 확인 → 사용자에게 짧은 요약
6. Phase 2: 전략가 실행 (~3-5분)
7. Phase 3: 종합 실행 (~3-5분)
8. `discovery_report.md` 출력 + Executive Summary 인용 + 피드백 요청

**부분 재실행 흐름**:
1. 사용자: "시장 부분 다시 조사해줘"
2. Phase 0: `_workspace/03_market_demand.md` 존재 확인
3. `market-demand-analyst` 호출 (기존 보고서 갱신 모드)
4. 영향받는 후속 에이전트(`product-ideation-strategist`, `discovery-synthesizer`) 재호출
5. 이전 산출물은 `_workspace/03_market_demand_prev.md`로 백업
6. 변경 사항 요약 + 피드백 요청

**에러 흐름**:
1. Phase 1 중 `tech-feasibility-researcher`가 빈 결과 반환
2. 1회 재시도
3. 재실패 시 → 사용자에게 보고하고 옵션 제시: "(a) 기술 부분 누락한 채 진행 (b) 사용자가 직접 기술 자료 제공 (c) 중단"

## 후속 작업 키워드 검출

다음 표현이 사용자 요청에 있으면 *반드시* 이 오케스트레이터를 다시 호출:

| 키워드 | 의미 | 동작 |
|-------|------|------|
| "다시", "재실행" | 전체 새로 | Phase 0에서 새 실행으로 분기 |
| "업데이트", "보완" | 부분 갱신 | Phase 0 부분 재실행 매트릭스 |
| "기술만", "시장만", "경쟁만" | 영역 한정 | 매트릭스의 해당 행 |
| "옵션 추가" | 컨셉 확장 | product-ideation-strategist만 |
| "보고서 수정" | 종합만 | discovery-synthesizer만 |

오케스트레이터를 *수동으로 우회*해서 개별 에이전트를 직접 호출하지 않는다. 사용자가 그렇게 요청해도, 이 오케스트레이터가 적절한 모드로 분기하는 게 맞다.
