import { Check } from 'lucide-react'
import { Section } from '../components/Section'
import { Container } from '../components/Container'
import { CtaPrimary } from '../components/CtaPrimary'
import { cn } from '../lib/cn'
import { useCopy } from '../hooks/useCopy'

export function Pricing() {
  const copy = useCopy()

  return (
    <Section tone="cool" paddingY="xl" id="pricing">
      <Container>
        <h2
          data-reveal
          className="text-heading-1 lg:text-display-lg text-center text-text-primary"
          style={{ fontWeight: 700, letterSpacing: '-0.02em' }}
        >
          {copy.pricing.title[0]}
          <br className="hidden md:inline" /> {copy.pricing.title[1]}
        </h2>

        <div
          data-reveal-stagger
          className="mt-16 grid gap-5 md:grid-cols-3 md:gap-6"
        >
          {copy.pricing.tiers.map((tier) => (
            <div
              key={tier.key}
              data-reveal
              className={cn(
                'relative flex flex-col gap-6 rounded-2xl border bg-bg-cool p-7 transition-all duration-300',
                tier.recommended
                  ? 'border-cta shadow-xl ring-1 ring-cta-soft md:-translate-y-2 md:scale-[1.03]'
                  : 'border-line hover:-translate-y-1 hover:shadow-md',
              )}
            >
              {tier.badges && (
                <div className="absolute -top-3 right-6 flex gap-2">
                  {tier.badges.map((b, i) => (
                    <span
                      key={b}
                      className={cn(
                        'rounded-full px-3 py-1 text-caption font-medium shadow-sm',
                        i === 0
                          ? 'bg-cta text-white'
                          : 'bg-clinical-soft text-clinical-deep',
                      )}
                    >
                      {b}
                    </span>
                  ))}
                </div>
              )}

              <div>
                <h3 className="text-heading-3 text-text-primary" style={{ fontWeight: 700 }}>
                  {tier.header}
                </h3>
                <div className="mt-4 flex items-baseline gap-2">
                  <span className="text-display-lg text-text-primary" style={{ fontWeight: 800 }}>
                    {tier.price}
                  </span>
                  <span className="text-body text-text-muted">{tier.period}</span>
                </div>
                {tier.strikePrice && (
                  <p className="mt-1 text-caption text-text-muted line-through">{tier.strikePrice}</p>
                )}
                {tier.helper && (
                  <p className="mt-2 text-body-sm font-medium text-clinical-deep">{tier.helper}</p>
                )}
              </div>

              <ul className="space-y-3 text-body-sm text-text-secondary">
                {tier.features.map((f) => (
                  <li key={f} className="flex items-start gap-2.5">
                    <Check
                      size={18}
                      strokeWidth={2}
                      className={cn(
                        'mt-0.5 shrink-0',
                        tier.recommended ? 'text-cta' : 'text-clinical-deep',
                      )}
                    />
                    <span>{f}</span>
                  </li>
                ))}
              </ul>

              <div className="mt-auto flex flex-col gap-3">
                <CtaPrimary
                  label={tier.cta}
                  size="md"
                  href="#final-cta"
                  onClick={() =>
                    document.getElementById('final-cta')?.scrollIntoView({ behavior: 'smooth' })
                  }
                  className={cn(!tier.recommended && 'bg-text-primary hover:bg-text-secondary')}
                  trackingName="pricing_cta_click"
                />
                <p className="text-caption text-text-muted">{tier.cancelPolicy}</p>
              </div>
            </div>
          ))}
        </div>

        {/* 가격 정당화 */}
        <div data-reveal className="mx-auto mt-12 max-w-prose-narrow text-center">
          <p className="text-body-sm leading-relaxed text-text-muted">
            {copy.pricing.note.map((line, i) => (
              <span key={line}>
                {i > 0 && <br />}
                {i === copy.pricing.note.length - 1 ? (
                  <em className="not-italic text-text-secondary">{line}</em>
                ) : (
                  line
                )}
              </span>
            ))}
          </p>
          <p className="mt-4 text-caption text-text-subtle">
            {copy.pricing.refundNote}
          </p>
        </div>
      </Container>
    </Section>
  )
}
