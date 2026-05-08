import { Section } from '../components/Section'
import { Container } from '../components/Container'
import { Calendar, Sparkles, Activity, Heart } from 'lucide-react'
import { useCopy } from '../hooks/useCopy'

const iconMap = [Calendar, Sparkles, Activity, Heart]

const accentMap = {
  clinical: 'text-clinical-deep bg-clinical-soft/40',
  cta: 'text-cta bg-cta-soft/60',
  coaching: 'text-coaching-deep bg-coaching-soft/50',
}

export function Differentiation() {
  const copy = useCopy()

  return (
    <Section tone="cool" paddingY="xl" id="differentiation">
      <Container>
        <h2
          data-reveal
          className="text-heading-1 lg:text-display-lg text-center text-text-primary"
          style={{ fontWeight: 700, letterSpacing: '-0.02em' }}
        >
          {copy.differentiation.title[0]}
          <br className="hidden md:inline" /> {copy.differentiation.title[1]}
        </h2>

        {/* 큰 2 + 작은 2 그리드 */}
        <div data-reveal-stagger className="mt-16 grid gap-5 md:grid-cols-2 lg:grid-cols-4">
          {copy.differentiation.cards.map((c, index) => {
            const Icon = iconMap[index] ?? Heart
            const isLg = c.size === 'lg'
            return (
              <div
                key={c.id}
                data-reveal
                className={`group relative flex flex-col gap-4 rounded-2xl border border-line bg-bg-cool p-6 transition-all duration-300 hover:-translate-y-1 hover:shadow-lg md:p-7 ${
                  isLg ? 'lg:col-span-2' : 'lg:col-span-1'
                }`}
              >
                <div
                  className={`flex h-11 w-11 items-center justify-center rounded-lg ${accentMap[c.accent]}`}
                >
                  <Icon size={22} strokeWidth={1.6} />
                </div>
                <h3
                  className={`${isLg ? 'text-heading-3' : 'text-heading-4'} text-text-primary`}
                  style={{ fontWeight: 700 }}
                >
                  {c.title}
                </h3>
                <p
                  className={`${isLg ? 'text-body' : 'text-body-sm'} leading-relaxed text-text-secondary`}
                >
                  {c.body}
                </p>
              </div>
            )
          })}
        </div>

        <p
          data-reveal
          className="mt-16 text-center text-heading-3 text-text-primary lg:text-heading-2"
          style={{ fontWeight: 600 }}
        >
          {copy.differentiation.closing}
        </p>
      </Container>
    </Section>
  )
}
