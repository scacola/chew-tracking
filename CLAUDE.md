 # Chew Tracking Project

이 프로젝트에는 **세 개의 하네스**가 운영된다 — 디스커버리(의사결정용), 랜딩(마케팅 사이트), iOS 앱(실제 제품). 각 하네스는 독립적으로 트리거되며 산출물 디렉토리도 분리된다.

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

## 하네스 3: Chew Coach iOS 앱

**목표:** 디스커버리 1순위 컨셉(옵션 G)의 *측정 엔진 + 사용자 대시보드 슬라이스*를 실제 작동하는 iOS 네이티브 앱으로 빌드한다. AirPods IMU 자동 식사 검출, SwiftData 기반 식사 세션 저장, 친근한 한국어 코칭 메시지, 5초 룰·접근성·다크모드 통과를 목표로 한다.

**트리거:** AirPods IMU 저작·식습관 트래킹 iOS 앱·Swift/SwiftUI 빌드·식습관 대시보드 앱 관련 요청 시 `chew-coach-app` 스킬을 사용하라. 디스커버리·랜딩은 각각 하네스 1·2를 사용한다.

**스코프 (V1):** 측정 엔진(옵션 G MVP #2) + 사용자 대시보드(MVP #5) + 코칭 메시지 골격(MVP #4 골격). **V1 범위 외** — 28일 코스 콘텐츠(MVP #1, KOL+카피라이터 별도 트랙), 임상 RCT 모듈(MVP #3, 의료 자문 후), 안드로이드(기술 한계).

**산출물 위치:**
- 앱 본체: `app/` (프로젝트 루트, Xcode 프로젝트)
- 작업 산출물: `_workspace/app/01-06*.md`, `_workspace/app/screenshots/`
- 이전 실행 백업: `_workspace/_app_prev_<timestamp>/`, `_workspace/_app_code_prev_<timestamp>/`

**전제:** 디스커버리 산출물(`discovery_report.md`, `_workspace/04_product_ideation.md`, `_workspace/01_tech_feasibility.md`)이 *이미 존재*해야 한다. 빌드 환경: Xcode 16+ + iOS 17+ 시뮬레이터 + xcodegen(권장). 실데이터 검증은 AirPods Pro 2/3/Max + iPhone 실기기 필요(시뮬레이터로는 Mock 모션 스트림으로 흐름·UI만 검증).

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
| 2026-05-02 | 하네스 3 초기 구성 (5 에이전트 + 5 도메인 스킬 + 1 오케스트레이터) — chewing-signal-engineer / ios-app-architect / app-experience-designer / ios-app-implementer / ios-app-qa + chew-coach-app 오케스트레이터. V1 스코프는 옵션 G의 측정 엔진 + 대시보드 슬라이스(MVP #2/#4 골격/#5)로 한정 | app 하네스 전체 | 사용자가 AirPods IMU 기반 저작 트래킹 iOS 앱 제작 요청 |
| 2026-05-03 | iOS 앱 V1 빌드 완료 — Phase 1(신호·아키텍처·UX·통합 브리프) → Phase 2(구현). 60 Swift 소스(11 화면+7 Custom 컴포넌트+SwiftData 6 entity+신호 파이프라인 3-stage+코칭 메시지 32+CMHeadphoneMotionManager Live/Mock 분기). xcodebuild clean build SUCCEEDED, 단위 테스트 29/29 통과 (T1~T12 + repository CRUD + library lint + calibration). 외부 SPM 0건. 앱 코드 워닝 0건 (SwiftData KeyPath warning 7건은 Apple 프레임워크 한계로 잔존) | app/ 코드, _workspace/app/05_build_report | 사용자 빌드 요청, 시뮬 0개 환경에서 시작했으나 platform iOS 26.4 자동 다운로드로 단위 테스트까지 완료 |
| 2026-05-03 | iOS 앱 QA·폴리시 라운드 1 — 종합 4.0/5, 옵션 G 톤 가이드 위반 0건(의료 약속/영어 잔존/도구 프레이밍 모두 0). 9개 파일 11건 이슈 직접 폴리시(Critical 1: 권한 거부 fallback 누락 / High 2 / Medium 5 / Low 3). 5초 룰 통과(시뮬 캡처 3건). 단위 테스트 29/29 회귀 없음. 재작업 요청 5건(구현자 2 + 디자이너 3, 신호 엔지니어 0) + 실기기 전용 검증 항목 8건(F1·권한·audio session·AirPods 분리·Live Activity·BackgroundTasks·iPhone SE FAB·CSV ShareSheet) 사용자 안내 | OnboardingMotionPermissionView·DashboardView·MealResultCard·WeeklyRecapView·Persona·Font 외, _workspace/app/06_qa_report, screenshots/ | 사용자 빌드 요청 (자동 후속) |
| 2026-05-03 | iOS 앱 v1.1 patch — "감지 살리기" 라운드. 사용자 보고 "씹는 횟수 전혀 트래킹 못함" 결함 해결. 신호 엔지니어 v1.1 결정(detrended magnitude로 정류 주파수 2배 결함 해결 + 3-tier 임계값 시스템 [Sensitivity 0.015g/12 → Default 0.025g/18 → Calibrated] + Mock 자동 emitter API). 구현자 14개 파일 변경(Detection 3 + Storage 4 + Sensing 1 + Features 4 + App 1 + Tests 1). 신규 단위 테스트 8개(T13~T18 풀 파이프라인 + ChewSamplePersistence 2). 핵심 보정: ChewDetector abs() 정류 제거 + Mock baseline DC 0.10g (반파 정류 회피). QA 라운드 2 종합 4.2/5, 37/37 통과(T17 정류 결함 회귀 가드 통과 — 1.2Hz sine → 평균 chew 간격 0.83s), 카피 폴리시 3건(디버그 패널 한국어화 + 감도 모드 배지). ChewSample @Model SwiftData 영속화 path 추가. 실기기 안내 6건 추가(총 14건) | _workspace/app/01_signal_processing §v1.1, 05_build_report §v1.1, 06_qa_report 라운드 2, app/Core/Detection·Storage·Sensing·Features 14파일 | 사용자 "음식을 씹어도 검출 0건" 보고 → "정확하진 않아도 감지는 되어야" 요청 |
| 2026-05-03 | iOS 앱 v1.2 — 사후 분석 정확도 개선 라운드 *설계*. IMchew (Lin et al. 2024) 정독 + v1.1 실측 검출률 < 0.30 진단 + 5개 알고리즘 옵션(IMchew-RF / ACF / FFT / Ensemble / HMM) 비교 → **옵션 D Ensemble (룰 + ACF + Spectral + gyro veto) 채택**. IMchew 차용 핵심 기법 4개: ★1 FFT-peak counting 10초 윈도우 (lab MAPE 9.51%) / ★2 Butterworth 0.1-3Hz + Moving Average / ★5 3-of-N majority voting / ★8 gyro veto. KPI 현실화: F1 0.55-0.65 (학술 wild 0.71 근접) + chew count MAPE ±20-25%. **권장 경로 B (단계적)** — 2주 데이터 수집 인프라(IMUFrame @Model + CSV export + Settings 옵트인) → 베타 협력자 5–10명 × 20+ 식사 누적 → Python notebook 검증 + 매직 넘버 튜닝 → 본구현. 구현·QA는 사용자 결정 후 별도 라운드 | _workspace/app/01_signal_processing §v1.2 (1068→2059줄, +991줄) | 사용자 실 AirPods 검증 결과 검출률 매우 낮음 → "사후 분석으로도 OK, IMchew.pdf 참고해서 정확도 개선" 요청 |
| 2026-05-04 | 하네스 2 확장 — 백엔드리스 데이터 수집 에이전트 추가 | `.claude/agents/landing-data-collector.md` + `.claude/skills/landing-data-collection/SKILL.md` + `chew-coach-landing` 오케스트레이터 Phase 4 + 후속 키워드 표 갱신 | 사용자 요청: "랜딩 페이지에 이메일 수집 기능 추가, 별도 백엔드 없이 노션·구글시트 등 옵션 탐색 후 가벼운 방식으로 구현" — 정적 GitHub Pages 호스팅이라는 강한 제약(클라이언트 비밀 노출·CORS 차단) 하에서 옵션 비교·구현·운영 가이드를 한 사이클로 책임지는 에이전트 1명을 추가, 오케스트레이터 새 빌드와는 직교한 후속 모드로 통합 |
| 2026-05-03 | iOS 앱 v1.2 1단계 — **데이터 수집 인프라 빌드**. 신호 §v1.2-6/§v1.2-9 사양대로 IMUFrame @Model + IMUFrameBuffer (1초 batch flush, NSLock thread-safe) + MealRepository 6개 메서드 (appendIMUFrames/imuFrameCount/imuFrameTotalStats/deleteIMUFrames/deleteAllIMUFrames/exportIMUFramesCSV) + PostHocAnalyzer protocol + RuleBasedAnalyzer no-op stub + Settings 옵트인 토글(default OFF, privacy first) + MealDetail "IMU 데이터 내보내기" 버튼(옵트인 시만 노출). 11개 파일 변경 + 신규 IMUFrame.swift / IMUFrameBuffer.swift / PostHocAnalyzer.swift / IMUDataCollectionTests.swift. 신규 단위 테스트 T19~T22 4개 모두 통과 → **41/41 (37→41)**. 빌드 SUCCEEDED, 앱 코드 워닝 0건. 메모리 추정: 식사 1회 ~2.7 MB 디스크, 30일 누적 ~405 MB (베타 사용자 안내). 옵션 G 톤 카피 — 의료 약속 0건, 친근/정직 어조, "익명·기기에만·명시적 export·언제든 끄기·삭제" 4가지 명시 | app/ChewCoach/Core/Storage·Detection / Features/Settings·MealHistory·ActiveMeal / App, ChewCoachTests, _workspace/app/05_build_report §v1.2-1 | 신호 §v1.2-11 권장 경로 B 1단계 — 알고리즘 본구현 전 인프라 먼저 |
| 2026-05-04 | 하네스 2 확장 v2 — **분석·데이터 인프라** (PostHog + Supabase + 컨센트 + 목적). 신규: `.claude/agents/landing-analytics-engineer.md` + `.claude/skills/landing-analytics-instrumentation/SKILL.md` (이벤트 taxonomy 표준 + funnel + identify/익명 정책 + autocapture PII 차단). 확장: `landing-data-collector.md`(Supabase·옵트인·목적 책임 추가, 8 함정 → 11 함정) + `landing-data-collection/SKILL.md`(핵심 원칙 #6/#7/#8 + Tier B+ Supabase + 의사결정 트리 갱신 + `references/supabase-integration.md` 신규 — 스키마 DDL·RLS·supabase-js·마이그 가이드) + `chew-coach-landing` 오케스트레이터(실행 모드 표 5행 확장 + Phase 5 신규: 분석·데이터 v2 인프라, 페어→단발 호출 하이브리드 / 5-A 분석 단독 / 5-B 풀세트 + 부분 재실행 매트릭스 4행 추가 + 후속 키워드 표 4행 추가 + 파일명 컨벤션 09~17 추가). PII 분리 표준(PostHog ↔ Supabase) + RLS 강제 + `purpose` enum(`diet`/`digestion`/`other`) + `consent_marketing`/`consent_at`/`consent_version` 3-컬럼 표준 + 옵션 G 톤 컨센트 카피 ("출시되면 이메일로 알려드릴게요") | `.claude/agents/landing-analytics-engineer.md` 신규, `.claude/skills/landing-analytics-instrumentation/SKILL.md` 신규, `landing-data-collector.md` 확장, `landing-data-collection/SKILL.md` + `references/supabase-integration.md` 신규, `chew-coach-landing/SKILL.md` 갱신, CLAUDE.md | 사용자 요청: "PostHog로 사용자 분석 + 다이어트/소화불량/위염/기타 목적 분류 + 출시 시 연락 옵트인 동의 + Supabase 백엔드". 4개 격차(PostHog 0건·목적 미수집·컨센트 카피만·Web3Forms write-only)를 한 라운드로 해결. Retrospect_Archive(hyunn522) 참고 — `track()` 단일 진입점 + 유니온 타입 + Provider 격리 패턴 차용 |
