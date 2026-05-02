# AirPods IMU 활용 컨텍스트

이 문서는 AirPods IMU 데이터에 *제3자 앱이 어떻게 접근할 수 있는지*에 대한 빠른 사실 확인용 참조다. 정확한 최신 정보는 항상 Apple Developer Docs를 직접 확인할 것.

## 핵심 사실 (검증 시점 기준)

### 접근 API
- **iOS**: `CMHeadphoneMotionManager` (iOS 14+) — AirPods Pro/Max/3세대+ 등 모션 센서 탑재 모델에서 가속도/회전율/방향 데이터 제공
- 샘플링 레이트: 약 25Hz (Apple 기본값, 변경 불가능에 가까움)
- iOS 권한 모델: 모션 데이터 사용 시 사용자 권한 동의 필요

### 미지원 영역
- 안드로이드: 공식 SDK 없음. AirPods를 안드로이드에서 IMU로 쓰는 건 사실상 불가능 → **타겟이 iOS 한정**으로 좁아짐
- 1세대 AirPods, 일반 AirPods (모션 센서 미탑재 모델)

### 데이터 종류
- 가속도 (3축, m/s² 또는 g)
- 회전율 (3축, rad/s)
- 방향 쿼터니언 / Euler 각

### 한계
- 25Hz는 머리 끄덕임 같은 큰 동작은 잘 잡지만, 미세한 저작운동(특히 어금니로 씹기)은 신호가 약할 수 있음
- 좌·우 AirPods 동시에 데이터를 보내지 않을 수 있음 (마이크 + 모션이 한쪽으로 집중)
- 배경에서 지속 수집 시 배터리 영향 — 정확한 수치는 측정 필요

## 학술 연구 단서

저작운동 검출에 IMU를 쓴 연구는 *주로 안경 또는 머리 부착형 센서*에서 진행되었다. AirPods 형태의 *귀 안* 센서로 저작 검출을 한 peer-reviewed 연구는 (조사 시점에) 매우 적다. 이는:
- 기회 — 미개척 영역
- 리스크 — 정확도 baseline 부재

이 두 해석 모두 보고서에 명시.

## 인접 학술 키워드

학술 검색 시 다음 키워드 조합도 시도:
- "in-ear sensor" + "eating"
- "earbud accelerometer" + "activity recognition"
- "head-mounted IMU" + "mastication"
- "hearable" + "health monitoring"

## 알려진 시장 사례

- **NTT Sound Zero / FRIEND** — 이어폰형 헬스 모니터링 시도들
- **Bose / Sony 헬스 이어버드** — 일부 시제품 단계
- **Apollo Neuro, Whoop 등** — 다른 폼팩터지만 비교 대상

이 사례들이 *왜 주류가 안 됐는지*를 함께 조사하면 시장 시사점이 된다.

## 검색 시 주의

"AirPods chewing" 같은 직접 키워드는 결과가 적다. 대신:
- "earbud" / "in-ear" / "hearable" 으로 우회
- "mastication" / "eating activity" / "intake monitoring" 으로 도메인 변환
- 한국어로는 "이어폰 모션" / "히어러블"
