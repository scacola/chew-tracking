import { Section } from '../components/Section'
import { Container } from '../components/Container'
import { EmailForm } from '../components/EmailForm'
import { eightWeeksFromNowKR } from '../lib/eightWeekDate'
import { CtaSecondary } from '../components/CtaSecondary'

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
            사용해보시고 느낀 점을 주시면 다음 업데이트에 반영할게요.
            <br />
          </p>
          <div className="mt-5">
            <p className="mb-3 text-caption text-text-on-deep/65">
              피드백은 오픈채팅으로 편하게 보내주세요.
            </p>
            <CtaSecondary
              href="https://open.kakao.com/o/sH35Fxti"
              label="오픈채팅으로 피드백 보내기"
              className="text-text-on-deep/90 hover:text-text-on-deep"
            />
          </div>
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
