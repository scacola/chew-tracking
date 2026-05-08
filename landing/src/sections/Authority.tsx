import { Section } from '../components/Section'
import { Container } from '../components/Container'
import { StatusChip } from '../components/StatusChip'
import { useCopy } from '../hooks/useCopy'

export function Authority() {
  const copy = useCopy()

  return (
    <Section tone="mist" paddingY="xl" id="authority">
      <Container size="narrow">
        <h2
          data-reveal
          className="text-heading-1 lg:text-display-lg text-center text-text-primary"
          style={{ fontWeight: 700, letterSpacing: '-0.02em' }}
        >
          {copy.trust.title[0]}
          <br className="md:hidden" /> {copy.trust.title[1]}
        </h2>

        <div data-reveal-stagger className="mt-12 space-y-5 lg:mt-16">
          {copy.trust.cards.map((card) => (
            <div
              key={card.title}
              data-reveal
              className="rounded-2xl border border-line bg-bg-cool p-7 transition-shadow hover:shadow-md md:p-8"
            >
              <div className="mb-4 flex items-center gap-3">
                <StatusChip status={card.status} label={card.statusLabel} />
                <h3 className="text-heading-3 text-text-primary" style={{ fontWeight: 700 }}>
                  {card.title}
                </h3>
              </div>
              <p className="text-body leading-relaxed text-text-secondary">
                {card.body.map((line, i) => (
                  <span
                    key={line}
                    className={i === 1 && card.status === 'beta' ? 'font-medium text-text-primary' : undefined}
                  >
                    {i > 0 && <br />}
                    {i === card.body.length - 1 && card.status === 'inProgress' ? (
                      <em className="not-italic text-text-muted">{line}</em>
                    ) : (
                      line
                    )}
                  </span>
                ))}
              </p>
              {card.progress && (
                <div className="mt-5 flex items-center gap-3">
                  <span className="text-caption text-text-muted">{card.progress.label}</span>
                  <div className="h-1.5 flex-1 overflow-hidden rounded-full bg-line">
                    <div
                      className="h-full rounded-full bg-clinical transition-[width] duration-1000 ease-reveal"
                      style={{ width: `${card.progress.percent}%` }}
                    />
                  </div>
                  <span className="text-caption font-mono text-clinical-deep">{card.progress.percent}%</span>
                </div>
              )}
              {card.bullets && (
                <ul className="mt-5 space-y-3 text-body-sm text-text-secondary">
                  {card.bullets.map((bullet) => (
                    <li key={bullet} className="flex items-start gap-3">
                      <span className="mt-1 inline-block h-1.5 w-1.5 shrink-0 rounded-full bg-clinical" />
                      <span>{bullet}</span>
                    </li>
                  ))}
                </ul>
              )}
            </div>
          ))}
        </div>

        {/* 닫는 메시지 */}
        <p
          data-reveal
          className="mx-auto mt-16 max-w-prose-narrow text-center text-body-lg leading-relaxed text-text-secondary"
        >
          <span className="font-medium text-text-primary">{copy.trust.closing[0]}</span>
          <br />
          <span className="font-medium text-text-primary">{copy.trust.closing[1]}</span>
        </p>
      </Container>
    </Section>
  )
}
