import { Section } from '../components/Section'
import { Container } from '../components/Container'
import { CalendarMini } from '../components/CalendarMini'
import { AirpodsSvg } from '../components/icons/AirpodsSvg'
import { useCopy } from '../hooks/useCopy'

export function HowItWorks() {
  const copy = useCopy()

  return (
    <Section tone="warm" paddingY="xl" id="how-it-works">
      <Container>
        <h2
          data-reveal
          className="text-heading-1 lg:text-display-lg text-center text-text-primary"
          style={{ fontWeight: 700, letterSpacing: '-0.02em' }}
        >
          {copy.how.title[0]}
          <br className="hidden md:inline" /> {copy.how.title[1]}
        </h2>

        <div data-reveal-stagger className="mt-16 grid gap-8 lg:grid-cols-3 lg:gap-10">
          {/* 컬럼 A — 28일 코스 */}
          <div data-reveal className="flex flex-col gap-5 rounded-2xl border border-line bg-bg-cool p-7">
            <h3 className="text-heading-3 text-text-primary" style={{ fontWeight: 700 }}>
              {copy.how.columns[0].title}
            </h3>
            <CalendarMini completedDays={7} />
            <ul className="space-y-2.5 text-body-sm text-text-secondary">
              {copy.how.columns[0].items?.map((item) => (
                <li key={item.label}>
                  <span className="font-medium text-text-primary">{item.label}</span> — {item.text}
                </li>
              ))}
            </ul>
          </div>

          {/* 컬럼 B — AirPods 자동 트래킹 */}
          <div data-reveal className="flex flex-col gap-5 rounded-2xl border border-line bg-bg-cool p-7">
            <h3 className="text-heading-3 text-text-primary" style={{ fontWeight: 700 }}>
              {copy.how.columns[1].title}
            </h3>
            <div className="flex justify-center">
              <div className="w-[180px]">
                <AirpodsSvg state="pulse" />
              </div>
            </div>
            <p className="text-body-sm leading-relaxed text-text-secondary">
              {copy.how.columns[1].body?.map((line, i) => (
                <span key={line}>
                  {i > 0 && <br />}
                  {line}
                </span>
              ))}
            </p>
            <div className="flex flex-wrap gap-2">
              {copy.how.columns[1].chips?.map((m) => (
                <span
                  key={m}
                  className="rounded-full border border-clinical/30 bg-clinical/8 px-3 py-1 text-caption text-clinical-deep"
                >
                  {m}
                </span>
              ))}
            </div>
          </div>

          {/* 컬럼 C — 친근한 한국 코치 페르소나 */}
          <div data-reveal className="flex flex-col gap-5 rounded-2xl border border-line bg-bg-cool p-7">
            <h3 className="text-heading-3 text-text-primary" style={{ fontWeight: 700 }}>
              {copy.how.columns[2].title}
            </h3>
            <div className="rounded-xl border border-coaching-soft/60 bg-coaching-soft/15 p-5">
              <p
                className="text-body leading-relaxed text-text-primary"
                style={{ fontFamily: 'var(--font-serif)', fontStyle: 'italic' }}
              >
                {copy.how.columns[2].quote?.map((line, i) => (
                  <span key={line}>
                    {i > 0 && <br />}
                    {line}
                  </span>
                ))}
              </p>
              <p className="mt-3 text-caption text-coaching-deep">{copy.how.columns[2].quoteFooter}</p>
            </div>
            <p className="text-body-sm leading-relaxed text-text-secondary">
              {copy.how.columns[2].body?.map((line, i) => (
                <span key={line}>
                  {i > 0 && <br />}
                  {line}
                </span>
              ))}
            </p>
          </div>
        </div>

        <p
          data-reveal
          className="mt-16 text-center text-heading-3 text-text-primary lg:text-heading-2"
          style={{ fontWeight: 600 }}
        >
          {copy.how.closing}
        </p>
      </Container>
    </Section>
  )
}
