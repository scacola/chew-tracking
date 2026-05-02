# Chew Tracking Project

이 프로젝트에는 **두 개의 하네스**가 운영된다 — 디스커버리(의사결정용)와 랜딩(마케팅 사이트). 각 하네스는 독립적으로 트리거되며 산출물 디렉토리도 분리된다.

---

## 하네스 1: 저작운동 트래킹 서비스 디스커버리

**목표:** AirPods IMU 센서 기반 저작운동/식사 속도 트래킹 서비스의 **기술 타당성 + 시장 수요 + 경쟁 환경 + 제품 컨셉**을 종합 디스커버리하여 GO/NO-GO/PIVOT 의사결정 근거를 만든다.

**트리거:** 저작운동·식습관·AirPods IMU·식사 속도·마음챙김 식사 관련 디스커버리/리서치/제품 기획 요청 시 `chew-tracking-discovery` 스킬을 사용하라. 단순 질문(예: "AirPods가 뭐야?")은 직접 응답 가능.

**산출물 위치:**
- 최종 보고서: `discovery_report.md` (프로젝트 루트)
- 중간 산출물: `_workspace/01-04*.md`, `_workspace/_brief.md`
- 이전 실행 백업: `_workspace/_prev_<timestamp>/`

---

## 하네스 2: Chew Coach 마케팅 랜딩 페이지

**목표:** 디스커버리 1순위 컨셉(옵션 G "Chew & Calm Coach")의 *인터랙티브 마케팅 랜딩 페이지*를 빌드한다. Apple·Linear·Stripe·Vercel급 퀄리티 기준, 결과 지향 카피, 5초 룰 통과, Lighthouse 통과를 목표로 한다.

**트리거:** 랜딩 페이지·마케팅 사이트·인터랙티브 웹 빌드·Chew Coach 페이지 관련 요청 시 `chew-coach-landing` 스킬을 사용하라. 디스커버리 자체는 하네스 1을 사용한다.

**산출물 위치:**
- 사이트 본체: `landing/` (프로젝트 루트, 코드)
- 빌드 산출: `landing/dist/`
- 작업 산출물: `_workspace/landing/01-06*.md`, `screenshots/`
- 이전 실행 백업: `_workspace/_landing_prev_<timestamp>/`

**전제:** 이 하네스는 디스커버리 산출물(`discovery_report.md`, `_workspace/04_product_ideation.md`)이 *이미 존재*해야 정상 작동한다. 옵션 G 정보가 없으면 하네스 1을 먼저 실행한다.

---

## 변경 이력 (전체 프로젝트)

| 날짜 | 변경 내용 | 대상 | 사유 |
|------|----------|------|------|
| 2026-05-01 | 하네스 1 초기 구성 (5 에이전트 + 5 스킬 + 1 오케스트레이터) | discovery 하네스 전체 | - |
| 2026-05-01 | 디스커버리 1차 실행 — 5개 컨셉 도출, 옵션 B(Slow Bites) 1순위, 조건부 GO | discovery_report.md, _workspace/01-04 | 초기 실행 |
| 2026-05-01 | 디스커버리 컨셉 보강 라운드 — 사용자 인사이트(주관 인식 약함, 콘텐츠/페르소나 = 해자, Apple 방어형)를 입력으로 콘텐츠/처방 기반 코칭 카테고리 심화 조사 + 옵션 F·G·H 추가, 1순위를 옵션 G "Chew & Calm Coach"로 교체 | 02_competitive_landscape, 04_product_ideation, discovery_report | 사용자 의견 기반 새 컨셉 발굴 요청 |
| 2026-05-01 | 하네스 2 초기 구성 (5 에이전트 + 5 스킬 + 1 오케스트레이터) | landing 하네스 전체 | 옵션 G의 인터랙티브 마케팅 랜딩 페이지 제작 요청 |
| 2026-05-02 | 랜딩 페이지 빌드 — Phase 1 카피·디자인·아키텍처 합의 + Phase 2 빌드 (Vite+React+Tailwind+GSAP+Lenis) 완료. 11 섹션 + 15 컴포넌트 + 4개 SVG 자산. gzipped 82.6KB | landing/ 코드, _workspace/landing/01-05 | 사용자 빌드 요청 |
| 2026-05-02 | QA·폴리시 라운드 1 — 의사·KOL 컨택 표시 모두 제거(14건), 어색한 카피 2건 다듬기, Differentiation 5→4 카드 재배치, Authority 권위 인용 → 닫는 메시지로 교체 | Hero·HowItWorks·Differentiation·Authority·Solution·AirPodsDemo, 06_qa_report | 사용자 QA 요청 (이상한 문구 제거 + 의사 컨택 제거) |
