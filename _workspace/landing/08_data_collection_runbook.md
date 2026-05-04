# 데이터 수집 운영 가이드 — Chew Coach 랜딩

서비스: **Web3Forms** (월 250건 무료, 데이터 자체 저장 없이 메일 즉시 forward)
수신처: `1213sam0@gmail.com`
작성일: 2026-05-04 / 작성자: landing-data-collector
관련: `_workspace/landing/07_data_collection_options.md` §5 추천안

---

## 1. 사용자가 *지금* 해야 할 일 (한 번만, ~15분)

### 1-1. Web3Forms 가입 + access_key 발급

1. <https://web3forms.com> 접속 → 우상단 "Get Started Free"
2. 이메일 `1213sam0@gmail.com` 입력 → 받은 메일의 인증 링크 클릭 (회원가입에 별도 비밀번호·카드 불필요)
3. 대시보드에서 **새 폼 생성**:
   - Form Name: `Chew Coach Beta Landing`
   - Receiving Email: `1213sam0@gmail.com`
   - Spam Protection: 기본값 유지 (자체 honeypot 켜짐)
4. **Access Key 복사** — UUID 형태 (예: `a1b2c3d4-e5f6-...`). 이 키는 *그 폼에 데이터 push 권한만* 있어 클라이언트 노출이 안전하다.

### 1-2. 로컬 개발 환경 — `landing/.env`에 키 넣기

```bash
cd /Users/sungho/Documents/programming/chew_tracking/landing
cp .env.example .env
# .env 파일을 에디터에서 열고:
#   VITE_W3FORMS_KEY=<위에서 복사한 키>
```

`.env`는 `.gitignore`에 이미 포함되어 있어 GitHub에 올라가지 않는다.

### 1-3. 프로덕션 (GitHub Pages) — repo Secret 등록

1. GitHub repo `chew_tracking` 페이지 접속
2. **Settings** → 좌측 메뉴 **Secrets and variables** → **Actions**
3. 우상단 **New repository secret** 클릭
4. Name: `VITE_W3FORMS_KEY` / Secret: `<발급받은 키>` → Add secret
5. 다음 push 또는 `workflow_dispatch`로 워크플로 재실행 시 빌드에 인라인된다 — `.github/workflows/deploy-landing.yml`의 Build 스텝이 `env`로 주입한다.

### 1-4. 첫 실 제출 테스트

```bash
cd /Users/sungho/Documents/programming/chew_tracking/landing
npm run dev
# http://localhost:5173 접속 → 베타 합류 폼에 본인 메일 입력 → 제출
```

성공 카피("합류해주셔서 감사해요...") 표시 + 5초 이내 Gmail에 도착하면 합격. (제목: `[Chew Coach] 새 베타 신청`, 발신: `noreply@web3forms.com`)

---

## 2. 어디서 보나요 (수신처)

### Gmail 받은편지함 — 단일 source of truth

- **수신**: `1213sam0@gmail.com` 받은편지함
- **발신**: `noreply@web3forms.com`
- **제목**: `[Chew Coach] 새 베타 신청`
- **본문**: 제출자의 이메일, 폼 source(`inline`/`stacked`/`caption`), 제출 시각

### Gmail 라벨 자동화 (권장 — ~3분)

베타 신청 메일이 일반 메일과 섞이면 놓치기 쉽다. 자동 라벨로 분리:

1. Gmail 좌측 메뉴 하단 **"라벨 만들기"** → 이름 `ChewCoach Beta`
2. 검색창에 `from:noreply@web3forms.com subject:"새 베타 신청"` 입력 → 검색
3. 검색바 우측 끝 **필터 만들기** 클릭
4. 체크박스 **라벨 적용: ChewCoach Beta** + **별표 표시** 선택 → 필터 만들기
5. 모바일 Gmail 앱: 설정 → `1213sam0@gmail.com` → **라벨 알림** → `ChewCoach Beta` → 알림 ON

이렇게 하면 신청자 1명마다 모바일 푸시가 즉시 온다.

---

## 3. 알림은 어디로 오나요

| 채널 | 시간 | 비고 |
|---|---|---|
| Gmail 받은편지함 | 즉시 (Web3Forms 큐 ~수 초) | 1차 source of truth |
| Gmail 모바일 푸시 | 즉시 | 라벨 알림 ON 한 경우 |
| Web3Forms 한도 경고 | 250건의 90% (≈225건) 도달 시 별도 메일 | 자동 |

---

## 4. 데이터를 export 하려면

베타 < 250/월 단위에서는 **Gmail 자체가 export 도구**다.

### 검색 + CSV 변환 (수동, ~5분)

1. Gmail 검색: `from:noreply@web3forms.com label:ChewCoach Beta`
2. 결과 우상단 햄버거 메뉴 → **검색 결과 페이지로 이동** (또는 Gmail 검색 결과 그대로 사용)
3. 메일 본문에서 이메일 주소만 뽑아 스프레드시트에 붙여넣기 — 베타 < 100건이면 손으로 충분

### 대량 export 필요 시 — Google Takeout

1. <https://takeout.google.com> 접속
2. **메일** 항목만 선택 → 라벨 필터에서 `ChewCoach Beta`만 선택
3. .mbox 파일 다운로드 → 파이썬·노드 스크립트로 파싱 (필요시 별도 라운드에서 작성)

---

## 5. 한도 모니터링

| 항목 | 값 |
|---|---|
| 현재 무료 한도 | **월 250건** ([web3forms.com/pricing](https://web3forms.com/pricing) 확인 2026-05-04) |
| 90% 도달 알림 | Web3Forms가 가입 메일로 자동 경고 발송 |
| 100% 초과 시 폼 동작 | Web3Forms가 401/403 응답 → 코드는 `rate-limit` 분기 → 사용자에게 "요청이 많아 잠시 쉬어가요. 1분 뒤 다시 시도해주세요." 표시 |
| 한도 초과 시 우리 액션 | (a) 다음 달 1일까지 폼 비활성 카피로 임시 패치, 또는 (b) Web3Forms Pro 업그레이드($9/월부터, 1k+/월), 또는 (c) Apps Script로 마이그레이션 (07 보고서 §6 대안) |

베타 트래픽 가정 < 100/월이라면 250건 한도는 **2.5배 여유**이므로 일반적으로 도달하지 않는다.

---

## 6. 개인정보 처리 안내 (랜딩 카피 권고)

옵션 G 톤 + 한국 정보통신망법 광고 표시 규칙 디폴트. 푸터 또는 폼 helperText 어딘가에 다음 한 줄 추가 권장 (실제 카피 변경은 marketing-storyteller 라운드에서):

> 수집 항목: 이메일 주소 / 목적: 베타 진행 소식 안내 / 보관: 베타 종료 시 삭제 / 처리위탁: Web3Forms (메일 전달 목적, 자체 저장 없음) / 문의: 1213sam0@gmail.com

**Web3Forms 처리 위치**: 미국 추정 (공식 페이지에 region 명시 부재). 단 *자체 DB에 저장하지 않고 메일로 즉시 forward*하는 구조이므로 영구 보관처는 Gmail이다 — 이게 한국 사용자 데이터 처리 측면에서 가벼운 선택의 핵심이다.

---

## 7. 사용자가 데이터 삭제 요청 시

Web3Forms는 자체 DB에 보관하지 않는다 → 별도 서비스 측 삭제 절차 불필요. **Gmail 받은편지함에서만 삭제하면 끝**.

### 처리 절차 (~3분)

1. 사용자에게서 삭제 요청 메일 수신 (예: "베타 신청 취소·내 데이터 삭제")
2. Gmail 검색: `from:<요청자 이메일>` 또는 본문에 그 이메일이 들어간 베타 신청 메일 검색
3. 해당 메일 삭제 + 휴지통도 비움 (30일 이후 자동 삭제됨)
4. 요청자에게 처리 완료 회신 (디폴트 SLA: 7일 이내)
   - 회신 카피 예: "요청 주신 이메일은 베타 신청 목록에서 삭제했어요. 추가 문의 있으면 알려주세요."

---

## 8. 폼이 안 작동할 때 (장애 fallback)

### 감지 방법

- 일주일 동안 Gmail에 새 베타 신청이 0건 + 랜딩 트래픽은 정상 (애널리틱스 등) → 의심 신호
- 사용자 제보 ("폼이 안 됐어요")
- 직접 시뮬: 본인 메일로 1건 제출 → 60초 안에 도착 확인

### 진단 순서

1. 브라우저 개발자도구 Network 탭 → `api.web3forms.com/submit` 호출 status 확인
2. <https://web3forms.com/status> 또는 Web3Forms 대시보드 status
3. `console` 탭에서 `[dataCollection] VITE_W3FORMS_KEY is not set` 경고 보이면 → GitHub Secret 누락 또는 빌드 시 주입 실패. 워크플로 재실행

### 임시 fallback 패치 (Web3Forms 다운 30분+ 시)

`landing/src/components/EmailForm.tsx`의 `handleSubmit`을 임시로 다음과 같이 교체하는 hot-patch PR:

> 복구할 때까지 폼이 mailto 링크로 fallback. 모바일 메일 앱이 없는 사용자에게는 안내 카피로 안내.

```tsx
// 임시 fallback (Web3Forms 장애 시에만)
window.location.href = `mailto:1213sam0@gmail.com?subject=베타%20신청&body=${encodeURIComponent(email)}`
```

장애 복구 후 즉시 revert 하는 것이 원칙. 이 패치는 *비상용*이고 평상시에는 적용하지 않는다.

---

## 9. 봇·스팸 방어 현황

- **honeypot**: `_gotcha` 필드가 폼에 들어 있음 — 시각적으로 완전히 숨김 + `tabIndex={-1}` + `aria-hidden="true"`. 봇이 모든 input을 채우면 클라이언트 측에서 차단 (실제 fetch 호출 안 함, 봇에는 success로 보임)
- **Web3Forms 자체 스팸 필터**: 대시보드에서 켜고 끌 수 있음 (디폴트 ON)
- **클라이언트 검증**: 길이 5–200자 + `@` 포함
- **추가 옵션 (필요 시)**: Web3Forms 대시보드에서 hCaptcha/Cloudflare Turnstile 켤 수 있음. 베타 단계에서는 UX 비용이 커 디폴트 OFF 추천

스팸 신고가 주에 5건 이상 들어오면 Turnstile 활성화 + 코드에 토큰 필드 추가 별도 라운드 진행.

---

## 10. 운영 체크리스트 (월 1회)

매월 1일 또는 15일 5분 점검:

- [ ] 지난 달 베타 신청 수 합산 (Gmail 라벨 카운트) — 250 한도 대비 사용률 확인
- [ ] 답장 못 보낸 신청자 응답 (베타 빌드 진행 소식)
- [ ] 삭제 요청 메일이 휴지통에서 30일 자동 정리 되었는지 확인
- [ ] Web3Forms 대시보드에서 스팸 통계 확인
- [ ] (사용자가 베타 빌드 배포 후) 응답 카피 업데이트 검토 — marketing-storyteller 협업
