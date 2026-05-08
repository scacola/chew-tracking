import { Headphones, Activity, Sparkles } from 'lucide-react'
import { Section } from '../components/Section'
import { Container } from '../components/Container'
import { useCopy } from '../hooks/useCopy'

const iconMap = [Headphones, Activity, Sparkles]

const accentMap = {
  clinical: { ring: 'ring-clinical-soft', icon: 'text-clinical-deep', label: 'text-clinical-deep' },
  cta: { ring: 'ring-cta-soft', icon: 'text-cta', label: 'text-cta' },
  coaching: { ring: 'ring-coaching-soft', icon: 'text-coaching-deep', label: 'text-coaching-deep' },
}

export function Solution() {
  const copy = useCopy()

  return (
    <Section tone="cool" paddingY="xl" id="solution">
      <Container>
        <h2
          data-reveal
          className="text-heading-1 lg:text-display-lg text-center text-text-primary"
          style={{ fontWeight: 700, letterSpacing: '-0.02em' }}
        >
          {copy.solution.title}
        </h2>

        <div data-reveal-stagger className="mt-16 grid gap-6 md:grid-cols-3 md:gap-8">
          {copy.solution.cards.map((card, index) => {
            const Icon = iconMap[index] ?? Sparkles
            const a = accentMap[card.accent]
            return (
              <div
                key={card.header}
                data-reveal
                className="group relative flex flex-col gap-5 rounded-2xl border border-line bg-bg-cool p-7 transition-all duration-300 hover:-translate-y-1 hover:shadow-lg md:p-8"
              >
                <div
                  className={`flex h-12 w-12 items-center justify-center rounded-xl ring-1 ${a.ring} bg-bg-mist ${a.icon}`}
                >
                  <Icon size={24} strokeWidth={1.6} />
                </div>
                <p className={`text-label uppercase tracking-wide ${a.label}`}>{card.label}</p>
                <h3 className="text-heading-2 text-text-primary" style={{ fontWeight: 700 }}>
                  {card.header}
                </h3>
                <p className="text-body leading-relaxed text-text-secondary">
                  {card.body.map((line) => (
                    <span key={line}>
                      {line}
                      <br />
                    </span>
                  ))}
                  {card.highlight && (
                    <span className={card.accent === 'cta' ? 'text-text-primary font-medium' : 'text-text-muted'}>
                      {card.highlight}
                    </span>
                  )}
                </p>
              </div>
            )
          })}
        </div>
      </Container>
    </Section>
  )
}
