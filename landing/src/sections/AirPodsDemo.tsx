import { Section } from '../components/Section'
import { Container } from '../components/Container'
import { AirpodsSvg } from '../components/icons/AirpodsSvg'
import { DataStream } from '../components/DataStream'
import { HealthScoreGauge } from '../components/HealthScoreGauge'
import { useCopy } from '../hooks/useCopy'

export function AirPodsDemo() {
  const copy = useCopy()

  return (
    <Section tone="deep" paddingY="xl" id="airpods-demo">
      <Container>
        <div className="grid gap-12 lg:grid-cols-[1.1fr_1fr] lg:gap-16">
          {/* 좌: 카피 + AirPods */}
          <div className="flex flex-col gap-8">
            <div data-reveal className="flex flex-col gap-3">
              <p className="text-label uppercase tracking-wider text-clinical-soft">
                {copy.demo.label}
              </p>
              <h2
                className="text-heading-1 lg:text-display-lg text-text-on-deep"
                style={{ fontWeight: 700, letterSpacing: '-0.02em' }}
              >
                {copy.demo.title.map((line, i) => (
                  <span key={line}>
                    {i > 0 && <br />}
                    {line}
                  </span>
                ))}
              </h2>
              <p className="text-body-lg text-text-on-deep/75">
                {copy.demo.body.map((line, i) => (
                  <span key={line}>
                    {i > 0 && <br />}
                    {line}
                  </span>
                ))}
              </p>
            </div>

            <div
              data-reveal
              className="flex justify-center lg:justify-start"
              style={{ ['--i' as never]: 1 }}
            >
              <div className="w-[280px] sm:w-[360px]">
                <AirpodsSvg state="streaming" />
              </div>
            </div>
          </div>

          {/* 우: 데이터 스트림 + 게이지 */}
          <div className="flex flex-col gap-6">
            <div data-reveal>
              <DataStream
                rows={copy.demo.rows}
                finale={{ score: 72, change: 3 }}
                finaleLabel={copy.demo.finaleLabel}
              />
            </div>

            <div
              data-reveal
              className="flex justify-center rounded-xl border border-line/30 bg-bg-cool/5 p-6"
              style={{ ['--i' as never]: 1 }}
            >
              <HealthScoreGauge
                score={72}
                change={3}
                size={220}
                label={copy.demo.gaugeLabel}
                ariaLabel={copy.demo.gaugeAria(72, 3)}
              />
            </div>
          </div>
        </div>
      </Container>
    </Section>
  )
}
