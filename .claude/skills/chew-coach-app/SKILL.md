---
name: chew-coach-app
description: 옵션 G "Chew & Calm Coach"의 iOS 앱(AirPods IMU 저작·식습관 트래킹 측정 엔진 + 사용자 대시보드)을 5명의 전문 에이전트(신호 엔지니어·아키텍트·UX 디자이너·구현자·QA)로 빌드하는 오케스트레이터. "에어팟 저작 트래킹 앱 만들어줘", "iOS 앱 빌드", "씹는 횟수 감지 앱", "AirPods IMU 식습관 앱", "Chew Coach 앱", "옵션 G 앱 구현", "디스커버리 결과를 앱으로", "식습관 대시보드 앱" 같은 요청 시 반드시 사용. 후속 작업: "다시 빌드", "재실행", "신호 알고리즘만 수정", "UX만 수정", "특정 화면 다시", "QA만 다시", "폴리시 더", "이전 빌드 기반 개선", "앱 업데이트" 같은 표현에서도 트리거.
---

# Chew Coach App Orchestrator

옵션 G "Chew & Calm Coach"의 iOS 앱(측정 엔진 + 사용자 대시보드 슬라이스) 빌드 워크플로우를 5명의 전문 에이전트로 조율한다. 이 하네스는 *디스커버리 하네스(`chew-tracking-discovery`)* 및 *랜딩 하네스(`chew-coach-landing`)와 별개* — 각각 의사결정 보고서, 마케팅 웹사이트, 실제 iOS 앱.

## 스코프 — 무엇을 빌드하고 무엇을 빌드하지 않는가

**V1에서 빌드:** 옵션 G의 *측정 엔진 + 사용자 대시보드 + 코칭 메시지 골격*
- AirPods IMU 자동 식사 검출 (옵션 G MVP #2)
- 식사 세션 데이터 저장·대시보드 시각화 (옵션 G MVP #5)
- 친근한 한국어 코칭 메시지 라이브러리 (옵션 G MVP #4 골격)
- iOS 17+ 네이티브 앱

**V1에서 *빌드하지 않음*:**
- 28일 위 건강 회복 코스 콘텐츠 (옵션 G MVP #1) — KOL 영입·콘텐츠 제작 별도 트랙
- 임상 RCT 데이터 수집 모듈 PRO 척도 통합 (옵션 G MVP #3) — 별도 의료 자문 후
- 안드로이드 (기술 한계, 디스커버리 결정)
- B2B 화이트라벨 (BM 단계 1 D2C 검증 후)

이 분리를 사용자에게 *명시적으로* 보고하고 시작.

## 실행 모드 — 하이브리드

Phase별 특성이 다르므로 하이브리드:

| Phase | 모드 | 이유 |
|-------|-----|------|
| **Phase 1: 설계 (팀)** | 에이전트 팀 (3명) | 신호·아키·UX는 *상호 영향* — 팀 통신으로 합의 |
| **Phase 2: 구현** | 서브 (1명) | 단일 집중 작업, 팀 통신 불필요 |
| **Phase 3: QA·폴리시** | 서브 (1명) | 독립 검증, 발견 시 재호출 트리거 |

모든 Agent 호출은 **`model: "opus"`** 명시 필수.

## Phase 0: 컨텍스트 확인

오케스트레이터 진입 즉시:

```
1. discovery_report.md + _workspace/04_product_ideation.md 존재 확인 (옵션 G 정보 입력)
   - 디스커버리 산출물이 없으면 사용자에게 보고 후 chew-tracking-discovery 우선 실행 권고
2. _workspace/01_tech_feasibility.md 존재 확인 (기술 baseline 입력)
3. _workspace/app/ 디렉토리 존재 여부 확인
4. app/ 디렉토리 (Xcode 프로젝트) 존재 여부 확인
5. 사용자 요청에서 의도 분류:
   - "다시 빌드", "재실행" → 새 실행 (기존 _workspace/app, app/을 _prev_*로 백업)
   - "알고리즘만 수정" → chewing-signal-engineer 재호출 → ios-app-implementer (영향 부분) → ios-app-qa
   - "UX만 수정" → app-experience-designer + ios-app-architect → ios-app-implementer → QA
   - "QA만 다시" → ios-app-qa만
   - "특정 화면 다시" → 해당 화면 디자이너+아키텍트+구현자
   - 기존 산출물 미존재 → 초기 실행
```

**부분 재실행 매트릭스:**

| 사용자 의도 | 실행할 에이전트 |
|------------|---------------|
| "신호 알고리즘만 수정" | chewing-signal-engineer → ios-app-architect (브리프 갱신) → ios-app-implementer (Detection 모듈만) → ios-app-qa |
| "UX/화면만 수정" | app-experience-designer → ios-app-architect → ios-app-implementer (영향 화면) → ios-app-qa |
| "코칭 메시지만 추가" | app-experience-designer (메시지 라이브러리 확장) → ios-app-implementer (MessageEngine만) → ios-app-qa |
| "특정 화면 다시" | 3명 팀 모두 (해당 화면만) → ios-app-implementer → ios-app-qa |
| "QA·폴리시 더" | ios-app-qa만 (필요 시 ios-app-implementer 재호출) |
| "정확도 개선" | chewing-signal-engineer (KPI·캘리브레이션) → ios-app-implementer (Detection·테스트) → ios-app-qa |
| "권한 흐름 변경" | ios-app-architect → ios-app-implementer → ios-app-qa |

새 실행 시:
```bash
ts=$(date +%Y%m%d_%H%M%S)
[ -d _workspace/app ] && mv _workspace/app _workspace/_app_prev_$ts
[ -d app ] && mv app _workspace/_app_code_prev_$ts
mkdir -p _workspace/app
```

`_workspace/app/_brief.md`에 사용자 원본 요청 + 디스커버리 옵션 G 발췌 + V1 스코프 명시 + 실행 모드를 기록.

## Phase 1: 설계 — 에이전트 팀 (3명)

**실행 모드: 에이전트 팀**

3명의 팀 구성:
- `chewing-signal-engineer` (신호 처리·검출 알고리즘)
- `app-experience-designer` (화면·UX·코칭 메시지)
- `ios-app-architect` (기술 명세 통합)

팀 워크플로우:
1. 오케스트레이터가 `TeamCreate`로 팀 생성, 각 멤버를 `general-purpose`로 추가, 모두 `model: "opus"`
2. 모두에게 공통 입력(`_workspace/app/_brief.md`, `discovery_report.md`, `_workspace/04_product_ideation.md`, `_workspace/01_tech_feasibility.md`)을 알림
3. 각자 *초안* 작성:
   - signal-engineer → `_workspace/app/01_signal_processing.md`
   - designer → `_workspace/app/03_app_ux_spec.md`
   - architect → `_workspace/app/02_app_architecture.md` (팀이 합의 단계 들어가기 전 stub만)
4. 팀 통신 (`SendMessage`)으로 *상호 영향 검토*:
   - signal-engineer가 검출 지연 5–10초 → designer에게 *실시간 햅틱 대신 사후 알림* 권고
   - designer가 화면 인벤토리 → architect에게 SwiftUI 가능성 검토
   - architect가 백그라운드 한계 → designer에게 *foreground 사용 명시 UX* 권고
5. 합의 후 architect가 `_workspace/app/04_app_brief_consolidated.md` 최종 통합 (알고리즘 + 화면 + 컴포넌트 명세 + 빌드 단계 모두 포함)
6. 오케스트레이터가 04_brief 파일 존재·완결성 확인 후 팀 정리 (`TeamDelete`)

### 팀 합의 게이트 (Phase 1 종료 조건)

다음 모두 충족해야 Phase 2로:
- 01_signal_processing.md: 알고리즘 의사코드, KPI(F1·CPM 정확도), 학술 baseline 인용, 4대 한계, 캘리브레이션 전략 ✓
- 03_app_ux_spec.md: 7일 여정, 화면 인벤토리, 코칭 메시지 30개+, 디자인 토큰, 접근성 가드, 5초 룰 시나리오 ✓
- 02_app_architecture.md: 기술 스택, Xcode 프로젝트 구조, 컴포넌트 명세, SwiftData 모델, 권한 흐름, 빌드 단계 ✓
- 04_app_brief_consolidated.md: 위 셋을 *ios-app-implementer가 그대로 빌드 가능한* 형태로 통합 ✓

미충족 시 해당 에이전트 1회 재호출. 재실패 시 사용자에게 보고하고 누락 부분 명시.

## Phase 2: 구현 — 서브 에이전트

**실행 모드: 서브 에이전트**

```
Agent({
  description: "iOS 앱 빌드",
  subagent_type: "general-purpose",
  model: "opus",
  prompt: "당신은 .claude/agents/ios-app-implementer.md에 정의된 에이전트다. .claude/skills/ios-app-craft/SKILL.md의 6단계 빌드 방법론을 따른다. 입력: _workspace/app/04_app_brief_consolidated.md. 빌드 산출물: 프로젝트 루트의 app/ 디렉토리 (Xcode 프로젝트). 빌드 보고: _workspace/app/05_build_report.md. 6단계 모두 검증 후 종료. 검증 누락 금지. xcodegen 사용 권장 (없으면 brew install xcodegen 시도, 실패 시 사용자에게 안내)."
})
```

(병렬 실행 불필요 — 단일 작업이므로 background 옵션 사용해도 무방, 결과 받을 때까지 대기.)

**환경 의존성:**
- Xcode 16+ 필요 (사용자 머신에 설치되어야 함)
- 시뮬레이터: iPhone 15 (iOS 17+)
- xcodegen 권장 (brew install)
- 환경 부재 시 구현자가 사용자에게 보고하고 빌드 중단

## Phase 3: QA·폴리시 — 서브 에이전트

**실행 모드: 서브 에이전트**

```
Agent({
  description: "iOS 앱 QA·폴리시",
  subagent_type: "general-purpose",
  model: "opus",
  prompt: "당신은 .claude/agents/ios-app-qa.md 에이전트다. .claude/skills/ios-app-qa-polish/SKILL.md의 3축 검증 방법론(기능·신호UX톤·접근성)을 따른다. 입력: app/ + _workspace/app/04_app_brief_consolidated.md + _workspace/app/05_build_report.md. 출력: _workspace/app/06_qa_report.md + 직접 수정한 코드. 디바이스 매트릭스 4개 + 5초 룰 + 옵션 G 톤 가이드 grep 필수. 시뮬레이터로 검증 못하는 항목은 '실기기 전용'으로 별도 표시."
})
```

QA가 Critical 이슈 발견 시:
- 직접 수정 가능 → 직접 수정 후 재검증
- 구현자 재작업 필요 → ios-app-implementer 1회 재호출
- 신호·UX·아키텍처 재작업 필요 → 사용자에게 보고 후 Phase 1 부분 재실행 결정

## 데이터 전달 프로토콜

**파일 기반** 전달:
- 작업 디렉토리: `_workspace/app/`
- 앱 본체: `app/` (프로젝트 루트, Xcode 프로젝트)
- 파일명 컨벤션:
  - `_workspace/app/_brief.md`
  - `_workspace/app/01_signal_processing.md`
  - `_workspace/app/02_app_architecture.md`
  - `_workspace/app/03_app_ux_spec.md`
  - `_workspace/app/04_app_brief_consolidated.md` ← Phase 2 입력 핵심
  - `_workspace/app/05_build_report.md`
  - `_workspace/app/06_qa_report.md`
  - `_workspace/app/screenshots/` (시뮬레이터 캡처)
- 이전 실행 보존: `_workspace/_app_prev_YYYYMMDD_HHMMSS/`, `_workspace/_app_code_prev_*/`

Phase 1 팀 모드에서는 추가로:
- **메시지 기반** (`SendMessage`) — 신호·디자이너·아키텍트 상호 검토
- **태스크 기반** (`TaskCreate`/`TaskUpdate`) — 합의 게이트 체크리스트

## 에러 핸들링

| 에러 유형 | 대응 |
|----------|------|
| 디스커버리 산출물 부재 | 즉시 보고, `chew-tracking-discovery` 선행 실행 권고 |
| Xcode 미설치 | 사용자에게 보고 + `xcode-select --install` 안내, 빌드 중단 |
| xcodegen 미설치 | `brew install xcodegen` 시도, 실패 시 .xcodeproj 수동 생성 fallback |
| Phase 1 팀원 1명 실패 | 1회 재시도. 재실패 시 사용자 보고 후 누락된 입력 표시 |
| 04_brief 미완결 (빠진 섹션) | architect에 1회 재호출 + 빠진 섹션 명시 |
| Phase 2 빌드 실패 (xcodebuild 에러) | 구현자에 에러 로그 전달하여 재시도. 2회 실패 시 사용자 보고 |
| Phase 2 단위 테스트 실패 | 구현자에게 fix 요청. 알고리즘 수정 필요 시 신호 엔지니어 재호출 |
| Phase 3 Critical 이슈 | QA가 직접 수정 시도 → 실패 시 구현자 재호출 |
| 신호 정확도 KPI 미달 | signal-engineer 재호출 (Phase 1 부분 재실행) — 학술 baseline 천장 인용 가능 |
| 옵션 G 톤 가이드 위반 | QA가 직접 수정(카피 수정)이거나 designer 재호출(시스템 변경) |
| 사용자가 수동으로 코드 수정 후 다시 호출 | git status로 감지, 무시 또는 통합 결정 |

핵심 원칙: 자동 진행보다 *사용자 의사결정 포인트*를 먼저. 빌드는 시간이 들고, 잘못된 방향으로 가면 매몰비용 큼.

## 진행 보고

각 Phase 시작·완료 시 사용자에게 짧은 업데이트:
- "Phase 0: 디스커버리 산출물 확인 + V1 스코프(측정·대시보드 슬라이스) 보고"
- "Phase 1 시작 — 신호·UX·아키텍처 3명 팀이 통합 브리프 작성 (예상 ~15-25분)"
- "Phase 1 완료 — 04_app_brief_consolidated.md 작성됨. 핵심 결정: [기술 스택], [V1 알고리즘], [화면 N개]"
- "Phase 2 시작 — Xcode 프로젝트 빌드 (예상 30-60분, Xcode 환경 필요)"
- "Phase 2 완료 — xcodebuild SUCCESS, 단위 테스트 N/N 통과. 다음 QA로"
- "Phase 3 완료 — 종합 점수 N/5. Critical 이슈 N개 (수정됨/대기). 실기기 전용 검증 항목 N개 사용자 안내"

## 최종 출력 — 사용자에게

전 라운드 완료 후:
1. `app/` 디렉토리에 빌드 통과한 Xcode 프로젝트
2. `_workspace/app/06_qa_report.md`의 종합 평가 + 5초 룰 결과 인용
3. 시뮬레이터 실행 명령 안내:
   ```bash
   cd app
   xcodebuild -scheme ChewCoach -destination 'platform=iOS Simulator,name=iPhone 15' build
   open ChewCoach.xcodeproj  # Xcode에서 ⌘R
   ```
4. **실기기 검증 가이드** — AirPods Pro 2/3/Max + iPhone 17.0+에서 검증해야 할 항목 리스트 (QA 보고서의 "실기기 전용 검증 항목")
5. **다음 트랙 안내** — V1 외 작업 (KOL 콘텐츠 / 임상 RCT / 28일 코스 / 마케팅 등)은 별도 트랙임을 명시
6. **피드백 요청**: "특정 화면을 수정하거나, 알고리즘 정확도·코칭 톤을 바꾸고 싶으면 말씀해주세요. 부분 재실행으로 영향받는 부분만 다시 만들 수 있습니다."

## 테스트 시나리오

**정상 흐름:**
1. 사용자: "옵션 G 앱 만들어줘" / "에어팟으로 씹는 횟수 감지하는 iOS 앱"
2. Phase 0: discovery 산출물 확인 + app/ 미존재 → 초기 실행 + V1 스코프 보고
3. _brief.md 작성 (V1 스코프 명시)
4. Phase 1: 팀 3명 합의 → 04_app_brief_consolidated.md
5. Phase 2: 빌드 → app/ 디렉토리 생성, xcodebuild 통과, 단위 테스트 통과
6. Phase 3: QA 검수 → Critical 0개, High 2개 직접 수정 후 재검증
7. 최종 보고 + 시뮬레이터 실행 가이드 + 실기기 검증 가이드 + 다음 트랙 안내 + 피드백 요청

**부분 재실행 흐름:**
1. 사용자: "코칭 메시지가 좀 딱딱한 것 같아. 더 다정하게."
2. Phase 0: 기존 _workspace/app 존재 확인 → 부분 재실행
3. app-experience-designer만 재호출 (코칭 메시지 라이브러리 톤 조정)
4. ios-app-architect 재호출 (04_brief 갱신, 메시지 라이브러리 부분만)
5. ios-app-implementer 재호출 (MessageEngine·MessageTemplates만 수정)
6. ios-app-qa 재호출 (코칭 메시지 grep + 톤 가이드 검증)
7. 변경 요약 + before/after 메시지 비교 보고

**에러 흐름 1 — Xcode 미설치:**
1. Phase 2 진입 시 `xcodebuild -version` 실패
2. 즉시 사용자 보고 + `xcode-select --install` 안내
3. 사용자 설치 완료 후 재호출 대기 (자동 진행 X)

**에러 흐름 2 — 신호 정확도 KPI 미달:**
1. Phase 3 QA가 단위 테스트 결과 확인 → 알고리즘 정확도 KPI 미달
2. 사용자 보고 + chewing-signal-engineer 재호출 권고
3. signal-engineer가 학술 baseline 천장 인용 → KPI 재정의 또는 캘리브레이션 강화
4. ios-app-implementer 재호출 (Detection 모듈만)
5. QA 재검증

## 후속 작업 키워드 검출

| 키워드 | 의도 | 동작 |
|-------|------|------|
| "다시 빌드", "재실행" | 전체 새로 | Phase 0 새 실행 분기 |
| "알고리즘만 수정", "정확도 올려줘" | 신호 부분 갱신 | 매트릭스 행 |
| "UX만 수정", "화면 다시" | UX 부분 갱신 | 매트릭스 행 |
| "코칭 메시지 추가", "톤 바꿔줘" | 메시지 라이브러리 | designer → implementer (MessageEngine만) → QA |
| "Dashboard만 다시" / "Onboarding 다시" | 화면 한정 | 3명 팀 (해당 화면) → implementer → QA |
| "QA만 다시", "폴리시 더" | 검수만 | ios-app-qa만 |
| "권한 흐름 변경" | 아키 부분 | architect → implementer → QA |
| "안드로이드도 지원" | 컨셉 자체 변경 | 디스커버리 결정(불가) 인용 + 대안(웹 dashboard) 제안 |
| "App Store 출시", "TestFlight" | 배포 | V1 범위 외 — 별도 트랙 안내 (provisioning·임상 검토 필요) |
| "28일 코스 콘텐츠", "KOL 영입" | V1 범위 외 | 별도 트랙 안내 (콘텐츠 제작·KOL 인터뷰 작업) |

오케스트레이터 우회하여 개별 에이전트를 직접 호출하지 않는다. 사용자가 그렇게 요청해도, 이 오케스트레이터가 적절한 모드로 분기하는 게 맞다.

## V1 범위 외 작업 (별도 트랙)

이 오케스트레이터는 *측정·대시보드 슬라이스만* 다룬다. 다음은 별도 워크플로우 또는 외부 작업:

| 작업 | 트랙 | 비고 |
|------|------|------|
| 28일 위 건강 코스 콘텐츠 | 콘텐츠 제작 (KOL + 카피라이터) | 디스커버리 옵션 G 가설#4 (8주 게이트) |
| 임상 RCT 데이터 수집 모듈 (PRO 척도) | 의료 자문 후 별도 빌드 | GERDQ, Rome IV FD |
| KOL 영입 (한국 소화기내과·신경과학자) | 8주 검증 게이트 작업 | 디스커버리 즉시 행동 1순위 |
| App Store 등록·심사 | DevOps + 법률 검토 | provisioning, 의료 카테고리 검토 |
| TestFlight 베타 | 테스트 그룹 모집 + 피드백 수집 | 별도 워크플로우 |
| 백엔드 (사용자 계정·동기화·익명 통계) | 별도 백엔드 하네스 | V1.5+ 후보 |
| 마케팅 랜딩 페이지 | `chew-coach-landing` 하네스 | 이미 운영 중 |

이 작업들이 필요해지면 별도 하네스 또는 사용자 결정 후 새 작업으로 진행.
