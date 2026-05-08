import { Section } from '../components/Section'
import { Container } from '../components/Container'
import { EmailForm } from '../components/EmailForm'
import { eightWeeksFromNowKR } from '../lib/eightWeekDate'
import { useCopy } from '../hooks/useCopy'

export function FinalCTA() {
  const dateLabel = eightWeeksFromNowKR()
  const copy = useCopy()

  return (
    <Section tone="deep" paddingY="xl" id="final-cta">
      <Container size="narrow">
        <h2
          data-reveal
          className="text-heading-1 lg:text-display-lg text-center text-text-on-deep"
          style={{ fontWeight: 700, letterSpacing: '-0.02em' }}
        >
          {copy.finalCta.title.map((line, i) => (
            <span key={line}>
              {i > 0 && <br />}
              {line}
            </span>
          ))}
          {copy.finalCta.datePrefix && (
            <>
              <br />
              {copy.finalCta.datePrefix}{' '}
              <span className="text-clinical-soft">{dateLabel}</span>에 도착해요.
            </>
          )}
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
            {copy.finalCta.letter.map((line, i) => (
              <span key={line}>
                {i > 0 && <br />}
                {line}
              </span>
            ))}
          </p>
        </div>

        {/* 폼 */}
        <div
          data-reveal
          className="mx-auto mt-10 max-w-prose-narrow rounded-2xl bg-bg-cool p-6 md:p-8"
          style={{ ['--i' as never]: 2 }}
        >
          <EmailForm
            variant="inline"
            ctaLabel={copy.finalCta.formCta}
            placeholder={copy.finalCta.formPlaceholder}
            helperText={copy.finalCta.formHelper}
          />
          {copy.finalCta.pricingLink && (
            <p className="mt-4 text-center text-caption text-text-muted">
              {copy.finalCta.pricingLink.prefix}{' '}
              <a
                href="#pricing"
                onClick={(e) => {
                  e.preventDefault()
                  document.getElementById('pricing')?.scrollIntoView({ behavior: 'smooth' })
                }}
                className="font-medium text-text-primary underline-offset-4 hover:underline"
              >
                {copy.finalCta.pricingLink.label}
              </a>
            </p>
          )}
        </div>
      </Container>
    </Section>
  )
}
