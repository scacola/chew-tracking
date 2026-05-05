import { Section } from '../components/Section'
import { Container } from '../components/Container'
import { EmailForm } from '../components/EmailForm'
import { eightWeeksFromNowKR } from '../lib/eightWeekDate'

export function FinalCTA() {
  const dateLabel = eightWeeksFromNowKR()

  return (
    <Section tone="deep" paddingY="xl" id="final-cta">
      <Container size="narrow">
        <h2
          data-reveal
          className="text-heading-1 lg:text-display-lg text-center text-text-on-deep"
          style={{ fontWeight: 700, letterSpacing: '-0.02em' }}
        >
          8주 후에는 식사 속도와
          <br />
          식사 리듬이 어떻게 달라졌는지 보이기 시작해요.
          <br />
          오늘 시작하면, 그 흐름이{' '}
          <span className="text-clinical-soft">{dateLabel}</span>에 도착해요.
        </h2>

        {/* 손편지 박스 (R3) */}
        <div
          data-reveal
          className="mx-auto mt-10 max-w-prose-narrow rounded-xl border-l border-coaching-soft bg-text-on-deep/5 p-6 md:p-8"
          style={{ ['--i' as never]: 1 }}
        >
          <p
            className="text-body-lg leading-relaxed text-text-on-deep/85"
            style={{ fontFamily: 'var(--font-serif)', fontStyle: 'italic', fontWeight: 400 }}
          >
            지금은 베타 단계예요.
            <br />
            피드백 주시면 바로 반영할게요.
            <br />
            아래 오픈채팅으로 연락 주세요.
          </p>
          <p className="mt-4 text-body-sm text-text-on-deep/75">
            <a
              href="https://open.kakao.com/o/sH35Fxti"
              target="_blank"
              rel="noreferrer"
              className="font-medium underline underline-offset-4 hover:text-text-on-deep"
            >
              https://open.kakao.com/o/sH35Fxti
            </a>
          </p>
        </div>

        {/* 폼 */}
        <div
          data-reveal
          className="mx-auto mt-10 max-w-prose-narrow rounded-2xl bg-bg-cool p-6 md:p-8"
          style={{ ['--i' as never]: 2 }}
        >
          <EmailForm
            variant="stacked"
            ctaLabel="업데이트 받기"
            placeholder="이메일 주소"
            helperText="개인정보는 진행 소식 외에는 사용하지 않아요."
            source="final_cta"
          />
        </div>
      </Container>
    </Section>
  )
}
