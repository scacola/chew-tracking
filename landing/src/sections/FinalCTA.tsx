import { Section } from '../components/Section'
import { Container } from '../components/Container'
import { EmailForm } from '../components/EmailForm'
import { eightWeeksFromNowKR } from '../lib/eightWeekDate'
import { track } from '../lib/analytics'

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
          8주 후의 위, 8주 후의 식사 속도, 8주 후의 검진 결과.
          <br />
          오늘 시작하면, 그게{' '}
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
            베타 합류는 무료예요.
            <br />
            정식 출시 시점에 50% 평생 할인이 적용돼요.
            <br />
            1만 명이 합류했다고 거짓말하지 않아요. 지금은 우리가 함께 걸을 첫 사람들을 모으고 있어요.
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
            ctaLabel="베타에 합류하기"
            placeholder="이메일 주소"
            helperText="개인정보는 진행 소식 외에는 사용하지 않아요."
            source="final_cta"
          />
          <p className="mt-4 text-center text-caption text-text-muted">
            구독 부담 없이 한 번만? —{' '}
            <a
              href="#pricing"
              onClick={(e) => {
                e.preventDefault()
                track('cta_click', {
                  cta_id: 'final_cta_single_link',
                  source: 'final_cta',
                  target: 'scroll',
                  section_id: 'final_cta',
                })
                document.getElementById('pricing')?.scrollIntoView({ behavior: 'smooth' })
              }}
              className="font-medium text-text-primary underline-offset-4 hover:underline"
            >
              28일 코스 단품 19,900원
            </a>
          </p>
        </div>
      </Container>
    </Section>
  )
}
