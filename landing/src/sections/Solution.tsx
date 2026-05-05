import { Headphones, Activity, Sparkles } from 'lucide-react'
import { Section } from '../components/Section'
import { Container } from '../components/Container'

const cards = [
  {
    label: '자동으로 기록해요',
    header: '1. 검출',
    icon: Headphones,
    accent: 'clinical' as const,
    body: (
      <>
        이미 끼고 있는 AirPods의 모션 센서가, 식사 동작을 자동으로 잡아내요.
        <br />
        앱을 켜거나 버튼을 누를 필요가 없어요.
        <br />
        <span className="text-text-muted">기록은 눈에 띄지 않게 시작돼요.</span>
      </>
    ),
  },
  {
    label: '오늘의 리듬을 보여줘요',
    header: '2. 깨달음',
    icon: Activity,
    accent: 'cta' as const,
    body: (
      <>
        매일 점심 후, 식사 속도와 변화가 카드 한 장으로 도착해요.
        <br />
        <span className="text-text-primary font-medium">
          "오늘은 8분이었어요. 어제보다 1분 더 천천히 드셨어요."
        </span>
        <br />
        내가 생각한 속도와 실제 속도의 차이가 보이기 시작해요.
      </>
    ),
  },
  {
    label: '함께 걸어요',
    header: '3. 코칭',
    icon: Sparkles,
    accent: 'coaching' as const,
    body: (
      <>
        28일 코스가 매일 2-3분 영상으로 안내해요.
        <br />
        잔소리 대신 격려, 평가 대신 동행 —
        <br />
        한국 사용자의 식사 맥락에 맞춘 친근한 코치 카드가 매일 도착해요.
      </>
    ),
  },
]

const accentMap = {
  clinical: { ring: 'ring-clinical-soft', icon: 'text-clinical-deep', label: 'text-clinical-deep' },
  cta: { ring: 'ring-cta-soft', icon: 'text-cta', label: 'text-cta' },
  coaching: { ring: 'ring-coaching-soft', icon: 'text-coaching-deep', label: 'text-coaching-deep' },
}

export function Solution() {
  return (
    <Section tone="cool" paddingY="xl" id="solution">
      <Container>
        <h2
          data-reveal
          className="text-heading-1 lg:text-display-lg text-center text-text-primary"
          style={{ fontWeight: 700, letterSpacing: '-0.02em' }}
        >
          보는 순간 이해되고,
          <br className="hidden md:inline" /> 바로 쓸 수 있어요.
        </h2>

        <div data-reveal-stagger className="mt-16 grid gap-6 md:grid-cols-3 md:gap-8">
          {cards.map((card) => {
            const Icon = card.icon
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
                <p className="text-body leading-relaxed text-text-secondary">{card.body}</p>
              </div>
            )
          })}
        </div>
      </Container>
    </Section>
  )
}
