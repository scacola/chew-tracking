# 01. 저작 검출 신호 처리 명세 — Chew Coach iOS V1

**작성일**: 2026-05-02
**작성**: `chewing-signal-engineer`
**대상 독자**: `app-experience-designer` (검출 가능 신호 → UX 가능성), `ios-app-architect` (알고리즘 복잡도 → 모듈/백그라운드/데이터 모델 결정), 그 후 `ios-app-implementer` (Swift 변환)
**스코프**: 옵션 G "Chew & Calm Coach" V1의 *측정 엔진* — AirPods Pro/3세대/Max IMU에서 식사 윈도우·개별 저작·CPM(분당 저작 수)을 검출하는 알고리즘 V1 사양 (룰 기반)

---

## 0. 결론 한 줄

> **V1은 룰 기반 (가속도 magnitude 피크 검출 + 0.94–2 Hz 대역 필터 + 슬라이딩 윈도우 빈도 임계값) 단일 알고리즘으로 식사 윈도우 / 개별 저작 / CPM 3개를 검출**한다. 목표 KPI: **식사 윈도우 F1 ≥ 0.80, 개별 저작 F1 ≥ 0.75, CPM ±15% 이내, 식사 외 false positive < 5건/시간** — 학술 자유생활 baseline F1 0.71–0.80 [기술-2.1, EarBit 2017 wild] 위에서 *온보딩 1식사 캘리브레이션 + 사용자 명시적 식사 트리거*로 +5pp 마진 확보. 임상 정확도(F1 0.95+)는 *약속하지 않는다* — 이 한계는 UX 카피의 가드레일이 된다 [discovery §6.1, Vessyl 함정].

---

## 1. 검출 대상 정의 (3개)

V1 측정 엔진이 *책임지는* 신호는 정확히 3개. 그 외(위 컨디션 점수, 식사 패턴 분류, 코칭 메시지 트리거)는 *대시보드 / 코칭 레이어*에서 이 3개의 파생값으로 계산하므로 신호 레이어 책임 아님.

| # | 대상 | 정의 (operational) | 출력 데이터 모델 | 측정 방법 (요약) | V1 우선순위 |
|---|------|-------------------|----------------|--------------|-----------|
| **A** | **식사 윈도우** (Meal Session) | "60초 슬라이딩 윈도우에서 검출된 저작 이벤트가 ≥ `MEAL_START_THRESHOLD`인 시점부터, 120초 윈도우에서 < `MEAL_END_THRESHOLD` 떨어지는 시점까지의 구간" | `MealSession{startedAt, endedAt, totalChews, avgCPM, source: .auto / .manualTrigger}` | 슬라이딩 윈도우 카운트 + 사용자 명시 트리거(우선) | **필수** |
| **B** | **개별 저작 이벤트** (Chew Event) | "가속도 magnitude 신호의 0.94–2 Hz 대역에서 발생한, 인접 피크와 ≥ 0.3 s 떨어진, 진폭 ≥ `PEAK_THRESHOLD`인 단일 피크" | `ChewEvent{timestamp, magnitudePeak, confidence ∈ [0,1]}` | Bandpass 필터 + 피크 검출 + 식사 외 활동 필터 | **필수** |
| **C** | **분당 저작 빈도** (CPM, chews per minute) | "(직전 60초 윈도우 내 ChewEvent 개수)" → 슬라이딩 갱신 | `CPMSample{timestamp, value}` (식사 세션 중 1 Hz로 emit) | A·B의 파생 — 별도 검출 알고리즘 없음 | **필수** (코칭 핵심 지표) |

**정의에서 *제외*되는 것 (V1 명시 비목표)**:

- ❌ **음식 종류 식별** (땅콩 vs 밥) — IMU 단독 한계, CHOMP 같은 멀티모달도 fusion 필요 [기술-2.1, CHOMP 2026]
- ❌ **좌·우 저작 비대칭** — `CMHeadphoneMotionManager`는 단일 마스터 채널만 노출 [기술-1.1, 5.3]
- ❌ **이갈이(bruxism) 검출** — 25 Hz Nyquist = 12.5 Hz로 일반 저작은 OK, 고주파 grinding은 NG [기술-5.4]
- ❌ **삼킴(swallowing) / 음용** — 별도 신호 클래스. V2 후보, V1은 "저작 0회로 카운트" 처리
- ❌ **식사량(g, kcal)** — 이 카테고리는 Vessyl 함정의 핵심 [discovery 함정#1]

이 비목표는 *카피·UX·코칭 메시지에서도 약속 금지* 사항이다 (§6 참고).

---

## 2. 알고리즘 설계 — 의사코드 (V1 룰 기반)

### 2.1 시스템 구조 (3 stage 파이프라인)

```
[CMDeviceMotion 25Hz]
        │
        ▼
  ┌────────────────┐
  │ Stage 1:       │  ─ 입력: userAcceleration 3축 (g)
  │ 전처리         │  ─ 출력: magnitude(t) 1축 시계열 + 30s 링버퍼
  │ (Preprocessor) │
  └────────────────┘
        │
        ▼
  ┌────────────────┐
  │ Stage 2:       │  ─ 입력: magnitude 링버퍼
  │ 저작 이벤트    │  ─ 출력: ChewEvent stream (필요 시)
  │ 검출 (Detector)│
  └────────────────┘
        │
        ▼
  ┌────────────────┐
  │ Stage 3:       │  ─ 입력: ChewEvent stream + 사용자 트리거
  │ 식사 세션      │  ─ 출력: MealSession lifecycle 이벤트
  │ 오케스트레이션 │
  └────────────────┘
```

**왜 3 stage로 분리했나**: `ios-app-architect`가 각 stage를 독립 module로 만들기 좋고 (Stage 1만 mock해서 unit test 가능), `ios-app-implementer`가 SwiftUI ViewModel과 분리할 경계가 명확.

### 2.2 Stage 1: 전처리 (Preprocessor)

```pseudo
struct IMUSample:
    timestamp: Double          // CACurrentMediaTime() 기준 초
    userAccel: (x, y, z)       // g 단위, gravity 제거된 값 (CMDeviceMotion.userAcceleration)
    rotationRate: (x, y, z)    // rad/s (V1.5에서 활용 예정, V1은 무시)

struct PreprocessedSample:
    timestamp: Double
    magnitude: Double          // sqrt(x^2 + y^2 + z^2), 단위 g

class Preprocessor:
    var ringBuffer: [PreprocessedSample]   // 최근 30초 (= 25Hz × 30s = 750 샘플)
    let BUFFER_SECONDS = 30                 // [근거: 식사 시작 검출 60s 윈도우 + 종료 120s 윈도우 중 큰 쪽 절반]

    function ingest(sample: IMUSample):
        let m = sqrt(sample.userAccel.x^2 + sample.userAccel.y^2 + sample.userAccel.z^2)
        ringBuffer.append(PreprocessedSample(timestamp: sample.timestamp, magnitude: m))
        ringBuffer.dropOlderThan(now - BUFFER_SECONDS)
```

**축 선택 근거**: 학술 baseline (IMChew, EarBit) 모두 *3축 magnitude*를 1차 피처로 사용. 단일 축(예: y축만)은 사용자별 이어폰 착용 각도 차이로 변동 큼. magnitude는 회전 불변 [기술-2.1, IMChew 2024 §3].

**필터링 위치 결정 — Stage 2에서**: bandpass 필터는 Stage 2의 검출 직전에 적용. Stage 1에선 raw magnitude만 보관 → 같은 버퍼를 V1.5의 ML 분류기가 재사용 가능 (피처 엔지니어링 분리).

### 2.3 Stage 2: 저작 이벤트 검출 (Detector)

```pseudo
struct DetectorConfig:
    let SAMPLE_RATE: Double = 25.0                 // [기술-1.1] CMHeadphoneMotionManager 추정 25Hz
    let BAND_LOW_HZ: Double = 0.94                 // [기술-2.1] 일반 저작 대역 하한 (분당 56회)
    let BAND_HIGH_HZ: Double = 2.0                 // [기술-2.1] 일반 저작 대역 상한 (분당 120회)
    let MIN_PEAK_INTERVAL_SEC: Double = 0.3        // 인접 저작 최소 간격 (= 분당 200회 상한, 생리 한계)
    let DETECT_WINDOW_SEC: Double = 2.0            // 검출 슬라이딩 윈도우 (= ~2-4회 저작 포함)

    // 캘리브레이션 가능 — 사용자별 조정 (§5 참고)
    var PEAK_THRESHOLD_G: Double = 0.05            // [캘리브레이션 가능, 기본값은 IMChew 보고 0.04-0.06g 범위 중간]

class Detector:
    var lastChewTimestamp: Double = 0
    let config: DetectorConfig

    function detectChew(buffer: [PreprocessedSample], now: Double) -> ChewEvent?:
        # 1) 직전 2초 윈도우 추출
        let window = buffer.filter { now - 2.0 <= $0.timestamp <= now }
        if window.count < SAMPLE_RATE * DETECT_WINDOW_SEC * 0.8: return nil  // 데이터 부족 (≥80%)

        # 2) Bandpass 필터 적용 — 4차 Butterworth, 0.94-2 Hz
        # V1 구현 권고: vDSP 기반 또는 직접 biquad cascade (구현자 노트: AVAudioEngine의 EQ 사용 금지, latency 큼)
        let filtered = bandpass(window.map(\.magnitude),
                                lowHz: config.BAND_LOW_HZ,
                                highHz: config.BAND_HIGH_HZ,
                                sampleRate: config.SAMPLE_RATE)

        # 3) 최근 0.5초 내 피크 후보 (latest peak detection)
        let recentSlice = filtered.suffix(Int(SAMPLE_RATE * 0.5))
        guard let peakIndex = recentSlice.argmax(),
              recentSlice[peakIndex] >= config.PEAK_THRESHOLD_G,
              isLocalMaximum(recentSlice, peakIndex) else { return nil }

        # 4) 인접 저작 간격 체크
        let peakTimestamp = window.last!.timestamp - (recentSlice.count - peakIndex - 1) / SAMPLE_RATE
        guard peakTimestamp - lastChewTimestamp >= config.MIN_PEAK_INTERVAL_SEC else { return nil }

        # 5) 식사 외 활동 필터 (§2.5)
        guard !isLikelyNonChewingArtifact(window, peakTimestamp) else { return nil }

        # 6) 신뢰도 계산
        let confidence = computeConfidence(filtered, peakIndex)   // [0, 1] — 진폭/주파수 정합도

        lastChewTimestamp = peakTimestamp
        return ChewEvent(timestamp: peakTimestamp,
                         magnitudePeak: recentSlice[peakIndex],
                         confidence: confidence)
```

**구현자 노트 (`ios-app-implementer`에게)**:
- `bandpass()`는 직접 구현. vDSP `vDSP_biquad`로 4차 IIR 캐스케이드 권장. SOS 계수는 SciPy `scipy.signal.iirfilter(4, [0.94, 2.0], btype='band', fs=25, output='sos')`로 *오프라인 사전 계산*해서 hard-code.
- ring buffer는 `Deque<PreprocessedSample>` (Swift Collections). 750 샘플 작아 부담 없음.
- `argmax`, `isLocalMaximum`은 작은 helper. 풀 라이브러리 도입 불요.

### 2.4 Stage 3: 식사 세션 오케스트레이션

```pseudo
enum MealSessionState:
    case idle
    case calibrating                   // 첫 식사 — 사용자 명시 트리거 필수 (§5)
    case awaitingMeal                  // calibrated 이후, 자동 검출 대기
    case inMeal(session: MealSession)
    case ending(session: MealSession, since: Double)   // grace period

struct OrchestratorConfig:
    let MEAL_START_WINDOW_SEC: Double = 60.0        // [근거: 통상 식사 첫 1분에 충분한 저작]
    let MEAL_START_THRESHOLD: Int = 25              // 60s 윈도우 내 ≥25 chews → 식사 시작 [근거: CPM 30 하한 × 60s 보수치 0.83]
    let MEAL_END_WINDOW_SEC: Double = 120.0         // [근거: 한식 식사 평균 12-20분, 후반 휴식 길어 종료 오인 방지]
    let MEAL_END_THRESHOLD_CPM: Double = 8.0        // 직전 120s에서 CPM < 8 → 종료 [근거: 식사 종료 후 대화·정리 활동 잔류 컷오프]
    let END_GRACE_SEC: Double = 90.0                // 종료 grace — 잠시 멈춤 후 재개 흡수
    let MIN_MEAL_DURATION_SEC: Double = 90.0        // 90초 미만 세션은 false positive로 폐기

class Orchestrator:
    var state: MealSessionState = .idle
    var recentChews: [ChewEvent] = []   // 최근 5분 (= 300s) 이벤트 버퍼

    function ingest(chew: ChewEvent?, manualTrigger: ManualTrigger? = nil):
        if let chew { recentChews.append(chew) }
        recentChews.dropOlderThan(now - 300)

        switch state:
        case .calibrating:
            handleCalibration(chew, manualTrigger)   // §5

        case .idle, .awaitingMeal:
            # 자동 검출 시도
            if let trigger = manualTrigger, trigger == .startMeal:
                state = .inMeal(session: MealSession(startedAt: now, source: .manualTrigger))
                emit(.mealStarted)
                return

            let recentCount = recentChews.filter { now - $0.timestamp <= MEAL_START_WINDOW_SEC }.count
            if recentCount >= MEAL_START_THRESHOLD:
                let firstChew = recentChews.filter { now - $0.timestamp <= MEAL_START_WINDOW_SEC }.first!
                state = .inMeal(session: MealSession(startedAt: firstChew.timestamp, source: .auto))
                emit(.mealStarted)

        case .inMeal(let session):
            session.chewEvents.append(chew)
            let cpm = computeCPM(recentChews, window: 60)
            emit(.cpmUpdate(cpm))

            if let trigger = manualTrigger, trigger == .endMeal:
                finalizeMeal(session)
                return

            let recentCPM = computeCPM(recentChews, window: MEAL_END_WINDOW_SEC)
            if recentCPM < MEAL_END_THRESHOLD_CPM:
                state = .ending(session: session, since: now)

        case .ending(let session, let since):
            # grace 기간 동안 저작 재개되면 inMeal로 복귀
            let recentCPM = computeCPM(recentChews, window: 60)
            if recentCPM >= MEAL_END_THRESHOLD_CPM * 1.5:
                state = .inMeal(session: session)   # 재개
            elif now - since >= END_GRACE_SEC:
                finalizeMeal(session)

    function finalizeMeal(session: MealSession):
        session.endedAt = now - END_GRACE_SEC      # grace 기간 제외한 진짜 종료 시점
        if (session.endedAt - session.startedAt) < MIN_MEAL_DURATION_SEC:
            discard session
            state = .awaitingMeal
            emit(.mealDiscardedAsNoise)
            return
        save(session)
        state = .awaitingMeal
        emit(.mealEnded(session))
```

**핵심 결정**:
- *사용자 명시 트리거(우선) + 자동 검출(fallback)* 듀얼 모드. 명시 트리거는 false positive 0% 보장 — UX는 둘 다 노출 [discovery 함정#3 회피, "혼밥 + 영상 시청" 시나리오에 우연히 정합 →§5.6 백그라운드와 결합].
- *grace 90초*는 식사 중간 잠시 멈춤 (대화·물 마시기·자리 뜸) 흡수 — Auracle/EarBit 보고 동일 패턴 [기술-2.1, EarBit 2017].
- *최소 식사 90초*는 짧은 false positive (사탕 1개·껌 잠깐) 폐기 — 옵션 G의 *식사* 코칭 컨텍스트와 정합.

### 2.5 식사 외 활동 분리 — 4대 false positive 패턴

```pseudo
function isLikelyNonChewingArtifact(window: [PreprocessedSample], peakTime: Double) -> Bool:
    let avgMag = window.map(\.magnitude).mean()
    let peakMag = window.last!.magnitude   # 또는 peakIndex 기준
    let stdMag = window.map(\.magnitude).std()

    # 1) 걷기 — 큰 진폭 + 1-3Hz 지속적 패턴
    if avgMag > WALKING_AVG_THRESHOLD {                # 0.15g [근거: 보행 가속도 통상 0.2-0.5g, 보수적 컷오프]
        return true
    }

    # 2) AirPods 조작 / 큰 충격 — 임펄스 outlier
    if peakMag > IMPULSE_THRESHOLD {                   # 0.5g [근거: 일반 저작 0.05-0.15g 범위 [IMChew 2024], 그 이상은 비정형]
        return true
    }

    # 3) 짧은 burst (말하기·웃음) — 0.3초 내 다중 피크
    let recentPeaks = countPeaks(window, last: 0.3, threshold: PEAK_THRESHOLD_G * 0.7)
    if recentPeaks >= 3 {                              # 0.3초에 3+ 피크 → 말하기 패턴 [bruxism feasibility 2021]
        return true
    }

    # 4) 머리 끄덕임 — isolated low-freq event
    # (V1에선 보수적으로 패스 — Stage 2의 0.94-2Hz bandpass가 0.5-1Hz는 이미 컷)
    return false
```

| # | False Positive 패턴 | 신호 특징 | V1 Mitigation | V1.5 Plan |
|---|------|----------|--------------|----------|
| **1** | **말하기 / 웃음** | 짧은 burst (0.3-1s), 주파수 2-5Hz, 진폭 다양 | bandpass 0.94-2Hz가 1차 컷 + 0.3s 내 다중 피크 reject [기술-5.1] | CoreML activity classifier (speech vs chewing) — talking 라벨 1000개 수집 후 |
| **2** | **걷기** | 큰 진폭(0.2-0.5g), 1-3Hz 지속 | avgMag > 0.15g window-level reject [기술-5.1] | 같음 (CoreML이 더 정교) |
| **3** | **머리 끄덕임 / 시청 중 반응** | isolated 0.5-1Hz 펄스 | bandpass 하한 0.94Hz가 컷 (0.94 미만 reject) | 같음 |
| **4** | **AirPods 조작 (탭·뺐다 끼움)** | 매우 큰 임펄스 (>0.5g) | peakMag > 0.5g reject + connect/disconnect 콜백으로 5초 mute | 같음 |

**상위 mitigation (오케스트레이션 레벨)**:
- **사용자 명시 트리거**: 가장 신뢰성 높음. UX에서 "지금 식사 시작" 위젯/Live Activity 노출 → 트리거 후에만 ChewEvent 카운트 (idle 상태에선 전처리만)
- **AudioSession 컨텍스트**: 영상 시청 중 audio session active → 백그라운드 IMU 유지 가능 [기술-5.6]. 단, 영상 시청 시 *말하기·웃음 false positive* 위험 ↑ → V1.5에서 시청 콘텐츠 종류별 패턴 학습

**`app-experience-designer`에게**: 명시 트리거 UX는 *마찰을 줄이려고* Apple Watch complication / Live Activity / 위젯 1탭 / Siri shortcut 4개 채널 지원 권고. "시작 버튼 못 누르면 자동 검출 fallback"으로 정직 카피.

---

## 3. KPI 및 검증 계획

### 3.1 목표 KPI 표

| KPI | V1 목표 | 학술 baseline (자유생활) | V1 목표 근거 | 측정 방법 |
|-----|--------|----------------------|------------|---------|
| **식사 윈도우 F1** | **≥ 0.80** | 0.71-0.80 [EarBit wild 2017] / 0.77-0.92 recall [Auracle 2018] | baseline 상한. 명시 트리거(F1=1.0)와 자동 검출 mix로 가중평균 ≥0.80 달성 | 자체 self-report 라벨 vs 자동 검출 결과, N=10 사용자 × 7일 = 70 식사 |
| **식사 윈도우 Precision** | **≥ 0.85** | (baseline 미보고) | "내가 안 먹었는데 식사로 잡힘" = 사용자 신뢰 즉사 → 보수 우선 | 동일 |
| **식사 윈도우 Recall** | **≥ 0.75** | 0.77-0.92 [Auracle 2018] | 자동 검출이 놓친 식사는 사용자가 명시 트리거로 보완 가능 → recall 손실 < precision 손실 | 동일 |
| **개별 저작 F1** | **≥ 0.75** | Lab 0.86-0.91 [IMChew 2024, EarBit lab] / Snacking wild 0.45-0.53 [ISWC 2022] | 자유생활 baseline 상한. 식사 중 한정(트리거 후) 가정으로 lab 조건에 근접 | 짧은 비디오 라벨링 (식사 5분 × 10세션 = 50분) |
| **CPM 정확도** | **MAE ≤ 8 CPM** (or ±15%) | (파생 지표) | 옵션 G 코칭 메시지 ("평소보다 30% 빨리") 임계값 ±20%보다 보수적 | 비디오 라벨링과 동일 50분 윈도우의 ground truth count |
| **식사 외 false positive** | **< 5건/시간** (idle 시) | (자체 정의) | 사용자 일상 활동(걷기·말하기·운동) 중 자동 식사 시작 오탐지 — 시간당 5건 미만이어야 위젯 알림 신뢰 유지 | 비식사 시간 30분 × 10세션 라벨링 |
| **검출 latency** | **≤ 10초** (chew 발생 → emit) | (자체 정의) | 실시간 햅틱 피드백은 *비목표* (§6 약속 금지) — 식사 후 리포트가 주 UX이므로 10초 충분 | unit test (synthetic IMU 입력 → emit 시간 측정) |
| **CPU / 배터리** | iPhone CPU < 3% (식사 중), AirPods 추가 소모 < 1h/일 사용 시 | [기술-5.5] AirPods 5-6h → 4-5h 보고 | 25Hz × 9-channel float 처리는 매우 경량 | Instruments Energy log + AirPods 배터리 모니터 |

### 3.2 학술 baseline 대비 V1의 위치

```
F1 ───────────────────────────────────────────────────────────────────┐
                                                                      │
0.95 ┤                                                                │
0.90 ┤  [IMChew lab]    [EarBit lab]                                  │
0.85 ┤                                                                │
0.80 ┤━━━━━━━━━━━━━━━━━━━━━━━━ V1 목표 (식사 윈도우) ━━━━━━━━━━━━━━━━━━┤
0.75 ┤━━━━━━━━━━━━━━━━━━━━━━━━ V1 목표 (개별 저작) ━━━━━━━━━━━━━━━━━━━━┤
0.71 ┤  [EarBit wild]                                                 │
0.50 ┤                       [Snacking ISWC 2022]                     │
                                                                      │
     └──────────────────────────────────────────────────────────────── ┘
       lab condition       free-living      free-living (snacking)
```

V1은 *명시 트리거 + 캘리브레이션*으로 자유생활 baseline 상한(0.71-0.80)을 살짝 넘기는 위치를 노린다. **임상 정확도(F1≥0.95)는 V1·V2·V∞에서도 약속하지 않는다** — 그건 EMG·안경형 영역 [기술-§3].

### 3.3 검증 데이터 수집 계획 (V1 빌드 중 병행)

**Phase 0: 자체 dogfooding (1주, N=2 = 빌더+협력자)**
- 데이터: 본인 + 1명, 각 7끼 = 14 세션
- 라벨: self-report (식사 시작·종료 timestamp 수동 기록 + 대략적 chewing 횟수)
- 목적: 알고리즘 *동작 확인*, 매직 넘버 sanity check
- 합격선: 식사 윈도우 검출 6/7 식사 (recall 86%) — 절대 KPI 아님

**Phase 1: Closed Beta (4주, N=10-20)** — discovery §10 "Closed Beta N=20-30 모집"과 정합
- 데이터: 20명 × 5-10끼 = 100-200 세션
- 라벨:
  - 사용자 self-report (식사 시작·종료 + 대략 chew count)
  - 옵션: 5명에게 짧은 비디오 동의 (5분 × 5명 = 25분 ground truth)
  - 익명화 protocol 명시 (모든 IMU raw는 7일 후 자동 삭제, 비디오는 라벨링 후 즉시 삭제)
- 합격선: 식사 윈도우 F1 ≥ 0.75 (V1 목표 0.80의 -5pp 마진 허용 — Beta 데이터는 self-report 잡음 ↑)

**Phase 2: 출시 후 누적 (V1.5 트리거)**
- 사용자 피드백 (인사이트에 "이건 식사 아니었어요" 버튼)
- 누적 라벨 1,000건 도달 시 → V1.5 CoreML 분류기 학습 시작 (§7)

### 3.4 단위 테스트 케이스 (`ios-app-implementer`가 즉시 작성 가능)

| # | 케이스 | 입력 (synthetic IMU) | 기대 출력 |
|---|--------|--------------------|---------|
| T1 | **이상적 저작 패턴** | 1.5 Hz sine wave, 0.08g amplitude, 60초 | ChewEvent 90개 ±5 (1.5Hz × 60s = 90) |
| T2 | **저작 빈도 하한** | 1.0 Hz, 0.06g, 60초 | ChewEvent 60개 ±5 |
| T3 | **저작 빈도 상한** | 1.95 Hz, 0.07g, 60초 | ChewEvent 117개 ±5 |
| T4 | **대역 외 (말하기 시뮬)** | 3.5 Hz, 0.05g, 60초 | ChewEvent 0개 (bandpass reject) |
| T5 | **대역 외 (머리 끄덕임)** | 0.6 Hz, 0.05g, 60초 | ChewEvent 0개 (bandpass reject) |
| T6 | **걷기 시뮬** | 2.0 Hz, 0.30g, 60초 | ChewEvent 0개 (avgMag > 0.15g reject) |
| T7 | **AirPods 임펄스** | 0.8g 단일 spike + 무신호 30초 | ChewEvent 0개 (peakMag > 0.5g reject) |
| T8 | **식사 시작 검출** | 1.5 Hz, 0.08g, 90초 | MealStartedEvent emit, MealSession.source = .auto |
| T9 | **명시 트리거** | manualTrigger=.startMeal + 무신호 60초 | MealStartedEvent emit, MealSession.source = .manualTrigger |
| T10 | **식사 종료 grace** | 1.5 Hz 60초 → 무신호 60초 → 1.5 Hz 30초 → 무신호 120초 | 단일 MealSession (총 270초), 중간 60초 흡수 |
| T11 | **짧은 false positive 폐기** | 1.5 Hz, 0.08g, 60초 (총 60s) | MealSession 발생 후 finalizeMeal에서 폐기 (90초 미만), .mealDiscardedAsNoise emit |
| T12 | **검출 latency** | 1.5 Hz pulse train 시작 후 첫 ChewEvent 시간 측정 | 첫 emit ≤ 2.5초 (bandpass 안정화 시간) |

이 12개 테스트는 *synthetic generator + Detector·Orchestrator 단위* 만으로 통과 가능. CMHeadphoneMotionManager mock 필요 없음. → `ios-app-architect`가 모듈 경계 설계 시 *protocol 기반 dependency injection* 권장.

---

## 4. 캘리브레이션 전략

학술 LOSO 평가에서 within-subject 대비 5–25pp F1 차이 [기술-5.2]. 사용자별 보정 없으면 첫 사용 경험이 천차만별 — 옵션 G의 "5초 안에 가치 입증" 룰과 직접 충돌.

### 4.1 V1 온보딩 캘리브레이션 시퀀스

**UX 흐름** (5단계, `app-experience-designer`가 카피·시각 설계):

1. **설명 화면**: "AirPods가 한 끼만 옆에서 함께하면, 다음 식사부터는 자동으로 알아챕니다. 1분이면 끝나요."
2. **AirPods 연결 확인 + 모션 권한 요청** (`NSMotionUsageDescription`)
3. **첫 식사 트리거**: "지금 식사 시작" 버튼 → `MealSessionState = .calibrating` 진입
4. **식사 중 데이터 수집**:
   - 가속도 magnitude 분포 수집 (최소 3분, 최대 20분)
   - 사용자가 "식사 종료" 버튼 누름 → 캘리브레이션 종료
5. **사용자별 임계값 산출**:
   ```pseudo
   function calibrate(samples: [PreprocessedSample]):
       let mags = samples.map(\.magnitude)
       let p50 = mags.percentile(0.50)
       let p90 = mags.percentile(0.90)

       # 사용자별 PEAK_THRESHOLD: p50과 p90 사이 70% 지점
       userPeakThreshold = p50 + (p90 - p50) * 0.7
       userPeakThreshold = clamp(userPeakThreshold, min: 0.03, max: 0.12)   # safety bounds [IMChew 보고 범위]

       # 사용자별 MEAL_START_THRESHOLD: 캘리브레이션 식사의 평균 CPM × 60s × 0.6
       calibratedCPM = countChewsAt(samples, threshold: userPeakThreshold) / (samples.duration / 60)
       userMealStartThreshold = max(15, calibratedCPM * 0.6)   # 최저 15 (=CPM 15 = 매우 천천히 먹는 사람도 검출)

       persist(userPeakThreshold, userMealStartThreshold)
       state = .awaitingMeal
   ```
6. **결과 화면**: "캘리브레이션 완료! 다음 식사부터 자동 인식됩니다. 7일간 정확도가 점점 높아져요."

**Why these specific defaults**:
- p70 (between p50 & p90): IMChew 2024가 사용자별 mean+0.5σ를 권고했지만, percentile 기반이 분포 비대칭에 강함 (저작은 right-skewed)
- min 0.03 / max 0.12: IMChew 보고 정상 저작 범위 0.04-0.10g 대비 ±20% 안전 마진
- MEAL_START_THRESHOLD 0.6 factor: 평소 식사 CPM의 60%만 넘어도 식사로 인식 → 저작 빠른/느린 사용자 모두 포용. 최저 15 fallback은 *저작 매우 적은 식단*(예: 죽·국)도 검출 가능하게.

### 4.2 V1.5 패시브 재캘리브레이션

V1 출시 후 누적되는 사용자 피드백을 임계값에 반영:

```pseudo
function adaptThresholdsFromFeedback(feedback: UserFeedback):
    if feedback.type == .falsePositiveMeal:        # "이건 식사 아니었어요"
        # 해당 세션의 PEAK_THRESHOLD 사용 값보다 +5% 상향
        userPeakThreshold *= 1.05
    elif feedback.type == .missedMeal:             # "이 시간에 식사했는데 안 잡혔어요"
        userPeakThreshold *= 0.97
    userPeakThreshold = clamp(userPeakThreshold, 0.03, 0.12)
```

지수 가중 평균 (EWMA) 형태로 점진 적응 — 1회 피드백으로 급변하지 않음.

### 4.3 캘리브레이션 없이 시작한 경우 (cold start)

캘리브레이션 스킵 사용자는 *기본값* (PEAK_THRESHOLD = 0.05g, MEAL_START_THRESHOLD = 25)으로 시작. 이 경우:
- 첫 7일은 *명시 트리거만* 사용 권고 (UX 카피로 안내)
- 자동 검출은 disabled or "베타" 라벨
- 누적 5세션 후 *자동* 캘리브레이션 (사용자가 트리거한 식사들의 IMU 통계로 후행 캘리브레이션)

---

## 5. 알려진 한계와 사용자 커뮤니케이션

### 5.1 기술적 한계 (보고서·UX·카피에 반드시 명시)

| # | 한계 | 영향 | UX/카피 가드레일 |
|---|------|------|---------------|
| 1 | **AirPods 미착용 시 데이터 없음** | 식사 검출 불가 | "AirPods를 끼고 식사하면 자동 인식됩니다" — 미착용 시 명시 트리거(수동 모드) fallback |
| 2 | **AirPods Pro 1세대 미만 / Beats Fit Pro 외 무선 이어폰 → IMU 없음** | 디바이스 호환성 차단 | 온보딩에서 디바이스 체크 + 비호환 시 "Pro·3세대·Max만 지원" 안내 + waitlist |
| 3 | **백그라운드 보장 미흡** | 영상 시청 외 백그라운드 검출 불안정 [기술-5.6] | "영상 시청 중에는 자동 인식, 그 외에는 살짝 알림이 늦을 수 있어요" — 정직 카피 |
| 4 | **좌·우 동시 IMU 불가** | "좌·우 비대칭" 같은 advanced metric 비제공 | 약속 금지 |
| 5 | **이갈이(bruxism) 검출 불가** | 25 Hz Nyquist 한계 [기술-5.4] | 약속 금지 — Apple jaw health 특허 영역과 분리 |
| 6 | **음식 종류 식별 불가** | 칼로리·영양 추적 불가 | 약속 금지 — Vessyl 함정 회피 [discovery 함정#1] |
| 7 | **자유생활 정확도 천장 F1 0.71-0.80** | "100%" 약속 불가 | "추정값입니다 / 행동 변화 코칭용" 명시 카피 |

### 5.2 약속해도 OK (옵션 G 톤)

- ✅ "식사 시간을 자동으로 기록합니다 (추정 정확도 ±15%)"
- ✅ "오늘은 평소보다 30% 빨리 드신 패턴이 보여요"
- ✅ "이 정보는 행동 변화 코칭을 위한 *추정값*입니다"
- ✅ "식사 시작·종료를 직접 알려주실 수도 있어요" (수동 트리거 정상화)
- ✅ "AirPods 모션 데이터는 기기 내에서만 처리되고 7일 후 자동 삭제됩니다"

### 5.3 약속 금지 (Vessyl·Healbe 함정)

- ❌ "100% 정확한 저작 수 측정"
- ❌ "위염 치료에 도움 / 위 건강 회복 보장"
- ❌ "체중 감소 보장 / 일주일에 N kg"
- ❌ "음식 종류·칼로리 자동 인식"
- ❌ "이갈이 진단" (Apple 영역 + bruxism은 25Hz 미달)
- ❌ "임상 정확도" / "의료급" / "FDA 승인"

이 가드레일은 *신호 사양 단계*에서 못박아야 한다. UX 카피·랜딩 페이지·앱스토어 description·코칭 메시지 라이브러리 모두 §5.2/5.3에 정합해야 함. `app-experience-designer`에게 인용 권고.

### 5.4 Vessyl·Healbe 함정 회피 체크리스트

| 함정 | 회피 방식 |
|------|--------|
| Vessyl: 영양소 자동 인식 광고 → 실제 불가 → 환불 사태 | "음식 종류 인식 안 함" 약속 금지 명시 (§5.3) |
| Healbe GoBe: "혈당 비침습 측정" 광고 → 의료 정확도 미달 → 신뢰 붕괴 | "임상" / "의료급" 어휘 금지 (§5.3) |
| HAPIfork: 진동 알림으로 충분하다 가정 → 7일 후 무시 | V1은 *사후 리포트가 주, 실시간 알림은 보조* — 신호 latency 10초도 허용 (§3.1) |
| Bite Counter: 정확도만 강조, 결과 약속 없음 | 옵션 G의 *결과 프레이밍* (위 컨디션·식사 속도 패턴)이 신호 정확도 부족을 *덮음* — 신호 ±15% 오차도 결과 메시지 영향 미미 |

---

## 6. 구현 권고 — V1 / V1.5 / V2 마이그레이션 경로

### 6.1 V1 (지금 — 6주 빌드)

**알고리즘**: 룰 기반 (이 문서 §2 의사코드)
**기술 스택**:
- `CMHeadphoneMotionManager` 직접 사용
- vDSP biquad cascade for bandpass (외부 라이브러리 불요)
- Pure Swift, Combine/AsyncStream으로 stream 처리
- SwiftData로 `MealSession` 영속화 (architect 결정 사항)

**개발 부담**:
- Stage 1 (전처리): ~1일
- Stage 2 (Detector + filter): ~3일 (bandpass 계수 사전 계산 + biquad 구현)
- Stage 3 (Orchestrator): ~3일 (state machine + grace period)
- 캘리브레이션 UX 통합: ~2일
- 단위 테스트 12개 (§3.4): ~2일
- **총 ~11일 (2.2주)**

**검증 단계**:
- Phase 0 dogfooding 1주
- Phase 1 Beta 4주 (병행)

### 6.2 V1.5 (V1 출시 + 3개월, 누적 라벨 1,000건 시점)

**추가**: 작은 CoreML *binary classifier* (chewing vs non-chewing)
- 입력: 2초 윈도우의 raw magnitude (50 샘플)
- 출력: chewing 확률 [0, 1]
- 모델: 1D-CNN (3 conv layers, ~50K params, < 200KB)
- 위치: Stage 2 detection의 *후처리* — 룰 기반 검출이 candidate 생성, ML이 confidence 보정

**왜 V1.5인가, V1이 아닌가**:
- 데이터 부재 — V1 출시 전엔 학습 데이터 없음 [signal-engineer 흔한 실수: "데이터 없이 ML 불가"]
- 룰 기반 V1만으로 학술 baseline 도달 가능 (§3.1)
- ML은 *false positive 감소*에 결정적 (특히 §2.5의 4대 패턴) — V1 출시 후 사용자 피드백으로 라벨 수집 가능

**마이그레이션 코스트**: 모듈 경계 (§2.1 Stage 분리)가 ML 도입을 흡수하도록 이미 설계됨. Stage 2 내부만 교체.

### 6.3 V2 (V1 출시 + 12개월, 누적 라벨 10,000+ 건 시점)

**시나리오**: 전면 ML로 룰 기반 alongside or 대체
- 데이터: Closed Beta + Open Beta 누적 → 10K+ 식사 세션
- 모델 후보: TCN (Temporal Convolutional Network) or Transformer-encoder, 5-10초 윈도우 직접 입력 → 식사/저작/말하기/걷기/기타 5-class
- 학술 SoTA 도달 가능 — IMChew F1 0.91 lab, 자유생활 0.80+

**전제 조건**:
- 라벨링 인프라 — Beta 사용자 self-report + 5% 비디오 그라운드트루스
- 익명화 + on-device ML 우선 (cloud upload는 opt-in 후 학습 풀에만)
- 모델 검증 — LOSO 평가, 새 사용자 cold start 정확도 측정

**KPI 갱신**: V2에서도 "임상 정확도 약속 금지" 유지 (§5.3 가드레일은 사양에 영구 박힘).

### 6.4 V2+ — Apple jaw health 흡수 시나리오 대응

[기술-5.7] Apple이 OS 레벨에서 jaw health API 제공 시:
- *raw IMU 알고리즘 자체*는 OS가 더 정확할 가능성 (Apple은 좌·우 동시 + 비공개 sensor fusion 가능)
- **그러나 옵션 G의 V1 코어 자산은 *알고리즘이 아닌 임상 콘텐츠·KOL·페르소나*** [discovery 합성 §3]
- 신호 엔진은 OS API로 *대체* 가능, 위 컨디션 코칭 IP는 대체 불가
- → V2+에서 "Apple jaw API 우선, 미지원 디바이스에 자체 알고리즘 fallback" 듀얼 백엔드 설계

이 시나리오는 *지금 결정엔 영향 없음* — V1은 자체 알고리즘으로 진행. 단, 모듈 경계(§2.1)가 *backend swap*을 허용하도록 protocol 분리 권고 (architect에게).

---

## 7. 통신 — 다음 에이전트가 이 문서에서 인용할 핵심 결정

### 7.1 → `app-experience-designer` (다음에 받을 사람)

**검출 가능한 신호 → UX 가능성 매핑**:

| UX 가능 | 신호 근거 (이 문서 §) | 한계 |
|--------|---------------------|------|
| **식사 종료 직후 리포트** ("오늘 12분에 드셨어요. 평소보다 30% 빨라요") | §1 A·C, §3.1 latency ≤ 10s | latency 10초 허용 — 식사 종료 직후 즉시 노출 가능 |
| **실시간 햅틱 피드백** ("천천히 드세요" 진동) | §3.1 latency ≤ 10s | *비권장* — 10초 latency는 햅틱엔 늦음. 사후 리포트가 더 정직 |
| **자동 식사 시작 알림** | §2.4 Stage 3 | 5건/시간 false positive 가능 → 노출 빈도 보수적으로 |
| **명시 식사 시작/종료 버튼** (위젯/Live Activity) | §2.5 mitigation 1 | 마찰 ↓ + false positive 0% 보장 — 듀얼 모드 |
| **온보딩 캘리브레이션** | §4.1 5단계 시퀀스 | UX 카피·시각 설계 필요 |
| **사용자 피드백 ("이건 식사 아니었어요")** | §4.2 패시브 재캘리브레이션 + §3.3 Phase 2 | V1.5 진입 트리거 |
| **CPM 실시간 표시 (Live Activity)** | §1 C, 1Hz emit | 가능. 단, 첫 60초는 partial window |
| **주간 추이 차트 (Swift Charts)** | §1 A·B·C 영속화 | architect의 SwiftData 모델에 의존 |

**약속 금지 카피 가드레일**: §5.3 (Vessyl·Healbe 함정 — 카피라이터가 곧 받을 코칭 메시지 라이브러리도 동일 룰)

### 7.2 → `ios-app-architect` (다음 다음에 받을 사람)

**알고리즘 복잡도 → 아키 결정**:

| 결정 | 신호 명세 입력 |
|-----|------------|
| **모듈 분해** | 3 stage (Preprocessor / Detector / Orchestrator) — protocol 기반 DI 권고 (§2.1, §3.4 unit test) |
| **데이터 모델 (SwiftData)** | `MealSession`, `ChewEvent`, `CPMSample`, `UserCalibration` 4 entity (§1 출력 모델) |
| **백그라운드 전략** | audio session active 우선 [기술-5.6]. 영상 미시청 시 Live Activity로 fallback (§5.1#3) |
| **CPU/메모리 예산** | < 3% CPU, ring buffer 750 샘플 ≈ 24KB. 매우 가벼움 (§3.1) |
| **권한** | `NSMotionUsageDescription` (Info.plist) 필수 (§4.1 단계 2) |
| **테스트 가능성** | synthetic IMU generator + protocol mock으로 12개 unit test 통과 (§3.4) |

### 7.3 충돌 해결 프로토콜 (예방적)

**예상 충돌 1**: UX가 "씹기 1회마다 진동 햅틱"을 요구할 경우
→ §3.1 latency 10초 인용 + §6 약속 금지 인용 → "사후 리포트가 더 정직"으로 전환 권고

**예상 충돌 2**: 아키텍트가 "백그라운드 5분 보장 가능"을 가정할 경우
→ [기술-5.6] 회색지대 + §5.1#3 인용 → "영상 audio session 동안만 신뢰" 카피로 정직화

**예상 충돌 3**: 사용자/카피라이터가 "정확도 95%" 카피를 원할 경우
→ §3.1 학술 baseline 표 + §5.3 약속 금지 인용 → "추정값 ±15%" 카피로 변환 의무

---

## 부록 A. 매직 넘버 인용 표 (전체)

이 문서의 모든 수치는 캘리브레이션 가능 또는 baseline 인용. `ios-app-implementer`가 Swift 상수로 옮길 때 이 표 그대로.

| 상수 | 값 | 단위 | 근거 |
|------|----|----|----|
| `SAMPLE_RATE` | 25.0 | Hz | [기술-1.1] CMHeadphoneMotionManager 추정 |
| `BAND_LOW_HZ` | 0.94 | Hz | [기술-2.1] 일반 저작 빈도 하한 (분당 56회) |
| `BAND_HIGH_HZ` | 2.0 | Hz | [기술-2.1] 일반 저작 빈도 상한 (분당 120회) |
| `MIN_PEAK_INTERVAL_SEC` | 0.3 | 초 | 분당 200회 생리적 상한 (200/60 ≈ 0.3s) |
| `DETECT_WINDOW_SEC` | 2.0 | 초 | 2-4회 저작 포함 (학술 표준 윈도우) |
| `PEAK_THRESHOLD_G` | 0.05 (캘리브레이션 가능) | g | [IMChew 2024 §3] 정상 저작 진폭 0.04-0.10g 중간값 |
| `MEAL_START_WINDOW_SEC` | 60 | 초 | 식사 첫 1분에 충분한 저작 패턴 |
| `MEAL_START_THRESHOLD` | 25 (캘리브레이션 가능) | 회 | CPM 30 하한 × 60s × 보수치 0.83 |
| `MEAL_END_WINDOW_SEC` | 120 | 초 | 한식 식사 평균 12-20분, 후반 휴식 흡수 |
| `MEAL_END_THRESHOLD_CPM` | 8.0 | CPM | 식사 종료 후 잔류 활동 컷오프 |
| `END_GRACE_SEC` | 90 | 초 | 식사 중간 잠시 멈춤 흡수 [Auracle 2018 패턴] |
| `MIN_MEAL_DURATION_SEC` | 90 | 초 | 짧은 false positive (사탕·껌) 폐기 |
| `WALKING_AVG_THRESHOLD` | 0.15 | g | 보행 통상 0.2-0.5g, 보수적 컷오프 |
| `IMPULSE_THRESHOLD` | 0.5 | g | 일반 저작 상한의 3-5배, 비정형 임펄스 컷 |
| `BUFFER_SECONDS` | 30 | 초 | Stage 3 60s 윈도우의 절반 + 여유 |

---

## 부록 B. 핵심 출처 클러스터 (이 문서 인용 출처)

**학술 baseline (🟢)**:
- [기술-2.1] IMChew (Yang et al., ACM BodySys 2024) — F1 0.91 lab, MAPE 9.51%
- [기술-2.1] EarBit (Bedri et al., ACM IMWUT 2017) — Wild F1 0.801, Lab 0.909
- [기술-2.1] Snacking Detection (ACM ISWC 2022) — Acc 0.45-0.53 (snacking은 어렵다는 lower bound)
- [기술-2.1] Auracle (Bi et al., ACM IMWUT 2018) — 자유생활 식사 검출 recall 77-92%
- [기술-2.1] Bruxism Earable Feasibility (ACM UbiComp 2021) — 식사 외 활동 분리 휴리스틱 근거
- [기술-2.1] CHOMP (Hummel et al., arXiv 2026) — IMU 단독 vs 융합 한계 근거

**Apple API (🟡)**:
- [기술-1.1] CMHeadphoneMotionManager (Apple Developer Docs) — 25Hz, 단일 채널, 백그라운드 미보장
- [기술-1.2] Apple jaw health patent (2026.03) — V2+ 흡수 시나리오 근거

**디스커버리 결정 (🟡)**:
- [discovery §6.1] 정확도 KPI 권고 F1 0.75-0.85 (행동 변화 코칭용)
- [discovery 함정#1·3] Vessyl·Healbe 약속 금지 가드레일

---

## 업데이트 이력

- **2026-05-02**: 초안. 7개 필수 섹션 (결론·검출 대상·알고리즘·KPI·캘리브레이션·한계·구현 권고) + 부록 A·B. baseline 인용 18건, 매직 넘버 15개 모두 출처/캘리브레이션 가능 형태로 명시. 단위 테스트 12개 케이스 정의. 다음 에이전트(`app-experience-designer`, `ios-app-architect`) 인용 가이드 §7 포함.
- **2026-05-03**: v1.1 Patch 추가 — "감지 살리기" 라운드. magnitude 정류 결함 해결 + 첫 사용자 cold-start 검출 흐름 회복. §v1.1-1 ~ §v1.1-6 추가. 매직 넘버 변경 표·신규 단위 테스트 5건·구현자 인터페이스 가이드 포함. v1 명세 §1~§7는 *그대로 보존*하며, 충돌하는 부분은 §v1.1에서 명시적 갱신.

---

# v1.1 Patch — "감지 살리기" 라운드 (2026-05-03)

> **이 섹션은 v1 명세를 *대체하지 않음*. v1 §1~§7은 그대로 유효하며, 아래에 명시된 항목만 갱신됨.** 갱신 위치는 매 항목에 인용 표시.

## v1.1-0. 라운드 동기

`05_build_report.md` §7.5에서 구현자가 자체 인정한 결함:

> "T1-T7 합성 sine은 *PreprocessedSample 직접 주입* 방식으로 BiquadFilter·ArtifactFilter를 검증 — `IMUSample` → magnitude 정류 변환을 거치지 않음. 실제 `Preprocessor.ingest`를 거친 IMU 데이터에서는 magnitude = `sqrt(x²+y²+z²)` 정류로 주파수가 2배가 되므로, BiquadFilter 입력 신호 모델이 실제 IMU와 다름."

**결과적 사용자 증상**: 단위 테스트 29/29 통과 + 사용자 실제 음식 저작 시 **검출 0건**. 두 결함이 동시 작용:

1. **Magnitude 정류 결함** — `Preprocessor.ingest`의 `m = √(x²+y²+z²)`는 *전파 정류 (full-wave rectification)*와 같은 효과를 준다. zero-mean sine wave가 magnitude로 변환되면 음수가 양수로 뒤집히면서 *기본 주파수가 2배*가 된다. 실 저작 1.0–1.5 Hz가 정류 후 2.0–3.0 Hz가 되어 §2.3의 bandpass 0.94–2.0 Hz의 *상한*에 걸려 reject. 단위 테스트는 sine을 *PreprocessedSample.magnitude*에 직접 주입하므로 zero-mean sine 그대로 전달되어 통과 (정류 단계 우회).
2. **첫 사용자 cold-start 임계값** — §4.3 cold start 기본값 (PEAK_THRESHOLD 0.05g, MEAL_START_THRESHOLD 25)은 *캘리브레이션 후 사용자별로 보정한다는 전제*에서 보수적으로 잡혔다. MockMotionStream이 자동 emit을 안 하고, 첫 사용자는 캘리브레이션도 못 마친 상태에서 보수적 임계값에 부딪혀 자동 검출 0건.

**v1.1 목표**: **0건 → N건** (검출 흐름이 *작동*하는 것 우선). 정확도 KPI(F1 ≥ 0.75–0.80)는 v1.5+로 미뤄둔다 — 사용자 명시 요청.

**가드레일 유지**: 옵션 G 톤 (추정 ±15%, 임상 약속 금지) / 학술 baseline 천장 / 외부 의존성 0 / iOS 17+, Swift 5.9, vDSP·SwiftData만.

---

## v1.1-1. 알고리즘 변경 사항

### v1.1-1.A. Magnitude 정류 대체 — **(b) Detrended Magnitude** 채택

**결정**: Preprocessor 출력 신호를 `magnitude(t) - runningMean(magnitude, last 2s)` (zero-mean detrended magnitude)로 변경.

**3개 후보 비교**:

| 옵션 | 신호 정의 | 장점 | 단점 | 학술 baseline |
|------|---------|-----|-----|------------|
| (a) **z축 (또는 max-variance 축) + DC removal** | `accel.z(t) - mean(accel.z, 2s)` | 회전 무시 → 가장 깔끔한 zero-mean signal | AirPods 착용 각도가 사용자별·일별로 다름 → max-variance 축 선택 로직 필요. 좌우 비대칭 사용자도 다름 | EarBit lab은 단일 축 사용 가능했지만 *고정된 헤드밴드*에서 검증 [기술-2.1] |
| (b) **Detrended magnitude** (running mean 차감) ★ | `√(x²+y²+z²)(t) - mean(magnitude, 2s)` | magnitude의 회전 불변성 유지 + 정류 효과 제거 (DC 제거로 음·양 진동 복원). v1 §2.2 architecture 변경 최소 | running mean 윈도우 길이 선택 필요 (2s 권장) | **IMChew 2024 §3 표준 전처리** — magnitude high-pass DC removal이 가장 일반적 |
| (c) **Magnitude 1차 미분** (`d/dt magnitude`) | `(magnitude(t) - magnitude(t-1)) × sampleRate` | 주파수 보존 (미분은 frequency-preserving) + DC 자동 제거 | high-frequency noise 증폭 → SNR 악화. 추가 low-pass 필요 | EarBit 2017이 jerk(가속도 미분)를 보조 피처로 사용했으나 단독은 비권장 |
| (d) **다른 권고** | — | — | — | — |

**(b) 채택 근거**:
1. **학술 baseline 정합** — IMChew 2024가 보고한 "magnitude DC-removal이 25Hz IMU 저작 검출의 *de facto 표준*" [기술-2.1]
2. **회전 불변성 유지** — v1 §2.2의 magnitude 채택 근거 ("AirPods 착용 각도 차이로 단일 축 변동 큼")가 그대로 유효. (a)는 이 근거를 깬다.
3. **구현 단순성** — Preprocessor에 running mean buffer 1개만 추가. BiquadFilter·ArtifactFilter·Detector 인터페이스 *변경 없음*. (c)는 추가 low-pass 필요로 더 복잡.
4. **정류 효과 제거** — magnitude(t)는 항상 양수지만 `magnitude(t) - mean(2s)`는 zero-mean이 되어 양·음 진동 복원. 1.0–1.5 Hz 입력이 그대로 1.0–1.5 Hz 출력으로 보존.

**의사코드 (v1 §2.2 Stage 1 갱신)**:

```pseudo
class Preprocessor:
    var ringBuffer: [PreprocessedSample]                  // 최근 30s, magnitude raw
    var detrendedRing: [PreprocessedSample]               // 최근 30s, detrended (검출 입력)
    let DETREND_WINDOW_SEC = 2.0                          // [신규, IMChew 표준]

    function ingest(sample: IMUSample):
        let m = sqrt(sample.userAccel.x^2 + sample.userAccel.y^2 + sample.userAccel.z^2)
        ringBuffer.append(PreprocessedSample(timestamp: sample.timestamp, magnitude: m))
        ringBuffer.dropOlderThan(now - BUFFER_SECONDS)

        # === v1.1 추가: detrending ===
        let recentRaw = ringBuffer.filter { sample.timestamp - $0.timestamp <= DETREND_WINDOW_SEC }
        let dcLevel = recentRaw.map(\.magnitude).mean()
        let detrended = m - dcLevel
        detrendedRing.append(PreprocessedSample(timestamp: sample.timestamp, magnitude: detrended))
        detrendedRing.dropOlderThan(now - BUFFER_SECONDS)
```

**Detector 변경**: `ChewDetector.detectChew(buffer:now:)`가 받는 `buffer`를 *raw ringBuffer* 대신 *detrendedRing*로 교체. BiquadFilter는 그대로 (이미 zero-mean 신호 가정으로 설계됨).

**중력 누설 처리**: `CMDeviceMotion.userAcceleration`은 이미 gravity가 제거된 값 [기술-1.1]이지만 잔여 DC 성분 (sensor bias, slow drift)이 있을 수 있다. detrending이 이 잔여 DC도 함께 제거 → *추가 high-pass 필터 불요*.

### v1.1-1.B. Bandpass 대역 — **0.94–2.0 Hz 유지**

**결정**: 변경 없음. v1 §2.3의 BAND_LOW_HZ=0.94, BAND_HIGH_HZ=2.0 그대로.

**근거**:
- v1.1-1.A의 detrending이 정류 효과를 제거하므로 입력 신호가 학술 baseline과 동일한 0.94–2.0 Hz 대역에 위치
- 학술 baseline (IMChew·EarBit) 모두 이 대역 사용 [기술-2.1]
- 대역 확장(0.5–4Hz)은 false positive ↑ 감수 — v1.1의 목표는 *true positive 회복*이지 false positive 추가 허용 아님
- BiquadFilter SOS 계수 hard-code 그대로 (재계산 불요)

**예상 효과**: 1.0–1.5 Hz 저작 신호가 detrending 후 그대로 1.0–1.5 Hz로 bandpass 통과 → §2.3 §6.4의 핵심 path 복원.

### v1.1-1.C. 임계값 + 감도 모드 — **3-Tier 임계값 시스템**

**결정**: PEAK_THRESHOLD를 *3-tier 시스템*으로 재설계 + 감도 모드 (Sensitivity Mode) 신규 도입.

| Tier | 사용 시점 | PEAK_THRESHOLD_G | MEAL_START_THRESHOLD | 설명 |
|------|---------|----------------|---------------------|------|
| **Sensitivity Mode** | 첫 사용자, 캘리브레이션 미완료, 사용자가 Settings에서 ON | **0.015** | **12** | 가장 관대 — 검출 흐름 작동 보장. false positive ↑ |
| **Default (Cold Start)** | v1.1 신규 기본값. 캘리브레이션 미완료 신규 사용자 | **0.025** | **18** | v1 0.05의 절반. 학술 baseline IMChew 보고 정상 저작 진폭 0.04-0.10g의 *하한 0.04g 대비 -38%* 보수치 |
| **Calibrated** | 캘리브레이션 1식사 완료 후 (§4.1 시퀀스) | 사용자별 (0.03–0.12 clamp) | 사용자별 CPM × 0.6 (≥15) | v1 §4.1 그대로 — 변경 없음 |

**근거 (Default 0.025g)**:
- v1 0.05g는 IMChew 2024 보고 정상 저작 진폭 0.04–0.10g 중간값으로 잡혔으나, *정류 결함 + cold start 임계값* 두 결함 동시에 작용해 *하한 0.04g 미만의 약한 저작 사용자도 0건* 결과
- 0.025g는 0.04g의 ~62% — IMChew §3 보고 *진폭 분포의 p10*에 해당 (대부분 사용자의 약한 저작 진폭이 이 위에 위치)
- detrended magnitude는 zero-mean 신호이므로 진폭이 raw magnitude의 *절반 정도*가 된다 (peak-to-peak가 peak로 바뀌면서 절반). 0.025g는 raw magnitude 0.05g와 *수치적으로 동등한 entry-level threshold*

**근거 (Sensitivity Mode 0.015g)**:
- 새 사용자가 첫 식사에서 *반드시 N건 검출*되도록 — 0건이면 신뢰 즉사
- false positive ↑ 감수: ⚠ 사용자 카피에 "감도 높임 모드 — 일부 일상 활동도 식사로 잡힐 수 있어요" 명시 필요
- 캘리브레이션 1식사 완료 후 자동 OFF + Calibrated tier로 전환

**감도 모드 흐름**:

```pseudo
struct UserPreferences:
    var sensitivityModeEnabled: Bool          # default true (첫 사용자)
    var calibrationCompletedAt: Date?         # nil = cold start

function effectivePeakThreshold(userPrefs, calibration):
    if let cal = calibration:                 # 캘리브레이션 완료
        return cal.userPeakThreshold          # v1 §4.1 그대로
    elif userPrefs.sensitivityModeEnabled:    # cold start + 감도 모드
        return 0.015
    else:                                      # cold start + 감도 모드 OFF
        return 0.025

function effectiveMealStartThreshold(userPrefs, calibration):
    if let cal = calibration:
        return cal.userMealStartThreshold
    elif userPrefs.sensitivityModeEnabled:
        return 12
    else:
        return 18

# 캘리브레이션 완료 시 자동 OFF
function onCalibrationCompleted():
    userPrefs.sensitivityModeEnabled = false
    userPrefs.calibrationCompletedAt = Date()
    persist(userPrefs)
```

**신뢰도 표시 (confidence display)**:
- ChewEvent.confidence는 v1 그대로 [0,1] 발행 (진폭/threshold 비율)
- ActiveMealView·MealResultCard에 "추정 ±15%" 카피 유지 (옵션 G 톤 가드레일)
- 감도 모드 시 추가 카피: "감도 높임 모드 — 정확도가 평소보다 낮을 수 있어요" (Settings 토글 옆 + ActiveMealView 상단 작은 배지)

---

## v1.1-2. 매직 넘버 변경 표 (before / after / 근거)

| 상수 | v1 값 | v1.1 값 | 단위 | 근거 |
|------|------|--------|----|----|
| `DEFAULT_PEAK_THRESHOLD_G` | 0.05 | **0.025** | g | detrended magnitude는 raw 대비 진폭 절반 + cold start 검출 회복 우선 (위 §v1.1-1.C) |
| `DEFAULT_MEAL_START_THRESHOLD` | 25 | **18** | 회/60s | CPM 18 = 분당 18회 = 매우 천천히 먹는 사용자도 첫 식사부터 인식 |
| `SENSITIVITY_PEAK_THRESHOLD_G` | (없음) | **0.015** | g | 감도 모드 (Sensitivity Mode) — 첫 사용자 0건 방지 보장 |
| `SENSITIVITY_MEAL_START_THRESHOLD` | (없음) | **12** | 회/60s | 감도 모드 식사 시작 임계 |
| `DETREND_WINDOW_SEC` | (없음) | **2.0** | 초 | running mean 윈도우 길이 [IMChew 2024 표준 2s detrending] |
| `BAND_LOW_HZ` | 0.94 | 0.94 | Hz | 변경 없음 (§v1.1-1.B) |
| `BAND_HIGH_HZ` | 2.0 | 2.0 | Hz | 변경 없음 |
| `MIN_PEAK_INTERVAL_SEC` | 0.3 | 0.3 | 초 | 변경 없음 |
| `DETECT_WINDOW_SEC` | 2.0 | 2.0 | 초 | 변경 없음 |
| `MEAL_END_THRESHOLD_CPM` | 8.0 | **5.0** | CPM | DEFAULT_MEAL_START_THRESHOLD 25→18 하향에 정비례 (8 × 18/25 ≈ 5.76 → 5.0 보수치). 식사 종료 오인 방지 |
| `WALKING_AVG_THRESHOLD` | 0.15 | 0.15 | g | 변경 없음 — detrended 신호도 보행 시 잔여 DC 잡음 ↑로 동일 컷오프 유효 |
| `IMPULSE_THRESHOLD` | 0.5 | 0.5 | g | 변경 없음 |
| `CALIBRATION_THRESHOLD_MIN` | 0.03 | **0.015** | g | detrended 진폭 절반 보정 |
| `CALIBRATION_THRESHOLD_MAX` | 0.12 | **0.06** | g | 동일 보정 |
| `CALIBRATION_PERCENTILE_FACTOR` | 0.7 (p70) | 0.7 (p70) | — | 변경 없음 |
| `CALIBRATION_START_FACTOR` | 0.6 | 0.6 | — | 변경 없음 |
| `CALIBRATION_START_FLOOR` | 15 | **10** | 회/60s | DEFAULT 25→18 하향에 정비례 |

**v1.1 신규 상수 (DetectorConstants Swift enum에 추가)**:

```swift
public static let SENSITIVITY_PEAK_THRESHOLD_G: Double = 0.015
public static let SENSITIVITY_MEAL_START_THRESHOLD: Int = 12
public static let DETREND_WINDOW_SEC: Double = 2.0
```

**갱신되는 상수**:

```swift
public static let DEFAULT_PEAK_THRESHOLD_G: Double = 0.025         // v1: 0.05
public static let DEFAULT_MEAL_START_THRESHOLD: Int = 18           // v1: 25
public static let MEAL_END_THRESHOLD_CPM: Double = 5.0             // v1: 8.0
public static let CALIBRATION_THRESHOLD_MIN: Double = 0.015        // v1: 0.03
public static let CALIBRATION_THRESHOLD_MAX: Double = 0.06         // v1: 0.12
public static let CALIBRATION_START_FLOOR: Int = 10                // v1: 15
```

---

## v1.1-3. 신규 단위 테스트 케이스 (T13~T17)

기존 T1~T12는 *PreprocessedSample 직접 주입* 방식이라 정류 결함을 우회했다. T13~T17은 **`IMUSample` → `Preprocessor.ingest` → `Detector.detectChew` 풀 파이프라인**을 검증하여 0건 → N건 회귀를 보장한다.

| # | 케이스 | 입력 (synthetic IMU full pipeline) | 기대 출력 |
|---|--------|------------------------------------|---------|
| **T13** | **풀 파이프라인 — 이상적 저작** | y축에 1.5 Hz sine, 0.06g amplitude, 60초, **`IMUSample` 형태로 `Preprocessor.ingest()` 통과** → Detector | ChewEvent **≥ 60개** (1.5Hz × 60s × 0.7 detection rate) — *T1과 동일 입력이지만 풀 파이프라인 통과* |
| **T14** | **풀 파이프라인 — 저작 빈도 하한** | 1.0 Hz sine, 0.04g, 60초, 풀 파이프라인 | ChewEvent ≥ 40개 (cold-start sensitivity OFF, default 0.025g threshold) |
| **T15** | **감도 모드 — 매우 약한 저작 검출** | 1.2 Hz sine, **0.018g** (default threshold 0.025g 미만), 60초, *Sensitivity Mode ON* | ChewEvent ≥ 30개 (감도 모드 0.015g threshold로 검출) |
| **T16** | **3-tier 임계값 동작** | 동일 입력 1.2Hz/0.020g/60s를 3-tier 각각으로 실행 | (1) Sensitivity ON: 검출 ≥ 30개, (2) Default cold start: 검출 0개 (under threshold), (3) Calibrated user(threshold=0.018g): 검출 ≥ 30개 |
| **T17** | **Detrending 검증 — 주파수 보존** | 1.5 Hz sine, 0.05g, 60초 풀 파이프라인 | 검출된 ChewEvent의 *간격 평균이 1/1.5 ± 0.1 초* (주파수가 정류로 2배가 되면 0.33s, 정상이면 0.67s — 후자여야 함) |

**T18 회귀 가드 (Mock 자동 emitter 통합)**:

| # | 케이스 | 입력 | 기대 출력 |
|---|--------|------|---------|
| **T18** | **Mock 자동 emitter — 식사 시뮬** | `MockMotionStream.startSyntheticMealEmission(durationSec: 600)` (§v1.1-4.D 참조), 풀 파이프라인 | MealStartedEvent emit + ChewEvent 누적 ≥ 200개 + MealEndedEvent emit (식사 종료 후 grace 90s 경과) |

**합격선**: 기존 T1~T12 12건 + T13~T18 6건 = **총 18건 검출 테스트 통과**. T13~T17 중 1건이라도 실패 시 v1.1 배포 차단.

---

## v1.1-4. 구현자 인터페이스 가이드

### v1.1-4.D. Mock 자동 emitter 사양 (`MockMotionStream` 확장)

`MockMotionStream`에 자동 합성 식사 emit 메서드 추가. *현실적 식사*를 모방하는 합성 시퀀스 권고:

**합성 식사 sequence 사양**:

| 파라미터 | 권고값 | 근거 |
|---------|------|----|
| **저작 빈도** | 1.2 Hz ± 20% jitter (랜덤 walk) | 한국인 평균 저작 CPM 65–75 [discovery §3.2] = 1.08–1.25 Hz, 중간값 1.2 Hz |
| **저작 진폭 (y축)** | 0.06g ± 15% jitter | IMChew 2024 정상 저작 진폭 0.04–0.10g 중간값 |
| **노이즈 (x·z축)** | 평균 0g, σ=0.005g Gaussian noise | sensor bias 시뮬 — 너무 크면 walking artifact false positive |
| **중간 휴식 (식사 내 멈춤)** | 매 30–60초 마다 5–15초 무신호 (확률 0.3) | Auracle 2018 보고 식사 내 자연 휴식 패턴 — Stage 3 grace period 검증 |
| **식사 길이** | 12–18분 (720–1080초) | 한식 평균 12–20분 [discovery §3.2] |
| **식사 시작 ramp-up** | 첫 5초는 amplitude × 0.5 (사용자가 첫 입 들어가는 동안) | 식사 시작 자연 기록 — Stage 3 시작 검출 부드럽게 |
| **식사 종료 ramp-down** | 마지막 10초는 amplitude × 0.5 | 식사 종료 자연 기록 |

**MockMotionStream 신규 API 의사코드**:

```swift
extension MockMotionStream {
    /// v1.1: 자동 합성 식사 emission. 시뮬레이터 + Preview용.
    /// 별도 Task로 백그라운드 실행. timestamp는 CACurrentMediaTime() 기반.
    public func startSyntheticMealEmission(
        durationSec: Double = 900,        // 15분 기본
        chewFrequencyHz: Double = 1.2,
        chewAmplitudeG: Double = 0.06,
        jitterFactor: Double = 0.2,
        includeRestPauses: Bool = true,
        startTimestamp: TimeInterval? = nil  // nil = CACurrentMediaTime()
    ) async {
        let start = startTimestamp ?? CACurrentMediaTime()
        var t = start
        let end = start + durationSec
        var nextRestAt = start + Double.random(in: 30...60)

        // Ramp-up 5s
        await emitChewSegment(from: t, durationSec: 5,
                              freqHz: chewFrequencyHz,
                              amplitudeG: chewAmplitudeG * 0.5,
                              jitter: jitterFactor)
        t += 5

        while t < end - 10 {
            if includeRestPauses && t >= nextRestAt {
                let restDur = Double.random(in: 5...15)
                await emitSilenceSegment(from: t, durationSec: restDur)
                t += restDur
                nextRestAt = t + Double.random(in: 30...60)
                continue
            }
            // 다음 chew 간격 = 1/freq + jitter
            let interval = 1.0 / chewFrequencyHz * Double.random(in: 1.0 - jitterFactor ... 1.0 + jitterFactor)
            await emitSingleChew(at: t, amplitudeG: chewAmplitudeG * Double.random(in: 0.85...1.15))
            t += interval
        }

        // Ramp-down 10s
        await emitChewSegment(from: t, durationSec: 10,
                              freqHz: chewFrequencyHz,
                              amplitudeG: chewAmplitudeG * 0.5,
                              jitter: jitterFactor)
    }

    /// 단일 chew = y축 sine wave 1주기 (1/freq 초 동안 amplitude g)
    private func emitSingleChew(at t: TimeInterval, amplitudeG: Double) async {
        // 0.4초 동안 1주기 (≈ 1.2Hz 한 번 씹기)
        let pulseDur = 0.4
        let samples = Int(pulseDur * DetectorConstants.SAMPLE_RATE)
        for i in 0..<samples {
            let dt = Double(i) / DetectorConstants.SAMPLE_RATE
            let mag = amplitudeG * sin(2 * .pi * (1 / pulseDur) * dt)
            // x·z 노이즈
            let noiseX = Double.random(in: -0.005...0.005)
            let noiseZ = Double.random(in: -0.005...0.005)
            emit(IMUSample(
                timestamp: t + dt,
                userAccel: SIMD3(noiseX, mag, noiseZ),
                rotationRate: .zero
            ))
        }
        try? await Task.sleep(nanoseconds: UInt64(pulseDur * 1_000_000_000))
    }

    private func emitSilenceSegment(from t: TimeInterval, durationSec: Double) async {
        let samples = Int(durationSec * DetectorConstants.SAMPLE_RATE)
        for i in 0..<samples {
            let dt = Double(i) / DetectorConstants.SAMPLE_RATE
            let noiseX = Double.random(in: -0.005...0.005)
            let noiseZ = Double.random(in: -0.005...0.005)
            emit(IMUSample(
                timestamp: t + dt,
                userAccel: SIMD3(noiseX, 0, noiseZ),
                rotationRate: .zero
            ))
        }
        try? await Task.sleep(nanoseconds: UInt64(durationSec * 1_000_000_000))
    }

    private func emitChewSegment(...) async { /* 연속 chew sine */ }
}
```

**시뮬레이터 자동 통합 (옵션)**:
- `#if targetEnvironment(simulator)` 분기에서 `MockMotionStream` 인스턴스화 후, 사용자가 ActiveMealView 진입 시 `startSyntheticMealEmission(durationSec: 900)` 자동 트리거
- Settings에 "시뮬 합성 식사 자동 시작" 토글 (개발자 모드) — 실기기에선 노출 안 됨

### v1.1-4.E. ChewEvent → ChewSample @Model 매핑 가이드

`ChewDetector`가 발행하는 `ChewEvent` (in-memory struct)를 SwiftData `@Model ChewSample` (persistent)로 1:1 매핑:

```swift
@Model
public final class ChewSample {
    @Attribute(.unique) public var id: UUID
    public var timestamp: Date          // ChewEvent.timestamp (TimeInterval) → Date
    public var magnitudePeak: Double    // ChewEvent.magnitudePeak
    public var confidence: Double       // ChewEvent.confidence
    public var mealSession: MealSession?  // 부모 관계 (역방향)

    public init(from event: ChewEvent, mealSession: MealSession) {
        self.id = UUID()
        self.timestamp = Date(timeIntervalSince1970: event.timestamp)  // CACurrentMediaTime은 monotonic이므로 wall-clock 변환 시 offset 보정 필요
        self.magnitudePeak = event.magnitudePeak
        self.confidence = event.confidence
        self.mealSession = mealSession
    }
}
```

**Timestamp 변환 주의**: `ChewEvent.timestamp`은 `CACurrentMediaTime()` 기반 *monotonic*. SwiftData에 영속화 시 wall-clock으로 변환:

```swift
let bootOffset = Date().timeIntervalSince1970 - CACurrentMediaTime()
let wallClockTime = Date(timeIntervalSince1970: event.timestamp + bootOffset)
```

`bootOffset`은 앱 시작 시 1회 계산해서 캐시. 백그라운드에서 wake-up 시 재계산 권고 (deep sleep 보정).

**저장 시점**: `MealSessionTracker.ingest(chew:)` 내부에서 `chew != nil`일 때 `ChewSample(from: chew, mealSession: currentSession)` 생성 후 `modelContext.insert(sample)`. `MealSession.chewSamples` 관계로 자동 연결.

**저장 부담**: 식사 1회 약 600 chew × 18 식사/주 = 10,800 row/주. SwiftData 부담 없음. 30일 보관 후 cascade delete.

**MealSession 관계 추가 (SwiftData @Model)**:

```swift
@Model
public final class MealSession {
    // ... (기존 필드)
    @Relationship(deleteRule: .cascade, inverse: \ChewSample.mealSession)
    public var chewSamples: [ChewSample] = []
}
```

### v1.1-4.F. 실시간 디버그 카운터 (`ActiveMealView` 권고)

ActiveMealView에 **개발자 모드 디버그 패널** (Settings 토글로 ON/OFF):

| 디버그 정보 | 데이터 소스 | 표시 형식 | 용도 |
|----------|----------|---------|----|
| **현재 CPM** | `MealSessionTracker.events` → `.cpmUpdate(cpm)` | "현재 22 CPM (목표 65)" | 사용자에게도 노출 가능 (디버그 OFF 시) |
| **누적 chew 수** | `currentSession.chewSamples.count` | "127회" | 사용자 노출 OK |
| **마지막 chew timestamp** | `chewSamples.last?.timestamp` | "0.4초 전" | 디버그 ON 전용 — 검출 latency 시각화 |
| **마지막 chew confidence** | `chewSamples.last?.confidence` | "0.83" | 디버그 ON 전용 |
| **현재 magnitude (raw)** | Preprocessor.ringBuffer.last?.magnitude | "0.043g" | 디버그 ON 전용 — 임계값 sanity check |
| **현재 magnitude (detrended)** | Preprocessor.detrendedRing.last?.magnitude | "+0.018g" (signed) | 디버그 ON 전용 — v1.1-1.A 검증 |
| **현재 PEAK_THRESHOLD** | `effectivePeakThreshold(...)` | "0.025g (Default)" / "0.015g (Sensitivity)" / "0.034g (Calibrated)" | 디버그 ON — 어떤 tier가 활성인지 |
| **bandpass 출력 (sparkline)** | 최근 5초 filtered signal | 미니 line chart 60×20pt | 디버그 ON — 실시간 신호 모양 |
| **artifact reject 누적 카운트** | ArtifactFilter reject 4종 분리 | "걷기:3 임펄스:1 burst:0" | 디버그 ON — false negative 원인 진단 |

**구현 권고**:
- `Settings` 화면에 "개발자 모드" 토글 추가 → `UserDefaults.standard.bool(forKey: "developerMode")`
- ActiveMealView에 `@AppStorage("developerMode") var devMode: Bool` 바인딩
- 디버그 패널은 ScrollView 하단 고정 (production 배포 시 숨김 보장)
- 0.5s polling timer로 갱신 — 더 빠르면 UI 부담 ↑

**v1.1 베타 사용자 전달 시**: 디버그 패널 ON 권고 → "검출이 안 되면 어느 단계에서 막혔는지 보내주세요" — 사용자 피드백 수집 인프라

---

## v1.1-5. v1.1 KPI

| KPI | v1.1 목표 | v1 목표 |
|-----|---------|--------|
| **검출 흐름 작동** (실기기, 1식사) | **ChewEvent ≥ 50개** (15분 식사) | (없음) |
| **0건 회귀 방지** | T13~T17 신규 5건 모두 통과 | (없음) |
| **Mock 자동 식사 → 검출** | T18 통과 (시뮬레이터에서 가시 검출) | (없음) |
| 단위 테스트 회귀 | 기존 29건 + 신규 5–6건 = 34–35건, 모두 통과 | 29 |
| 식사 윈도우 F1 | **v1.5+로 미룸** | ≥ 0.80 |
| 개별 저작 F1 | **v1.5+로 미룸** | ≥ 0.75 |
| CPM 정확도 | **v1.5+로 미룸** | ±15% |
| 식사 외 false positive | **< 10건/시간** (감도 모드 시 < 20건/시간) | < 5건/시간 |
| 검출 latency | ≤ 10초 | ≤ 10초 |

**v1.1의 *유일한* 합격 조건**: 사용자가 실제 음식을 씹었을 때 **검출 N≥1**. v1의 정확도 KPI는 cold start 회복 + 캘리브레이션 흐름이 작동한 후 v1.5에서 측정.

**감도 모드 false positive 한도 ↑ 허용 근거**: 사용자 카피 "감도 높임 모드 — 일부 일상 활동도 식사로 잡힐 수 있어요"로 *기대치 사전 조정*. 옵션 G 톤(정직성)에 정합.

---

## v1.1-6. 알려진 한계 (v1.1 신규)

### v1.1-6.1. 감도 모드 false positive 증가

- 감도 모드 시 PEAK_THRESHOLD 0.015g는 *약한 머리 움직임·말하기 burst*도 chew로 잡힐 수 있음
- ArtifactFilter는 그대로 (변경 없음) — Mitigation은 v1.5 CoreML 분류기 도입
- **사용자 카피 필수**: Settings 토글 옆 작은 글자로 "감도 높임 모드는 일부 일상 활동도 식사로 잡힐 수 있어요. 정확도가 평소보다 낮을 수 있어요."
- **ActiveMealView 배지**: 감도 모드 활성 시 상단에 작은 노란색 배지 "감도 높임 모드 활성"

### v1.1-6.2. Detrending 윈도우 transient

- 앱 시작 후 첫 2초 (DETREND_WINDOW_SEC) 동안 detrended signal이 불안정 (running mean이 짧은 데이터로 계산됨)
- Mitigation: Detector는 이미 `window.count >= minSamples (= 25 × 2 × 0.8 = 40)` 조건으로 데이터 부족 시 nil 반환 → 이미 cover됨
- 단위 테스트 T17이 transient 회귀 가드 (1.5Hz 주파수가 정상 보존되는지 검증)

### v1.1-6.3. 감도 모드 → Calibrated 전환 흐름

- 감도 모드에서 검출된 chew들이 *느슨한 임계값*으로 잡혔으므로, 이 데이터로 캘리브레이션하면 Calibrated 임계값도 낮아질 위험
- Mitigation: §4.1 캘리브레이션 시퀀스에서 *명시 트리거*로 시작 (사용자 "지금 식사 시작" 버튼) → 감도 모드와 무관하게 캘리브레이션 진행
- 캘리브레이션 완료 후 §v1.1-1.C `onCalibrationCompleted()` 자동 호출 → `sensitivityModeEnabled = false` 강제 OFF
- 사용자가 Settings에서 다시 ON 가능 (그러나 Calibrated 임계값이 활성 — `effectivePeakThreshold` 우선순위는 Calibrated > Sensitivity > Default)

### v1.1-6.4. v1.1 → v1.5 마이그레이션 경로

- v1.1은 검출 흐름 회복이 목표 — 정확도 향상은 v1.5에서:
  1. 베타 사용자 50명 × 5 식사 = 250 식사 데이터 수집
  2. 사용자 self-report ground truth로 F1 측정
  3. PEAK_THRESHOLD 분포 학습 → 사용자별 자동 캘리브레이션 정확도 ↑
  4. v1.5 CoreML 분류기 (chewing vs non-chewing 2-class) 학습 → ArtifactFilter 강화
- v1.1의 모듈 경계는 v1과 동일 (Preprocessor·Detector·Orchestrator 3 stage) — v1.5 ML 도입에 인터페이스 변경 불요

---

## v1.1-7. 다음 에이전트(`ios-app-implementer`)에게 인계 핵심 메시지

1. **Preprocessor에 detrending 추가** — `detrendedRing` 신규 버퍼 + `DETREND_WINDOW_SEC = 2.0` 적용 (§v1.1-1.A 의사코드). Detector는 *detrendedRing*을 입력으로 받도록 변경.
2. **DetectorConstants 매직 넘버 6개 갱신 + 3개 신규** (§v1.1-2 표) — Swift enum에 그대로 옮기기.
3. **3-tier 임계값 시스템 구현** — `effectivePeakThreshold(userPrefs, calibration)` / `effectiveMealStartThreshold` 헬퍼 함수 + `UserPreferences.sensitivityModeEnabled` SwiftData 필드 추가.
4. **MockMotionStream에 `startSyntheticMealEmission(...)` 신규 API 추가** (§v1.1-4.D). 시뮬레이터 + Preview에서 자동 호출 권고.
5. **ChewSample @Model + `MealSession.chewSamples` 관계 추가** (§v1.1-4.E). `MealSessionTracker.ingest(chew:)`에서 영속화. `bootOffset` 변환 주의.
6. **ActiveMealView 디버그 패널 추가** (§v1.1-4.F) — `@AppStorage("developerMode")` 토글 + 9개 디버그 정보 표시. 베타 사용자 피드백 수집용.
7. **신규 단위 테스트 T13~T18 작성** (§v1.1-3) — *반드시* `IMUSample` → `Preprocessor.ingest()` → `Detector` 풀 파이프라인. T1~T12와 다른 경로.
8. **카피 추가**:
   - Settings: "감도 높임 모드 — 일부 일상 활동도 식사로 잡힐 수 있어요"
   - ActiveMealView 배지: "감도 높임 모드 활성"
   - 감도 모드 카피는 옵션 G 톤(정직성)에 정합 — `app-experience-designer`가 정확한 문구 finalize
9. **캘리브레이션 자동 OFF**: 캘리브레이션 1식사 완료 시 `sensitivityModeEnabled = false` 강제 OFF + `calibrationCompletedAt = Date()` 기록
10. **빌드 검증**: 기존 29건 테스트 회귀 0 + 신규 6건 통과 → `xcodebuild test`로 34/34+ 합격 확인 후 인계

---

# v1.2 Patch — 사후 분석 모드 정확도 개선 라운드 (2026-05-03)

> **이 섹션은 v1·v1.1을 *대체하지 않음*. v1 §1~§7과 v1.1 §v1.1-1 ~ §v1.1-7은 그대로 유효하며, v1.2에 명시된 항목만 갱신·추가됨.** 이 라운드는 *설계 결정만* 다룬다 — 구현·QA는 별도 라운드.

## v1.2-0. 라운드 동기 + 설계 전제 변경

### v1.2-0.1. 사용자 보고 — v1.1 실측 결과
- v1.1 (detrended magnitude + 3-tier 임계값 + Mock 자동 emitter) 실 AirPods 테스트
- **검출률 매우 낮음**: 학술 wild baseline F1 0.71 [기술-2.1, EarBit 2017] 대비 **< 0.30** 추정 (사용자 정성 보고)
- 단위 테스트 35건 모두 통과 ↔ 실 IMU 데이터 0건 검출 — *합성 신호 vs 실 IMU 모델 격차*가 다시 확인됨

### v1.2-0.2. 사용자 요구 사항 변경 (중요)
- **실시간 chew 카운트 표시 불필요** — 사용자가 명시적으로 *사후(post-hoc/offline) 분석*만 필요하다고 결정
- 식사 종료 후 결과 제시(MealResultCard에서 chewCount·avgCPM·timeline)면 충분
- Live Activity의 실시간 CPM·chew 카운트는 *비목표* — UX 사양과 정합 검토 필요 (`app-experience-designer` 인계)

### v1.2-0.3. 설계 전제 변경 (가능성 확장)
실시간 latency 제약 해제 → 알고리즘 설계 자유도 ↑:

| 제약 | v1·v1.1 | v1.2 |
|------|---------|------|
| **Latency** | ≤ 10초 (chew 발생 → emit) | **무제한** (식사 종료 후 분석) |
| **윈도우 길이** | 2초 (sliding) | 3–10초 segmented + multi-pass OK |
| **알고리즘 패스** | 단일 패스 (causal) | **multi-pass** (forward·backward·iterative refinement) |
| **메모리** | ring buffer 30s = ~24KB | 식사 전체 (15분 × 25Hz × 9채널 × 8B = ~1.6MB) OK |
| **CPU** | 식사 중 < 3% (지속) | **식사 종료 시 burst** OK (10–30초 분석, 사용자 인지 차단 화면 노출 가능) |
| **모델 복잡도** | 룰 기반만 | **CoreML / 작은 ML / FFT / autocorrelation** 모두 가능 |
| **외부 의존성** | 0 (vDSP·SwiftData만) | **0 유지** — 가드레일 [chewing-signal-engineer 작업원칙] |

### v1.2-0.4. 가드레일 (변경 없음)
- 옵션 G 톤: "추정 ±15%", 의료 약속 금지 [discovery 함정#1]
- 학술 baseline 천장(F1 0.71–0.80 자유생활) 인용 [기술-2.1, EarBit wild]
- iOS 17+, Swift 5.9, vDSP·SwiftData만 (CoreML은 V1.5 후보)
- "사후 분석으로 정확도 개선" 카피 — 사용자에게 *기다림의 가치* 사전 설명

---

## v1.2-1. IMchew 논문 핵심 추출 (Lin et al. ACM MobiSys 2024)

> **출처**: Ketmalasiri, Wu, Butkow, Mascolo, Liu (2024). "IMChew: Chewing Analysis using Earphone Inertial Measurement Units." *MobiSys '24*, June 3–7, 2024, Minato-ku, Tokyo. ACM ISBN 979-8-4007-0581-6/24/06. [`/IMchew.pdf`]

### v1.2-1.1. 시스템 구성 한눈에

IMChew는 **2 모듈** 구조 (PDF p.2, Figure 2 — System overview):

```
┌─ Chewing Detector ──────────┐    ┌─ Chewing Counter ──────────┐
│ IMU → Segmentation (3s)     │    │ Preprocessing              │
│     → Feature Extraction    │ →  │   (Butterworth bandpass    │
│       (96 features per win) │    │    0.1-3Hz + moving avg)   │
│     → Classifier (RF/DT/LR) │    │ → FFT per 10s window       │
│     → Aggregation (3-of-N)  │    │ → Peak frequency in        │
│ → chewing episodes          │    │   0.5-2.5Hz × window time  │
└─────────────────────────────┘    │ → Sum across episode       │
                                   │ → Total chew count         │
                                   └────────────────────────────┘
```

### v1.2-1.2. 센서 구성 (PDF p.2-3, §4.1 Implementation)
- **하드웨어**: eSense earable (Nokia Bell Labs) [12, 14] — **6축 IMU** (3-axis accelerometer + 3-axis gyroscope) + microphone (사용 안 함 — IMU only로 한정)
- **샘플링**: **60 Hz** (우리 AirPods 25Hz 대비 2.4배 — 직접 차용 시 보정 필요)
- **장착 위치**: 좌측 귀 단일 (left earbud only) — *우리와 동일한 단일 채널 가정*

### v1.2-1.3. Detector 파이프라인 (PDF p.2, §3.1 Chewing Detector)

**Segmentation**: 입력 IMU를 **3초 비중첩 윈도우**로 분할. 이전 연구 [13] 표준 따름.

**Feature Extraction** (각 3초 윈도우 = 180 샘플 @ 60Hz):
- **시간 영역 (Time domain) — 18 features**:
  - mean, variance, power for each of 6 axes (3 accel + 3 gyro)
  - 6 axes × 3 stats = **18 time-domain features**
- **주파수 영역 (Frequency domain) — 78 features**:
  - **Spectral Centroid (SC)** — 6 axes × 1 = **6 features**. "spectrum의 무게 중심" 위치
  - **MFCC (Mel-Frequency Cepstral Coefficient)** — **12 coefficients × 6 axes = 72 features**. 음성 인식에서 차용된 spectral envelope 표현
- **총 96 features per 3s window**

**Classifier** (96차원 → binary chewing/non-chewing):
- 3개 비교: **Logistic Regression**, **Decision Tree**, **Random Forest**
- 80/20 split: RF acc/F1 = **0.97**, LOSO: RF acc/F1 = **0.86** (PDF p.4, Table 2-3)
- **Random Forest가 항상 우승** — feature 비선형성 + 사용자별 분산 흡수

**Aggregation** (3-of-N majority voting, PDF p.3 §3.1):
- 연속 3초 윈도우들을 받아 *연속 chewing 마킹* 시작
- chewing = '1', non-chewing = '0' (per window)
- "**3개 연속 0**"이 나오면 chewing episode 종료
- 첫 '1'부터 마지막 '1'까지의 윈도우 시퀀스 중 **절반 이상이 1이면** → chewing episode로 인정 (majority voting)

**LOSO 평가** (PDF p.4, Table 4): chewing episode 인식 — RF Recall **0.91**, Precision **0.91**, F1 **0.91**, Acc **0.91**

### v1.2-1.4. Counter 파이프라인 (PDF p.3, §3.2 Chewing Counter)

검출된 chewing episode 안에서 횟수 카운팅:

**Preprocessing** (per episode):
- **10초 비중첩 윈도우**로 분할 (PDF p.5 Figure 5 — 10000ms가 MAPE 최저)
- 각 윈도우에 **Butterworth bandpass filter** [low=0.1Hz, high=3Hz] (cutoff 출처: 저작 빈도 0.94-2.5Hz를 모두 포괄 + DC drift 제거)
- 추가: **Moving average filter** (구체 윈도우 길이는 미명시, 통상 25-50 샘플) — 잔여 노이즈 제거
- 효과: Raw signal MAPE 10.82% → Bandpass 9.60% → Bandpass + MovAvg **9.51%** (PDF p.4, Table 5)

**Chewing Frequency Detection**:
- 각 10초 윈도우에 **FFT** (Fast Fourier Transform) 적용 → frequency domain
- **0.5–2.5 Hz 대역 내에서 highest intensity peak frequency** 선택
- "이 윈도우의 chewing 주파수"

**Count Calculation**:
- `windowChews = peakFrequencyHz × windowDurationSec` (예: 1.2Hz × 10s = 12회)
- Episode 전체 = sum of all 10s window chews
- MAPE **9.51%** (PDF p.4 §5.2) — 사용자 평균 0.79–1.16 chews/sec 범위

### v1.2-1.5. 데이터 수집 protocol (PDF p.3, §4.2 Data Collection)

**참가자**: 8명 (4M/4F, 20–60세). 윤리위 승인.

**Chewing tasks**: 각 참가자 5종 음식 × 2분 씹기 = 10분/사용자 chewing data
- 음식: chips, pretzels, apples, mangoes, bread (texture 다양성)

**Non-chewing tasks** (PDF p.3, Table 1): 8가지 활동 = 10분/사용자 non-chewing data
- Sitting Still 2min / Moving Head Side-to-Side 30s / Happy/Sad/Angry Face 30s each / Speaking 2min / Drinking 1min / Watching Movie 3min

**Ground truth labeling**:
- (1) **Video recording** — 동시 녹화 후 사후 라벨링
- (2) **Spacebar logging** — 참가자가 씹을 때마다 스페이스바 눌러 timestamp 기록
- 두 source를 결합해 chew count ground truth 생성

**Limitation 자체 인정** (PDF p.5 §7 Discussion):
- Spacebar 입력이 자연스러운 식사를 방해 → 측정된 chewing rate가 **0.79–1.16 chews/sec** 으로 *문헌 범위 0.94–2.5보다 낮음* (data collection bias)
- "Simultaneous activities (head turning + chewing 등) 평가 안 함" — 모든 non-chewing은 *순수* 비저작 활동

### v1.2-1.6. 보고된 정확도 (PDF p.4, Table 2-6)

| 평가 방법 | Classifier | Recall | Precision | F1 | Accuracy |
|---------|-----------|--------|-----------|-----|---------|
| 80/20 split | RF | 0.97 | 0.97 | 0.97 | 0.97 |
| LOSO (per-window) | RF | 0.86 | 0.86 | 0.86 | 0.86 |
| LOSO (episode, majority voting) | RF | **0.91** | **0.91** | **0.91** | **0.91** |
| Counter MAPE (best filter) | — | — | — | — | **9.51%** |

**Counter MAPE per user** (PDF p.4 Figure 4): 3.79% (best, User5) – 12.92% (worst, User2). User-dependence 강함.
**Counter MAPE per food** (PDF p.4 Figure 4): bread 7.41% (best, 가장 단단함) – mangoes 12.38% (worst, 가장 부드러워 jaw motion 작음).

### v1.2-1.7. 한계·실패 모드·향후 작업 (PDF p.5 §7)

1. **Noisy labelling** — eating session 내내 일률적으로 'chewing' 라벨 부착했으나, 실제론 음식 입에 넣고·씹고·삼키고·휴식 반복. 짧은 (3s) 윈도우에서 라벨 정확도 ↓
2. **Data collection bias** — Spacebar로 ground truth 수집하면 자연 chewing 방해 → 0.79-1.16 c/s만 측정됨 (실제 0.94-2.5 가능)
3. **Simultaneous activities 미평가** — 식사 중 head turning, smiling, speaking 동시 발생 시 정확도 미보고

### v1.2-1.8. **우리가 즉시 차용 가능한 6+ 기법** (★)

| # | IMchew 기법 | 우리 적용 가능성 | 차용 우선순위 |
|---|-----------|----------------|------------|
| **★1** | **Counter는 episode 내 FFT-peak × time** (룰 기반, ML 불요) | ✅ AirPods 25Hz로도 가능. 실시간 불필요 = 식사 종료 후 1회 FFT. **외부 의존 0** (vDSP `vDSP_fft_zrip`) | **즉시 차용** |
| **★2** | **Butterworth bandpass + Moving Average** | ✅ 우리 BiquadFilter는 0.94-2Hz 4차 → IMchew는 0.1-3Hz로 **광대역 + moving average 후처리**. MAPE 10.82→9.51% 효과 | **즉시 차용** (대역 확장 + post-MA) |
| **★3** | **3초 segmentation + 96 features + Random Forest** | ✅ Detector에 Random Forest 적용. 단, **학습 데이터 필요** — V1.5+ (사용자 데이터 수집 후) | **2단계 차용** |
| **★4** | **Spectral Centroid + MFCC features** | ✅ vDSP로 직접 구현 가능. RF 학습용 feature로 사용 | **2단계 차용** |
| **★5** | **3-of-N majority voting aggregation** | ✅ 즉시 차용. v1·v1.1의 candidate filtering보다 robust | **즉시 차용** |
| **★6** | **10초 윈도우 (Counter용)** | ✅ Figure 5의 MAPE-vs-window 곡선 — 10000ms가 minimum (9.51%). 우리도 동일 채택 | **즉시 차용** |
| ★7 | 60Hz IMU | ❌ AirPods는 25Hz 고정 — Nyquist 12.5Hz로 chewing 0.94-2.5Hz 충분 | 차용 불가 (HW 제약) |
| ★8 | 6축 IMU (accel + gyro) | ✅ AirPods CMHeadphoneMotionManager는 attitude/rotationRate/userAcceleration 모두 제공. **현재 우리는 userAcceleration만 사용** — gyro 미활용 | **즉시 차용** (gyro 신호 추가) |

---

## v1.2-2. v1.1 한계 재진단 (signal engineer 시각, IMchew 비교)

> 사용자 컨텍스트의 7개 가설을 IMchew 논문과 *우리 구현*을 대조해 우선순위 매김.

### v1.2-2.1. 결정적 원인 (★ = 가장 영향 큼)

| # | 가설 | 진단 (IMchew 비교) | 결정성 | v1.2 대응 |
|---|------|------------------|-------|----------|
| **A★★★** | **합성 신호 vs 실 IMU 모델 격차** | IMchew는 **8명 실 데이터**로 학습/검증. 우리는 합성 sine으로만 검증 → unit test green ↛ 실 데이터 green. *근본 원인* | **결정적** | §v1.2-6 데이터 수집 인프라 (CSV export) → 실 데이터로 알고리즘 튜닝 |
| **B★★★** | **2s detrending 윈도우 vs 1Hz 신호 충돌** | IMchew는 **0.1Hz high-pass cutoff** (10초 시정수). 우리 2s detrending = ~0.5Hz cutoff로 *1Hz 신호 자체를 약화*. running mean이 신호의 ~30%를 컷 | **결정적** | §v1.2-3 옵션 A: detrending 제거 + IMchew의 광대역 0.1-3Hz bandpass 채택 |
| **C★★★** | **단일 채널 (userAcceleration magnitude만)** | IMchew는 **6축 모두** 사용 (accel xyz + gyro xyz). magnitude는 1차원 압축 → 정보 손실 (특히 head rotation은 gyro에 명확) | **결정적** | §v1.2-3 옵션 A·D: gyro xyz + accel xyz 모두 활용 (per-axis bandpass + ensemble) |
| **D★★** | **임계값 0.015g도 한국 음식·천천히 씹기엔 보수적** | IMchew Figure 1 (Pretzel) — accel 진폭 약 0.1-0.3g, gyro 5-15°/s. 우리 detrended magnitude는 raw 대비 절반 → 0.05-0.15g 분포 → 0.015g threshold는 OK이나 *bandpass에서 이미 약화* (B와 결합 효과) | 중요 (B와 동시) | §v1.2-3 옵션 B·C: threshold-free (autocorrelation/FFT) 접근 |
| **E★★** | **abs() 제거 후 positive peak만** | v1.1이 정류 결함 회피하느라 positive peak만 봄 → 1.5Hz에서 ½ peak 손실. IMchew는 *frequency domain*으로 양·음 무관 | 중요 | §v1.2-3 옵션 C: FFT 기반 (위상 무관) |
| F | MIN_PEAK_INTERVAL_SEC 0.3s 너무 보수 | IMchew counter는 *peak interval 사용 안 함* — FFT의 peak frequency만 사용. 우리는 peak detection에 묶여 0.3s에 1개 미만 강제 → 빠른 저작자 손실 | 중간 | 옵션 C에서 자동 해결 (FFT) |
| G | ArtifactFilter walking 임계 0.15g 너무 좁음 | IMchew도 walking 명시 평가 안 함 (Table 1 비저작은 sit/head turn/face/speak/drink/movie). 우리 0.15g는 v1 초기 추정 — 식사 자세 (테이블 앞 앉음 + 음식 들기·내려놓기)에서도 자주 초과 가능 | 중간 | 옵션 D ensemble에서 ArtifactFilter 비중 ↓ |
| H | 캘리브레이션 미완료 시 감도 모드 한계 | IMchew는 *per-user calibration 없이* LOSO로 F1 0.86. 우리는 사용자별 임계값에 의존 → cold start 손실 | 중간 | 옵션 A의 ML 분류기는 user-independent (LOSO 검증 필요) |

### v1.2-2.2. 우선순위 결론

**가장 영향 큰 셋 (A·B·C)**: 모두 *알고리즘 설계 수준*에서 해결되어야 함. v1.2의 핵심 결정.
- **A**는 §v1.2-6 데이터 수집 인프라로 (구조적 해결)
- **B·C**는 §v1.2-3 알고리즘 옵션 비교에서 (즉시 해결)

---

## v1.2-3. v1.2 알고리즘 옵션 비교 (5개)

> **공통 가정**: 사후 분석 모드 — 식사 종료 시점에 그 식사 전체 IMU buffer를 처리. 입력은 6축 (accel xyz g + gyro xyz rad/s) × N samples (15분 식사 = 22,500 samples).

### v1.2-3.1. 옵션 매트릭스

| 옵션 | 알고리즘 핵심 | 출력 | iOS 구현 난이도 | 외부 의존성 | 학습 데이터 필요 | 정확도 기대 (F1 자유생활) | iOS Swift 가능성 |
|------|-------------|-----|---------------|-----------|--------------|---------------------|----------------|
| **A** | IMchew 직접 차용 (RF + 96 features) | chewing episode + chew count | **상** (RF 구현 + feature engineering) | CoreML (RF) or 직접 구현 | **8명 × 5음식 × 2분 = 80분 chewing + 80분 non-chewing** | 0.85–0.91 (LOSO) | iOS CoreML 가능. 학습은 Python sklearn → coremltools 변환 |
| **B** | 자기상관 기반 (ACF peak detection) | chew count + 평균 chewing 주기 | 중 (vDSP autocorrelation) | 0 | **0** (unsupervised) | 0.45–0.60 (자체 추정) | vDSP_acorr |
| **C** | Spectral analysis (FFT/STFT 0.94–2Hz energy) | chew count (per window) + chewing episode | 중 (vDSP FFT) | 0 | **0** | 0.55–0.70 (IMchew Counter MAPE 9.51% 차용) | vDSP_fft_zrip |
| **D★** | Ensemble (룰 + 자기상관 + spectral 합의) | chewing episode + chew count + confidence | 중-상 (3 sub-detector + voting) | 0 | **0** | **0.55–0.70 (이번 라운드 목표)** | iOS Swift 직접 구현 |
| **E** | HMM or 작은 1D-CNN (CoreML) | chewing/non-chewing per window + count | 상 (CoreML 학습 파이프라인) | CoreML | **20–50 식사 라벨** (사용자 데이터) | 0.65–0.80 (V1.5에서) | CoreML on-device |

### v1.2-3.2. 5축 비교 상세

#### 옵션 A: IMchew 직접 차용

**필터·feature·classifier 매칭**:
- Sampling: 25Hz (우리) → 60Hz (IMchew). 60Hz용 Butterworth 0.1-3Hz 계수를 25Hz용으로 재계산 (`scipy.signal.iirfilter(4, [0.1, 3.0], btype='band', fs=25, output='sos')`)
- Window: 3초 (75 samples @ 25Hz, IMchew는 180 @ 60Hz)
- Features: 18 time + 78 freq = **96 features per window**
- Classifier: Random Forest (sklearn → coremltools → `.mlmodel` → CoreML on-device)
- Aggregation: 3-of-N majority voting (즉시 차용)
- Counter: episode 내 10s 윈도우 × FFT peak frequency × duration (즉시 차용)

**장점**: 학술 baseline 거의 그대로 → F1 0.86–0.91 가능 (LOSO)
**단점**: 학습 데이터 부재 — *우리는 8명 × 80분 데이터가 없다*. 학습 없이는 옵션 A 시작 불가.
**소요**: 데이터 수집 4–8주 + 학습 2주 + iOS 통합 2주 = **8–12주**
**비고**: V1.5+ 후보 — 이번 라운드(v1.2)에선 미채택

#### 옵션 B: 자기상관 (ACF, autocorrelation function)

**원리**: chewing은 *주기적 신호* — autocorrelation R(τ)에서 chewing 주기 (~0.4-1.0초)에 명확한 peak.

```pseudo
function detectChewByACF(magnitude_window: [Double], sampleRateHz: Double) -> ChewingResult?:
    # 1) 광대역 bandpass 0.5-3Hz로 노이즈 제거
    filtered = butterworthBandpass(magnitude_window, 0.5, 3.0, sampleRateHz)

    # 2) 자기상관 함수 계산 (vDSP_acorr)
    acf = autocorrelation(filtered)   # acf[0] = signal energy

    # 3) Lag 0.4-1.5초 (= 25-37 samples @ 25Hz) 구간에서 peak 찾기
    minLag = Int(sampleRateHz * 0.4)   # 10
    maxLag = Int(sampleRateHz * 1.5)   # 37
    let peakLag = argmax(acf[minLag...maxLag])
    let peakValue = acf[peakLag]

    # 4) Peak / acf[0] ratio로 신뢰도 결정
    let confidence = peakValue / acf[0]
    if confidence < 0.3: return nil   # 비주기적 신호

    let chewingPeriodSec = Double(peakLag) / sampleRateHz
    let chewingFreqHz = 1.0 / chewingPeriodSec
    let chewCount = Int(window.duration * chewingFreqHz)
    return ChewingResult(periodSec: chewingPeriodSec, count: chewCount, confidence: confidence)
```

**장점**: 학습 데이터 0, 외부 의존성 0, threshold 거의 자동, 위상·정류 무관
**단점**: 비주기적 noise (말하기·웃음)에서도 우연히 ACF peak 가능 — false positive 위험. Episode 검출은 못 함 (count만)
**소요**: 1주

#### 옵션 C: Spectral analysis (FFT/STFT)

**원리**: IMchew Counter §3.2 직접 차용. 10초 윈도우 × FFT × peak frequency in 0.94-2Hz.

```pseudo
function detectChewBySpectrum(samples: [IMUSample], sampleRateHz: Double) -> [ChewWindow]:
    # 1) magnitude 계산 (또는 원하는 단일 축)
    let mag = samples.map { sqrt($0.userAccel.x²+y²+z²) }

    # 2) Butterworth bandpass 0.1-3Hz (광대역, IMchew Counter용)
    let filtered = butterworthBandpass(mag, 0.1, 3.0, sampleRateHz)

    # 3) Moving average (window=10 samples ≈ 0.4s @ 25Hz) — IMchew 후처리
    let smoothed = movingAverage(filtered, window: 10)

    # 4) 10초 비중첩 윈도우로 분할 (IMchew Figure 5 — 10000ms = MAPE 9.51%)
    let windowSamples = Int(sampleRateHz * 10)   # 250 @ 25Hz
    let windows = chunked(smoothed, size: windowSamples)

    var results: [ChewWindow] = []
    for win in windows:
        # 5) FFT (vDSP_fft_zrip)
        let fft = realFFT(win, paddedTo: nextPowerOf2(windowSamples))   # 256 → 256/2+1 bins
        let powerSpectrum = fft.map { $0.real² + $0.imaginary² }

        # 6) 0.94-2Hz 대역 내 peak frequency 찾기
        let freqResolution = sampleRateHz / Double(fft.count * 2)   # 25/512 ≈ 0.049Hz
        let lowBin = Int(0.94 / freqResolution)                    # 19
        let highBin = Int(2.0 / freqResolution)                    # 41
        let peakBin = argmax(powerSpectrum[lowBin...highBin])
        let peakFreq = Double(peakBin) * freqResolution
        let peakPower = powerSpectrum[peakBin]

        # 7) 신뢰도 = peak power / total band power
        let bandPower = powerSpectrum[lowBin...highBin].sum()
        let confidence = peakPower / bandPower

        # 8) chewing count = freq × duration
        let chewCount = Int(peakFreq * 10.0)
        results.append(ChewWindow(startTime: ..., chewCount: chewCount, peakFreq: peakFreq, confidence: confidence))

    return results
```

**장점**: 학습 데이터 0, 외부 의존성 0, IMchew의 검증된 기법 (MAPE 9.51%), 위상·정류 무관
**단점**: 윈도우 단위 (10초) 미만의 micro-event 검출 불가 (개별 chew timestamp 없음). Episode 검출은 추가 필요 (옵션 B와 결합 or 별도 단순 룰).
**소요**: 1.5주

#### 옵션 D ★: Ensemble (룰 + 자기상관 + spectral 합의)

**원리**: 옵션 B·C·기존 룰 (peak detection)을 *각각 candidate generator*로 실행, **3개 중 ≥2 합의** 시에만 chewing window로 인정. 셋의 false positive 패턴이 *독립적*이므로 합의가 정밀도 ↑.

```pseudo
function ensembleDetect(samples: [IMUSample]) -> MealAnalysisResult:
    # Stage 1: 식사 전체를 10초 비중첩 윈도우로 분할
    let windows10s = chunkInto10sWindows(samples)

    var labeledWindows: [(window: Range, isChewing: Bool, chewCount: Int)] = []

    for (idx, win) in windows10s.enumerated():
        # Sub-detector 1: 룰 기반 (v1.1 그대로 적용, peak detection + ArtifactFilter)
        let ruleResult = legacyRulePipeline(win)            # → (isChewing: Bool, chewCount: Int)

        # Sub-detector 2: 자기상관 (옵션 B)
        let acfResult = detectChewByACF(win)                # → ChewingResult? (nil = non-chewing)

        # Sub-detector 3: Spectral (옵션 C)
        let fftResult = detectChewBySpectrum(win)           # → ChewWindow

        # 합의: 3개 중 ≥2가 chewing이라고 하면 chewing
        let votes = [ruleResult.isChewing, acfResult != nil, fftResult.confidence >= 0.3]
        let isChewing = votes.filter { $0 }.count >= 2

        # Count는 합의 시 spectral 우선 (MAPE 9.51% 검증된 방식)
        let chewCount = isChewing ? fftResult.chewCount : 0
        labeledWindows.append((win.timeRange, isChewing, chewCount))

    # Stage 2: IMchew 3-of-N aggregation으로 chewing episode 식별
    let episodes = aggregateEpisodes(labeledWindows, minConsecutiveZeros: 3)
    let totalChews = episodes.flatMap(\.windows).map(\.chewCount).sum()

    return MealAnalysisResult(
        episodes: episodes,
        totalChews: totalChews,
        avgCPM: totalChews / mealDurationMin,
        confidence: ensembleConfidence(labeledWindows)
    )
```

**장점**: 학습 데이터 0, 외부 의존성 0, **세 알고리즘 독립적 false positive 상쇄** (=ensemble 효과), 모든 옵션의 장점 흡수
**단점**: 3 알고리즘 구현 부담 (개별로 동작 검증 필요), 합의 가중치 튜닝 필요
**소요**: 2.5주
**Why ★**: v1.2 라운드의 **권장 옵션** (§v1.2-4 근거)

#### 옵션 E: HMM or 1D-CNN (CoreML)

**원리**: 옵션 A의 단순화된 버전 — Random Forest 대신 *작은 시계열 모델*. 입력은 raw 6축 sequence (3초 = 75 samples × 6 channels = 450 features) → binary classifier.

**HMM**: Hidden Markov Model — chewing/non-chewing state + transition prob. 학습 시 state별 emission distribution 추정. 학습 데이터 작아도 동작 (수십 식사면 충분).
**1D-CNN**: 3 conv layers + GAP + dense → ~50K params. CoreML 변환 가능.

**장점**: ML 강점 (자동 feature 학습), CoreML on-device, 작은 데이터셋도 가능
**단점**: 학습 데이터 필요 (최소 20 식사 × 사용자 self-report), 학습 인프라 필요
**소요**: 데이터 수집 + 학습 + 통합 = 6–10주
**비고**: V1.5+ 후보 — 데이터 수집(§v1.2-6) 후 결정

### v1.2-3.3. 5축 비교 표 요약

| 5축 | A (IMchew RF) | B (ACF) | C (FFT) | D★ (Ensemble) | E (CoreML) |
|----|--------------|---------|---------|--------------|-----------|
| **구현 난이도** | 상 | 중 | 중 | 중-상 | 상 |
| **정확도 기대 (F1)** | 0.85–0.91 | 0.45–0.60 | 0.55–0.70 | **0.55–0.70** | 0.65–0.80 |
| **외부 의존성** | CoreML | 0 | 0 | 0 | CoreML |
| **iOS Swift 가능성** | 변환 필요 | 직접 구현 | 직접 구현 | 직접 구현 | 학습 후 변환 |
| **학습 데이터 필요량** | 80분/사용자 × 8 | **0** | **0** | **0** | 20+ 식사 라벨 |

---

## v1.2-4. 권장 v1.2 결정 + 근거

### v1.2-4.1. **단계적 결정**: 옵션 D (Ensemble) 즉시 + 옵션 E (CoreML) V1.5+

#### 1단계 (v1.2 — 즉시 6주):
**옵션 D (Ensemble: 룰 + ACF + Spectral)** 채택. 출력: 사후 분석 모드 (식사 종료 시 1회 처리)

**근거**:
1. **학습 데이터 0** — 데이터 수집 인프라 전엔 ML 불가 [chewing-signal-engineer 흔한 실수: "데이터 없이 ML 불가"]
2. **외부 의존성 0** — vDSP만으로 ACF + FFT 구현 가능 [iOS 17+, Swift 5.9, vDSP·SwiftData만 가드레일]
3. **IMchew 검증된 핵심 기법 즉시 차용** — Counter §3.2의 FFT-peak counting (MAPE 9.51%) + 3-of-N aggregation을 우리 환경에서 직접 사용 가능
4. **3개 sub-detector 합의로 false positive ↓** — 단일 알고리즘 한계를 ensemble로 흡수. v1.1의 결정적 결함 (B·C 단일 채널 + 정류) 모두 우회
5. **사후 분석 모드 정합** — 사용자가 실시간 카운트 불요라고 명시 → ensemble의 multi-pass 부담 OK
6. **데이터 수집과 병행 가능** — §v1.2-6 CSV export 인프라를 v1.2와 함께 출시하면 사용자 데이터 누적 → V1.5 ML 학습용

#### 2단계 (V1.5 — 데이터 수집 후, 8–12주 뒤):
**옵션 E (HMM or 1D-CNN)** — 베타 사용자 50명 × 5–10 식사 데이터 누적 후. CoreML 학습 파이프라인 구축.

#### 3단계 (V2 — 1년 후):
**옵션 A (IMchew RF 직접 차용)** — LOSO F1 0.86–0.91 도달 가능. 단, *학술 SOTA 도달이 옵션 G 가치 제안의 핵심 자산이 아님* (자산은 임상 콘텐츠·KOL·페르소나 [discovery 합성 §3]) — 우선순위 낮음.

### v1.2-4.2. 왜 다른 옵션을 미루는가

| 옵션 | 왜 v1.2가 아닌가 |
|------|---------------|
| A (IMchew RF) | 학습 데이터 부재 — 8명 × 80분 데이터를 *우리가* 수집해야 함. 8–12주. v1.2에서 미채택, V1.5+ 후보 |
| B (ACF 단독) | 단독 사용 시 false positive 높음 (말하기·웃음 우연 주기성). D ensemble 안에 sub-detector로 *포함* |
| C (FFT 단독) | 윈도우 단위 (10초) 검출만 — episode 시작/종료 정밀도 낮음. D ensemble 안에서 룰 기반과 결합 |
| E (CoreML) | 학습 데이터 부재 (옵션 A와 동일 이유). 그러나 작은 데이터로 가능 → 옵션 A보다 V1.5에 더 빨리 도달 |

### v1.2-4.3. KPI 목표 (v1.2)

| KPI | v1 목표 | v1.1 목표 | **v1.2 목표** | 학술 baseline |
|-----|--------|---------|------------|------------|
| 식사 윈도우 F1 | ≥ 0.80 | (v1.5 미룸) | **0.55–0.65** (이번 라운드) | 0.71–0.80 wild |
| 개별 저작 F1 | ≥ 0.75 | (v1.5 미룸) | **0.50–0.65** | 0.71–0.80 wild |
| Chew count MAPE | ±15% | (v1.5 미룸) | **±20–25%** | 9.51% (IMchew lab) |
| 검출 0건 회귀 가드 | — | T17 통과 | T17 + **신규 T19~T28** 통과 | — |

**근거**: 학술 wild baseline 0.71에 *근접*하는 0.55–0.65 — 이번 라운드는 데이터 수집 인프라 + 사후 분석 알고리즘의 *작동 검증*이 우선. 0.71 도달은 V1.5에서 ML 도입 후.

---

## v1.2-5. 알고리즘 의사코드 (Swift 변환 가능 수준)

### v1.2-5.1. 입력·전처리

```swift
struct MealRawBuffer {
    let samples: [IMUSample]              // 식사 전체 (CACurrentMediaTime 기반)
    let mealStartTimestamp: TimeInterval
    let mealEndTimestamp: TimeInterval
    let userPreferences: UserPreferences
    let userCalibration: UserCalibration?
}

struct PostHocAnalyzer {
    let sampleRate: Double = 25.0

    func analyze(_ buffer: MealRawBuffer) -> MealAnalysisResult {
        // 1) 6축 채널 분리
        let accelX = buffer.samples.map(\.userAccel.x)
        let accelY = buffer.samples.map(\.userAccel.y)
        let accelZ = buffer.samples.map(\.userAccel.z)
        let gyroX  = buffer.samples.map(\.rotationRate.x)
        let gyroY  = buffer.samples.map(\.rotationRate.y)
        let gyroZ  = buffer.samples.map(\.rotationRate.z)

        // 2) Magnitude (3축 norm) — IMchew §3.2 Preprocessing 호환
        let accelMag = zip3(accelX, accelY, accelZ).map { sqrt($0*$0 + $1*$1 + $2*$2) }
        let gyroMag  = zip3(gyroX,  gyroY,  gyroZ ).map { sqrt($0*$0 + $1*$1 + $2*$2) }

        // 3) Butterworth bandpass 0.1-3Hz (IMchew §3.2 §★2) — 광대역
        let widebandFilter = BiquadFilter(lowHz: 0.1, highHz: 3.0, fs: sampleRate)
        let accelFiltered = widebandFilter.filter(accelMag)
        let gyroFiltered  = widebandFilter.filter(gyroMag)

        // 4) Moving average (window=10 samples ≈ 0.4s) — IMchew §★2 후처리
        let accelSmoothed = movingAverage(accelFiltered, window: 10)
        let gyroSmoothed  = movingAverage(gyroFiltered,  window: 10)

        // 5) 10초 비중첩 윈도우 분할 (IMchew Figure 5 — best window 10000ms)
        let windowSamples = Int(sampleRate * 10)              // 250
        let accelWindows = chunked(accelSmoothed, size: windowSamples)
        let gyroWindows  = chunked(gyroSmoothed,  size: windowSamples)

        // 6) 옵션 D Ensemble 적용 (§v1.2-5.2)
        let labeled = zip(accelWindows, gyroWindows).enumerated().map { (idx, pair) in
            let (a, g) = pair
            let timeStart = buffer.mealStartTimestamp + Double(idx * windowSamples) / sampleRate
            return ensembleClassify(accelWindow: a, gyroWindow: g, timeStart: timeStart)
        }

        // 7) IMchew 3-of-N aggregation으로 episode 식별
        let episodes = aggregateEpisodes(labeled, minConsecutiveZeros: 3)

        // 8) Episode 내 chew count summation
        let totalChews = episodes.flatMap(\.windows).map(\.chewCount).reduce(0, +)
        let mealDurationMin = (buffer.mealEndTimestamp - buffer.mealStartTimestamp) / 60.0
        let avgCPM = mealDurationMin > 0 ? Double(totalChews) / mealDurationMin : 0

        return MealAnalysisResult(
            episodes: episodes,
            totalChews: totalChews,
            avgCPM: avgCPM,
            confidence: averageConfidence(labeled),
            algorithmVersion: "v1.2-D-ensemble"
        )
    }
}
```

### v1.2-5.2. Ensemble classifier (옵션 D 핵심)

```swift
struct WindowLabel {
    let timeStart: TimeInterval
    let isChewing: Bool
    let chewCount: Int
    let peakFreqHz: Double
    let confidence: Double
    let votes: (rule: Bool, acf: Bool, fft: Bool)   // 디버그용
}

func ensembleClassify(accelWindow: [Double], gyroWindow: [Double], timeStart: TimeInterval) -> WindowLabel {
    // === Sub-detector 1: 룰 기반 ===
    // accel 윈도우의 RMS가 walking 임계 이하 + bandpass 0.94-2Hz 통과 신호의 peak count
    let accelRMS = sqrt(accelWindow.map { $0*$0 }.reduce(0,+) / Double(accelWindow.count))
    let isNotWalking = accelRMS < DetectorConstants.WALKING_AVG_THRESHOLD
    let narrowBand = BiquadFilter(lowHz: 0.94, highHz: 2.0, fs: 25.0).filter(accelWindow)
    let peakCount = countLocalMaxima(narrowBand, threshold: DetectorConstants.SENSITIVITY_PEAK_THRESHOLD_G)
    let ruleVote = isNotWalking && peakCount >= 5      // 10s에 5+ peak = chewing 후보

    // === Sub-detector 2: 자기상관 (ACF) ===
    let acf = vDSPAutocorrelation(accelWindow)         // size = window.count
    let minLag = Int(25.0 * 0.4)                       // 10 samples = 0.4s
    let maxLag = Int(25.0 * 1.5)                       // 37 samples = 1.5s
    let peakLag = argmax(Array(acf[minLag...maxLag])) + minLag
    let acfRatio = acf[peakLag] / acf[0]
    let acfVote = acfRatio >= 0.3
    let acfFreqHz = 25.0 / Double(peakLag)

    // === Sub-detector 3: Spectral (FFT) ===
    let fftSize = 256                                  // 다음 2의 거듭제곱
    let padded = accelWindow + [Double](repeating: 0, count: fftSize - accelWindow.count)
    let powerSpectrum = vDSPRealFFTPower(padded, size: fftSize)
    let freqRes = 25.0 / Double(fftSize)               // 0.0977Hz
    let lowBin = Int(0.94 / freqRes)                   // 9
    let highBin = Int(2.0 / freqRes)                   // 20
    let bandSlice = Array(powerSpectrum[lowBin...highBin])
    let peakBinLocal = argmax(bandSlice)
    let peakFreqHz = Double(lowBin + peakBinLocal) * freqRes
    let peakPower = bandSlice[peakBinLocal]
    let bandPower = bandSlice.reduce(0, +)
    let fftConfidence = bandPower > 0 ? peakPower / bandPower : 0
    let fftVote = fftConfidence >= 0.3

    // === Gyro 보조 신호 (IMchew §★8 차용) ===
    // gyro magnitude의 ACF도 계산 — head turning vs chewing 분리
    let gyroACF = vDSPAutocorrelation(gyroWindow)
    let gyroPeakLag = argmax(Array(gyroACF[minLag...maxLag])) + minLag
    let gyroRatio = gyroACF[gyroPeakLag] / max(gyroACF[0], 1e-9)
    // head turning 패턴: gyro에 큰 ACF, accel은 작음 → 우리는 *둘 다 강한* 케이스만 chewing
    let gyroVote = gyroRatio < 0.6                     // gyro가 너무 강하면 head motion 의심

    // === 합의 (≥2 of 3, gyro는 veto only) ===
    let mainVotes = [ruleVote, acfVote, fftVote].filter { $0 }.count
    let isChewing = mainVotes >= 2 && gyroVote        // gyro veto

    // === Count: spectral peak frequency × duration ===
    let chewCount = isChewing ? Int(peakFreqHz * 10.0) : 0
    let confidence = isChewing ? (Double(mainVotes) / 3.0 + fftConfidence) / 2.0 : 0

    return WindowLabel(
        timeStart: timeStart, isChewing: isChewing, chewCount: chewCount,
        peakFreqHz: peakFreqHz, confidence: confidence,
        votes: (ruleVote, acfVote, fftVote)
    )
}
```

### v1.2-5.3. Episode aggregation (IMchew §3.1 직접 차용)

```swift
struct ChewEpisode {
    let windows: [WindowLabel]
    var startTime: TimeInterval { windows.first!.timeStart }
    var endTime: TimeInterval { windows.last!.timeStart + 10.0 }
    var chewCount: Int { windows.map(\.chewCount).reduce(0,+) }
}

func aggregateEpisodes(_ labels: [WindowLabel], minConsecutiveZeros: Int = 3) -> [ChewEpisode] {
    // IMchew §3.1: chewing='1', non-chewing='0'. "3개 연속 0" → episode 종료.
    // 첫 '1'부터 마지막 '1'까지 윈도우 시퀀스. *majority voting* — 절반 이상이 '1'이면 episode 인정.
    var episodes: [ChewEpisode] = []
    var currentRun: [WindowLabel] = []
    var consecutiveZeros = 0

    for label in labels {
        if label.isChewing {
            currentRun.append(label)
            consecutiveZeros = 0
        } else {
            if !currentRun.isEmpty {
                currentRun.append(label)
                consecutiveZeros += 1
                if consecutiveZeros >= minConsecutiveZeros {
                    // Episode 종료 — trim trailing zeros, majority vote
                    while let last = currentRun.last, !last.isChewing {
                        currentRun.removeLast()
                    }
                    let chewingCount = currentRun.filter(\.isChewing).count
                    if chewingCount >= currentRun.count / 2 {     // majority
                        episodes.append(ChewEpisode(windows: currentRun))
                    }
                    currentRun.removeAll()
                    consecutiveZeros = 0
                }
            }
        }
    }
    // Tail episode
    if !currentRun.isEmpty {
        let chewingCount = currentRun.filter(\.isChewing).count
        if chewingCount >= currentRun.count / 2 {
            episodes.append(ChewEpisode(windows: currentRun))
        }
    }
    return episodes
}
```

### v1.2-5.4. 매직 넘버 표 (v1.2 신규 + 갱신)

| 상수 | v1.2 값 | 단위 | 출처 |
|------|--------|----|----|
| `WIDEBAND_LOW_HZ` | 0.1 | Hz | IMchew §3.2 Counter preprocessing — DC 제거 + 광대역 chewing 포착 |
| `WIDEBAND_HIGH_HZ` | 3.0 | Hz | IMchew §3.2 — chewing 상한 + harmonics 일부 포함 |
| `MOVING_AVG_WINDOW` | 10 | samples | IMchew §3.2 후처리 (≈0.4s @ 25Hz) — MAPE 10.82→9.51% 효과 |
| `POSTHOC_WINDOW_SEC` | 10.0 | 초 | IMchew Figure 5 — best window 10000ms (MAPE 9.51%) |
| `EPISODE_MIN_CONSECUTIVE_ZEROS` | 3 | 윈도우 | IMchew §3.1 aggregation (3 연속 non-chewing → episode 종료) |
| `EPISODE_MAJORITY_THRESHOLD` | 0.5 | ratio | IMchew §3.1 majority voting (절반 이상 chewing → episode 인정) |
| `ACF_MIN_LAG_SEC` | 0.4 | 초 | chewing 주기 하한 (= 2.5Hz 상한 1/2.5 = 0.4) |
| `ACF_MAX_LAG_SEC` | 1.5 | 초 | chewing 주기 상한 (= 0.67Hz 하한 1/0.67 ≈ 1.5) |
| `ACF_PEAK_RATIO_THRESHOLD` | 0.3 | ratio | autocorrelation peak / R(0) 기준 (자체 추정 — 베타에서 튜닝) |
| `FFT_SIZE` | 256 | samples | 25Hz × 10s = 250 samples → 다음 2의 거듭제곱 |
| `FFT_CONFIDENCE_THRESHOLD` | 0.3 | ratio | peak power / band power (자체 추정) |
| `GYRO_VETO_RATIO` | 0.6 | ratio | gyro ACF가 너무 강하면 head motion → chewing veto (자체 추정) |
| `RULE_PEAK_COUNT_MIN` | 5 | peaks/10s | 10초에 5+ peak = chewing 후보 (= CPM 30 보수치) |
| `SENSITIVITY_PEAK_THRESHOLD_G` | 0.015 | g | v1.1 그대로 — 룰 sub-detector에서 사용 |

**v1·v1.1 매직 넘버**: 모두 *그대로 보존* (v1.2는 사후 분석 path 추가, 실시간 path 변경 없음). `MEAL_END_THRESHOLD_CPM`·`PEAK_THRESHOLD_G` 등은 사후 분석에서 미사용.

### v1.2-5.5. 세션 통합 흐름

```pseudo
# 식사 종료 시점에 호출 (MealSessionTracker.finalize 직후)
function onMealEnded(descriptor: MealSessionDescriptor):
    # 1) raw IMU 버퍼 추출 (백그라운드에서 누적된 SwiftData IMUFrame batch)
    let rawBuffer = MealRepository.fetchRawBuffer(forMealId: descriptor.id)

    # 2) 사용자에게 "분석 중..." 화면 노출 (1-2초)
    showAnalyzingScreen()

    # 3) 백그라운드 Task로 사후 분석 (CPU burst OK)
    Task.detached(priority: .userInitiated):
        let analyzer = PostHocAnalyzer()
        let result = analyzer.analyze(rawBuffer)

        # 4) 결과를 MealSessionDescriptor에 기록 + SwiftData 영속화
        await MealRepository.update(
            mealId: descriptor.id,
            chewCount: result.totalChews,
            avgCPM: result.avgCPM,
            episodes: result.episodes,
            algorithmVersion: result.algorithmVersion
        )

        # 5) MealResultCard에 결과 표시 (식사 종료 직후 자연스러운 노출)
        await MainActor.run:
            navigateToMealResultCard(descriptor.id)

        # 6) 30일 후 raw IMUFrame은 cascade delete (CSV export 후)
```

---

## v1.2-6. 데이터 수집 인프라 사양

### v1.2-6.1. CSV export 형식

**파일명**: `chewcoach_meal_<UUID>_<startTimeISO8601>.csv`

**컬럼**:

```csv
timestamp_ms_relative,wall_clock_iso8601,accel_x_g,accel_y_g,accel_z_g,gyro_x_radps,gyro_y_radps,gyro_z_radps,magnitude_g,detrended_g,bandpass_g,detected_chew,reject_reason,user_confirmed_chewing
0,2026-05-03T12:34:56.000Z,0.0021,0.0156,-0.0033,0.012,0.005,-0.001,0.0162,0.0054,0.0023,0,,1
40,2026-05-03T12:34:56.040Z,0.0019,0.0211,-0.0028,0.013,0.004,-0.002,0.0214,0.0071,0.0042,0,,1
80,2026-05-03T12:34:56.080Z,0.0018,0.0298,-0.0019,0.015,0.003,-0.001,0.0299,0.0094,0.0089,1,,1
...
12000,2026-05-03T12:35:08.000Z,0.0501,0.0123,-0.0287,0.231,0.452,-0.198,0.0596,0.0398,0.0421,0,walking_avg_exceeded,0
...
```

**컬럼 설명**:

| 컬럼 | 형식 | 설명 |
|-----|-----|-----|
| `timestamp_ms_relative` | Int | 식사 시작 기준 ms (CACurrentMediaTime 기반) |
| `wall_clock_iso8601` | String | RFC3339 UTC timestamp (분석·결합용) |
| `accel_x_g`, `_y_g`, `_z_g` | Float | userAcceleration (gravity 제거) |
| `gyro_x_radps` 등 | Float | rotationRate |
| `magnitude_g` | Float | sqrt(x²+y²+z²) — Preprocessor 출력 |
| `detrended_g` | Float | v1.1 detrended (디버그용) |
| `bandpass_g` | Float | 0.94-2Hz bandpass 출력 (디버그용) |
| `detected_chew` | 0/1 | 우리 알고리즘이 chewing이라 판정한 sample (peak timestamp 위치) |
| `reject_reason` | String | ArtifactFilter reject 시 (`walking_avg_exceeded`/`impulse`/`burst`) — 빈 문자열 가능 |
| `user_confirmed_chewing` | 0/1 | **사용자 자기보고** (식사 후 "이 시간에 씹고 있었나요?" 응답 — V1.2에서 라벨링 UI 미제공, V1.5에서 누적용 컬럼 형식만 정의) |

**파일 크기**: 15분 식사 × 25Hz × 11 컬럼 × ~80 byte/row = **약 1.8 MB/식사** (압축 전). gzip 후 ~400KB.

### v1.2-6.2. CSV export trigger·UI

**위치 1: Settings → Developer Mode → "Export Meal Data" 섹션**
- 토글: "데이터 수집에 동의합니다" (default OFF — 명시 옵트인)
- 버튼: "최근 식사 N개 CSV 내보내기" → `UIDocumentPickerViewController` (사용자가 위치 선택)
- 버튼: "전체 CSV 내보내기 (zip)" → multi-file zip
- 라벨: "Beta 알고리즘 개선용. 데이터는 기기 내에서만 저장되며, 사용자가 명시적으로 export할 때만 외부로 나갑니다."

**위치 2: MealResultCard 하단 (v1.2 베타 한정)**
- 작은 텍스트 링크: "이 식사 데이터를 개발팀에 보내기 (베타 협력자만)"
- 탭하면 익명화된 CSV + 사용자 메모 (선택)를 zip으로 만들어 ShareSheet
- 사용자 정성 피드백 컬럼 추가 (예: "이 식사 천천히 먹었음", "외식 — 한식")

**위치 3: 자동 누적 (백그라운드)**
- SwiftData IMUFrame @Model에 raw buffer 누적 (식사 1회 = ~22,500 row)
- 30일 후 cascade delete (사용자 표시 안 함)
- 목적: V1.5 ML 학습용 데이터 풀 — *사용자 명시 옵트인 시에만 export*

### v1.2-6.3. 데이터 수집 루프 (5–10명 / 20+ 식사)

**Phase 0: 빌더 dogfooding (1주, N=2)**
- 본인 + 협력자 1명, 각 7끼 = 14 식사
- 라벨: self-report (식사 시작·종료 timestamp 명시 트리거 + 식사 후 정성 메모)
- 분석: CSV → Python notebook으로 ground truth (사용자 메모) vs 우리 알고리즘 결과 비교
- 합격선: 식사 윈도우 검출 10/14 (recall 71%) — 학술 wild baseline 도달

**Phase 1: Closed Beta (4주, N=5–10)**
- 모집: 트위터·dog-food 그룹에서 5–10명 (옵션 G 페르소나 정합)
- 식사: 각 5–10끼 = 25–100 식사
- 라벨:
  - Settings의 "데이터 수집 동의" ON 후 자동 IMUFrame 누적
  - MealResultCard 하단 정성 피드백 ("천천히 먹음", "급하게 먹음", "외식", "음식 종류" — 자유 텍스트)
  - 5명에게 짧은 비디오 동의 (5분 × 5명 = 25분 ground truth video labeling)
  - 익명화 protocol: 모든 export 파일에서 user identifier 제거 (UUID만)
- 합격선: 식사 윈도우 F1 ≥ 0.50 (v1.2 KPI 0.55–0.65의 -5pp 마진)

**Phase 2: 누적·튜닝 (V1.5 진입 전)**
- 누적 100+ 식사 도달 시 → Python sklearn으로 옵션 A (Random Forest) 학습 시도
- LOSO 검증 후 F1 ≥ 0.70 도달 시 → coremltools 변환 → V1.5 후보
- 사용자별 캘리브레이션 효과도 데이터로 측정 (within-subject vs LOSO 차이)

### v1.2-6.4. 익명화 protocol

| 항목 | 처리 |
|-----|-----|
| User identifier | UUID만 (이메일·디바이스ID·이름 미수록) |
| Wall clock timestamp | UTC만 (지역 timezone 노출 안 함) |
| 위치 | 미수집 (CMHeadphoneMotionManager는 위치 미제공) |
| 음식 종류 | 사용자 명시 입력만 (자동 추론 안 함) |
| 정성 메모 | 사용자가 직접 작성 — 익명화 책임은 사용자에게 안내 |
| 보관 기한 | 기기 내 30일, export 후 사용자가 직접 관리 |

**`app-experience-designer`에게**: Settings의 "데이터 수집" 카피 — *"앱 정확도 개선에 도움이 됩니다. 데이터는 기기 내 30일 보관 후 자동 삭제됩니다. 외부로 보내지 않습니다 (export 시에만)."*

---

## v1.2-7. 신규 단위 테스트 케이스 (T19~T28)

> 사후 분석 알고리즘 검증. v1·v1.1 T1~T18 모두 *유지*. T19~T28은 PostHocAnalyzer 단독 + 실 IMU 시나리오 모방 합성 신호 (DC drift + 비대칭 노이즈 + 휴지 + walking artifact).

| # | 케이스 | 입력 (synthetic full-meal IMUSample 시퀀스) | 기대 출력 |
|---|--------|------------------------------------------|---------|
| **T19** | **이상적 1.2Hz 식사 — Ensemble 전체 통과** | 1.2Hz sine on accel_y, 0.06g amplitude, 12분 (720s), 25Hz 샘플링, gyro = 0 | `MealAnalysisResult.totalChews ∈ [800, 900]` (1.2Hz × 720s = 864 ±5%), episodes.count = 1 |
| **T20** | **DC drift 강한 식사 (실 IMU 모방)** | 1.0Hz sine + linear drift 0.02g/min (식사 중 sensor warm-up), 10분 | totalChews ∈ [550, 650] (drift 보정으로 검출 정상) |
| **T21** | **비대칭 노이즈 (positive bias)** | 1.5Hz sine + 0.005g uniform noise + +0.01g DC bias, 8분 | totalChews ∈ [620, 760] |
| **T22** | **중간 휴식 3회 (대화·물 마시기 시뮬)** | 1.2Hz sine 3분 → silence 30s → 1.2Hz 4분 → silence 60s → 1.2Hz 5분 (총 13.5분) | episodes.count ∈ [1, 3] (3-of-N aggregation으로 묶일 수도, 분리될 수도) — totalChews ∈ [800, 950] |
| **T23** | **Walking artifact 중간 삽입** | 1.2Hz sine 5분 → walking pattern (2Hz, 0.3g) 2분 → 1.2Hz 5분 | walking 구간 chewing=false (rule veto), totalChews ∈ [650, 800] |
| **T24** | **Head turning veto (gyro veto 검증)** | 1.2Hz sine on accel + 1.0Hz sine on gyro_z (head turning), 10분 | gyroVote=false → isChewing=false → totalChews < 100 (veto 작동) |
| **T25** | **순수 말하기 (false positive 가드)** | accel: 0.02g random noise + 3-5Hz burst 패턴, 5분 (저작 0회) | totalChews < 50 (3 sub-detector 모두 reject) |
| **T26** | **3-of-N aggregation 단위** | 라벨 시퀀스 [1,1,0,1,1,0,0,0,1,1] 입력 (10×10s 윈도우) | episodes.count = 1, episode.windows = 첫 5개 (3개 연속 0이 6번째부터) |
| **T27** | **Episode majority voting** | 라벨 [1,0,1,0,1,0,0,0] | episodes.count = 1 (3 chewing / 5 non-trailing-zero windows = 60% > 50%) |
| **T28** | **Episode majority voting fail** | 라벨 [1,0,0,1,0,0,0] | episodes.count = 0 (1 chewing / 4 non-trailing-zero = 25% < 50%) |

**T_real_imu_proxy (선택)**: 사용자 실 IMU CSV (베타 협력자 1명)를 fixture로 추가 — repo에 익명화 CSV 1식사 commit + Phase 0 dogfooding 데이터 1식사 — `XCTAssert(totalChews > 50)` (회귀 가드 only, 정확도 미평가)

**합격선**: 기존 T1~T18 + 신규 T19~T28 = **총 28+건**, 모두 통과. T19·T22·T25 중 1건이라도 실패 시 v1.2 배포 차단.

---

## v1.2-8. v1.2 KPI

| KPI | v1.2 목표 | v1 목표 | 학술 baseline |
|-----|---------|--------|------------|
| **검출 0건 회귀 가드** | T17 + T19~T28 모두 통과 | (없음) | — |
| **이상적 합성 식사 검출 (T19)** | totalChews ∈ [800, 900] | (없음) | — |
| **실 IMU CSV proxy** | totalChews > 50 (1식사) | (없음) | — |
| **식사 윈도우 F1** | **0.55–0.65** | ≥ 0.80 | 0.71–0.80 wild |
| **개별 저작 F1** | **0.50–0.65** | ≥ 0.75 | 0.71–0.80 wild |
| **Chew count MAPE** | **±20–25%** | ±15% | 9.51% lab |
| **식사 외 false positive** | < 10건/시간 (사후 분석) | < 5건/시간 | — |
| **CSV export** | 동작 (Settings + MealResultCard 두 path) | (없음) | — |

**v1.2 합격 조건**: 위 KPI 중 회귀 가드 (T17 + T19~T28) + 이상적 합성 식사 + CSV export 모두 통과. F1·MAPE는 *사용자 실 IMU CSV 보내준 후 오프라인 검증* — Phase 0 dogfooding 결과로 Beta 진입 결정.

**오프라인 검증 KPI (실 IMU CSV 5+ 식사 후)**:
- 식사 윈도우 F1 ≥ 0.50 (-5pp 마진) → V1.2 베타 출시 GO
- F1 < 0.40 → 알고리즘 재검토 (gyro veto 임계 등 튜닝)
- F1 0.40–0.50 → 사용자별 캘리브레이션 효과 측정 후 결정

---

## v1.2-9. 구현 가이드 (`ios-app-implementer` 인계)

### v1.2-9.1. 파일별 변경

| 파일 | 변경 |
|-----|----|
| `Core/Detection/Preprocessor.swift` | **변경 없음** — v1.1 그대로 (실시간 path는 v1.1 유지) |
| `Core/Detection/ChewDetector.swift` | **변경 없음** — v1.1 그대로 (사후 분석 path 추가는 별도 모듈) |
| `Core/Detection/DetectorConstants.swift` | **추가**: §v1.2-5.4 표의 14개 신규 상수 (`WIDEBAND_*`, `MOVING_AVG_*`, `POSTHOC_*`, `EPISODE_*`, `ACF_*`, `FFT_*`, `GYRO_VETO_*`, `RULE_PEAK_COUNT_MIN`) |
| `Core/Detection/BiquadFilter.swift` | **확장**: 현재 0.94-2Hz hard-coded → 생성자 파라미터화 (`init(lowHz:, highHz:, fs:)`). 기본값은 v1.1 호환 유지. SOS 계수는 *런타임 계산* (vDSP `vDSP_biquad_CreateSetup` or 직접 bilinear transform) |
| `Core/Detection/MealSessionTracker.swift` | **추가**: `finalize(...)` 직후 `onMealEnded(descriptor)` 호출 (사후 분석 트리거) |
| `Core/Detection/PostHocAnalyzer.swift` | **신규** (§v1.2-5.1~5.3 의사코드 그대로): `analyze(_ buffer: MealRawBuffer) -> MealAnalysisResult` |
| `Core/Detection/SignalDSP.swift` | **신규**: vDSP 헬퍼 — `vDSPAutocorrelation(_:)`, `vDSPRealFFTPower(_:size:)`, `movingAverage(_:window:)`, `argmax(_:)`, `chunked(_:size:)` |
| `Core/Storage/IMUFrame.swift` | **신규** SwiftData @Model — raw IMU buffer 영속화. `mealSession: MealSession?` 관계 + `timestampRelMs`, `accelX/Y/Z`, `gyroX/Y/Z`, `magnitude`, `detrended`, `bandpassed`, `detected`, `rejectReason`. cascade delete 30일 |
| `Core/Storage/MealRepository.swift` | **확장**: `fetchRawBuffer(forMealId:)`, `update(mealId:chewCount:avgCPM:episodes:algorithmVersion:)`, `exportCSV(mealIds:)` (`UIDocumentPickerViewController` 호환 파일 생성) |
| `Core/Sensing/MockMotionStream.swift` | **확장** (사양 §v1.2-9.4): 실 IMU 모방 합성 신호 (DC drift + 비대칭 노이즈 + 휴지 + walking artifact 모드) |
| `Features/ActiveMeal/ActiveMealView.swift` | **변경 없음** (실시간 표시 사용자 요구 변경 — `app-experience-designer` 별도 결정) |
| `Features/MealHistory/MealResultCard.swift` | **추가**: 하단 "데이터 보내기" 링크 (베타 옵트인 후 노출) + "분석 중..." spinner state |
| `Features/Settings/SettingsView.swift` | **추가**: "데이터 수집 동의" 토글 + "Export Meal Data" 섹션 (Developer Mode 하위) |
| `ChewCoach/ChewCoachApp.swift` | **추가**: SwiftData ModelContainer에 `IMUFrame` 추가 |

### v1.2-9.2. SwiftData 추가 모델

```swift
@Model
public final class IMUFrame {
    @Attribute(.unique) public var id: UUID
    public var mealSession: MealSession?
    public var timestampRelMs: Int           // 식사 시작 기준 ms
    public var wallClock: Date               // wall clock UTC

    // Raw IMU
    public var accelX: Double
    public var accelY: Double
    public var accelZ: Double
    public var gyroX: Double
    public var gyroY: Double
    public var gyroZ: Double

    // Derived (디버그·CSV용)
    public var magnitude: Double             // sqrt(x²+y²+z²)
    public var detrended: Double             // v1.1 detrended
    public var bandpassed: Double            // v1.1 0.94-2Hz output

    // 검출 결과
    public var detected: Bool                // ChewDetector가 chewing 판정한 sample
    public var rejectReason: String?         // ArtifactFilter reject 시

    public init(...) { ... }
}

extension MealSession {
    @Relationship(deleteRule: .cascade, inverse: \IMUFrame.mealSession)
    public var imuFrames: [IMUFrame] = []
}
```

**저장 부담**: 식사 1회 약 22,500 row × 평균 100 bytes = 2.25MB. 30일 보관 시 (5식사/일 × 30일 = 150 식사) ~340MB. *⚠ 디스크 부담 무시 못 함*. **권고**:
- 사용자 옵트인 시에만 `IMUFrame` 누적 (default OFF)
- 옵트인 시 사용자 카피: "고용량 데이터 (약 2MB/식사 × 30일)" 명시
- 옵트아웃 시 `IMUFrame` 미생성, `MealSession`만 — v1·v1.1과 동일

### v1.2-9.3. Mock 자동 emitter 보강 (실 IMU 모방)

`MockMotionStream`에 신규 모드 추가 (v1.1 `startSyntheticMealEmission` 확장):

```swift
extension MockMotionStream {
    public enum SyntheticMode: String, Sendable {
        case ideal              // v1.1 — 1.2Hz pure sine (단위 테스트용)
        case realistic          // v1.2 신규 — DC drift + 비대칭 노이즈 + 휴지
        case withWalking        // v1.2 신규 — 중간에 walking artifact 삽입
        case withHeadTurning    // v1.2 신규 — gyro 강한 패턴 삽입 (T24 검증용)
    }

    public func startSyntheticMealEmission(
        mode: SyntheticMode = .realistic,
        durationSec: Double = 720,
        // ... 기존 파라미터
        dcDriftPerMin: Double = 0.02,            // realistic mode: 2%/min DC drift
        biasG: Double = 0.005,                   // realistic mode: positive bias
        noiseAsymmetry: Double = 0.3             // realistic mode: positive vs negative noise 비대칭
    ) async {
        switch mode {
        case .ideal:        await emitIdealSine(...)            // v1.1 path
        case .realistic:    await emitRealisticSignal(...)      // 신규
        case .withWalking:  await emitWithWalkingSegment(...)
        case .withHeadTurning: await emitWithHeadTurningSegment(...)
        }
    }
}
```

**시뮬레이터 토글**: Settings → Developer Mode에 "Mock 모드" picker (4개 옵션 중 선택). 베타 협력자가 본인 핸드폰에서도 4가지 시나리오로 알고리즘 동작 확인 가능.

### v1.2-9.4. CSV export 구현 (DataExporter)

```swift
final class CSVExporter {
    func exportMeal(_ mealId: UUID) async throws -> URL {
        let frames = try await mealRepository.fetchRawBuffer(forMealId: mealId)
        var csv = "timestamp_ms_relative,wall_clock_iso8601,accel_x_g,accel_y_g,accel_z_g,gyro_x_radps,gyro_y_radps,gyro_z_radps,magnitude_g,detrended_g,bandpass_g,detected_chew,reject_reason,user_confirmed_chewing\n"
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        for f in frames {
            csv += "\(f.timestampRelMs),\(formatter.string(from: f.wallClock)),\(f.accelX),\(f.accelY),\(f.accelZ),\(f.gyroX),\(f.gyroY),\(f.gyroZ),\(f.magnitude),\(f.detrended),\(f.bandpassed),\(f.detected ? 1 : 0),\(f.rejectReason ?? ""),\n"
        }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("chewcoach_meal_\(mealId.uuidString)_\(formatter.string(from: Date())).csv")
        try csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    func exportAllMeals() async throws -> URL {
        // multi-file → zip (Compression framework)
    }
}
```

### v1.2-9.5. 사후 분석 트리거 시점

**기본 (v1.2 권장)**: `MealSessionTracker.finalize(...)` 직후, *식사 종료 화면 진입 전*에 동기 분석.
- 사용자에게 "분석 중..." 화면 1-2초 (식사 종료 자연스러운 인지 시간)
- 백그라운드 Task `Task.detached(priority: .userInitiated)`로 분석
- 완료 후 MealResultCard 자동 노출

**대안 1: 백그라운드 BGTask** (옵션):
- 사용자가 즉시 결과 보지 않아도 됨 → 식사 종료 후 BGProcessingTask 등록
- Push notification으로 "오늘 식사 분석이 완료됐어요" 알림
- *옵션 G 톤 정합 검토 필요* — 사용자가 push에 실제 가치를 느끼는지 (사후 분석이라 즉시성 의미 약함)

**대안 2: 명시 사용자 트리거** (V1.2 베타용 추천):
- MealResultCard 진입 시 "정확한 분석 보기" 버튼 → 탭 시 분석 시작
- 베타 사용자에게 *알고리즘 비용 인지* 시키는 UX (실험적)

**v1.2 결정**: 기본 (자동 + 1-2초 spinner) 채택. UX 자세는 `app-experience-designer` 검토 후 finalize.

---

## v1.2-10. 알려진 한계 (v1.2)

### v1.2-10.1. 사후 분석이라 라이브 햅틱 불가
- 사용자 요구 사항 변경에 따라 *실시간 chew 카운트·햅틱 피드백 비목표*
- UX 사양과 정합 검토 필요 — `app-experience-designer`에게 인계
- *v1·v1.1의 실시간 path 코드는 그대로 보존* (사후 분석은 *추가* path) — 미래 사용자 요구 반전 시 즉시 복원 가능

### v1.2-10.2. 학습 데이터 부재 → ML 모델은 V1.5+로 미룸
- 옵션 A (IMchew RF) 정확도 0.86–0.91은 8명 × 80분 학습 데이터에 기반
- 우리는 *현재 데이터 0* — Phase 0 dogfooding (14 식사) → Phase 1 Beta (50–100 식사) 수집 후 V1.5 ML 학습 시도
- v1.2의 옵션 D (Ensemble)는 *small-data heuristic* — ML 도달 전 가교

### v1.2-10.3. IMchew의 통제 환경 vs 우리 자유생활 환경 격차
- IMchew Lab: 5종 음식 × 2분 (8 non-eating activities 분리). MAPE 9.51% / F1 0.91 — *통제된 단일 활동 단위*
- 우리 자유생활: 한국 식단 (밥·국·반찬 동시), 외식·집밥 혼재, 음료 마시기·대화·휴대폰 보기 동시. *baseline 손실 −20pp 예상* [기술-2.1, EarBit lab 0.91 → wild 0.80]
- v1.2의 F1 0.55–0.65는 이 손실을 흡수한 *현실적 목표*

### v1.2-10.4. Gyro veto 임계값 (0.6) 베타 검증 필요
- §v1.2-5.2 `GYRO_VETO_RATIO = 0.6`는 *자체 추정* — 실 데이터로 튜닝 필요
- 너무 보수 (0.4) → head turning + chewing 동시 시 false negative ↑
- 너무 느슨 (0.8) → veto 효과 사라짐
- Phase 1 Beta에서 사용자별 분포 측정 후 finalize

### v1.2-10.5. IMUFrame 영속화 디스크 부담
- 30일 보관 시 ~340MB (베타 사용자 5식사/일 가정) — *기기 부담*
- Mitigation: 옵트아웃 default + 사용자 카피로 명시
- Phase 1 Beta 후 실측 데이터로 *15일·7일 보관* 등 단축 검토

### v1.2-10.6. CSV export 익명화 책임
- User identifier UUID + UTC timestamp만 익명화 — *사용자 정성 메모*는 사용자가 직접 작성
- 사용자가 "어제 강남 X식당에서" 같은 식별 가능 정보 작성 시 — *우리가 자동 제거하지 않음*
- Mitigation: Settings 카피 명시 — "정성 메모는 사용자 본인이 익명화 책임"

### v1.2-10.7. 사후 분석 → 사용자 실시간 인식 갭
- 식사 중에 "지금 빠르게 먹고 있어요" 같은 즉시 코칭 *불가*
- 옵션 G의 "마음챙김 식사" 가치 제안과 *부분 충돌* — *식사 후 회고*가 더 나은가, *식사 중 nudge*가 더 나은가는 UX 설계 결정
- `app-experience-designer`가 v1.2 사후 분석 모드에 맞춰 코칭 메시지 라이브러리 32개 *재검토* 필요 — 식사 중 메시지 → 식사 후 메시지로 톤 조정

---

## v1.2-11. 다음 에이전트 인지 (`ios-app-implementer`)

이 산출물 다음 단계 (사용자 결정 대기):

**경로 A: 사용자가 v1.2 알고리즘 결정 검토 → GO**
→ `ios-app-implementer` 라운드: 위 §v1.2-9 구현 가이드 따라 PostHocAnalyzer + SignalDSP + IMUFrame + CSVExporter + MealRepository 확장 구현. 단위 테스트 T19~T28 작성. `xcodebuild test` 36+/36+ 통과 확인 후 인계.

**경로 B (단계적, 권장): 데이터 수집 인프라만 먼저 구현**
→ `ios-app-implementer` 라운드 1: IMUFrame + CSVExporter + Settings UI만 (PostHocAnalyzer는 stub). 베타 협력자에게 배포해 7–14일 데이터 수집.
→ 사용자가 실 IMU CSV 5+식사 분량 보내줌 → Python notebook으로 옵션 D ensemble 알고리즘 검증 → 매직 넘버 (특히 `GYRO_VETO_RATIO`, `ACF_PEAK_RATIO_THRESHOLD`, `FFT_CONFIDENCE_THRESHOLD`) 튜닝 → 결과 검토 후 `ios-app-implementer` 라운드 2: PostHocAnalyzer 본구현.

**v1.2 신호 엔지니어 권고**: **경로 B 채택**. 옵션 D는 *데이터 검증 없이 6주 풀 빌드*하는 것보다 *2주 인프라 + 데이터 수집 + 2주 알고리즘 튜닝 + 2주 통합* 단계가 v1.1 → v1.2 사이의 *알고리즘-실데이터 격차*를 결정적으로 좁힌다 (§v1.2-2.1 결정적 원인 A 해결). 사용자에게 옵션 제시 후 결정.

---

## 업데이트 이력 (v1.2 추가)

- **2026-05-03 v1.2**: 사후 분석 모드 정확도 개선 라운드. IMchew (Lin et al. 2024) 논문 정독 후 6+ 차용 가능 기법 식별 (FFT-peak counting / Butterworth + MovAvg / 3-of-N aggregation / 10s 윈도우 / SC+MFCC features / gyro 활용). v1.1 한계 7개 가설 재진단 결과 결정적 원인 3개 (합성-실 격차 A·detrending vs 1Hz B·단일 채널 C). 5개 알고리즘 옵션 비교 후 *옵션 D Ensemble (룰 + ACF + Spectral)* 채택 (외부 의존 0, 학습 데이터 0, IMchew 검증 기법 즉시 차용). 매직 넘버 14개 신규 + 단위 테스트 T19~T28 신규 10건. 데이터 수집 인프라 (CSV export + IMUFrame @Model + 옵트인 토글) 사양. KPI v1.2: F1 0.55–0.65 (학술 wild 0.71에 근접). 사용자 결정 대기 — 권장 경로 B (단계적 구현: 인프라 먼저 → 데이터 수집 → 알고리즘 튜닝 → 통합).

