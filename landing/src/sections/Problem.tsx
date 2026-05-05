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
          대부분은 자신이 얼마나 빨리 먹는지
          <br />
          정확히 모른 채 식사해요.
        </h2>

        <div data-reveal className="mt-12 lg:mt-16" style={{ ['--i' as never]: 1 }}>
          <div className="space-y-5 text-body-lg leading-relaxed text-text-secondary">
            <p>
              의사가{' '}
              <em className="not-italic font-medium text-text-primary">천천히 드세요</em> 라고 해도,
              그게 실제로 몇 분인지 감으로만 넘기기 쉽죠.
            </p>
            <p>
              바쁜 점심은 금방 끝나고,
              <br />
              식사 속도는 기억보다 훨씬 빠르게 지나가요.
              <br />
              그런데 정작 본인은 — <em className="not-italic">나는 적당히 먹고 있다</em> 고 느끼기 쉬워요.
            </p>
            <p className="text-text-primary">
              그래서 먼저 필요한 건 치료가 아니라, 내 식사 리듬을 보게 해주는 도구예요.
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
              한국 성인 검진 코호트에서는
              <span className="text-coaching-deep"> 5분 미만 식사군의 미란성 위염 위험이 71% 높았어요.</span>
            </p>
            <p className="mt-3 text-caption text-text-muted">
              — 한국 성인 데이터, 빠른 식사와 위장 부담의 연결
            </p>
          </div>
          <div data-reveal className="rounded-xl border-l-4 border-coaching bg-bg-cool p-6 shadow-sm">
            <p className="text-heading-3 leading-snug text-text-primary">
              저작 횟수 RCT에서는
              <span className="text-coaching-deep"> 40회 씹기가 식욕과 후속 섭취를 낮췄어요.</span>
            </p>
            <p className="mt-3 text-caption text-text-muted">
              — 씹는 행동 자체를 바꾸는 개입의 단기 효과
            </p>
          </div>
        </div>

        {/* 페르소나 트리거 3줄 */}
        <div
          data-reveal-stagger
          className="mt-16 space-y-5"
        >
          {[
            { quote: '오늘도 금방 먹었는데, 정확히 얼마나 빨랐는지는 모르겠어요.', label: '익명 응답' },
            { quote: '식사만 느려져도 하루가 달라질 것 같은데 방법이 없었어요.', label: '익명 응답' },
            { quote: '천천히 먹으라는 말은 많이 들었는데, 기준이 없었어요.', label: '익명 응답' },
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
          모르는 게 아니라, 볼 수 있는 도구가 없었던 거예요.
        </p>
      </Container>
    </Section>
  )
}
