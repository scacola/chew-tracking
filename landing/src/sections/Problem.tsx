import { Section } from '../components/Section'
import { Container } from '../components/Container'
import { Clock } from '../components/Clock'

export function Problem() {
  return (
    <Section tone="warm" paddingY="xl" id="problem">
      <Container size="narrow">
        <h2
          data-reveal
          className="text-heading-1 lg:text-display-lg text-center text-text-primary"
          style={{ fontWeight: 700, letterSpacing: '-0.02em' }}
        >
          당신은 자신의 식사 속도를,
          <br />
          정확히는 모르고 있어요.
        </h2>

        <div data-reveal className="mt-12 lg:mt-16" style={{ ['--i' as never]: 1 }}>
          <div className="space-y-5 text-body-lg leading-relaxed text-text-secondary">
            <p>
              위염 진단을 받고 의사가{' '}
              <em className="not-italic font-medium text-text-primary">천천히 드세요</em> 라고 했을 때,
              그게 정확히 몇 분인지 알려주는 사람은 없었을 거예요.
            </p>
            <p>
              한국 직장인의 평균 점심 시간은{' '}
              <span className="font-mono font-medium text-coaching-deep">11분</span>.
              <br />
              권장 식사 시간(20분 이상)의 절반이에요.
              <br />
              그런데 정작 본인은 — <em className="not-italic">나는 적당히 먹고 있다</em> 고 느껴요.
            </p>
            <p className="text-text-primary">
              이게 위염·정체기 다이어트·식후 더부룩함의 가장 흔한 시작점이에요.
            </p>
          </div>
        </div>

        {/* 시계 비교 */}
        <div
          data-reveal
          className="mt-16 grid grid-cols-2 gap-6 md:gap-12"
          style={{ ['--i' as never]: 2 }}
        >
          <Clock minutes={11} target={20} variant="fast" label="한국 직장인 평균" />
          <Clock minutes={20} target={20} variant="target" label="권장 시간" />
        </div>

        {/* 의학 근거 카드 2 */}
        <div
          data-reveal-stagger
          className="mt-16 grid gap-4 md:grid-cols-2 md:gap-6"
        >
          <div data-reveal className="rounded-xl border-l-4 border-coaching bg-bg-cool p-6 shadow-sm">
            <p className="text-heading-3 leading-snug text-text-primary">
              빠른 식사군은 미란성 위염 위험이{' '}
              <span className="text-coaching-deep">71% 더 높아요.</span>
            </p>
            <p className="mt-3 text-caption text-text-muted">
              — Hurst & Fukuda, 위장관 연구 메타분석 (2018)
            </p>
          </div>
          <div data-reveal className="rounded-xl border-l-4 border-coaching bg-bg-cool p-6 shadow-sm">
            <p className="text-heading-3 leading-snug text-text-primary">
              빠른 식사 습관은 비만 위험을{' '}
              <span className="text-coaching-deep">2.15배</span> 높여요.
            </p>
            <p className="mt-3 text-caption text-text-muted">
              — Ohkuma et al., 식이 속도와 BMI 코호트 연구 (2015)
            </p>
          </div>
        </div>

        {/* 페르소나 트리거 3줄 */}
        <div
          data-reveal-stagger
          className="mt-16 space-y-5"
        >
          {[
            { quote: '오늘 점심도 영상 보면서 끝났어요. 시간이 얼마나 걸렸는지 모르겠어요.', label: '한지원 (위염, 32세)' },
            { quote: '운동도 했고 칼로리도 줄였는데, 왜 안 빠지는지 모르겠어요.', label: '박소연 (정체기, 34세)' },
            { quote: '내시경 받을 때마다 듣는 그 말. 어떻게 지키는지 모르겠어요.', label: '김상훈 (검진 후, 41세)' },
          ].map((item, i) => (
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
          모르는 게 문제가 아니라, 볼 수 있는 도구가 없었던 것뿐이에요.
        </p>
      </Container>
    </Section>
  )
}
