import { Section } from '../components/Section'
import { Container } from '../components/Container'
import { EmailForm } from '../components/EmailForm'
import { eightWeeksFromNowKR } from '../lib/eightWeekDate'
import { CtaPrimary } from '../components/CtaPrimary'
import { useCopy } from '../hooks/useCopy'
import { purposeCopyJa } from '../data/copy/purpose'
import {
  consentDialogCopyJa,
  errorCopyJa,
  successCopyJa,
} from '../data/copy/consent'

export function FinalCTA() {
  const copy = useCopy()
  const dateLabel = eightWeeksFromNowKR()
  const isJa = copy.locale === 'ja'

  return (
    <Section tone="deep" paddingY="xl" id="final-cta">
      <Container size="narrow">
        <h2
          data-reveal
          className="text-heading-1 lg:text-display-lg text-center text-text-on-deep"
          style={{ fontWeight: 700, letterSpacing: '-0.02em' }}
        >
          {copy.finalCta.title.map((line) => (
            <span key={line} className="block">
              {line}
            </span>
          ))}
          {!isJa && (
            <span className="block">
              {copy.finalCta.datePrefix} <span className="text-clinical-soft">{dateLabel}</span>에 도착해요.
            </span>
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
            {copy.finalCta.letter.map((line) => (
              <span key={line} className="block">
                {line}
              </span>
            ))}
          </p>
          {!isJa && <div className="mt-5">
            <CtaPrimary
              href="https://open.kakao.com/o/sH35Fxti"
              label="오픈채팅으로 피드백 보내기"
              size="md"
              className="w-fit bg-text-on-deep/10 text-text-on-deep shadow-none ring-1 ring-inset ring-text-on-deep/18 hover:bg-text-on-deep/16 hover:shadow-none"
            />
          </div>}
        </div>

        {/* 폼 */}
        <div
          data-reveal
          className="mx-auto mt-10 max-w-prose-narrow rounded-2xl bg-bg-cool p-6 md:p-8"
          style={{ ['--i' as never]: 2 }}
        >
          <EmailForm
            variant="stacked"
            ctaLabel={copy.finalCta.formCta}
            placeholder={copy.finalCta.formPlaceholder}
            helperText={copy.finalCta.formHelper}
            source="final_cta"
            purposeCopy={isJa ? purposeCopyJa : undefined}
            consentCopy={isJa ? consentDialogCopyJa : undefined}
            successCopy={isJa ? successCopyJa : undefined}
            errorCopy={isJa ? errorCopyJa : undefined}
            submittingLabel={copy.form.submitting}
          />
        </div>
      </Container>
    </Section>
  )
}
