# 04 — Chew & Calm Coach 랜딩 페이지 통합 브리프 (구현자 입력)

**제품**: Chew & Calm Coach (옵션 G)
**작성일**: 2026-05-01
**작성자**: landing-architect (storyteller·designer 종합)
**다음 작업자**: `frontend-implementer`
**입력 출처**: `_brief.md`, `01_strategy_copy.md`, `02_visual_ux.md`, `03_architecture.md` 종합

> **이 한 파일만 보고 빌드한다.** 카피·디자인 토큰·컴포넌트 명세·인터랙션 사양·빌드 단계·검증 체크리스트가 모두 들어 있다. 다른 파일을 안 봐도 된다.
>
> 결정 위임이나 회신 메모는 03_architecture.md §0에서 모두 처리됨 — 이 파일은 *결정된 사양만* 담는다.

---

## 0. 페이지 한 페이지 요약 (5초 이해)

- **무엇**: 위염·식후 더부룩함·소화불량 30·40대 한국 직장인을 위한 *AirPods 자동 식사 측정 + 임상 28일 코스 + 한국 KOL 자문* 디지털 코치.
- **누가**: 한지원형(위염 직장인) 1차 / 박소연형(다이어트 정체기) / 김상훈형(검진 결과 동기) 3 페르소나.
- **다음 행동**: 베타 합류 (이메일 1줄 폼) + 28일 코스 단품 구매(보조).
- **1차 KPI**: 베타 가입 30%+ 전환, 가격 도달 15%+, FAQ 도달 20%+.
- **빌드 목표**: Apple/Linear/Stripe/Calm급 퀄리티, 모바일 80% 우선, Lighthouse 90/95/100, 모바일 60fps 시그니처.

---

## 1. 카피 (섹션별, 그대로 복사)

### 1.0 절대 쓰지 말 단어 (Banned List)

> 혁신적인, 차세대, AI 기반, 스마트한, 최첨단, 씹기 트래커/카운터(기능 설명 외), 100%, 완벽한, 절대, 다이어트 보장, 치료, AI, 머신러닝, 딥러닝, 다이어트(단독), 치유/치유력, 보장/확실한/반드시, "지금 바로!"·"오늘부터!"·"딱 한 번의 기회", 스트레스 0/걱정 없는, 당신의 인생을 바꿀, "전문가가 인정한"(출처 없이), 1만 명이 선택한/★4.8/리뷰 1,000건, 과도한 영어("Solution"·"Mission"·"Onboarding" 등은 한글로).

**선호 어휘**: 위 건강, 소화, 식사 속도, 회복, 되찾다, 차분히, 여유, 8주, 28일, 11분, 임상, 내과 전문의, 신경과학, 함께, 천천히, 괜찮아요, 수고했어요.

**존댓말**: 일관 `~예요/~이에요`. `~합니다`는 인용·임상 근거에서만.

### 1.1 Hero 섹션

**H1 (보존 필수 — `<br>` 줄바꿈 강제, 모바일도 두 줄)**

```
당신의 점심은 평균 11분.
8주만, 위 건강을 차분히 되찾아요.
```

> 액센트: "11분"·"8주"만 `text-clinical-deep`. 외 본문 색은 `text-primary`.

**보조 1줄 (R2 결정 반영 — 데스크탑 2줄 / 모바일 3줄 분기)**

데스크탑 (`lg:` 이상):
```
이미 끼고 있는 AirPods가 식사 속도를 자동으로 보여주고,
임상 28일 코스가 매일 2-3분, 함께 걸어요.
```

모바일 (`<lg:`):
```
이미 끼고 있는 AirPods가
식사 속도를 보여주고,
임상 28일 코스가 매일 2-3분 함께 걸어요.
```

> 구현: `<br className="hidden lg:inline" />` + `<br className="lg:hidden" />` 패턴.

**CTA (Hero에 폼 *없음*, 버튼만)**

- Primary: `[ 베타에 합류하기 ]` → 클릭 시 Final CTA 섹션으로 smooth scroll
- Secondary: `어떻게 작동하는지 보기` (텍스트 링크 + 화살표) → AirPods Demo로 smooth scroll

**진실 시그널 미니 라인 (CTA 아래)**

```
임상 RCT 진행 중 · 내과 전문의 자문 [영입 진행 중] · 베타 모집 중
```

> 가로 도트 `·` 구분, `caption` 사이즈, `text-muted` 70% opacity.

### 1.2 페르소나별 서브 헤드라인 (URL `?p=stomach|diet|checkup`)

#### 기본 진입 / `?p=stomach` (한지원형)

```
점심마다 영상 보며 11분 만에 끝나는 식사,
당신의 위가 보내는 신호일 수 있어요.
의사가 말한 "천천히 드세요" — 이번엔 데이터로 함께해요.
```

#### `?p=diet` (박소연형)

```
운동도, 칼로리도, 다 지켰는데 안 빠진다면 —
먹는 *속도*를 의심해보세요.
8주 만에, 정체기를 풀어줄 새로운 변수.
```

#### `?p=checkup` (김상훈형)

```
건강검진 결과지 위에 적혀 있던 그 한 줄 —
"식사 속도 개선 권장."
8주 코스로, 다음 검진까지 차분히 준비해요.
```

### 1.3 Problem 섹션

**섹션 헤더**
```
당신은 자신의 식사 속도를, 정확히는 모르고 있어요.
```

**리드 카피**
> 위염 진단을 받고 의사가 *천천히 드세요* 라고 했을 때,
> 그게 정확히 몇 분인지 알려주는 사람은 없었을 거예요.
>
> 한국 직장인의 평균 점심 시간은 11분.
> 권장 식사 시간(20분 이상)의 절반이에요.
> 그런데 정작 본인은 — *나는 적당히 먹고 있다* 고 느껴요.
> 이게 위염·정체기 다이어트·식후 더부룩함의 가장 흔한 시작점이에요.

**의학 근거 카드 2장 (인용 — 출처 보존 필수)**

카드 1:
```
빠른 식사군은 미란성 위염 위험이 71% 더 높아요.
— Hurst & Fukuda, 위장관 연구 메타분석 (2018)
```

카드 2:
```
빠른 식사 습관은 비만 위험을 2.15배 높여요.
— Ohkuma et al., 식이 속도와 BMI 코호트 연구 (2015)
```

**페르소나 트리거 3줄 (Noto Serif KR Italic + 인용부호)**

```
"오늘 점심도 영상 보면서 끝났어요. 시간이 얼마나 걸렸는지 모르겠어요."
"운동도 했고 칼로리도 줄였는데, 왜 안 빠지는지 모르겠어요."
"내시경 받을 때마다 듣는 그 말. 어떻게 지키는지 모르겠어요."
```

각 카드 하단 라벨:
- 카드 1: `한지원 (위염, 32세)`
- 카드 2: `박소연 (정체기, 34세)`
- 카드 3: `김상훈 (검진 후, 41세)`

**섹션 닫는 1줄 (`heading-3` 가운데 정렬)**

```
모르는 게 문제가 아니라, 볼 수 있는 도구가 없었던 것뿐이에요.
```

### 1.4 Solution 섹션 (3단계)

**섹션 헤더**
```
보지 못했던 것을, 함께 보고, 함께 바꿔요.
```

**카드 1 — 검출**
- 라벨 (uppercase, `text-clinical-deep`): `AIRPODS가 봐줘요`
- 헤더: `1. 검출`
- 본문:
> 이미 끼고 있는 AirPods의 모션 센서가, 식사 동작을 자동으로 잡아내요.
> 앱을 켜거나 버튼을 누를 필요가 없어요.
> *측정 정확도는 베타에서 매주 개선 중이에요.*

**카드 2 — 깨달음**
- 라벨: `데이터가 말해줘요`
- 헤더: `2. 깨달음`
- 본문:
> 매일 점심 후, 식사 속도와 위 건강 점수가 카드 한 장으로 도착해요.
> "오늘 8분에 드셨어요. 어제보다 1분 더 천천히 — 잘하셨어요."
> 처음 보는 자기 자신, 처음으로 객관화돼요.

**카드 3 — 코칭**
- 라벨: `함께 걸어요`
- 헤더: `3. 코칭`
- 본문:
> 임상 신경과학 기반 28일 코스가 매일 2-3분 영상으로 안내해요.
> 한국 내과 전문의 KOL이 자문한 콘텐츠와,
> 다노식 친근한 한국 코치 카드가 매일 도착해요.

### 1.5 AirPods Demo 섹션 (시그니처)

**카피 (작게)**
```
이미 끼고 있는 그것이, 식사를 보고 있어요.
AirPods 모션 센서 → 식사 동작 검출 → 위 건강 점수.
베타에서 매주 정확도가 개선되고 있어요.
```

**데이터 스트림 패널 텍스트 (모노스페이스)**
```
> 12:32:08  식사 시작 검출
> 12:32:18  씹기 패턴: 1.2초/회
> 12:33:42  속도: 빠름 → 평균
> 12:39:47  식사 종료 (총 7분 39초)
─────────────────────────────
  위 건강 점수 → 72  ↑ +3
```

### 1.6 How it works 섹션

**섹션 헤더**
```
28일 코스 + AirPods 자동 측정 + 한국 임상 코치 트리오
```

**컬럼 A — 28일 위 건강 회복 코스**
> 매일 2-3분 영상 강의 + 가이드 식사 명상.
> 1주차 — *왜 천천히 먹어야 하는가*. 임상 신경과학 기초.
> 2주차 — *식사 명상 30초 입문*. 호흡과 첫 한 입.
> 3주차 — *위 컨디션 관찰 일지*. 자기 데이터 읽는 법.
> 4주차 — *습관 정착 + 8주 후 계획*. 졸업이 아니라 시작.

**컬럼 B — AirPods 자동 트래킹**
> AirPods Pro / AirPods 3세대 / AirPods 4세대 호환.
> 모션 센서로 식사를 자동 감지하고, iPhone에서 위 건강 점수로 변환해요.
> 안드로이드는 2026년 하반기 별도 디바이스 검토 중이에요.

호환 칩(작은 알약): `Pro` / `3` / `4`

**컬럼 C — 한국 임상 코치 + KOL 자문**
> 한국 소화기내과 전문의 + 신경과학자 KOL 1-2명 영입 진행 중.
> 영입 합의된 KOL은 이름·자격·자문 범위를 *공개*해요. 가짜 권위는 만들지 않아요.
> 친근한 한국 페르소나 코치(다노식)가 매일 카드를 보내요.

**닫는 1줄**
```
AirPods만 있으면, 다른 디바이스는 필요 없어요.
```

### 1.7 Differentiation 섹션

**섹션 헤더**
```
Apple watchOS가 흡수해도, 우리만 가진 것 5가지.
```

**큰 카드 (a) — 한국 임상 KOL 자산**
> 한국 소화기내과·신경과학자 1-2명이 코스 콘텐츠를 직접 자문해요.
> Apple은 *기능*을 만들지만, 한국 위염 환자의 *맥락*은 못 만들어요.

**큰 카드 (c) — 28일 한국어 코스 IP**
> "한국 직장인의 회식·야근·점심 11분"이라는 *맥락 위에서* 쓴 코스.
> 일반 jaw-health 메트릭으로는, 한국 위염을 못 다뤄요.

**큰 카드 (d) — 친근한 한국 페르소나 코치**
> Eat Right Now의 Dr. Jud + 다노식 친근함을 결합한 한국형 코치 톤.
> "오늘 8분에 드셨어요" — 데이터를 *마음으로* 번역하는 자산.

**작은 카드 (b) — 임상 RCT 데이터**
> 1차 베타부터 학술 발표 가능 형식으로 익명화 누적 중. 8주차 진행 중.

**작은 카드 (e) — "위 건강 회복" 결과 라벨**
> 측정 메트릭이 아닌 *결과*를 약속하는 자산. 한국 30·40대 페인 직결.

**닫는 1줄**
```
도구는 베껴도, 맥락과 권위와 톤은 베낄 수 없어요.
```

### 1.8 Authority 섹션

**섹션 헤더**
```
거짓 사회증거 대신, 현재 우리가 진짜 하고 있는 일을 보여드려요.
```

**카드 1 — 임상 RCT 진행 중**
- 상태 칩: `진행 중`
- 본문:
> 식사 속도 개선과 위 건강 점수의 상관관계를 검증하는 RCT 8주차 진행 중.
> 학술 발표 가능 형식으로 익명화 누적 중.
> *완료 시점: 2026년 4분기 예정.*

**카드 2 — 내과 전문의 KOL — 영입 진행 중**
- 상태 칩: `영입 진행 중`
- 본문:
> 한국 소화기내과 전문의 1명, 신경과학자 1명 — *영입 단계 협의 중*.
> 합의 완료 시점에 이름·자격·자문 범위를 이 페이지에 *그대로* 공개해요.
> *KOL 자리는 비워두지만, 영입 진행 상황을 매주 업데이트해요.*

**카드 3 — 베타 모집 중**
- 상태 칩: `베타 모집 중`
- 본문:
> 현재 시점, 베타 사용자 모집 중.
> 1만 명이 사용 중이라고 거짓말하지 않아요.
> *베타 합류 시: 8주 코스 무료 + 정식 출시 시 50% 평생 할인.*

**권위 인용 (Noto Serif KR Italic, 가운데)**
```
"음식은 약과 같다."
— 임상 코치 [KOL 이름 영입 진행 중]
```

### 1.9 Pricing 섹션

**섹션 헤더**
```
내과 진료 한 번보다 적은 비용으로, 8주를 함께해요.
```

**카드 1 — 월간**
- 헤더: `월간`
- 가격: `9,900원` `/월`
- 기능:
  > 28일 코스 + AirPods 자동 트래킹 + 매일 코치 카드 + 임상 콘텐츠 무제한.
  > 언제든 해지 가능.

**카드 2 — 연간 (R4 결정: "추천" + "한 달 무료" 칩, 강조 카드)**
- 헤더: `연간`
- 우상단 칩: `추천`, `한 달 무료`
- 가격: `79,000원` `/년` (취소선 보조: `9,900 × 12 = 118,800원`)
- 보조 카피: `33% 할인 — 한 달 무료에 가까워요`
- 기능:
  > 월간과 동일한 모든 혜택 + 연간 위 건강 리포트.
  > 30일 환불 보장.

**카드 3 — 28일 코스 단품**
- 헤더: `28일 코스 단품`
- 가격: `19,900원` `/1회 결제`
- 기능:
  > 28일 코스만, 자동 트래킹 없이.
  > 구독 부담 없이 코스만 체험하고 싶다면.

**가격 정당화 카피 (카드 아래, body-sm, text-muted, 보존 필수)**
> 한국 내과 진료 1회 평균 비용이 약 12,000~25,000원이에요.
> Chew & Calm의 한 달 구독은 그보다 적은 9,900원이고,
> 글로벌 비교 제품인 Eat Right Now($24.99/월, 약 35,000원)의 1/3 이하예요.
> *진료를 대체하지 않아요. 진료가 닿지 못하는 8주의 일상을 채워요.*

**환불 정책 1줄 (caption)**
> 연간 구독은 30일 안에 100% 환불 가능해요.
> 월간 구독은 다음 결제일 24시간 전까지 해지하면 추가 청구 없어요.

### 1.10 FAQ 섹션 (단일 펼침)

**섹션 헤더**
```
자주 묻는 질문 8가지.
```

**Q1**
- Q: `가격이 왜 9,900원이에요? 너무 싸 보여요.`
- A:
> 한국 내과 진료 한 번 비용보다 적게 받으면서, *8주의 일상*을 채우는 게 우리 모델이에요.
> 미국 Eat Right Now($24.99/월)의 1/3 이하 가격을 의도적으로 책정했어요.
> 베타 단계에서 학습하고, 정식 출시 시점에도 이 가격을 유지하려고 해요.

**Q2 (highlight: trust-core)**
- Q: `정확도는 얼마나 돼요? "95% 정확" 같은 광고를 본 적 있어요.`
- A:
> "정확도 95%" 같은 단정적 표기는 사용하지 않아요.
> AirPods 모션 센서 기반 식사 검출은 *환경에 따라 변동*이 있고, 베타에서 매주 개선 중이에요.
> 절대 수치보다는, *당신의 어제와 오늘의 차이*가 더 중요한 데이터예요.

**Q3**
- Q: `AirPods가 없으면 못 쓰나요? 어떤 모델이 호환돼요?`
- A:
> AirPods Pro (1세대 이상), AirPods (3세대 이상), AirPods 4세대까지 호환해요.
> AirPods 1·2세대는 모션 센서가 없어서 자동 측정이 어렵고, 28일 코스는 그대로 이용 가능해요.
> 안드로이드 사용자를 위한 별도 디바이스는 2026년 하반기 검토 중이에요.

**Q4**
- Q: `안드로이드에서는요?`
- A:
> 현재 iPhone + AirPods 조합 우선이에요.
> 안드로이드 + 일반 무선 이어폰의 모션 데이터는 OS·기종마다 편차가 커서, 코스 단품(19,900원)으로 먼저 시작하시는 걸 권해요.

**Q5**
- Q: `환불은 어떻게 돼요?`
- A:
> 연간 구독은 결제 후 30일 안에 100% 환불해요. 사유 안 물어봐요.
> 월간 구독은 다음 결제일 24시간 전까지 해지하면 추가 청구가 없어요.
> 28일 코스 단품은 콘텐츠 1주차 미시청 상태에서 7일 안에 환불 요청 가능해요.

**Q6 (highlight: trust-core, 보존 필수 — 짧게 줄이지 말 것)**
- Q: `임상 근거가 진짜 있나요?`
- A:
> 식사 속도와 위염·비만의 상관관계는 메타분석 수준의 임상 근거가 있어요 (Hurst 2018, Ohkuma 2015 등).
> 우리 *제품 자체*의 효과는 현재 RCT 8주차 진행 중이고, 결과는 학술 발표 형식으로 공개할 예정이에요.
> *지금 시점에서 우리 제품으로 위염이 낫는다고 약속할 수는 없어요. 임상 근거가 쌓이면 그대로 공개해요.*

**Q7 (highlight: trust-core)**
- Q: `데이터 프라이버시는 어떻게 보호돼요?`
- A:
> 식사 데이터는 *기기 내부에서* 1차 처리하고, 클라우드에는 익명화된 집계 형식으로만 올라가요.
> 이름·식사 사진 같은 개인 식별 데이터는 수집하지 않아요.
> 임상 RCT 데이터로 사용될 때는 *별도 동의*를 받아요.

**Q8**
- Q: `8주 후엔 어떻게 돼요?`
- A:
> 28일 코스를 두 번 (8주) 완료하면, 식사 속도와 위 건강 점수의 *개인 베이스라인*이 만들어져요.
> 이후엔 월 1회 위 건강 리포트와, 매일 코치 카드만 받는 *유지 모드*로 전환할 수 있어요.
> *졸업이 아니라, 새 시작이에요.*

### 1.11 Final CTA 섹션

**큰 헤더 (display-lg, "7월 첫 주" 자동 계산 — `lib/eightWeekDate.ts`)**

```
8주 후의 위, 8주 후의 식사 속도, 8주 후의 검진 결과.
오늘 시작하면, 그게 [DYNAMIC_8W_DATE]에 도착해요.
```

> `[DYNAMIC_8W_DATE]` 예: today=2026-05-01 → 56일 후 = 2026-06-26 → 그 주 일요일 시작 ISO 주의 첫 주를 한글 포맷("6월 마지막 주" 또는 "7월 첫 주" 중 가까운 표현). 빌드 시점에 계산.

**손편지 박스 (R3 결정 — 별도 박스 + 좌측 1px coaching 라인 + Noto Serif KR Italic, 보존 필수)**

```
베타 합류는 무료예요.
정식 출시 시점에 50% 평생 할인이 적용돼요.
1만 명이 합류했다고 거짓말하지 않아요. 지금은 우리가 함께 걸을 첫 사람들을 모으고 있어요.
```

> 박스 배경 `rgba(245,247,250,0.06)`, `radius-lg`, 패딩 24px, 좌측에 `border-left: 1px solid var(--color-coaching-soft)`. 폰트 Noto Serif KR Regular Italic.

**베타 가입 폼 (1필드)**
- 인풋: `type="email"`, placeholder `이메일 주소`, font-size 16px+
- 버튼: `베타에 합류하기` (Primary CTA)
- 보조 텍스트 (caption, opacity 0.6): `개인정보는 진행 소식 외에는 사용하지 않아요.`

**Secondary 텍스트 링크**
```
28일 코스 단품 19,900원
```

### 1.12 Footer

- 좌: 로고 `Chew & Calm` + `© 2026 Chew & Calm Coach`
- 가운데: 빠른 링크 — `How / Pricing / FAQ / Privacy / Terms`
- 우: 작은 1필드 폼 `이메일로 진행 소식 받기` (variant: caption)

---

## 2. 디자인 토큰

### 2.1 CSS 변수 (`src/styles/tokens.css`에 그대로 붙여넣기)

```css
:root {
  /* === 배경 === */
  --color-bg-cool:        #FFFFFF;
  --color-bg-warm:        #F8F4ED;
  --color-bg-deep:        #0A0E1A;
  --color-bg-mist:        #F4FBFA;

  /* === 텍스트 === */
  --color-text-primary:   #0A0E1A;
  --color-text-secondary: #2D3340;
  --color-text-muted:     #5A5F6E;
  --color-text-subtle:    #8C92A1;
  --color-text-on-deep:   #F5F7FA;

  /* === 액센트 — 임상 === */
  --color-clinical:        #00B894;
  --color-clinical-soft:   #B2EFE3;
  --color-clinical-deep:   #007A66;

  /* === 액센트 — 코칭 === */
  --color-coaching:        #FF7A59;
  --color-coaching-soft:   #FFE1D6;
  --color-coaching-deep:   #C24A2F;

  /* === CTA === */
  --color-cta:             #1F4FE0;
  --color-cta-hover:       #1A41C7;
  --color-cta-soft:        #DCE5FF;

  /* === 시맨틱 === */
  --color-success:         #16A34A;
  --color-warn:            #EA580C;
  --color-error:           #DC2626;
  --color-info:            #0284C7;

  /* === 라인 === */
  --color-line:            #E8EAEE;
  --color-line-strong:     #C9CDD4;
  --color-line-on-deep:    #2A3142;

  /* === 차트 === */
  --color-chart-fast:      #FB7185;
  --color-chart-target:    #00B894;
  --color-chart-progress:  #1F4FE0;
  --color-chart-grid:      #E8EAEE;

  /* === 폰트 === */
  --font-sans:  'Pretendard Variable', 'Inter', -apple-system, BlinkMacSystemFont, 'Apple SD Gothic Neo', 'Helvetica Neue', sans-serif;
  --font-serif: 'Noto Serif KR', 'Source Serif Pro', Georgia, serif;
  --font-mono:  'JetBrains Mono', 'SF Mono', Consolas, monospace;

  /* === 간격 (8px 기반) === */
  --space-0:   0;
  --space-1:   4px;
  --space-2:   8px;
  --space-3:   12px;
  --space-4:   16px;
  --space-5:   20px;
  --space-6:   24px;
  --space-8:   32px;
  --space-10:  40px;
  --space-12:  48px;
  --space-16:  64px;
  --space-20:  80px;
  --space-24:  96px;
  --space-32:  128px;
  --space-40:  160px;

  /* === 컨테이너 === */
  --container-max:    1200px;
  --container-narrow:  880px;
  --container-prose:   680px;

  /* === Border Radius === */
  --radius-sm:   6px;
  --radius-md:   12px;
  --radius-lg:   16px;
  --radius-xl:   24px;
  --radius-2xl:  32px;
  --radius-full: 9999px;

  /* === Shadow === */
  --shadow-xs:  0 1px 2px rgba(10, 14, 26, 0.04);
  --shadow-sm:  0 2px 4px rgba(10, 14, 26, 0.05),
                0 1px 2px rgba(10, 14, 26, 0.04);
  --shadow-md:  0 6px 12px rgba(10, 14, 26, 0.06),
                0 2px 4px rgba(10, 14, 26, 0.04);
  --shadow-lg:  0 12px 24px rgba(10, 14, 26, 0.08),
                0 4px 8px rgba(10, 14, 26, 0.04);
  --shadow-xl:  0 24px 48px rgba(10, 14, 26, 0.10),
                0 8px 16px rgba(10, 14, 26, 0.06);
  --shadow-glow-clinical: 0 0 32px rgba(0, 184, 148, 0.18);
  --shadow-glow-coaching: 0 0 32px rgba(255, 122, 89, 0.18);

  /* === 그라데이션 === */
  --grad-hero:
    radial-gradient(ellipse 60% 50% at 75% 30%, var(--color-clinical-soft) 0%, transparent 70%),
    radial-gradient(ellipse 50% 40% at 25% 70%, var(--color-coaching-soft) 0%, transparent 70%),
    var(--color-bg-cool);
  --grad-solution:
    linear-gradient(180deg, var(--color-bg-cool) 0%, var(--color-bg-mist) 30%, var(--color-bg-mist) 100%);
  --grad-airpods-demo:
    radial-gradient(ellipse 80% 60% at 50% 30%, rgba(0, 184, 148, 0.18) 0%, transparent 60%),
    radial-gradient(ellipse 60% 40% at 50% 80%, rgba(255, 122, 89, 0.10) 0%, transparent 60%),
    var(--color-bg-deep);
  --grad-cta:
    linear-gradient(135deg, var(--color-cta) 0%,
      color-mix(in srgb, var(--color-cta) 80%, var(--color-coaching) 20%) 100%);
  --grad-final-cta:
    linear-gradient(180deg, var(--color-bg-deep) 0%,
      color-mix(in srgb, var(--color-bg-deep) 90%, var(--color-clinical) 10%) 100%);
}

/* === 한국어 줄바꿈 규칙 (전역) === */
html { word-break: keep-all; overflow-wrap: anywhere; }

/* === iOS Safari 100vh === */
.h-svh { min-height: 100vh; min-height: 100svh; }

/* === reduced motion === */
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
  [data-reveal] { opacity: 1 !important; transform: none !important; }
}

/* === Focus visible === */
:focus-visible { outline: 2px solid var(--color-cta); outline-offset: 2px; border-radius: 4px; }
```

### 2.2 Tailwind Config (`tailwind.config.ts` 그대로)

```ts
import type { Config } from 'tailwindcss'

export default {
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: {
    container: { center: true, padding: '1rem' },
    screens: {
      sm:  '640px',
      md:  '768px',
      lg:  '1024px',
      xl:  '1280px',
      '2xl': '1536px',
    },
    extend: {
      colors: {
        'bg-cool': 'var(--color-bg-cool)',
        'bg-warm': 'var(--color-bg-warm)',
        'bg-deep': 'var(--color-bg-deep)',
        'bg-mist': 'var(--color-bg-mist)',
        'text-primary':   'var(--color-text-primary)',
        'text-secondary': 'var(--color-text-secondary)',
        'text-muted':     'var(--color-text-muted)',
        'text-subtle':    'var(--color-text-subtle)',
        'text-on-deep':   'var(--color-text-on-deep)',
        clinical: {
          DEFAULT: 'var(--color-clinical)',
          soft:    'var(--color-clinical-soft)',
          deep:    'var(--color-clinical-deep)',
        },
        coaching: {
          DEFAULT: 'var(--color-coaching)',
          soft:    'var(--color-coaching-soft)',
          deep:    'var(--color-coaching-deep)',
        },
        cta: {
          DEFAULT: 'var(--color-cta)',
          hover:   'var(--color-cta-hover)',
          soft:    'var(--color-cta-soft)',
        },
        line: {
          DEFAULT: 'var(--color-line)',
          strong:  'var(--color-line-strong)',
        },
        'chart-fast':     'var(--color-chart-fast)',
        'chart-target':   'var(--color-chart-target)',
        'chart-progress': 'var(--color-chart-progress)',
      },
      fontFamily: {
        sans:  ['Pretendard Variable', 'Inter', 'system-ui', 'sans-serif'],
        serif: ['Noto Serif KR', 'Georgia', 'serif'],
        mono:  ['JetBrains Mono', 'monospace'],
      },
      fontSize: {
        // [size, { lineHeight, letterSpacing, fontWeight? }]
        'display-xl':    ['64px', { lineHeight: '72px', letterSpacing: '-0.025em', fontWeight: '700' }],
        'display-lg':    ['52px', { lineHeight: '60px', letterSpacing: '-0.02em',  fontWeight: '700' }],
        'heading-1':     ['40px', { lineHeight: '48px', letterSpacing: '-0.015em', fontWeight: '600' }],
        'heading-2':     ['32px', { lineHeight: '40px', letterSpacing: '-0.01em',  fontWeight: '600' }],
        'heading-3':     ['24px', { lineHeight: '32px', letterSpacing: '-0.005em', fontWeight: '600' }],
        'heading-4':     ['20px', { lineHeight: '28px', fontWeight: '600' }],
        'body-lg':       ['18px', { lineHeight: '30px' }],
        'body':          ['16px', { lineHeight: '26px' }],
        'body-sm':       ['14px', { lineHeight: '22px' }],
        'caption':       ['13px', { lineHeight: '20px', letterSpacing: '0.005em' }],
        'label':         ['12px', { lineHeight: '18px', letterSpacing: '0.04em', fontWeight: '500' }],
        'quote-display': ['36px', { lineHeight: '48px', letterSpacing: '-0.005em' }],
        'data-mono':     ['14px', { lineHeight: '22px', fontWeight: '500' }],
      },
      spacing: {
        '0': 'var(--space-0)',
        '1': 'var(--space-1)',
        '2': 'var(--space-2)',
        '3': 'var(--space-3)',
        '4': 'var(--space-4)',
        '5': 'var(--space-5)',
        '6': 'var(--space-6)',
        '8': 'var(--space-8)',
        '10': 'var(--space-10)',
        '12': 'var(--space-12)',
        '16': 'var(--space-16)',
        '20': 'var(--space-20)',
        '24': 'var(--space-24)',
        '32': 'var(--space-32)',
        '40': 'var(--space-40)',
      },
      borderRadius: {
        sm: '6px', md: '12px', lg: '16px', xl: '24px', '2xl': '32px',
      },
      boxShadow: {
        xs: 'var(--shadow-xs)',
        sm: 'var(--shadow-sm)',
        md: 'var(--shadow-md)',
        lg: 'var(--shadow-lg)',
        xl: 'var(--shadow-xl)',
        'glow-clinical': 'var(--shadow-glow-clinical)',
        'glow-coaching': 'var(--shadow-glow-coaching)',
      },
      backgroundImage: {
        'grad-hero':         'var(--grad-hero)',
        'grad-solution':     'var(--grad-solution)',
        'grad-airpods-demo': 'var(--grad-airpods-demo)',
        'grad-cta':          'var(--grad-cta)',
        'grad-final-cta':    'var(--grad-final-cta)',
      },
      maxWidth: {
        'container':      '1200px',
        'narrow':         '880px',
        'prose-narrow':   '680px',
      },
      transitionTimingFunction: {
        'reveal': 'cubic-bezier(0.16, 1, 0.3, 1)',
      },
    },
  },
  plugins: [],
} satisfies Config
```

### 2.3 폰트 로드 (`index.html` `<head>`)

```html
<link rel="preconnect" href="https://cdn.jsdelivr.net" crossorigin>
<link rel="preload" as="style"
      href="https://cdn.jsdelivr.net/gh/orioncactus/pretendard@v1.3.9/dist/web/variable/pretendardvariable-dynamic-subset.min.css">
<link rel="stylesheet"
      href="https://cdn.jsdelivr.net/gh/orioncactus/pretendard@v1.3.9/dist/web/variable/pretendardvariable-dynamic-subset.min.css">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Noto+Serif+KR:wght@400;700&display=swap">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500&display=swap">
```

### 2.4 메타 태그 (`index.html`)

```html
<html lang="ko">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover" />
  <title>Chew & Calm Coach — 8주, 위 건강을 차분히 되찾아요</title>
  <meta name="description" content="위염 진단을 받았거나, 체중이 정체되었거나, 점심마다 더부룩한 30·40대라면 — 이미 끼고 있는 AirPods로 식사 속도를 자동 측정하고, 임상 28일 코스로 매일 2-3분 위 건강을 되찾아요." />
  <meta property="og:title" content="Chew & Calm Coach — 8주, 위 건강을 차분히 되찾아요" />
  <meta property="og:description" content="이미 끼고 있는 AirPods가 식사 속도를 자동으로 보여주고, 임상 28일 코스가 매일 2-3분 함께 걸어요." />
  <meta property="og:image" content="/og-image.png" />
  <meta property="og:type" content="website" />
  <meta property="og:locale" content="ko_KR" />
</head>
```

---

## 3. 컴포넌트 명세

### 3.1 페이지 섹션 (10개)

| 컴포넌트 | 책임 | Props | 의존 | 모션 마운팅 |
|---|---|---|---|---|
| `<StickyNav>` | 상단 네비, 100vh 후 blur | 없음 | 로고, `<CtaSecondary>` | scroll listener |
| `<Hero>` | H1 + CTA + AirPods 정적 SVG | `{ persona }` | `<Display>`, `<CtaPrimary>`, `<AirpodsSvg state="idle">`, `<ScrollIndicator>` | mount fade+up sequence |
| `<Problem>` | 자기 인식 + 시계 + 의학 + 페르소나 | 없음 | `<Heading>`, `<Clock>` x2, `<StatCard>` x2, `<QuoteCard>` x3 | scroll 시계 자동 채움 |
| `<Solution>` | 3단계 카드 | 없음 | `<Card>` x3, `<AirpodsSvg state="pulse">`, `<CalendarMini>`, `<KolPlaceholder>` | stagger fade + 펄스 + 막대 + 캘린더 |
| `<AirPodsDemo>` | 시그니처 4단계 | 없음 | `<AirpodsSvg state="streaming">`, `<DataStream>`, `<HealthScoreGauge>` | GSAP pin (≥1024) / IO 4 카드 (<1024) |
| `<HowItWorks>` | 3 컬럼 트리오 | 없음 | `<CalendarMini>`, `<AirpodsSvg>`, `<KolPlaceholder>`, `<CoachAvatarSvg>` | stagger + 캘린더 1주차 점등 |
| `<Differentiation>` | 5 자산 카드 | 없음 | `<Card>` x5, 미니어처 SVG | stagger fade |
| `<Authority>` | 정직 사회증거 3 + 인용 | 없음 | `<StatusChip>` x3, `<KolPlaceholder>`, RCT 막대 SVG, 사람 그리드, `<QuoteCard>` | KOL breathe + chip pulse + 막대 진입 |
| `<Pricing>` | 3 가격 카드 | 없음 | `<PriceCard>` x3 | stagger + 추천 카드 glow |
| `<FAQ>` | 8 Q&A 단일 펼침 | 없음 | `<FaqItem>` x8 (data/faq.ts) | accordion height |
| `<FinalCTA>` | 헤더 + 손편지 박스 + 폼 + Footer | 없음 | `<Display>`, `<EmailForm>`, Footer 마크업 | 헤더 fade+up + 박스 0.4s 딜레이 |

### 3.2 재사용 컴포넌트 (19개)

| 컴포넌트 | Props 시그니처 | 임포트 의존 |
|---|---|---|
| `Section` | `{ tone: 'cool'\|'warm'\|'mist'\|'deep', paddingY?: 'lg'\|'xl', children }` | `clsx` |
| `Container` | `{ size?: 'default'\|'narrow'\|'prose', children }` | `clsx` |
| `Heading` | `{ level: 1\|2\|3\|4, accent?: 'clinical'\|'coaching', as?: 'h1'\|'h2', children }` | — |
| `Display` | `{ size: 'xl'\|'lg', accentWords?: string[], children }` | `clsx` |
| `CtaPrimary` | `{ href?: string, onClick?: () => void, label, icon?: React.ReactNode }` | `lucide-react` |
| `CtaSecondary` | `{ href, label }` | `lucide-react` (`ArrowRight`) |
| `Card` | `{ variant?: 'flat'\|'elevated'\|'highlight', tone?, children }` | `clsx` |
| `StatCard` | `{ label, stat, source, description }` | — |
| `QuoteCard` | `{ quote, persona?, label? }` | — |
| `KolPlaceholder` | `{ role, status: 'recruiting' }` | `KolSilhouetteSvg` |
| `StatusChip` | `{ status: 'inProgress'\|'beta'\|'live', label }` | — |
| `PriceCard` | `{ tier: 'monthly'\|'yearly'\|'single', price, period, header, badges?: string[], features: string[], cancelPolicy: string, recommended?: boolean }` | — |
| `FaqItem` | `{ id, q, a, highlight?: 'trust-core', isOpen, onToggle }` | `lucide-react` (`ChevronDown`) |
| `EmailForm` | `{ onSubmit?, placeholder?, ctaLabel?, helperText?, variant: 'inline'\|'stacked'\|'caption' }` | `useEmailSubmit` |
| `Clock` | `{ minutes: number, target: number, label: string, variant: 'fast'\|'target' }` | — |
| `HealthScoreGauge` | `{ score: number, change?: number, animateOnView?: boolean }` | — |
| `CalendarMini` | `{ weeks?: 4, completedDays: number, animateSequence?: boolean }` | — |
| `DataStream` | `{ rows: { time: string, label: string }[] }` | — |
| `ScrollIndicator` | 없음 | — |

### 3.3 SVG 아이콘 (5개 커스텀)

`components/icons/`:
- `AirpodsSvg.tsx` — `{ variant: 'mono'\|'light', state: 'idle'\|'pulse'\|'streaming'\|'gauge' }`. 뷰박스 480×480. Named groups: `#airpod-body`, `#airpod-stem`, `#airpod-pulse`, `#airpod-data-line`. < 8KB.
- `HealthGaugeSvg.tsx` — 원형 게이지 r=64 stroke 6, `pathLength="100"`.
- `StomachSoftSvg.tsx` — 옵션, Solution 카드 보조.
- `CoachAvatarSvg.tsx` — 둥근 얼굴, 코랄 톤, 최소 디테일.
- `KolSilhouetteSvg.tsx` — 회색 실루엣, 부드러운 둥근 모양.

### 3.4 Lucide 아이콘 (트리쉐이킹 9개)

```ts
import { Headphones, Calendar, Stethoscope, Activity, ChevronDown, Check, ArrowRight, Mail, Quote } from 'lucide-react'
```

stroke-width 1.5px, 색 `currentColor`, 사이즈 24/20/32.

---

## 4. 인터랙션 사양

### 4.1 표준 모션 라이브러리

| 모션 ID | 트리거 | duration | easing | 변화 | 사용처 |
|---|---|---|---|---|---|
| `motion.scrollReveal` | scroll IO 70% | 0.6s | `cubic-bezier(0.16,1,0.3,1)` | opacity 0→1, translateY 16→0 | 모든 섹션 진입 |
| `motion.scrollRevealStagger` | scroll | 0.6s + 0.12s/child | 동상 | 동상, 자식 stagger | 카드 그룹 |
| `motion.hoverLift` | hover | 0.2s | `ease-out` | translateY -2, shadow md→lg | 카드, 작은 CTA |
| `motion.hoverLiftLg` | hover | 0.25s | `ease-out` | translateY -4, shadow md→xl | 큰 카드 (가격 추천) |
| `motion.ctaPress` | active | 0.12s | `ease-in-out` | scale 1→0.97 | 모든 CTA |
| `motion.ctaHover` | hover | 0.2s | `ease-out` | bg-cta → bg-cta-hover, shadow md→lg | Primary CTA |
| `motion.scrollIndicator` | mount infinite | 1.6s | `ease-in-out` | translateY -4↔4 | Hero 화살표 |
| `motion.smoothScroll` | wheel/touch | linear interp 0.1 | — | 페이지 부드러움 | 전역 (Lenis, 데스크탑만) |
| `motion.faqAccordion` | click | 0.3s | `cubic-bezier(0.16,1,0.3,1)` | max-height + arrow rotate 180 | FAQ |
| `motion.formFocus` | focus | 0.2s | `ease-out` | border-color + glow | 폼 인풋 |
| `motion.formError` | submit error | 0.3s | `ease-out` | translateX shake ±6 4회 | 폼 실패 |
| `motion.statePulse` | mount infinite | 1.5s | `linear` | scale 0.9↔1.1, opacity 0.4↔0.8 | Authority chip 점 |
| `motion.kolBreathe` | mount infinite | 3s | `ease-in-out` | opacity 0.7↔0.9 | KOL 실루엣 |

### 4.2 IntersectionObserver Reveal (`src/interactions/revealOnScroll.ts`)

```ts
export function initRevealOnScroll(): IntersectionObserver {
  const io = new IntersectionObserver(
    (entries) => {
      entries.forEach((e) => {
        if (e.isIntersecting) {
          e.target.classList.add('revealed')
          io.unobserve(e.target)
        }
      })
    },
    { threshold: 0.2, rootMargin: '0px 0px -10% 0px' }
  )
  document.querySelectorAll('[data-reveal]').forEach((el) => io.observe(el))
  return io
}
```

```css
/* globals.css */
[data-reveal] {
  opacity: 0; transform: translateY(16px);
  transition: opacity .6s var(--ease-reveal, cubic-bezier(.16,1,.3,1)),
              transform .6s var(--ease-reveal, cubic-bezier(.16,1,.3,1));
}
[data-reveal].revealed { opacity: 1; transform: translateY(0); }
[data-reveal-stagger] > * { transition-delay: calc(var(--i, 0) * 0.12s); }
```

### 4.3 Lenis 스무스 스크롤 (`src/interactions/smoothScroll.ts`)

```ts
import gsap from 'gsap'
import { ScrollTrigger } from 'gsap/ScrollTrigger'

export async function initSmoothScroll(): Promise<void> {
  if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return
  if (window.matchMedia('(max-width: 1023px)').matches) return  // 모바일은 네이티브
  const { default: Lenis } = await import('lenis')
  const lenis = new Lenis({
    duration: 1.0,
    easing: (t) => 1 - Math.pow(1 - t, 3),
    smoothWheel: true,
  })
  function raf(time: number) { lenis.raf(time); requestAnimationFrame(raf) }
  requestAnimationFrame(raf)
  lenis.on('scroll', ScrollTrigger.update)
  gsap.ticker.add((time) => lenis.raf(time * 1000))
  gsap.ticker.lagSmoothing(0)
}
```

### 4.4 시그니처 인터랙션 — AirPods Demo (`src/interactions/airpodsScroll.ts`)

옵션 B 정밀 SVG + GSAP scroll-trigger + 4단계. **drawSVG 미사용 — strokeDashoffset + cross-fade로 무료 구현.**

```ts
import gsap from 'gsap'
import { ScrollTrigger } from 'gsap/ScrollTrigger'
gsap.registerPlugin(ScrollTrigger)

const LINE_LENGTH = 540  // SVG path total length, getTotalLength()로 계산

export function initAirpodsSignature(): void {
  if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
    // 정적 4 카드 모드로 즉시 표시
    gsap.set(['#airpod-pulse', '#data-stream-line', '#stream-rows', '#health-score-gauge'],
             { opacity: 1 })
    return
  }

  ScrollTrigger.matchMedia({
    // 데스크탑: 핀 + scrub
    '(min-width: 1024px)': () => {
      const tl = gsap.timeline({
        scrollTrigger: {
          trigger: '#airpods-demo',
          start: 'top top',
          end: '+=180%',
          scrub: 0.3,
          pin: true,
          pinSpacing: true,
          anticipatePin: 1,
        },
      })

      // Phase 1 → 2: 정지 → 펄스 (0~25%)
      tl.fromTo('#airpod-pulse',
        { scale: 0.8, opacity: 0 },
        { scale: 1.4, opacity: 0.8, duration: 0.25, ease: 'power2.out' })
        .to('#airpod-pulse', { scale: 2.0, opacity: 0, duration: 0.25 })

      // Phase 2 → 3: 데이터 라인 그려짐 + typewriter (25~60%)
      tl.fromTo('#data-stream-line',
        { strokeDashoffset: LINE_LENGTH },
        { strokeDashoffset: 0, duration: 0.35, ease: 'power1.inOut' })
        .from('.stream-row', {
          opacity: 0, y: 8, stagger: 0.07, duration: 0.3, ease: 'power2.out',
        }, '<')

      // Phase 3 → 4: 라인 fade-out + 게이지 fade-in (cross-fade — drawSVG 회피)
      tl.to('#data-stream-line', {
          opacity: 0, duration: 0.2, ease: 'power2.inOut',
        })
        .fromTo('#health-score-gauge',
          { opacity: 0, scale: 0.9 },
          { opacity: 1, scale: 1, duration: 0.4, ease: 'power3.out' }, '<')
        .fromTo('#health-score-number',
          { textContent: 0 },
          { textContent: 72, duration: 0.4, ease: 'power2.out',
            snap: { textContent: 1 } /* 정수 카운트업 */ }, '<')
    },

    // 모바일: 핀/scrub 비활성, 4 카드 IO 진입
    '(max-width: 1023px)': () => {
      // .airpods-phase-card[data-phase="1"]..[data-phase="4"] 4 카드
      gsap.utils.toArray<HTMLElement>('.airpods-phase-card').forEach((card) => {
        gsap.from(card, {
          opacity: 0, y: 24, duration: 0.6, ease: 'cubic-bezier(0.16, 1, 0.3, 1)',
          scrollTrigger: { trigger: card, start: 'top 80%', once: true },
        })
      })
    },
  })
}
```

### 4.5 차트 모션 (`src/interactions/chartAnimations.ts`)

```ts
// Problem 시계 진입
export function animateClockOnScroll(el: HTMLElement, type: 'fast' | 'target') {
  const FULL = 100  // pathLength normalized
  const fillTo = type === 'fast' ? 55 : 100  // 11/20 = 55%, 20/20 = 100%
  const duration = type === 'fast' ? 1.2 : 2.0

  gsap.fromTo(
    el.querySelector('circle.progress'),
    { strokeDashoffset: FULL },
    {
      strokeDashoffset: FULL - fillTo,
      duration,
      ease: 'power3.out',
      delay: type === 'target' ? 0.3 : 0,
      scrollTrigger: { trigger: el, start: 'top 70%', once: true },
    }
  )
}

// Solution 28일 캘린더 stagger 점등
export function animateCalendarSequence(el: HTMLElement, completedDays: number) {
  gsap.from(el.querySelectorAll<SVGElement>('.cell-active'), {
    opacity: 0, scale: 0.6,
    stagger: 0.06, duration: 0.3, ease: 'power2.out',
    scrollTrigger: { trigger: el, start: 'top 75%', once: true },
  })
}

// Authority RCT 8 막대
export function animateRctBars(el: HTMLElement) {
  gsap.from(el.querySelectorAll('rect.bar'), {
    scaleX: 0, transformOrigin: '0 50%',
    stagger: 0.1, duration: 0.5, ease: 'power2.out',
    scrollTrigger: { trigger: el, start: 'top 75%', once: true },
  })
}
```

### 4.6 FAQ 아코디언 (단일 펼침)

```tsx
// FAQ.tsx
const [openId, setOpenId] = useState<string | null>(null)

return (
  <ul role="list">
    {faq.map((entry) => (
      <FaqItem
        key={entry.id}
        {...entry}
        isOpen={openId === entry.id}
        onToggle={() => {
          setOpenId(openId === entry.id ? null : entry.id)
          track('faq_open', { id: entry.id })
        }}
      />
    ))}
  </ul>
)
```

```tsx
// FaqItem.tsx
<li className="faq-item border-b border-line">
  <button
    className="w-full flex items-center justify-between py-4 text-left min-h-[56px]"
    aria-expanded={isOpen}
    aria-controls={`faq-a-${id}`}
    onClick={onToggle}
  >
    <span className="text-heading-4">{q}</span>
    <ChevronDown className={clsx('transition-transform duration-300', isOpen && 'rotate-180')} />
  </button>
  <div
    id={`faq-a-${id}`}
    role="region"
    aria-labelledby={`faq-q-${id}`}
    className="overflow-hidden transition-[max-height] duration-300 ease-reveal"
    style={{ maxHeight: isOpen ? '800px' : '0' }}
  >
    <div className="pb-6 pr-8 text-body text-text-secondary whitespace-pre-line">{a}</div>
  </div>
</li>
```

### 4.7 EmailForm 제출 플로우

```tsx
// hooks/useEmailSubmit.ts
export function useEmailSubmit(source: 'final' | 'footer') {
  const [state, setState] = useState<'idle' | 'loading' | 'success' | 'error'>('idle')
  const submit = async (email: string) => {
    setState('loading')
    track('beta_form_submit', { source })
    try {
      await fetch(import.meta.env.VITE_BETA_SUBMIT_URL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, source }),
      })
      setState('success')
      track('beta_form_success', { source })
    } catch (err) {
      setState('error')
      track('beta_form_error', { source, error: String(err) })
    }
  }
  return { state, submit }
}
```

### 4.8 8주 후 날짜 자동 계산 (`src/lib/eightWeekDate.ts`)

```ts
export function get8WeekDateLabel(now: Date = new Date()): string {
  const target = new Date(now)
  target.setDate(target.getDate() + 56)
  // "M월 N째 주" 형식으로 변환 — 해당 주가 그 달의 몇 번째 주인지
  const month = target.getMonth() + 1
  const dayOfMonth = target.getDate()
  const weekIndex = Math.ceil(dayOfMonth / 7)
  const weekLabel = ['첫째', '둘째', '셋째', '넷째', '다섯째'][weekIndex - 1] ?? '마지막'
  return `${month}월 ${weekLabel} 주`
}
```

### 4.9 페르소나 라우팅 (`src/hooks/usePersonaRoute.ts`)

```ts
export function usePersonaRoute(): Persona {
  const [persona, setPersona] = useState<Persona>('default')
  useEffect(() => {
    const params = new URLSearchParams(window.location.search)
    const p = params.get('p')
    if (p === 'stomach' || p === 'diet' || p === 'checkup') {
      setPersona(p)
      track('persona_routed', { persona: p })
    }
  }, [])
  return persona
}
```

---

## 5. 빌드 단계 + 검증 체크리스트

### Step 1 — Setup (30min)

- [ ] `npm create vite@latest landing -- --template react-ts`
- [ ] 의존성: `npm i react@18 react-dom@18 gsap lenis lucide-react clsx`
- [ ] 개발 의존성: `npm i -D tailwindcss@3.4 postcss autoprefixer @types/react @types/react-dom typescript`
- [ ] `npx tailwindcss init -p`
- [ ] `tailwind.config.ts`에 §2.2 토큰 그대로 입력
- [ ] `src/styles/tokens.css`에 §2.1 :root 변수 그대로
- [ ] `src/styles/globals.css`에 Tailwind base + reset + reduced-motion (§2.1 하단)
- [ ] `index.html`에 §2.3 폰트 preload + §2.4 메타 태그
- [ ] `<html lang="ko">` 확인
- **검증**:
  - [ ] `npm run dev` → localhost 5173 정상 렌더
  - [ ] 빈 div에 `bg-clinical text-coaching-deep font-sans`로 토큰 작동 확인
  - [ ] Pretendard 글리프 표시 확인
  - [ ] Network 탭에서 폰트 200 OK

### Step 2 — 정적 마크업 + 스타일 (4-5h)

- [ ] `data/faq.ts`, `personas.ts`, `pricing.ts`, `medicalEvidence.ts` — §1에서 그대로 입력
- [ ] 19개 재사용 컴포넌트 (`components/*`) — §3.2 시그니처대로
- [ ] 5개 커스텀 SVG (`components/icons/*`) — §3.3 사양대로
- [ ] 10개 섹션 (`sections/*`) — §1 카피 그대로 + §3.1 의존 컴포넌트로 조합
- [ ] `App.tsx`에서 10개 섹션 조립
- [ ] `usePersonaRoute()` 훅으로 Hero 서브헤드라인 분기
- [ ] 헤드라인 `<br>` 줄바꿈 강제 (보존 필수: §1.1 H1)
- [ ] Hero 보조 1줄 R2 분기 — `<br className="hidden lg:inline" />` 패턴
- [ ] 손편지 박스 R3 — Final CTA의 별도 박스 + 좌측 1px coaching-soft 라인 + Noto Serif KR Italic
- [ ] Pricing 카드 2 R4 — 칩 `추천` + `한 달 무료`
- [ ] OG 이미지 1200×630 생성 → `public/og-image.png`
- **검증**:
  - [ ] 모든 섹션 시안과 일치 (스크린샷 비교)
  - [ ] 다음 문장 *그대로* 페이지에 존재 (검색):
    - `당신의 점심은 평균 11분.`
    - `8주만, 위 건강을 차분히 되찾아요.`
    - `Hurst & Fukuda` (출처 보존)
    - `Ohkuma et al.`
    - `12,000~25,000원` (가격 비교 보존)
    - `$24.99/월`
    - `1만 명이 합류했다고 거짓말하지 않아요.` (보존 필수)
    - `지금 시점에서 우리 제품으로 위염이 낫는다고 약속할 수는 없어요.` (Q6 보존 필수)
    - `[영입 진행 중]` (KOL 라벨 보존)
  - [ ] `?p=stomach`, `?p=diet`, `?p=checkup`에서 서브헤드라인 변경

### Step 3 — 반응형 (1-2h)

- [ ] 320 / 414 / 768 / 1024 / 1280 / 1920 6개 너비 검증
- [ ] iOS Safari 100svh — Hero `min-h-[100svh]`
- [ ] 폼 인풋 `text-base` 이상 (16px+) — 자동 줌 방지
- [ ] 호버 `@media (hover: hover)` 한정 — Tailwind `hover:` + `pointer-fine` 미디어
- [ ] Pricing 모바일 세로 스택 — *연간이 최상단* (CSS order)
- [ ] Problem 페르소나 카드 모바일 수평 스크롤 — `flex overflow-x-auto snap-x snap-mandatory`
- **검증**:
  - [ ] 6개 너비 깨짐 없음 (Chrome DevTools Device Mode)
  - [ ] iOS Safari 실기 — Hero 100svh 정확 (URL bar 표시 시에도 핵심 메시지 보임)
  - [ ] 폼 인풋 탭 시 자동 줌 *없음* (iOS Safari)

### Step 4 — 기본 인터랙션 (2-3h)

- [ ] `interactions/revealOnScroll.ts` IO + `[data-reveal]` 적용
- [ ] `interactions/smoothScroll.ts` Lenis (데스크탑 dynamic import)
- [ ] Lenis ↔ ScrollTrigger 동기화
- [ ] CTA 호버/active 표준 모션 (Tailwind utilities)
- [ ] FAQ 단일 펼침 아코디언
- [ ] EmailForm 포커스/제출/성공/실패 피드백 (`useEmailSubmit` 훅)
- [ ] StickyNav 100vh 통과 시 backdrop-blur (state + scroll listener passive)
- [ ] Hero 스크롤 인디케이터 `motion.scrollIndicator` (CSS @keyframes)
- [ ] `prefers-reduced-motion` 전역 처리 검증
- **검증**:
  - [ ] 모든 인터랙션 60fps (Chrome DevTools Performance)
  - [ ] reduced-motion 시 모션 정지 + 즉시 최종 상태
  - [ ] FAQ Tab/Enter/Space 키보드 작동
  - [ ] EmailForm 2 위치(Final CTA + Footer) 모두 정상 — 성공/실패 피드백 표시
  - [ ] StickyNav backdrop-blur 100vh 후에 발화

### Step 5 — 시그니처 인터랙션 (3-5h)

- [ ] `interactions/airpodsScroll.ts` GSAP timeline (§4.4)
- [ ] AirpodsSvg 인라인 — named groups (`#airpod-body`, `-stem`, `-pulse`, `-data-line`)
- [ ] Phase 1→2: 펄스
- [ ] Phase 2→3: strokeDashoffset 라인 + typewriter stagger
- [ ] Phase 3→4: 라인 fade-out + 게이지 fade-in cross-fade (drawSVG 회피)
- [ ] Phase 4: 점수 카운트업 0→72 (`snap: { textContent: 1 }`)
- [ ] 모바일 분기 `ScrollTrigger.matchMedia` — 4 카드 IO 진입
- [ ] Problem 시계 자동 채움 (`animateClockOnScroll`)
- [ ] Solution 28일 캘린더 stagger 점등
- [ ] How it works 1주차 7셀 stagger
- [ ] Authority KOL breathe (`motion.kolBreathe`) + 상태 칩 pulse + RCT 8막대 stagger + 사람 4개 stagger
- [ ] Pricing 추천 카드 mount glow
- **검증**:
  - [ ] 데스크탑 시그니처 60fps (DevTools Performance, scroll 시 frame drop 0)
  - [ ] 모바일 4 카드 60fps
  - [ ] 시각 일관성 — 디자이너 시안과 4 단계 매칭
  - [ ] reduced-motion 시 정적 4 카드 즉시 표시
  - [ ] 게이지 점수 정확히 72 카운트업

### Step 6 — 성능·접근성 마감 (2-3h)

- [ ] 폰트 preload + `font-display: swap` + `size-adjust` fallback (CLS 방지)
- [ ] Lenis dynamic import 검증 — 모바일 진입 시 Lenis 청크 미로드
- [ ] Vercel 배포 (`vercel:deploy` 스킬)
- [ ] 프로덕션 Lighthouse 측정 (Mobile + Desktop)
- [ ] WCAG AA 색 대비 검증 (Stark/Axe DevTools) — `02_visual_ux.md` §2.2 표 그대로
- [ ] 키보드 네비게이션 풀 테스트 — Skip link → Nav → Hero CTA → FAQ → Final CTA
- [ ] 스크린 리더 테스트 (VoiceOver) — 헤드라인, 차트 alt, FAQ 펼침
- [ ] structured data — Product + FAQPage (`<script type="application/ld+json">`)
- [ ] sitemap.xml + robots.txt
- [ ] `vite-bundle-visualizer`로 번들 분석
- **검증**:
  - [ ] Lighthouse Mobile Performance ≥ 90
  - [ ] Lighthouse Desktop Performance ≥ 95
  - [ ] Lighthouse Accessibility ≥ 95
  - [ ] Lighthouse SEO = 100
  - [ ] JS 번들 < 100KB gzipped
  - [ ] CSS 번들 < 50KB gzipped
  - [ ] 이미지/SVG 합 < 500KB
  - [ ] CLS < 0.1, LCP < 2.5s, INP < 200ms (mobile 4G throttling)

**총 예상**: 12-18h.

---

## 6. 성공 기준 체크리스트 (빌드 끝에 통과 의무)

### 6.1 카피 보존

- [ ] H1 두 줄 보존: `당신의 점심은 평균 11분.` / `8주만, 위 건강을 차분히 되찾아요.`
- [ ] 의학 근거 출처 표기 보존: `Hurst & Fukuda, 2018`, `Ohkuma et al., 2015`
- [ ] KOL 라벨 보존: `[영입 진행 중]` (줄임 금지)
- [ ] 가격 비교 수치 보존: `12,000~25,000원`, `$24.99/월`, `9,900원`
- [ ] FAQ Q6 정직 문장 보존: `지금 시점에서 우리 제품으로 위염이 낫는다고 약속할 수는 없어요.`
- [ ] Final CTA self-aware 문장 보존: `1만 명이 합류했다고 거짓말하지 않아요. 지금은 우리가 함께 걸을 첫 사람들을 모으고 있어요.` (별도 박스 처리)
- [ ] Banned List 위반 0개 (페이지 검색)

### 6.2 디자인 정합

- [ ] 모든 섹션 시안과 시각 일치 (스크린샷 비교)
- [ ] 4개 디바이스 사이즈 검증: 320 / 768 / 1024 / 1920
- [ ] 컬러 팔레트 토큰만 사용 (하드코딩 hex 0개)
- [ ] 헤드라인 폰트 Pretendard 800 (R1)
- [ ] Pricing 추천 카드 강조 + "추천" / "한 달 무료" 칩 (R4)
- [ ] Final CTA 손편지 박스 별도 처리 (R3)
- [ ] KOL placeholder가 "부끄럽지 않게" 자신감 톤 (M4)
- [ ] 사진 0장 (라이센스/진정성)

### 6.3 인터랙션

- [ ] 시그니처 인터랙션 데스크탑 핀 + 4단계 정상 작동
- [ ] 시그니처 인터랙션 모바일 4 카드 분리 진입 정상
- [ ] 모든 인터랙션 60fps 보장 (DevTools Performance)
- [ ] FAQ 단일 펼침 (새 Q 펼치면 기존 닫힘)
- [ ] EmailForm 제출 → 로딩 → 성공/실패 피드백
- [ ] StickyNav 100vh 후 backdrop-blur 발화
- [ ] 페르소나 라우팅 `?p=stomach|diet|checkup` 작동

### 6.4 성능 (Lighthouse Mobile, 4G throttling)

- [ ] Performance ≥ 90
- [ ] Accessibility ≥ 95
- [ ] Best Practices ≥ 95
- [ ] SEO = 100
- [ ] LCP < 2.5s
- [ ] CLS < 0.1
- [ ] INP < 200ms
- [ ] JS 번들 < 100KB (gzipped)
- [ ] CSS 번들 < 50KB (gzipped)
- [ ] 이미지/SVG 합 < 500KB

### 6.5 접근성 (WCAG AA)

- [ ] 본문 색 대비 ≥ 4.5:1 (`02_visual_ux.md` §2.2 표)
- [ ] 큰 텍스트 색 대비 ≥ 3.0:1
- [ ] 모든 인터랙티브 요소 Tab 도달
- [ ] `:focus-visible` 2px outline 표시
- [ ] `prefers-reduced-motion` 전역 대응
- [ ] 차트 SVG `aria-label` 명시
- [ ] FAQ `<button aria-expanded>` + `<region aria-labelledby>`
- [ ] EmailForm `<label>` 명시 (visually-hidden 가능)
- [ ] Skip link `<a href="#main">` 첫 자식
- [ ] `<html lang="ko">`
- [ ] 사용자 200% 확대 시 깨짐 없음 (rem 단위)

### 6.6 SEO + 분석

- [ ] `<title>`, `<meta description>`, OG 태그 입력
- [ ] OG 이미지 1200×630
- [ ] structured data Product + FAQPage
- [ ] sitemap.xml + robots.txt
- [ ] `track()` placeholder 모든 이벤트 위치 발화 (Step 4 이후 dev console로 검증)

### 6.7 비즈니스

- [ ] 베타 가입 폼 1필드(email) — Final CTA + Footer 2위치
- [ ] Hero CTA → Final CTA로 smooth scroll (앵커)
- [ ] Pricing CTA 3개 모두 명확한 라벨
- [ ] 가격 정당화 카피 보존 (모바일에서도 항상 표시)
- [ ] "7월 첫 주" 자동 계산 (today + 56일) Final CTA에 표시

---

## 7. 기술 충돌 해결 — 구현자 우선순위

### 7.1 시그니처 인터랙션 우선순위

**모바일 4 카드 분리를 *먼저*** 구현 → 그 후 데스크탑 핀 추가. 모바일이 80% 사용자라 핵심 경험.

### 7.2 drawSVG 유료 회피

라인→게이지 morph는 **2개 SVG cross-fade**로 대체. drawSVG 미사용. **0원**.

### 7.3 Recharts 미사용

차트 4종(원형 진행도, 게이지, 4×7 격자, 8 막대)은 모두 인라인 SVG 직접 구현. 16KB 절약.

### 7.4 카피 분량 vs 시안

가격 정당화 카피(4-5줄)는 모바일에서도 *항상 표시*. 폰트만 `body-sm` `text-muted`로 작게. 접기/펼치기 토글 *사용 안 함* — 신뢰 카피는 항상 보여야.

### 7.5 Hero 폼 위치

Hero는 *버튼만*, 폼은 Final CTA + Footer 2곳에만. EmailForm 컴포넌트 mount 위치 명확히 분리.

---

## 8. 후속 작업

- 카피 변경: §1만 갱신 (또는 `data/*.ts`)
- 토큰 변경: §2.1 + `tokens.css` + `tailwind.config.ts` 동시
- 새 섹션: §3 + §5 빌드 단계 갱신
- 시그니처 변경: §4.4 + `airpodsScroll.ts` + `03_architecture.md` §1.3 갱신
- 성능 미달: §6.4 검증 → 디자인 협상 (예: KOL breathe 비활성)

---

**문서 끝.** 이 한 파일만 보고 빌드 가능. 결정 누락 시 `landing-architect`에게 회신.
