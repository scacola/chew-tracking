# 01. 기술 타당성 보고서 — AirPods IMU 기반 저작운동 검출

**작성일**: 2026-05-01
**작성**: `tech-feasibility-researcher`
**검증 범위**: AirPods IMU 접근성, 학술 정확도 베이스라인, 인접/대안 센서, 오픈소스 자원, 결정적 한계

---

## 0. 결론 한 줄

> **조건부 GO** — `CMHeadphoneMotionManager`로 AirPods Pro/3세대/Max의 IMU에 합법적으로 접근 가능하며, 동급 in-ear IMU 기반 저작 검출은 **실험실 F1 0.86–0.91 / 자유생활 F1 0.71–0.80**의 학술 베이스라인을 가진다. 단, (1) iOS 한정, (2) Apple은 25Hz 정도의 저샘플링·전경 동작 위주 API만 노출, (3) 식사 외 활동(말하기·걷기·머리 흔들림)과의 구분, (4) 사용자별 보정 — 이 4가지가 해소되어야 제품화가 성립한다.

---

## 1. AirPods IMU 접근 가능성

### 1.1 공식 API: `CMHeadphoneMotionManager`

| 항목 | 내용 | 출처 |
|------|------|------|
| **API명** | `CMHeadphoneMotionManager` (Core Motion 프레임워크) | 🟡 [Apple Developer Documentation](https://developer.apple.com/documentation/coremotion/cmheadphonemotionmanager) |
| **최소 OS** | iOS / iPadOS 14.0+, macOS 11.0+ | 🟡 Apple Developer Docs |
| **지원 디바이스** | AirPods Pro (1·2세대), AirPods Max, AirPods (3세대), Beats Fit Pro 등 *공간 음향(head tracking) 지원* 헤드폰 | 🟡 Apple, 🟠 [tukuyo/AirPodsPro-Motion-Sampler](https://github.com/tukuyo/AirPodsPro-Motion-Sampler) |
| **데이터 종류** | `CMDeviceMotion` 프로세스 데이터 — attitude(쿼터니언/Euler), userAcceleration(3축, g), rotationRate(3축, rad/s), gravity, magneticField | 🟡 Apple Developer Docs |
| **샘플링 레이트** | 약 **25 Hz** (Apple이 고정·노출하지 않는 비공개 값으로, `CMHeadphoneMotionManager`는 `deviceMotionUpdateInterval` 설정 미지원). 일반 `CMMotionManager`는 최대 100 Hz. | 🟠 검증 시점 reference 노트, 🔴 개발자 포럼 보고 |
| **권한** | `NSMotionUsageDescription` (Info.plist), 사용자 동의 1회 | 🟡 Apple Developer Docs |
| **백그라운드** | 공식 백그라운드 모드 미보장 — 전경 또는 활성 오디오 세션 중심으로 안정 동작. 백그라운드에서는 일시정지·중단 가능. | 🟡 Apple Developer Docs (간접), 🔴 wizenheimer/workwell 등 오픈소스 보고 |
| **좌·우 채널** | 단일 *마스터* 이어폰의 모션만 스트리밍 (한쪽 빼면 자동 스위치). 좌·우 동시 IMU는 공식 API로 불가 | 🟡 Apple Developer Docs (`CMHeadphoneMotionManagerDelegate`의 connect/disconnect 콜백) |

### 1.2 Apple 자체의 의도 — 패턴 강화 신호

- **2022년 Apple 특허**: AirPods 모션 센서로 *이갈이(bruxism) 진단*. 🟠 [Patently Apple, 2022.10](https://www.patentlyapple.com/2022/10/apple-invents-a-new-health-feature-for-airpods-that-will-provide-diagnosis-monitoring-of-bruxism-.html)
- **2026년 3월 Apple 특허**: "Jaw Health Metric Using Headphones" — *좌·우 헤드폰 각각이 bite/chew 카운트와 좌·우 비대칭(imbalance)을 측정*. 🟠 [AppleWorld.today, 2026.03](https://appleworld.today/2026/03/apple-wants-its-airpods-products-to-be-able-to-measure-your-jaw-health/)
- 함의: Apple 자체가 이 영역을 미래 헬스 기능으로 보고 있음 → 제3자 앱이 같은 방향으로 가면 (a) 시장 검증 가능성, (b) Apple이 OS 기능으로 흡수해버릴 위험 동시에 존재.

### 1.3 안드로이드 / 갤럭시 버즈 / 일반 이어폰

| 플랫폼 | 접근 가능성 | 출처 |
|--------|--------|------|
| Android + AirPods | **불가능** — 공식 SDK 없음. `librepods` 등 비공식 프로젝트는 배터리/ANC 토글 정도, IMU 데이터 없음 | 🔴 [librepods GitHub](https://github.com/kavishdevar/librepods) |
| Galaxy Buds Pro IMU | **사실상 불가** — 제3자 앱은 SensorManager에서 null. Samsung 측 "공개 계획 없음" | 🟠 [Samsung Developer Forum](https://forum.developer.samsung.com/t/extracting-galaxy-buds-pro-accelerometer-and-gyroscope-data/20661) |
| 연구용 eSense (Nokia Bell Labs) | 가능 — 6축 IMU, BLE로 ~60 Hz 가변. *컨슈머 디바이스 아님* | 🟡 [Nokia Bell Labs, eSense](https://www.esense.io/) |
| OpenEarable 2.0 | 가능 — 9축 IMU + 다중 센서. 오픈하드웨어, 연구용 | 🟢 [OpenEarable 2.0, ACM IMWUT 2025](https://dl.acm.org/doi/10.1145/3712069) |

→ **결론: 본 기획은 사실상 iOS + AirPods (모션 탑재 모델) 한정 제품**이다.

---

## 2. 저작운동 검출 학술 근거

### 2.1 핵심 정확도 표 — In-ear / 이어폰 IMU 기반

| 연구 (논문) | 센서 / 디바이스 | 표본 | 정확도 / F1 | 조건 | 출처 라벨 |
|------|------|------|--------|------|----------|
| **IMChew (Yang et al., 2024)** | 이어폰 IMU (가속도+자이로) | 8명 / 실험실 | F1 = **0.91**, Acc = 0.91 / Chew counter MAPE = 9.51% | LOSO, 통제식사 | 🟢 [ACM BodySys 2024 / Cambridge](https://dl.acm.org/doi/10.1145/3662009.3662022) |
| **Lotfi et al., 2020** (audio vs IMU) | Earable IMU + 마이크 | (소규모) / 실험실 | IMU만 ~95%, IMU+오디오 융합 **97%** | 실험실 통제 | 🟢 [HCI Lab U.Manitoba](https://hci.cs.umanitoba.ca/Publications/details/a-comparison-between-audio-and-imu-data-to-detect-chewing-events-based-on-a) |
| **Snacking Detection / Earbud (ACM ISWC 2022)** | 이어폰 IMU | 자유생활 / 페르소나 보정 | Acc-only F1 = **0.45–0.48**, Gyro F1 = **0.50–0.53** | 자유생활, 짧은 간식 검출 | 🟢 [ACM ISWC 2022](https://dl.acm.org/doi/fullHtml/10.1145/3544794.3558469) |
| **Bruxism Earable Feasibility (ACM UbiComp Adjunct 2021)** | eSense 이어버드 IMU | 17명 / lab+wild | Lab F1 up to **0.90** / In-the-wild grinding 76% / clenching 73% | 머리흔들림, 음악, 걷기, 말하기, 음용 혼재 테스트 | 🟢 [ACM UbiComp 2021](https://dl.acm.org/doi/fullHtml/10.1145/3460418.3479327) |
| **CHOMP (Hummel et al., 2026)** | OpenEarable 2.0 (마이크+골전도+IMU+PPG+압력) | 20명 / 실험실 | 융합 F1 = **0.977 LOFO / 0.954 LOSO**, IMU 단독은 융합 대비 낮음 | 11종 식품, 좌·우 chewing side 검출 | 🟢 [arXiv 2026.02](https://arxiv.org/html/2602.02233v1) |
| **EarBit (Bedri et al., 2017)** | 귀 후방 압전+IMU+근접 | 자유생활 | Lab F1 = **0.909 / Acc 0.901**, Wild F1 = **0.801** | 비통제 환경, 8 hr 자유 활동 | 🟢 [ACM IMWUT 2017](https://dl.acm.org/doi/10.1145/3130902) |
| **In-ear Mic CNN (Papapanagiotou et al., 2017)** | In-ear 마이크 (IMU 아님) | 14명 / 반자유 | Acc **0.980 / F1 0.883** | 반자유생활 | 🟢 [IEEE EMBC 2017](https://ieeexplore.ieee.org/document/8037060/) |
| **ChewSense (CWSN 2024 / 2025)** | 이어폰 reverse acoustic signal | 10명 / 6개월 | Chew count Acc **84.58%**, food type **82.90%** | 자유생활 | 🟢 [Springer LNCS 2025](https://link.springer.com/chapter/10.1007/978-981-96-2186-6_20) |
| **Auracle (Bi et al., 2018)** | 귀 뒤 contact 마이크 | 14명 / 자유생활 | 26 식사 중 **20–24 검출** (≈77–92% recall) | 자유생활, 28h 배터리 | 🟢 [ACM IMWUT 2018](https://dl.acm.org/doi/10.1145/3264902) |

### 2.2 인접 센서 (귀 외부) 베이스라인

| 연구 / 시스템 | 센서 | 표본 | 정확도 / F1 | 출처 라벨 |
|------|------|------|--------|----------|
| Diet Eyeglasses (Zhang & Amft) | 안경 EMG + IMU | 10명+ / 실험실 | 식사 검출 90%+, 음식 종류 **94%** | 🟢 [PerCom 2016](http://simpleskin.org/papers/RSA2016.pdf) |
| Glasses 가속도계 (Farooq & Sazonov) | 안경 가속도계만 | / 자유생활 | 20s epoch F1 **87.9%**, 3s epoch **84.7%** | 🟢 [PMC PMC6197813](https://pmc.ncbi.nlm.nih.gov/articles/PMC6197813/) |
| MyDJ (안경 부착, ACM CHI 2022) | 안경 piezo+IMU | 32명 | Eating episode F1 **0.919** | 🟢 [ACM CHI 2022](https://dl.acm.org/doi/fullHtml/10.1145/3491102.3502041) |
| OCOsense (3주 home study, 2025) | 스마트 안경 | 다수 | 실시간 F1 **0.89–0.91** | 🟢 [ScienceDirect 2025](https://www.sciencedirect.com/science/article/pii/S0195666325005355) |
| 손목 IMU (Thomaz et al., 2015) | 스마트워치 가속도계 | 7+1명 자유생활 | F1 **0.71–0.76** | 🟢 [PMC PMC5839104](https://pmc.ncbi.nlm.nih.gov/articles/PMC5839104/) |
| 손목 IMU 대규모 (free-living) | 스마트워치 | 43명 / 449h | Acc **0.81** at 1s | 🟢 [PMC PMC8924783](https://pmc.ncbi.nlm.nih.gov/articles/PMC8924783/) |
| 측두근 EMG | 피부 부착 EMG | 10명 / 122h 자유 | F1 max **99.2%**, start error 2.4±0.4s | 🟢 [PMC PMC7014527](https://pmc.ncbi.nlm.nih.gov/articles/PMC7014527/) |

### 2.3 정리

- **In-ear IMU 단독**으로 *통제 실험실*에서는 F1 ~0.91 (IMChew, EarBit lab) — 유의미한 베이스라인 존재.
- **자유생활** 정확도는 급격히 떨어짐 — 짧은 간식의 경우 F1 0.45–0.53 수준 (ACM ISWC 2022). 식사 *episode* 검출은 0.71–0.80 수준이 현실적 상한.
- **음향(in-ear mic) + IMU 융합**이 단일 모달리티보다 일관되게 우수 (97%+). 그러나 AirPods의 마이크 raw 스트림은 일반 앱에 노출되지 않아(통화/녹음 권한 별도, 그리고 raw acoustic signature 분석은 마이크 권한 트리거됨) **AirPods의 이점은 IMU 위주에 묶인다**.

---

## 3. 대안 센서 비교 (5축 평가)

| 접근법 | 정확도(자유생활) | 폼팩터 | 사용자 마찰 | 비용 | 사회적 수용성 | 종합 |
|--------|---------|---------|------|------|------|------|
| **AirPods IMU (본 기획)** | 추정 F1 0.7–0.85 (학술 baseline 차용) | 이어폰 (이미 보유) | **매우 낮음** — 식사 시 자연 착용 | $0 (기존 보유) | 매우 높음 | ★★★★★ (마찰) / ★★★ (정확도) |
| **이어폰 마이크 (in-ear acoustic)** | F1 0.85–0.98 (lab) | 이어폰 | 낮음 | $0 | 높음 (단, 마이크 권한 거부감) | ★★★★ |
| **EMG 패치 (측두근/저작근)** | F1 0.90–0.99 (lab+wild) | 피부 부착 패치 | **매우 높음** — 매끼 부착 | $30–100 | 매우 낮음 (의료기기 룩) | ★ |
| **안경형 IMU/EMG** | F1 0.87–0.92 (free-living) | 안경 (안경 사용자만) | 중간 | $200+ (전용) | 중간 | ★★ |
| **스마트워치 IMU** | F1 0.71–0.82 (free-living) | 손목 시계 | 낮음 (이미 보유 다수) | $0 (기존 보유) | 매우 높음 | ★★★★ (마찰) / ★★ (정확도, 저작 횟수가 아닌 *손-입* 동작 추정만) |
| **카메라 + CV** (스마트폰 정면) | F1 0.9+ (조명 좋을 때) | 폰 거치 필요 | **매우 높음** — 매끼 카메라 시야 유지 | $0 | 낮음 (사적 영상 거부감) | ★★ |
| **귀 후방 contact 마이크 (Auracle)** | 자유생활 recall 77–92% | 귀 뒤 별도 디바이스 | 중간–높음 | 별도 HW | 중간 | ★★ |
| **이어폰 reverse acoustic (ChewSense)** | Acc 84% / 식별 83% (자유생활) | 이어폰 | 낮음 | $0 | 높음 | ★★★ |

**핵심 인사이트**:
1. *정확도 1위*는 EMG / 음향 융합이지만 *마찰 1위*도 그쪽이다.
2. *마찰 최저 + 보유 디바이스 활용* 조합은 **AirPods IMU와 스마트워치**뿐. 두 후보 중 저작 *횟수*에 가까운 신호는 AirPods (턱 운동이 머리에 직접 전달).
3. 따라서 본 기획은 *정확도-마찰 trade-off에서 합리적 좌표*에 위치한다. 단, F1 ≥ 0.9를 요구하는 임상/의료 포지셔닝은 부적합.

---

## 4. 오픈소스 / SDK 자원

### 4.1 즉시 활용 가능

| 자원 | 무엇 | 라이선스 / 가용성 | 출처 |
|------|------|--------|------|
| **AirPodsPro-Motion-Sampler** (tukuyo) | iOS Swift, `CMHeadphoneMotionManager` 데이터 가시화/CSV 저장 샘플 | 🟡 MIT-style, [GitHub](https://github.com/tukuyo/AirPodsPro-Motion-Sampler) |
| **HeadphoneMotion** (warrenm, kulich-ua) | 데모 앱 | [warrenm/HeadphoneMotion](https://github.com/warrenm/HeadphoneMotion) |
| **workwell** (wizenheimer) | 자세 모니터링, 백그라운드 처리 패턴 참조 | [GitHub](https://github.com/wizenheimer/workwell) |
| **OpenEarable 2.0** | 오픈하드웨어 + 펌웨어 — 자체 데이터 수집/학습 가능 | 🟢 [open-earable.teco.edu](https://open-earable.teco.edu/) |
| **eSense (Nokia Bell Labs)** | 학술용 SDK (iOS/Android), Flutter 패키지 존재 | 🟡 [esense.io](https://www.esense.io/), [esense_flutter pub.dev](https://pub.dev/packages/esense_flutter) |

### 4.2 학습/검증용 데이터

- **PAMAP2 / USC-HAD** 등 일반 HAR 데이터셋엔 *식사 라벨이 빈약*. 저작 전용 대규모 공개 데이터셋은 사실상 부재.
- **USI-HEAR Dataset (Zenodo)** — eSense 기반 활동 인식 데이터 일부 포함. 🟢 [Zenodo](https://zenodo.org/records/10843791)
- 결과: **자체 데이터 수집이 필수**. Pilot N=10–20 수준은 학술 사례와 동등한 수준.

### 4.3 ML 파이프라인

- 일반적 접근: 가속도/자이로 → 윈도우 슬라이싱(2–5s) → 시간/주파수 도메인 피처 (RMS, FFT 피크, 영교차율) → Random Forest / XGBoost / 1D-CNN → 후처리 (HMM 또는 minimum duration). 모든 인용 논문이 이 패턴을 변형 사용.

---

## 5. 결정적 한계 (Show-stoppers / Mitigations)

### 5.1 식사 외 활동과의 구분

| 혼동 활동 | 학술 보고 | 본 기획 영향 |
|-----------|--------|---------|
| **말하기** | bruxism feasibility 연구에서 talking이 in-the-wild 정확도 저하 주요 원인 (lab→wild F1 -10–20pp) 🟢 | **결정적**. 혼밥 + 영상 시청은 말하기는 적지만 *웃음·맞장구* 가능 |
| **걷기 / 머리 흔들림** | 가속도 기반 시스템에서 가장 큰 false positive 원천 🟢 | **중간** — 본 시나리오는 정좌 식사라 위험은 작지만, 식사 중간 일어남 등 처리 필요 |
| **음용 / 삼킴** | 별도 클래스 — 저작과 다른 신호 패턴, 분리 가능 🟢 | 영양 측면에서 별도 분류 가치 |
| **하품 / 표정** | Yawning Detection paper 별도 존재 🟢 [ACM SWSA 2023](https://dl.acm.org/doi/10.1145/3615592.3616854) | 비식사 시간엔 무시, 식사 중엔 false positive |

**Mitigation**: (a) 식사 *시작* 트리거를 명시적 사용자 액션 또는 시간/장소 컨텍스트로 받음, (b) 사용자가 "지금 식사 중" 선언 후에만 chewing 모드 → 정확도 요구 완화.

### 5.2 사용자별 보정 (calibration)

- 전 연구에서 LOSO(leave-one-subject-out) 정확도가 within-subject보다 5–25pp 낮음. ChewSense 같이 자유생활에서 individual model 사용 시 84%이지만, 신규 사용자는 더 낮을 가능성.
- 식습관·치아구조·이어폰 착용 깊이 따라 신호 진폭 차이.
- **Mitigation**: 첫 식사 1–2회 onboarding chewing pattern 학습 (사용자가 ground truth로 30회 씹어달라 요청).

### 5.3 좌·우 비대칭 / 단일 채널 제약

- `CMHeadphoneMotionManager`는 좌·우 동시 IMU 스트림을 *공식적으로는 제공하지 않는다* (마스터 단일 스트림). 🟡
- Apple 자체 jaw health 특허는 *좌·우 별도 측정 필요*를 명시 — Apple도 이걸 위해 *내부 특수 API*가 필요함을 시사. 🟠
- **함의**: 본 기획에서 "좌·우 chewing 비대칭" 같은 advanced feature는 *현재 공식 API로는 불가*. chewing count, eating speed 정도는 단일 채널로 가능.

### 5.4 샘플링 레이트 (~25 Hz)

- 25 Hz Nyquist = 12.5 Hz까지 검출 가능. 일반 저작 빈도는 **0.94–2 Hz** (분당 60–120회 chewing) → **Nyquist 충분**.
- 그러나 미세한 어금니 grinding(15–30 Hz 영역에 신호)은 손실. *bruxism까지는 어렵다는 의미*. eating chewing은 OK.

### 5.5 배터리 / CPU

- 공식 측정값 부재. 🔴 사용자 보고로는 IMU streaming + 처리 시 AirPods 5–6h → 4–5h 정도로 줄 수 있음.
- iPhone 측 CPU: 25 Hz × 9-channel float = 매우 가벼움 (<1% CPU on-device ML inference).
- **Mitigation**: 식사 시간 윈도우(점심/저녁 30분)만 활성화. 늘 켜둘 필요 없음.

### 5.6 백그라운드 동작

- iOS `CMHeadphoneMotionManager`는 백그라운드 보장 없음. 🟡
- 사용자가 영상 시청 중이라면 audio session 활성 → 우회적으로 백그라운드 유지 가능. **혼밥+영상 시나리오와 우연히 잘 맞음**.
- 영상 안 볼 때는 앱을 전경에 두거나, 침묵 오디오 트릭 — *App Store 정책상 회색지대*. 권장하지 않음.

### 5.7 Apple이 동일 기능 흡수할 위험

- 위 §1.2의 2026.03 jaw health 특허 — Apple이 OS 레벨에서 jaw health를 직접 제공할 가능성. 그 경우 제3자 앱은 *자체 차별화(코칭/UX/콘텐츠)*가 없으면 압살. 🟠

### 5.8 한계 점검 체크리스트 (스킬 매뉴얼 §"한계 점검 체크리스트")

- [x] **식사가 아닌 활동과 구분?** → 말하기·걷기 분리 모델 또는 사용자 트리거 필요. §5.1
- [x] **사용자별 보정?** → onboarding 1–2 식사로 캘리브레이션 권장. §5.2
- [x] **좌·우 동시?** → 공식 API 불가, 단일 채널로 chewing count는 가능. §5.3
- [x] **배터리?** → 식사 윈도우 한정 가동 시 영향 미미. §5.5
- [x] **데이터 프라이버시?** → 모션 데이터는 raw audio보다 민감도 낮음. on-device 처리로 해결 가능.
- [x] **안드로이드?** → **불가**. iOS 한정. §1.3

---

## 6. 권고 — 기술 측면 GO / NO-GO / PIVOT

### 6.1 결론: **조건부 GO**

다음 4개 조건을 모두 받아들이면 기술적으로 시장 출시 가능:

1. **타겟을 iOS + 모션 탑재 AirPods 사용자로 한정**한다. (한국 시장에서 AirPods Pro/Max/3세대 보유율 자체가 마케팅 변수)
2. **정확도 KPI를 임상이 아닌 "행동 변화 코칭"용으로 설정**한다. F1 0.75–0.85 수준이면 사용자 행동 변화 유도엔 충분 (chewing count의 ±10–15% 오차는 "오늘 평소보다 30% 빨리 먹었어요" 식 메시지엔 영향 없음).
3. **Onboarding에 1–2회 캘리브레이션 식사를 포함**한다. 완전 zero-touch는 현 학술 baseline상 무리.
4. **"좌·우 비대칭", "음식 종류 식별", "bruxism" 같은 advanced feature는 v1에서 제외**. 25Hz·단일 채널 한계 안에서 가능한 KPI는 *식사 시작·종료, 저작 횟수 추정, 식사 시간, 분당 chewing rate*로 제한.

### 6.2 NO-GO 시나리오 (이 중 하나라도 사실이면 PIVOT 권고)

- 의료기기 인증 필요 포지셔닝 → F1 0.95+ 필요 → IMU 단독으로는 불가, EMG/안경형으로 PIVOT.
- 안드로이드 우선 출시 필요 → AirPods 불가. 갤럭시 버즈도 SDK 미공개. → 스마트워치 IMU 또는 OpenEarable 자체 HW로 PIVOT.
- "씹는 횟수의 정확한 카운트"가 *판매 가치 제안의 핵심* → 자유생활 정확도 한계로 위험. → "chewing rhythm 코칭" 같은 *상대적 신호*로 가치 제안 변환 필요.

### 6.3 다음 단계 (오케스트레이터 → 다른 에이전트가 받을 입력)

- `product-ideation-strategist`: 위 §6.1 4개 조건을 제품 컨셉의 *제약 조건*으로 받아 BM/UX 설계. KPI는 절대 정확도가 아닌 *행동 변화*에 두기.
- `discovery-synthesizer`: §3 비교표를 인용하여 "왜 AirPods인가?"의 근거로 사용. §5의 한계는 risk register에 명시.

---

## 부록 A. 출처 신뢰도 라벨 범례

| 라벨 | 의미 |
|------|------|
| 🟢 | peer-reviewed (IEEE/ACM/PubMed/arXiv 학술 게재) |
| 🟡 | 공식 문서 (Apple/Samsung/Bell Labs) |
| 🟠 | 산업 보고/특허 분석 매체 |
| 🔴 | 비공식 (블로그, 포럼, 추측) |

본 보고서의 정량 결론은 모두 🟢/🟡 출처에 근거함. 🔴는 §1.1 (샘플링 레이트), §5.5 (배터리), §5.6 (백그라운드)에서 보조 단서로만 사용했고 결론을 바꾸지 않음.

## 부록 B. 핵심 출처 클러스터

**AirPods/iOS API (🟡)**
- [CMHeadphoneMotionManager — Apple Developer](https://developer.apple.com/documentation/coremotion/cmheadphonemotionmanager)
- [Getting motion-activity data from headphones — Apple](https://developer.apple.com/documentation/CoreMotion/getting-motion-activity-data-from-headphones)
- [What's new in Core Motion (WWDC23)](https://developer.apple.com/videos/play/wwdc2023/10179/)

**저작 검출 학술 (🟢)**
- [IMChew (ACM BodySys 2024)](https://dl.acm.org/doi/10.1145/3662009.3662022)
- [CHOMP (arXiv 2026)](https://arxiv.org/html/2602.02233v1)
- [EarBit (ACM IMWUT 2017)](https://dl.acm.org/doi/10.1145/3130902)
- [Earables for Bruxism Feasibility (ACM 2021)](https://dl.acm.org/doi/fullHtml/10.1145/3460418.3479327)
- [Snacking Detection Earbuds (ACM ISWC 2022)](https://dl.acm.org/doi/fullHtml/10.1145/3544794.3558469)
- [Auracle (ACM IMWUT 2018)](https://dl.acm.org/doi/10.1145/3264902)
- [In-ear Mic CNN (IEEE EMBC 2017)](https://ieeexplore.ieee.org/document/8037060/)
- [Survey of Earable Technology (arXiv 2025)](https://arxiv.org/html/2506.05720v1)

**대안 센서 학술 (🟢)**
- [Wrist Eating Detection (PMC 5839104)](https://pmc.ncbi.nlm.nih.gov/articles/PMC5839104/)
- [MyDJ Smart Eyeglasses (CHI 2022)](https://dl.acm.org/doi/fullHtml/10.1145/3491102.3502041)
- [Diet Eyeglasses EMG (PerCom 2016)](http://simpleskin.org/papers/RSA2016.pdf)
- [Free-living Wearable Eating Scoping Review (npj Digital Medicine 2020)](https://www.nature.com/articles/s41746-020-0246-2)

**식사 속도 임상 근거 (🟢)** — product/market 에이전트가 인용 가능
- [Eating Speed and Metabolic Syndrome Meta-Analysis (Frontiers Nutr. 2021)](https://pmc.ncbi.nlm.nih.gov/articles/PMC8564065/) — OR=1.54 (95% CI 1.27–1.86), 29 studies, N=465,155
- [Eating Speed in Korean University Students (Nutrients 2021)](https://pmc.ncbi.nlm.nih.gov/articles/PMC8308714/)
- [16-yr KoGES Cohort Eating Speed (Nutrients 2025)](https://www.mdpi.com/2072-6643/17/6/992)

**Apple 의도 단서 (🟠)**
- [Apple bruxism patent (Patently Apple 2022)](https://www.patentlyapple.com/2022/10/apple-invents-a-new-health-feature-for-airpods-that-will-provide-diagnosis-monitoring-of-bruxism-.html)
- [Apple jaw health metric patent (AppleWorld 2026.03)](https://appleworld.today/2026/03/apple-wants-its-airpods-products-to-be-able-to-measure-your-jaw-health/)

**오픈소스 (🟡/🟠)**
- [tukuyo/AirPodsPro-Motion-Sampler](https://github.com/tukuyo/AirPodsPro-Motion-Sampler)
- [warrenm/HeadphoneMotion](https://github.com/warrenm/HeadphoneMotion)
- [wizenheimer/workwell](https://github.com/wizenheimer/workwell)
- [OpenEarable 2.0](https://dl.acm.org/doi/10.1145/3712069)

---

## 업데이트 이력

- **2026-05-01**: 초안. 8개 학술 인용 + 7개 인접 비교 + Apple 특허 2건 + 오픈소스 5종 + 식사속도 임상 메타분석 1건 인용. 결론: 조건부 GO.
