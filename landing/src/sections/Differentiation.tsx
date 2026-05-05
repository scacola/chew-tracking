import { Section } from '../components/Section'
import { Container } from '../components/Container'
import { Calendar, Sparkles, Activity, Heart } from 'lucide-react'

const cards = [
  {
    id: 'c',
    size: 'lg' as const,
    icon: Calendar,
    accent: 'clinical' as const,
    title: '식사 속도에만 집중',
    body: '체중, 칼로리, 식단 기록이 아니라 식사 속도와 리듬 하나에만 집중해요. 복잡한 입력 없이 바로 이해돼요.',
  },
  {
    id: 'd',
    size: 'lg' as const,
    icon: Sparkles,
    accent: 'coaching' as const,
    title: '매일 한 장의 코치 카드',
    body: '데이터를 따뜻한 언어로 번역하는 한국형 코치 톤. "오늘 8분이었어요"처럼 짧고 구체적으로 안내해요.',
  },
  {
    id: 'b',
    size: 'sm' as const,
    icon: Activity,
    accent: 'cta' as const,
    title: '자동으로 시작',
    body: '앱을 열거나 버튼을 누르지 않아도, 평소처럼 식사하면 기록이 시작돼요.',
  },
  {
    id: 'e',
    size: 'sm' as const,
    icon: Heart,
    accent: 'coaching' as const,
    title: '결과가 눈에 보임',
    body: '오늘과 어제의 차이를 바로 볼 수 있어, 무엇을 바꿔야 하는지 한눈에 보여요.',
  },
]

const accentMap = {
  clinical: 'text-clinical-deep bg-clinical-soft/40',
  cta: 'text-cta bg-cta-soft/60',
  coaching: 'text-coaching-deep bg-coaching-soft/50',
}

export function Differentiation() {
  return (
    <Section tone="cool" paddingY="xl" id="differentiation">
      <Container>
        <h2
          data-reveal
          className="text-heading-1 lg:text-display-lg text-center text-text-primary"
          style={{ fontWeight: 700, letterSpacing: '-0.02em' }}
        >
          서비스가 하는 일이
          <br className="hidden md:inline" /> 한 번에 읽히는 4가지.
        </h2>

        {/* 큰 2 + 작은 2 그리드 */}
        <div data-reveal-stagger className="mt-16 grid gap-5 md:grid-cols-2 lg:gap-6">
          {cards.map((c) => {
            const Icon = c.icon
            return (
              <div
                key={c.id}
                data-reveal
                className="group relative flex h-full min-h-[260px] flex-col gap-4 rounded-2xl border border-line bg-bg-cool p-6 transition-all duration-300 hover:-translate-y-1 hover:shadow-lg md:p-7"
              >
                <div
                  className={`flex h-11 w-11 items-center justify-center rounded-lg ${accentMap[c.accent]}`}
                >
                  <Icon size={22} strokeWidth={1.6} />
                </div>
                <h3 className="text-heading-3 text-text-primary" style={{ fontWeight: 700 }}>
                  {c.title}
                </h3>
                <p className="text-body leading-relaxed text-text-secondary">{c.body}</p>
              </div>
            )
          })}
        </div>

        <p
          data-reveal
          className="mt-16 text-center text-heading-3 text-text-primary lg:text-heading-2"
          style={{ fontWeight: 600 }}
        >
          복잡한 설명보다, 한눈에 보이는 흐름이 먼저예요.
        </p>
      </Container>
    </Section>
  )
}
