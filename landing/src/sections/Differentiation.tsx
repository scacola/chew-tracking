import { Section } from '../components/Section'
import { Container } from '../components/Container'
import { Calendar, Sparkles, Activity, Heart } from 'lucide-react'

const cards = [
  {
    id: 'c',
    size: 'lg' as const,
    icon: Calendar,
    accent: 'clinical' as const,
    title: '28일 한국어 코스 IP',
    body: '"한국 직장인의 회식·야근·점심 11분"이라는 맥락 위에서 쓴 코스. 일반 jaw-health 메트릭으로는, 한국 위염을 못 다뤄요.',
  },
  {
    id: 'd',
    size: 'lg' as const,
    icon: Sparkles,
    accent: 'coaching' as const,
    title: '친근한 한국 페르소나 코치',
    body: '데이터를 따뜻한 언어로 번역하는 한국형 코치 톤. "오늘 8분에 드셨어요" — 잔소리 대신 격려, 평가 대신 동행.',
  },
  {
    id: 'b',
    size: 'sm' as const,
    icon: Activity,
    accent: 'cta' as const,
    title: '임상 RCT 데이터 누적',
    body: '베타 1일차부터 학술 발표 가능 형식으로 익명화 누적. 메트릭이 시간이 갈수록 단단해져요.',
  },
  {
    id: 'e',
    size: 'sm' as const,
    icon: Heart,
    accent: 'coaching' as const,
    title: '"위 건강 회복" 결과 라벨',
    body: '측정 메트릭이 아닌 결과를 약속하는 자산. 한국 30·40대 페인 직결.',
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
          Apple watchOS가 흡수해도,
          <br className="hidden md:inline" /> 우리만 가진 것 4가지.
        </h2>

        {/* 큰 2 + 작은 2 그리드 */}
        <div data-reveal-stagger className="mt-16 grid gap-5 md:grid-cols-2 lg:grid-cols-4">
          {cards.map((c) => {
            const Icon = c.icon
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
          도구는 베껴도, 맥락과 톤은 베낄 수 없어요.
        </p>
      </Container>
    </Section>
  )
}
