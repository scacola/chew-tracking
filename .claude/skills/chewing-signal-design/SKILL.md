---
name: chewing-signal-design
description: AirPods IMU 25Hz·단일 채널 데이터를 저작 이벤트(횟수·속도·식사 윈도우)로 변환하는 신호 처리·검출 알고리즘을 설계하는 방법론. 학술 baseline(IMChew·EarBit) 인용, F1 0.75–0.85 KPI 정의, 식사 외 활동 분리·캘리브레이션 전략 포함. AirPods 저작 검출 알고리즘 설계, IMU 신호 처리 명세, 식사 검출 KPI 정의 시 반드시 사용.
---

# Chewing Signal Design

AirPods 25Hz, 단일 채널 IMU에서 *임상이 아닌 행동 변화 코칭용* 저작 이벤트를 검출하는 알고리즘을 설계한다. `chewing-signal-engineer` 에이전트가 사용한다.

## 왜 이 스킬이 필요한가

신호 처리 설계의 흔한 실패:
- 학술 baseline 무시한 *과약속* ("정확도 95%")
- 알고리즘 의사코드 없이 "ML로 해결" — 데이터 없이 ML 불가
- 식사 외 활동(말하기·걷기) 분리 누락 → false positive
- 캘리브레이션 전략 부재 → LOSO 5–25pp 차이로 첫 사용자 경험 망함
- KPI를 *학술 대비 어디에 위치시킬지* 모호

이 스킬은 *baseline 인용 + 의사코드 + 한계 명시 + 검증 가능 KPI*를 강제한다.

## 입력 컨텍스트 우선 확인

먼저 다음 파일을 읽고 baseline·제약을 인용 가능한 형태로 정리:
- `discovery_report.md` — 옵션 G 컨셉, 정확도 KPI 권고 (F1 0.75–0.85)
- `_workspace/01_tech_feasibility.md` — 학술 baseline (IMChew, EarBit, lab vs free-living), CMHeadphoneMotionManager API 제약 (25Hz, 단일 채널, 백그라운드)
- `_workspace/app/_brief.md` — 사용자 요청 발췌

baseline과 제약을 *제안서에 인용 형식으로* 가져온다. 임의의 수치 사용 금지.

## 알고리즘 설계 프레임워크

### 1. 검출 대상 정의 (3개)

| 대상 | 정의 | 측정 방법 | V1 우선순위 |
|------|------|----------|-----------|
| **식사 윈도우** | 식사의 시작·종료·총 시간 | 일정 시간(예: 5분) 동안 저작 이벤트 빈도 임계값 + 사용자 트리거 또는 audio session 컨텍스트 | **필수** |
| **개별 저작 이벤트** | 한 번 씹기 (peak) | 가속도 norm 피크 검출 + 0.94–2Hz 대역 필터 | **필수** |
| **분당 저작 빈도** | chews per minute (CPM) | (윈도우 내 이벤트 수) / (윈도우 길이 분) | **필수** (코칭 핵심 지표) |

식후 위 컨디션 점수, 다음 식사 예측 등은 *대시보드 레이어*에서 파생하는 것 — 신호 레이어 책임 아님.

### 2. 알고리즘 의사코드 — V1 룰 기반

```
function processIMUSample(sample: IMUSample, state: DetectionState):
    # 1) 전처리
    accelNorm = sqrt(sample.x^2 + sample.y^2 + sample.z^2)
    state.recentSamples.push((sample.timestamp, accelNorm))
    state.recentSamples.dropOlderThan(state.now - 30sec)

    # 2) 식사 윈도우 검출 (오케스트레이션)
    if not state.inMealSession:
        recentChewCount = countChewPeaks(state.recentSamples, last=60sec)
        if recentChewCount >= MEAL_START_THRESHOLD:  # baseline 인용 (예: 30회/분)
            state.startMealSession(at = state.recentSamples[0].timestamp)
            emit MealStartedEvent
        return

    # 3) 식사 중 — 개별 저작 검출
    chewCandidate = detectPeak(state.recentSamples, lastWindow=2sec,
                                bandpass=(0.94, 2.0)Hz,
                                minPeakHeight=PEAK_THRESHOLD)
    if chewCandidate and not isLikelySpeechOrWalking(chewCandidate, state):
        state.recordChew(chewCandidate)
        emit ChewDetectedEvent

    # 4) 식사 종료 검출
    recentChewRate = state.chewRate(lastWindow=120sec)
    if recentChewRate < MEAL_END_THRESHOLD:  # baseline 인용
        state.endMealSession()
        emit MealEndedEvent

function isLikelySpeechOrWalking(peak, state):
    # 휴리스틱 (V1):
    # - 가속도 magnitude가 너무 큼 → 걷기
    # - 주파수 대역이 0.94-2Hz 밖 → 말하기 또는 노이즈
    # - 짧은 burst (1초 미만) → 말하기 가능성
    return ...
```

매직 넘버(`MEAL_START_THRESHOLD`, `PEAK_THRESHOLD` 등)는 *모두* baseline 출처와 함께. 캘리브레이션 단계에서 사용자별 조정.

### 3. 식사 외 활동 분리 — 4대 false positive 패턴

| 패턴 | 신호 특징 | 분리 휴리스틱 |
|------|----------|-------------|
| **말하기** | 짧은 burst (0.3-1s), 주파수 2-5Hz | minimum sustained duration 필터 + 주파수 대역 |
| **걷기** | 큰 진폭, 1-3Hz, 양쪽 IMU 동기화 | 가속도 magnitude 임계값 |
| **머리 끄덕임** | 일시적, 주파수 0.5-1Hz | 윈도우 평균 비교, isolated event reject |
| **AirPods 조작** | 매우 큰 임펄스 | magnitude 클리핑 + outlier 제거 |

mitigation 전략 (V1):
- 사용자가 "지금부터 식사 시작" 명시적 트리거 (간단한 위젯/모달) — 가장 신뢰성 높음
- audio session active 컨텍스트 (영상 시청 중) — 우연히 식사와 정합 [기술-한계#5.6]
- V1.5: 작은 CoreML 분류기(activity classification)

### 4. 캘리브레이션 전략

LOSO(Leave-One-Subject-Out) 학술 평가에서 **5–25pp 차이**가 발생한다 [기술 출처]. 사용자별 보정 없으면 첫 사용 경험이 천차만별.

**V1 캘리브레이션 시퀀스 (온보딩):**
1. "이 한 끼만 평소처럼 드시면, 다음 끼부터 자동으로 인식합니다"
2. 사용자가 식사 시작·종료 *명시적* 트리거
3. 식사 중 IMU 통계(평균 진폭, 주파수 분포) 수집
4. 사용자별 PEAK_THRESHOLD, MEAL_START_THRESHOLD 조정
5. 다음 식사부터 자동 모드, *과거 캘리브레이션 데이터 가중치*로 점진 학습

**V1.5 패시브 재캘리브레이션:**
- 사용자가 인사이트에 "이건 식사 아니었어요" 피드백 제공 가능
- 거짓 양성/음성 패턴을 임계값 조정에 반영

### 5. KPI 및 검증 계획

| KPI | 목표 | 학술 baseline | 검증 방법 |
|-----|------|-------------|---------|
| 식사 윈도우 F1 | ≥ 0.80 | 자유생활 0.71-0.80 | 자체 self-report 라벨 vs 검출 결과 |
| 개별 저작 F1 | ≥ 0.75 | EarBit lab 0.86-0.91, free-living 0.71-0.80 | 짧은 비디오 라벨링 (실험실 조건) |
| CPM 정확도 | ±15% 이내 | — (파생 지표) | 식사 윈도우 내 ground truth count |
| 식사 외 false positive | < 5% / 시간 | — (자체 정의) | 일상 활동 30분 데이터 라벨링 |

검증 데이터 수집 (V0 단계):
- 5–10명 사용자, 각 5–10끼니 (50–100세션)
- 사용자 self-report (식사 시작·종료·대략 저작 수)
- 가능하면 짧은 비디오 라벨링 (식사 5분 분량)
- 익명화 protocol 명시

### 6. 사용자 커뮤니케이션 (약속/비약속)

**약속 OK:**
- "식사 시간을 자동으로 기록합니다 (추정 정확도 ±15%)"
- "오늘 평소보다 빠르게 드신 패턴이 보입니다"
- "이 정보는 행동 변화 코칭을 위한 *추정값*입니다"

**약속 금지:**
- "100% 정확한 저작 수 측정"
- "위염 치료에 도움"
- "체중 감소 보장"

→ 옵션 G 톤 가이드와 정합. 신호 사양 단계에서 *약속의 한계*를 미리 정해야 UX 카피가 망가지지 않는다.

### 7. 알려진 한계 — 보고서에 반드시 포함

1. **AirPods 미착용 시 데이터 없음** → 수동 모드 fallback
2. **AirPods Pro 1세대 미만 / 무선 이어폰 비-AirPods → IMU 없음** → 디바이스 호환성 안내
3. **백그라운드 보장 미흡** → audio session active 우선 사용 (영상 시청 시 자동 검출)
4. **좌·우 동시 IMU 불가** → 단일 채널 한계 안에서 가치 제안
5. **bruxism (이갈이) 검출 불가** — 25Hz Nyquist 12.5Hz로 일반 저작은 OK, 고주파 bruxism은 NG

이 한계들을 *보고서에 명시*하고, UX/구현 에이전트에게 전파.

## 출력 — `_workspace/app/01_signal_processing.md`

위 7개 섹션을 모두 담은 마크다운 보고서.

각 섹션은:
- baseline 출처 인용 (예: `[기술-2.1, IMChew 2024]`)
- 의사코드 또는 표
- 한계 명시
- 다음 에이전트(아키텍트·UX)가 인용하기 좋은 헤더

## 팀 통신 시 주의

- 아키텍트가 "백그라운드 폴링 5분 가능?" 물으면 → 알고리즘 윈도우 길이 조정 가능 답변
- 디자이너가 "실시간 햅틱 가능?" 물으면 → 검출 지연(예: 5–10초) 인용해서 *사후 알림이 더 정직* 권고
- 충돌 시 *학술 baseline*을 인용해 *과약속을 거절*하는 게 신호 엔지니어의 책임

## 후속 작업

- 사용자 피드백 ("정확도 더 올려줘") → baseline 천장 인용 + V1.5 ML 마이그레이션 경로 제시
- QA 보고서에서 false positive 발견 → 4대 패턴 중 어느 것인지 분류 후 mitigation 강화
- 새 데이터셋 확보 시 KPI 재검증 + 보고서 업데이트

## 흔한 실수

- ❌ 학술 baseline 인용 없이 임의 수치
- ❌ 의사코드 누락
- ❌ 식사 외 활동 분리 미설계
- ❌ 캘리브레이션 전략 부재
- ❌ "100% 정확" 같은 과약속을 카피·UX 단계에 흘림
- ❌ V2 ML을 V1에 욱여넣기 (데이터 없이 ML 불가)
