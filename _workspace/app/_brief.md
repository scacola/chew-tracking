# Chew Coach iOS App — 빌드 브리프

**작성일**: 2026-05-02
**오케스트레이터**: `chew-coach-app`
**실행 모드**: 초기 실행 (기존 _workspace/app, app/ 모두 미존재)

---

## 1. 사용자 원본 요청

> 옵션 G IOS 앱 만들어줘
>
> (앞선 컨텍스트) 에어팟을 이용하여서 저작운동을 트랙킹하는 앱을 제작하려고 합니. 에어팟의 IMU 센서를 이용하여 사용자의 씹는 횟수, 속도 등을 감지하여 올바른 식습관을 형성할 수 있도록 하고자 합니다. 사용자가 자신의 식습관 현황을 확인할 수 있도록 효과적인 앱을 만들고자 합니다.

---

## 2. V1 스코프 (옵션 G의 측정·대시보드 슬라이스)

### 빌드 대상 (V1)

옵션 G "Chew & Calm Coach"의 *측정 엔진 + 사용자 대시보드 + 코칭 메시지 골격*:

1. **AirPods IMU 자동 식사 검출** (옵션 G MVP #2) — `CMHeadphoneMotionManager` 통합, 룰 기반 검출 알고리즘 V1, F1 0.75–0.85 KPI 목표
2. **식사 세션 데이터 저장 + 대시보드 시각화** (옵션 G MVP #5) — SwiftData 모델, 7일 추이 차트(Swift Charts), Discoveries 카드 V1
3. **친근한 한국어 코칭 메시지 라이브러리 (골격)** (옵션 G MVP #4 골격) — 다노식 친근 톤 30개+ 템플릿, 의료 약속 금지

### V1 범위 외 (별도 트랙)

- ❌ 28일 위 건강 회복 코스 콘텐츠 (옵션 G MVP #1) — KOL 영입 + 카피라이터 협업 별도 트랙
- ❌ 임상 RCT 데이터 수집 모듈 (옵션 G MVP #3, GERDQ·Rome IV FD) — 의료 자문 후 별도 빌드
- ❌ 안드로이드 (디스커버리 결정 — 기술 한계 [기술-결론#1.3])
- ❌ B2B 화이트라벨 (BM 단계 1 D2C 검증 후)
- ❌ App Store 등록·심사 (V1 외, provisioning + 의료 카테고리 검토 필요)
- ❌ 백엔드·계정·동기화 (V1.5+ 후보, V1은 로컬 only)

---

## 3. 디스커버리 옵션 G 발췌 (입력)

### 한 문장 정의 [discovery_report.md §5.1]

> *위염·식후 더부룩함·소화불량으로 고생하는 30·40대 한국 직장인*이 임상 신경과학 기반 28일 코스와 AirPods 자동 측정으로 *식사 후 위 컨디션을 회복*하게 만드는, 임상 권위 + 친근 페르소나가 결합된 디지털 코치.

### 1순위·2순위 페르소나 [discovery §3.3]

- **한지원 (1순위, 강도 8/10)** — 32세 IT 개발자, 위염 진단, 점심 12분, 영상 시청, AirPods 매일. 지불의향 4–7천원/월
- **박소연 (2순위, 7/10)** — 29세 마케터, 다이어트 정체기, 자기진단 완료. 지불의향 3천–9,900원/월

### 핵심 톤·포지셔닝 (앱 전반에 적용)

- **결과 프레이밍** — "씹기 트래커" ❌ → "위 건강·체중 결과 코치" ✓
- **다노식 친근 + 임상 권위 균형** — "오늘 8분에 드셨어요. 다음 식사를 11분에 가볼까요?"
- **거짓 약속 금지** — "100% 정확", "위염 치료" 표현 금지 (Vessyl·Healbe 함정 회피)
- **5초 룰** — 첫 실행 5초 / 첫 식사 결과 5초 안에 무엇/누구/다음행동 답 가능

---

## 4. 기술 baseline 입력 (`_workspace/01_tech_feasibility.md` 핵심)

- **API**: `CMHeadphoneMotionManager`, AirPods Pro/3세대/Max 한정, iOS 17+
- **샘플링 레이트**: ~25Hz (Nyquist 12.5Hz, 일반 저작 빈도 0.94–2Hz 충분)
- **단일 채널** (좌·우 동시 IMU 불가)
- **백그라운드 회색지대** — V1은 *foreground + audio session active* 우선 (영상 시청 시나리오와 우연히 정합)
- **학술 baseline F1**: 실험실 0.86–0.91 (IMChew 2024, EarBit lab) / 자유생활 0.71–0.80 (EarBit wild)
- **Apple jaw health 특허 (2026.03)** — OS 흡수 위험 (V1 자산은 콘텐츠·페르소나 별도 트랙)

---

## 5. 빌드 환경 점검 결과

| 항목 | 상태 | 비고 |
|------|------|------|
| Xcode | ✓ 26.4 (Build 17E192) | iOS 17+ 타겟 빌드 OK |
| xcodegen | ✓ 2.45.3 (`/opt/homebrew/bin/xcodegen`) | project.yml 기반 프로젝트 생성 |
| 시뮬레이터 디바이스 | ⚠ 설치 0개 (`xcrun simctl list devices` 결과 비어있음) | 빌드(generic destination)는 가능, 시뮬 실행 검증은 사용자가 별도로 시뮬 다운로드 필요 |
| AirPods Pro 2 + iPhone 실기기 | (사용자 보유 가정) | 실데이터 정확도 검증은 실기기 전용 |

**시뮬레이터 미설치 안내**: 사용자가 빌드 후 시뮬레이터에서 직접 실행하려면:
1. Xcode → Settings → Platforms → iOS 시뮬레이터 다운로드
2. 또는 `xcodebuild -downloadPlatform iOS`

빌드 자체는 generic destination으로 가능하므로 Phase 2 진행에 차단 없음.

---

## 6. 실행 모드

**하이브리드:**
- Phase 1: 에이전트 팀 (3명: chewing-signal-engineer, app-experience-designer, ios-app-architect)
- Phase 2: 서브 에이전트 (1명: ios-app-implementer)
- Phase 3: 서브 에이전트 (1명: ios-app-qa)

모든 호출 `model: "opus"`.

---

## 7. 산출물 위치

- 작업 디렉토리: `_workspace/app/`
- 앱 본체: `app/` (프로젝트 루트, Xcode 프로젝트, V1 단계에서 첫 생성)
- 단계별 파일:
  - `_workspace/app/_brief.md` (이 파일)
  - `_workspace/app/01_signal_processing.md`
  - `_workspace/app/02_app_architecture.md`
  - `_workspace/app/03_app_ux_spec.md`
  - `_workspace/app/04_app_brief_consolidated.md` (← Phase 2 입력 핵심)
  - `_workspace/app/05_build_report.md`
  - `_workspace/app/06_qa_report.md`
  - `_workspace/app/screenshots/` (시뮬 캡처, 시뮬 미설치 시 제한)
