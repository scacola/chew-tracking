import { Section } from '../components/Section'
import { Container } from '../components/Container'
import { Clock } from '../components/Clock'
import { useCopy } from '../hooks/useCopy'

export function Problem() {
  const copy = useCopy()

  return (
    <Section tone="warm" paddingY="xl" id="problem">
      <Container size="narrow">
        <h2
          data-reveal
          className="text-heading-1 lg:text-display-lg text-center text-text-primary"
          style={{ fontWeight: 700, letterSpacing: '-0.02em' }}
        >
          {copy.problem.title.map((line, i) => (
            <span key={line}>
              {i > 0 && <br />}
              {line}
            </span>
          ))}
        </h2>

        <div data-reveal className="mt-12 lg:mt-16" style={{ ['--i' as never]: 1 }}>
          <div className="space-y-5 text-body-lg leading-relaxed text-text-secondary">
            {copy.problem.paragraphs.map((paragraph, i) => (
              <p key={paragraph} className={i === copy.problem.paragraphs.length - 1 ? 'text-text-primary' : undefined}>
                {paragraph}
              </p>
            ))}
          </div>
        </div>

        {/* 시계 비교 */}
        <div
          data-reveal
          className="mt-16 grid grid-cols-2 gap-6 md:gap-12"
          style={{ ['--i' as never]: 2 }}
        >
          {copy.problem.clocks.map((clock) => (
            <Clock
              key={clock.label}
              minutes={clock.minutes}
              target={clock.target}
              variant={clock.variant}
              label={clock.label}
            />
          ))}
        </div>

        {/* 의학 근거 카드 2 */}
        <div
          data-reveal-stagger
          className="mt-16 grid gap-4 md:grid-cols-2 md:gap-6"
        >
          {copy.problem.evidence.map((item) => (
            <div key={item.source} data-reveal className="rounded-xl border-l-4 border-coaching bg-bg-cool p-6 shadow-sm">
              <p className="text-heading-3 leading-snug text-text-primary">
                {item.text}{' '}
                <span className="text-coaching-deep">{item.accent}</span>
              </p>
              <p className="mt-3 text-caption text-text-muted">{item.source}</p>
            </div>
          ))}
        </div>

        {/* 페르소나 트리거 3줄 */}
        <div
          data-reveal-stagger
          className="mt-16 space-y-5"
        >
          {copy.problem.quotes.map((item, i) => (
            <blockquote
              key={i}
              data-reveal
              className="border-l-2 border-coaching-soft pl-5 md:pl-6"
            >
              <p
                className="text-quote-display leading-relaxed text-text-primary"
                style={{ fontFamily: 'var(--font-serif)', fontStyle: 'italic' }}
              >
                "{item.quote}"
              </p>
              <footer className="mt-2 text-caption text-text-muted">— {item.label}</footer>
            </blockquote>
          ))}
        </div>

        {/* 닫는 1줄 */}
        <p
          data-reveal
          className="mt-16 text-center text-heading-3 text-text-primary lg:text-heading-2"
          style={{ ['--i' as never]: 1, fontWeight: 600 }}
        >
          {copy.problem.closing}
        </p>
      </Container>
    </Section>
  )
}
