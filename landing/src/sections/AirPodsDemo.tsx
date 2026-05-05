import { Section } from '../components/Section'
import { Container } from '../components/Container'
import { AirpodsSvg } from '../components/icons/AirpodsSvg'
import { DataStream } from '../components/DataStream'
import { HealthScoreGauge } from '../components/HealthScoreGauge'

const streamRows = [
  { time: '12:32:08', label: '식사 시작 검출' },
  { time: '12:32:18', label: '씹기 패턴: 1.2초/회' },
  { time: '12:33:42', label: '속도: 빠름 → 평균', emphasis: true },
  { time: '12:39:47', label: '식사 종료 (총 7분 39초)' },
]

export function AirPodsDemo() {
  return (
    <Section tone="deep" paddingY="xl" id="airpods-demo">
      <Container>
        <div className="grid gap-12 lg:grid-cols-[1.1fr_1fr] lg:gap-16">
          {/* 좌: 카피 + AirPods */}
          <div className="flex flex-col gap-8">
            <div data-reveal className="flex flex-col gap-3">
              <p className="text-label uppercase tracking-wider text-clinical-soft">
                Signature
              </p>
              <h2
                className="text-heading-1 lg:text-display-lg text-text-on-deep"
                style={{ fontWeight: 700, letterSpacing: '-0.02em' }}
              >
                이미 끼고 있는 그것이,
                <br />
                식사를 보고 있어요.
              </h2>
              <p className="text-body-lg text-text-on-deep/75">
                AirPods의 모션 센서가 식사 동작을 잡아내면,
                <br />
                그 데이터가 매일 식사 속도 요약으로 정리돼요.
                <br />
                중요한 건 정확한 숫자보다도, 오늘과 어제의 차이를 보는 일이에요.
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
              <DataStream rows={streamRows} finale={{ score: 72, change: 3 }} />
            </div>

            <div
              data-reveal
              className="flex justify-center rounded-xl border border-line/30 bg-bg-cool/5 p-6"
              style={{ ['--i' as never]: 1 }}
            >
              <HealthScoreGauge score={72} change={3} size={220} />
            </div>
          </div>
        </div>
      </Container>
    </Section>
  )
}
