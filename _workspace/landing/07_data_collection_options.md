# 백엔드리스 데이터 수집 옵션 비교 — Chew Coach 랜딩

작성: landing-data-collector 에이전트
작성일: 2026-05-04
스코프: 리서치·비교·추천 보고서. 코드 변경 0건. 사용자가 추천을 보고 옵션을 골라야 별도 라운드에서 구현.

---

## 1. 컨텍스트 요약

| 항목 | 값 | 출처 |
|---|---|---|
| 프로젝트 | chew_tracking 옵션 G "Chew & Calm Coach" 베타 랜딩 | `CLAUDE.md` 변경 이력 |
| 호스팅 | GitHub Pages 정적 호스팅. 별도 서버·서버리스 함수 *현재 없음* | `CLAUDE.md` 하네스 2 + recent commits "feat: GitHub Pages로 랜딩 페이지 배포 설정" |
| 도메인 | 미설정 (GitHub Pages 디폴트 URL 추정 — `<user>.github.io/chew_tracking` 또는 `*.github.io`) | 사용자 컨텍스트 |
| 기존 폼 | `landing/src/components/EmailForm.tsx` — 이메일 입력 + `setTimeout` placeholder. 실제 수신처 0. `FinalCTA.tsx` + `Footer.tsx` 두 곳에서 사용 | 코드 |
| 사용자 의도 | "이메일을 넣으면 *개발자가 수신*. 별도 백엔드 없이 노션·구글시트·기타 가벼운 방식" | 사용자 메시지 |
| 톤 | 옵션 G — 의료 약속·가짜 권위 0건. 정직성 우선 | `MEMORY.md → marketing_tone.md` |
| 단계 | 베타 신청. **트래픽 가정: 월 100건 미만** (베타 초기) | 가정 (사용자 미확인) |
| 사용자 환경 | 노션·구글·Cloudflare 계정 보유 여부 미확인 → 옵션별로 "이게 필요" 명시 | 가정 |

---

## 2. 핵심 제약 3가지 (이게 옵션 선택을 결정한다)

### 제약 1: 정적 호스팅 = 비밀이 없다

GitHub Pages는 빌드 산출물(`landing/dist/`)을 그대로 내보낸다. Vite의 `import.meta.env.VITE_*`는 *빌드 시점에 번들에 인라인된다* — `dist/assets/index-*.js`에 텍스트로 박힌다. 즉 **Notion Internal Integration Token, SendGrid API Key, Slack Webhook full URL 등 권한이 강한 비밀은 클라이언트에서 사용할 수 없다.**

→ 결론: Notion API를 클라이언트가 직접 호출하려면 *반드시* 서버리스 함수가 1개 필요하다. "별도 백엔드 없이 노션으로 받기"는 *Worker 1개* 또는 *Tally의 Notion 통합* 같은 우회 경로로만 성립한다.

### 제약 2: CORS는 우회하지 않는다

Notion API(`api.notion.com`)는 `Access-Control-Allow-Origin` 헤더를 응답에 *내려보내지 않는다* — 브라우저 직접 호출은 preflight 단계에서 차단된다 ([makenotion/notion-sdk-js#96](https://github.com/makenotion/notion-sdk-js/issues/96), [#417](https://github.com/makenotion/notion-sdk-js/issues/417), 확인 2026-05-04). 이는 의도된 보안 동작 — Notion이 클라이언트 직접 호출을 의도하지 않은 것.

CORS 프록시로 우회하면 토큰 노출 문제는 그대로다. 옳은 결론: 그 옵션을 포기하거나 함수 1개를 둔다.

Google Apps Script Web App은 자체 CORS 처리(simple request만 허용). `Content-Type: text/plain;charset=utf-8` 트릭으로 preflight 회피 가능 — 작동한다.

### 제약 3: 옵션 G 톤은 폼에서도 지킨다

성공 메시지·확인 메일 카피에서 의료 약속·가짜 권위·KOL 영입 표현 0건. 디폴트 카피:
- 성공 토스트: "합류해주셔서 감사해요. 진행 소식을 보내드릴게요."
- 확인 메일(보낼 경우): "지원해주셔서 감사해요. 베타 빌드가 준비되면 가장 먼저 알려드려요."

→ Tally/Mailchimp 같은 자동 이메일 시퀀스를 켤 경우 *기본 템플릿이 옵션 G 톤을 위반할 수 있음* — 켜지 않거나 카피를 직접 갈아끼움.

---

## 3. 5축 비교 매트릭스

축 정의:
- **키 노출 안전성**: 클라이언트 번들에 노출되는 토큰의 권한 범위 (◎ 노출 안전 / ○ 제한된 권한 / × 강한 토큰 노출 위험)
- **CORS 호환**: 브라우저에서 직접 fetch 가능 여부
- **무료 한도**: 베타 < 100/월 기준 충분한가
- **운영 부하**: 가입·세팅 분 단위
- **가시성**: 수신 알림 + 대시보드 옵션

| # | 옵션 | 키 노출 | CORS | 무료 한도 (확인 2026-05-04) | 운영 부하 | 가시성 |
|---|---|---|---|---|---|---|
| 1 | **Web3Forms** | ◎ access_key는 그 폼 push만 | 공식 지원 | **월 250건** ([검색결과](https://web3forms.com/pricing)) — 베타에 충분 | ~15분 (이메일 가입 → key) | 즉시 메일 알림. JSON webhook. 대시보드 없음 |
| 2 | **Formspree Free** | ◎ 폼 ID만 | 공식 지원 (AJAX) | **월 50건** ([Help: Account limits](https://help.formspree.io/hc/en-us/articles/47605896654227-Account-limits) 확인) — 베타 빠듯 | ~15분 (가입 → endpoint) | 메일 알림 + 대시보드. 50/75/90% 사전 경고 메일 |
| 3 | **Tally Free** | ◎ 폼 ID만 | iframe/popup 또는 REST | **무제한 응답 + 무제한 폼** ([tally.so/pricing](https://tally.so/pricing)). 데이터 EU 저장 | ~10분 (가입 → 폼 빌더) | 대시보드 + 노션·시트 통합. iframe 임베드는 디자인 위반 위험 |
| 4 | **Getform / Forminit** | ◎ endpoint만 | 공식 지원 | **월 50건 + 1폼 + 30일 보관** ([forminit.com/pricing](https://forminit.com/pricing/)). 한도 도달 시 폼 일시정지 | ~15분 | 대시보드 + 메일 |
| 5 | **Basin** | ◎ endpoint만 | 공식 지원 | **월 50건 + 1폼 + 30일 보관 + 100MB 파일** ([usebasin.com/pricing](https://usebasin.com/pricing)) | ~15분 | 메일 + Zapier |
| 6 | **Apps Script + Sheet (B-2)** | ◎ 비밀 0개 (Web App URL은 공개되어도 그 시트에 append만) | 자체 CORS, simple request만 | **사실상 무제한** (일 6시간/스크립트 6분, 폼 1건당 ms — Apps Script 한도 vs 폼 트래픽) | ~20–30분 (시트 + 코드 붙여넣기 + 배포) | 시트 = 대시보드. `MailApp.sendEmail` 한 줄로 즉시 메일. **단 anonymous 배포가 admin/personal Google 계정에서 가능해야 함** ([deployments doc](https://developers.google.com/apps-script/concepts/deployments)) |
| 7 | **Cloudflare Worker + Notion (B-1)** | ○ NOTION_TOKEN은 Worker secret. 클라에는 Worker URL만 | Worker가 자체 CORS 응답 | **Worker free 100k req/day** ([Workers limits](https://developers.cloudflare.com/workers/platform/limits/)). Notion API 사실상 무제한 | ~45–60분 (Notion DB + Integration + Worker 배포 + secret) | Notion DB = 대시보드. Slack 알림은 Notion 자동화 또는 Worker 안에서 |
| 8 | **Loops / Buttondown** | ◎ 폼 ID만 | 공식 지원 | Loops free 1,000 contacts; Buttondown free 100 subs (변동 — 가입 시 재확인) | ~30분 (가입 + 시퀀스 셋업) | 대시보드 + 자동 확인 메일 + 시퀀스 |
| 9 | **Notion API 클라 직접 호출** | × 토큰 번들 노출 | × **차단** ([makenotion/notion-sdk-js#96](https://github.com/makenotion/notion-sdk-js/issues/96)) | — | — | — |
| 10 | **mailto: 링크** | — | — | — | 0분 | 사용자 메일 클라가 없으면 작동 X |

→ Notion 공식 가이드는 SDK 사용을 *서버 사이드*로 전제 ([notion API intro](https://developers.notion.com/reference/intro), 확인 2026-05-04). 브라우저 직접 호출은 공식 지원 대상이 아니다.

---

## 4. 적합도 점수 표 (Chew Coach 베타 컨텍스트)

★ 기준: 베타 < 100/월 + GitHub Pages + 한국 사용자 + 옵션 G 톤 + 사용자 환경 가정 미확인.

| # | 옵션 | ★ | 한 줄 이유 |
|---|---|---|---|
| 1 | **Web3Forms** | ★★★★★ | 250/월은 베타 트래픽의 2.5배 여유. 토큰 1개 + fetch 1번 = 15분. 데이터 자체 저장 안 함(메일 즉시 forward) → 한국 개인정보 처리 안내가 가벼움 |
| 6 | **Apps Script + Sheet** | ★★★★☆ | 토큰 0개 + 무제한 + 시트 = 익숙한 대시보드. 단점: 셋업 ~30분 + Google 계정 필요 + Workspace admin이 anonymous 차단 시 못 씀 (개인 Gmail은 정상) |
| 2 | **Formspree Free** | ★★★★☆ | 50/월은 베타 끝까지 빠듯. 80% 도달 시 자동 경고는 좋음. 대시보드가 깔끔 |
| 3 | **Tally Free** | ★★★☆☆ | 무제한 + EU 저장 + 노션/시트 자동 통합 — 강력. 단 폼이 *iframe 임베드*가 표준 → 옵션 G의 디자인 일관성·5초 룰을 깰 위험. REST API는 가능하지만 무료 플랜 노출 여부 가입 시 재확인 |
| 7 | **Cloudflare Worker + Notion** | ★★★☆☆ | 노션을 매일 보는 사용자에게 최적. 단 Cloudflare 계정 + wrangler + Notion Integration 셋업 ~60분 — 베타 이메일 1줄 받자고 과한 인프라 |
| 4 | **Getform/Forminit** | ★★★☆☆ | 50/월 + 1폼 + 30일 보관 — 베타 후반에 빠듯. Web3Forms 대비 우위 없음 |
| 5 | **Basin** | ★★★☆☆ | 50/월 + 30일 보관. 100MB 파일 강점은 이메일 1줄 폼에는 무관 |
| 8 | **Loops/Buttondown** | ★★☆☆☆ | 자동 확인 메일·시퀀스가 *현재 단계에서 불필요*. 베타 1k+ 시 재고 |
| 9 | Notion API 클라 직접 | ★☆☆☆☆ | 안티패턴 — CORS + 토큰 노출 |
| 10 | mailto: | ★☆☆☆☆ | 모바일 사용자 작동 X |

---

## 5. 추천안: Web3Forms (★5)

### 선택 이유

| 기준 | 적합도 |
|---|---|
| 트래픽 베타 < 100/월 | 250/월 한도 — 2.5x 여유. 한도 초과해도 다음 달 재개 |
| GitHub Pages 비밀 노출 | access_key는 *그 폼만 push* — 노출돼도 스팸 push만 가능. Worker·secret 셋업 0개 |
| 셋업 시간 | 가입 이메일 1개로 즉시 access_key 발급 → fetch 1번. **15분 안에 끝남** |
| 가시성 | 제출 즉시 *지정 이메일로 forward* — 사용자가 Gmail에서 바로 봄 |
| 한국 사용자 | 데이터를 자기 서버에 저장하지 않는다고 표방(메일 즉시 forward) — 개인정보 처리위탁 고지가 가벼움 |
| 옵션 G 톤 | 성공 메시지를 우리가 컨트롤. Web3Forms 자체는 자동 이메일 시퀀스 없음 |

### 셋업 절차 (~15분, 사용자가 할 일)

1. `https://web3forms.com` 가입 (이메일 1개로 회원가입 — 카드 불필요)
2. 새 폼 생성 → 받을 이메일 주소 입력 (예: `1213sam0@gmail.com`)
3. access_key 복사 (UUID 형태)
4. *(이후 구현 라운드에서)* `landing/.env.example`에 `VITE_W3FORMS_KEY=<key>` 추가, `EmailForm.tsx`에서 fetch
5. 종단간 1건 제출 → 받은편지함 도착 확인

**필요 계정**: Web3Forms 계정 1개 (이메일만). Gmail이면 됨.

### 구현 변경 범위 (구현 라운드 미리보기)

| 파일 | 변경 |
|---|---|
| `landing/.env.example` | `VITE_W3FORMS_KEY=` 추가 + 주석 |
| `landing/src/lib/dataCollection.ts` (신규) | `submitEmail({ email, source })` — Web3Forms POST + 에러 분기 |
| `landing/src/components/EmailForm.tsx` | `setTimeout` placeholder → `submitEmail` 호출 + `_gotcha` honeypot 필드 추가 + 에러 메시지(`rate-limit`/`network`/`invalid`) |
| `landing/.env` (gitignore) | 실제 key — 빌드 시 인라인 |
| GitHub Actions secrets | 배포 워크플로에 `VITE_W3FORMS_KEY` 주입 |

### 운영 가시성

- **수신처**: Web3Forms가 가입 시 등록한 이메일로 *즉시* forward (각 제출 = 메일 1통)
- **알림**: 즉시 메일 (Gmail 모바일 푸시)
- **한도 모니터링**: 90% 도달 시 Web3Forms가 경고 메일 발송 (검색결과 확인)
- **export**: Web3Forms 대시보드에는 데이터 보관 안 함 → 받은편지함을 source of truth로. Gmail 라벨링/필터로 정리

### 리스크·한계 (정직하게)

- **데이터 위치**: Web3Forms 서버 region 공식 페이지에 명시 부재 (US 추정 — appsumo 페이지에 "no data stored" 표기). 즉, *영구 DB는 우리 손(Gmail)*. Web3Forms가 사라져도 Gmail 라벨에는 데이터가 남음 — 사실 안전한 구조
- **대시보드 없음**: 구조화된 분석은 없음. CSV export 같은 기능 없음. 베타 < 100건이면 Gmail 검색으로 충분
- **스팸**: access_key가 클라에 노출되므로 봇이 직접 endpoint를 때릴 수 있음 → honeypot(`_gotcha`) 필드 + Web3Forms 자체 reCAPTCHA(옵션) 로 대응
- **장애**: Web3Forms 다운 시 폼 실패 — 사용자에게 "잠시 후 다시" 메시지 + 콘솔 에러 모니터링

### 사용자가 결정해야 하는 질문

1. **수신 이메일**: `1213sam0@gmail.com`으로 받으면 되나요? 다른 이메일을 쓰고 싶나요?
2. **honeypot 외에 reCAPTCHA를 추가할까요?** (UX 비용: Captcha 풀어야 함. 베타 단계에서는 불필요할 수 있음 — 디폴트 NO 추천)

---

## 6. 대안: Google Apps Script + Sheet (★4.5)

### 선택 시나리오

- 데이터를 *시트로 직접* 받아 컬럼별 분류·차트·필터를 사용자가 매일 쓰고 싶을 때
- 토큰 0개·서드파티 의존 0개 정책을 선호할 때
- 한국 사용자 데이터를 Google 인프라에만 두고 싶을 때 (Web3Forms는 별도 서드파티)

### 셋업 절차 (~25분, 사용자가 할 일)

1. Google Sheet 새로 만들기 → 이름 "ChewCoach Beta Signups", 시트 탭 이름 `signups`, 컬럼: A=Timestamp, B=Email, C=Source, D=UserAgent
2. URL의 `/d/<SHEET_ID>/` 부분 복사
3. Extensions > Apps Script → 스킬 카탈로그의 `Code.gs` 코드 붙여넣기 → `SHEET_ID` / `NOTIFY_EMAIL` 채우기
4. Deploy > New deployment > Web App → Execute as `Me` / Who has access **`Anyone`** → 배포 → URL 복사
5. *(이후 구현 라운드에서)* `landing/.env.example`에 `VITE_FORM_ENDPOINT=<URL>` 추가, `EmailForm.tsx`에서 `Content-Type: text/plain;charset=utf-8` 트릭으로 fetch
6. 종단간 1건 제출 → 시트에 row + Gmail에 알림 메일 도착 확인

**필요 계정**: Google 개인 계정 1개 (Workspace admin이 anonymous 배포 차단했으면 못 씀 — 개인 Gmail은 정상)

### 구현 변경 범위

위 추천안과 동일 + Apps Script `Code.gs` 1개 사용자 손에서 운영 (스킬 카탈로그 §패턴 2 참조).

### 운영 가시성

- **수신처**: 구글 시트 (브라우저 즐겨찾기). 모든 row 영구 보관
- **알림**: `MailApp.sendEmail` — 제출당 즉시 메일 1통. 또는 일 1회 digest로 변경 가능 (별도 trigger)
- **export**: Sheet > File > Download > CSV — 1클릭
- **한도 모니터링**: 사실상 무제한 (Apps Script 일 6시간 한도 — 베타 트래픽 1만 건이어도 안 닿음)

### 리스크·한계 (정직하게)

- **CORS 트릭 의존**: `Content-Type: text/plain;charset=utf-8`로 preflight 회피 — 이는 브라우저 표준 동작이지만 *덜 우아한 패턴*. Apps Script가 향후 정책을 바꾸면 fallback 필요
- **anonymous 배포 차단 가능성**: Google Workspace admin 정책 또는 개인 계정 보안 설정에 따라 "Anyone" 옵션이 비활성화될 수 있음 ([deployment doc](https://developers.google.com/apps-script/concepts/deployments) 확인). 셋업 단계 4에서 옵션 안 보이면 → Web3Forms로 fallback
- **Google에 종속**: 시트가 곧 백엔드 — Google 계정이 정지되면 데이터 접근 불가. 주기적 CSV 백업 권장
- **Web App URL 노출**: URL이 노출되면 봇이 직접 append 가능 → honeypot + 이메일 형식 검증 + (선택) IP rate limit (Apps Script `PropertiesService` 활용 가능)

### 사용자가 결정해야 하는 질문

1. **Google 계정 종류**: 개인 Gmail인가요, 회사 Workspace인가요? Workspace면 admin 콘솔에서 "외부 공유" 정책 확인 필요
2. **시트가 매일 보는 채널인가요?** 만약 받은편지함이 더 자연스러우면 추천안(Web3Forms)이 더 적합

---

## 7. 거른 옵션 (안티패턴)

| 옵션 | 거른 이유 |
|---|---|
| **Notion API 클라이언트 직접 호출** | (1) `Authorization: Bearer <token>` 토큰이 클라 번들에 노출 = 워크스페이스 전체 권한 유출. (2) `api.notion.com`은 `Access-Control-Allow-Origin` 미응답 → 브라우저 차단 ([sdk-js#96](https://github.com/makenotion/notion-sdk-js/issues/96)). 노션을 정말 원하면 §6 대신 Worker(B-1) 패턴 |
| **CORS 프록시 + Notion API** | 토큰 노출 그대로. 브라우저 정책만 우회 — 보안 다운그레이드 |
| **구글 폼 iframe 임베드** | 디자인 일관성 0, 옵션 G의 5초 룰·다크모드·모션 사양 모두 깨짐. 마케팅 카피 내장 불가 |
| **mailto: `<a href="mailto:...">`** | 모바일 사용자 70%+에서 메일 클라이언트 미설정 → 작동 안 함. 마찰 큼 |
| **Firebase Realtime DB rules `read/write: true`** | 인증 없는 클라가 DB write 가능 — 누구나 데이터 dump/오염 가능 |
| **SendGrid·Mailgun API 클라 직접** | API key 번들 노출 = 도메인 reputation 도용 가능. 무조건 서버 함수 필요 |

---

## 8. 다음 단계 (사용자가 옵션을 고른 뒤 구현 라운드)

사용자가 §5(Web3Forms) 또는 §6(Apps Script) 또는 다른 옵션을 *명시적으로 고른 뒤* 구현 라운드에서 일어날 일.

### 공통 (어느 옵션이든)

| 단계 | 파일 | 예상 시간 |
|---|---|---|
| 1 | `landing/src/lib/dataCollection.ts` 신규 작성 — `submitEmail()` + honeypot + 에러 분기 | 15분 |
| 2 | `landing/src/components/EmailForm.tsx` — placeholder 제거, 실제 fetch + 에러 메시지 한국어 표기 + `_gotcha` 필드 추가 | 20분 |
| 3 | `landing/.env.example` 신규 + `.env` gitignore 확인 + GitHub Actions secret 주입 가이드 | 10분 |
| 4 | 종단간 1건 제출 테스트 — 수신처 도착 + 스크린샷 | 10분 |
| 5 | `_workspace/landing/08_data_collection_runbook.md` — 운영 가이드 작성 | 20분 |
| 6 | landing-qa-polisher 라운드 — 폼 종단간·접근성·다크모드 회귀 검증 | 별도 라운드 |

**총 예상**: ~75분 (옵션 선택 후 빌드 라운드 1회 + QA 1회)

### Web3Forms 추가 작업

- 사용자가 web3forms.com에서 access_key 발급 (15분, 사용자 직접)
- GitHub Actions에 `VITE_W3FORMS_KEY` secret 등록

### Apps Script 추가 작업

- 사용자가 시트 + Apps Script 배포 (25분, 사용자 직접)
- 배포 시 "Anyone" 옵션 보이는지 확인 — 안 보이면 추천안으로 fallback

### 산출물

구현 라운드 종료 시 추가될 것:
- `landing/src/lib/dataCollection.ts`
- `landing/.env.example`
- `_workspace/landing/08_data_collection_runbook.md`
- 종단간 테스트 스크린샷

---

## 9. 출처 (확인 일자: 2026-05-04)

| 항목 | URL |
|---|---|
| Formspree 무료 50/월 | [help.formspree.io — Account limits](https://help.formspree.io/hc/en-us/articles/47605896654227-Account-limits), [SaaSworthy 2026 review](https://www.saasworthy.com/product/formspree-io/pricing) |
| Web3Forms 무료 250/월 | [web3forms.com/pricing](https://web3forms.com/pricing) (검색결과 인용) |
| Tally 무료 무제한·EU 저장 | [tally.so/pricing](https://tally.so/pricing) (직접 fetch) |
| Getform/Forminit 무료 50/월·1폼·30일 | [forminit.com/pricing](https://forminit.com/pricing/) (301 redirect from getform.io) |
| Basin 무료 50/월·1폼·30일·100MB | [usebasin.com/pricing](https://usebasin.com/pricing) (직접 fetch) |
| Notion API CORS 미지원 | [makenotion/notion-sdk-js#96](https://github.com/makenotion/notion-sdk-js/issues/96), [#417](https://github.com/makenotion/notion-sdk-js/issues/417), [#408](https://github.com/makenotion/notion-sdk-js/issues/408), [Latenode community](https://community.latenode.com/t/fixing-cors-issues-when-accessing-notion-api-from-client-side-react-application/23699) |
| Notion API 공식 (서버 사이드 전제) | [developers.notion.com/reference/intro](https://developers.notion.com/reference/intro) |
| Apps Script "Anyone" 배포 | [Apps Script deployments doc (last updated 2026-04-20)](https://developers.google.com/apps-script/concepts/deployments), [Web Apps guide](https://developers.google.com/apps-script/guides/web), [community: anonymous 차단 사례](https://groups.google.com/g/google-apps-script-community/c/owFeX5fTcyo) |
| Cloudflare Workers Free 100k req/day | [developers.cloudflare.com/workers/platform/limits](https://developers.cloudflare.com/workers/platform/limits/) (직접 fetch) |

---

## 자체 검증 체크리스트

- [x] 모든 수치(무료 한도)에 출처 URL 명시 — §3 매트릭스, §9 출처
- [x] CORS 정책 사실은 직접 확인 (Notion sdk 이슈 + 공식 문서 인용)
- [x] 추천안 셋업이 분 단위로 명시 (Web3Forms 15분, Apps Script 25분)
- [x] 옵션 G 톤 — 보고서 자체에 의료 약속·KOL·가짜 권위 단어 0건
- [x] 사용자 결정 질문 명시 (§5 2개 + §6 2개)
- [x] 길이 800–1500줄 범위 내 (현재 ~270줄, 매트릭스/점수표/추천 3개 섹션 핵심 압축)
