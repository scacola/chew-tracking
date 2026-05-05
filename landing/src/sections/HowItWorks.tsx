import { Section } from '../components/Section'
import { Container } from '../components/Container'
import { CalendarMini } from '../components/CalendarMini'
import { AirpodsSvg } from '../components/icons/AirpodsSvg'

export function HowItWorks() {
  return (
    <Section tone="warm" paddingY="xl" id="how-it-works">
      <Container>
        <h2
          data-reveal
          className="text-heading-1 lg:text-display-lg text-center text-text-primary"
          style={{ fontWeight: 700, letterSpacing: '-0.02em' }}
        >
          AirPods 자동 기록 + 짧은 코치 + 습관 리듬,
          <br className="hidden md:inline" /> 한국 친근 코치 톤, 셋이 함께.
        </h2>

        <div data-reveal-stagger className="mt-16 grid gap-8 lg:grid-cols-3 lg:gap-10">
          {/* 컬럼 A — 28일 코스 */}
          <div data-reveal className="flex flex-col gap-5 rounded-2xl border border-line bg-bg-cool p-7">
            <h3 className="text-heading-3 text-text-primary" style={{ fontWeight: 700 }}>
              28일 식사 리듬 코스
            </h3>
            <CalendarMini completedDays={7} />
            <ul className="space-y-2.5 text-body-sm text-text-secondary">
              <li>
                <span className="font-medium text-text-primary">1주차</span> — 내 식사 속도 알기. 기준 잡는 법.
              </li>
              <li>
                <span className="font-medium text-text-primary">2주차</span> — 첫 한 입과 마지막 한 입 사이를 넓히는 법.
              </li>
              <li>
                <span className="font-medium text-text-primary">3주차</span> — 패턴을 읽고, 자주 먹는 습관을 바꾸는 법.
              </li>
              <li>
                <span className="font-medium text-text-primary">4주차</span> — 유지 루틴 만들기. 하루 한 번만 돌아보기.
              </li>
            </ul>
          </div>

          {/* 컬럼 B — AirPods 자동 트래킹 */}
          <div data-reveal className="flex flex-col gap-5 rounded-2xl border border-line bg-bg-cool p-7">
            <h3 className="text-heading-3 text-text-primary" style={{ fontWeight: 700 }}>
              AirPods 자동 기록
            </h3>
            <div className="flex justify-center">
              <div className="w-[180px]">
                <AirpodsSvg state="pulse" />
              </div>
            </div>
            <p className="text-body-sm leading-relaxed text-text-secondary">
              모션 센서로 식사 동작을 감지하고, iPhone에서 식사 속도 요약으로 보여줘요.
              안드로이드는 지원 범위를 따로 검토 중이에요.
            </p>
            <div className="flex flex-wrap gap-2">
              {['Pro', '3', '4'].map((m) => (
                <span
                  key={m}
                  className="rounded-full border border-clinical/30 bg-clinical/8 px-3 py-1 text-caption text-clinical-deep"
                >
                  AirPods {m}
                </span>
              ))}
            </div>
          </div>

          {/* 컬럼 C — 친근한 한국 코치 페르소나 */}
          <div data-reveal className="flex flex-col gap-5 rounded-2xl border border-line bg-bg-cool p-7">
            <h3 className="text-heading-3 text-text-primary" style={{ fontWeight: 700 }}>
              친근한 한국 코치 카드
            </h3>
            <div className="rounded-xl border border-coaching-soft/60 bg-coaching-soft/15 p-5">
              <p
                className="text-body leading-relaxed text-text-primary"
                style={{ fontFamily: 'var(--font-serif)', fontStyle: 'italic' }}
              >
                "오늘은 8분이었어요.
                <br />
                어제보다 1분 더 천천히 드셨어요.
                <br />
                내일 점심엔 첫 한 입만 조금 늦춰볼까요?"
              </p>
              <p className="mt-3 text-caption text-coaching-deep">— 매일 받는 코치 카드 예시</p>
            </div>
            <p className="text-body-sm leading-relaxed text-text-secondary">
              차가운 데이터를 따뜻한 언어로 번역해요.
              <br />
              잔소리 대신 격려, 평가 대신 동행 — 한국 사용자의 식사 맥락에 맞춘 톤이에요.
            </p>
          </div>
        </div>

        <p
          data-reveal
          className="mt-16 text-center text-heading-3 text-text-primary lg:text-heading-2"
          style={{ fontWeight: 600 }}
        >
          AirPods만 있으면, 따로 시작할 준비는 끝나요.
        </p>
      </Container>
    </Section>
  )
}
