import { useEffect, useRef } from 'react'
import { Check } from 'lucide-react'
import { Section } from '../components/Section'
import { Container } from '../components/Container'
import { CtaPrimary } from '../components/CtaPrimary'
import { cn } from '../lib/cn'
import { track } from '../lib/analytics'

type Tier = {
  key: string
  header: string
  price: string
  period: string
  strikePrice?: string
  helper?: string
  badges?: string[]
  features: string[]
  cancelPolicy: string
  recommended?: boolean
  cta: string
}

const tiers: Tier[] = [
  {
    key: 'monthly',
    header: '월간',
    price: '9,900원',
    period: '/월',
    features: [
      '28일 코스 + 매일 코치 카드',
      'AirPods 자동 트래킹',
      '임상 콘텐츠 무제한',
    ],
    cancelPolicy: '언제든 해지 가능',
    cta: '월간 시작하기',
  },
  {
    key: 'yearly',
    header: '연간',
    price: '79,000원',
    period: '/년',
    strikePrice: '9,900 × 12 = 118,800원',
    helper: '33% 할인 — 한 달 무료에 가까워요',
    badges: ['추천', '한 달 무료'],
    features: [
      '월간 동일한 모든 혜택',
      '연간 위 건강 리포트 1회',
      '30일 환불 보장',
    ],
    cancelPolicy: '30일 안에 100% 환불',
    recommended: true,
    cta: '연간 합류하기',
  },
  {
    key: 'single',
    header: '28일 코스 단품',
    price: '19,900원',
    period: '/1회 결제',
    features: [
      '28일 코스만, 자동 트래킹 없이',
      '구독 부담 없이 체험',
    ],
    cancelPolicy: '7일 안에 1주차 미시청 시 환불',
    cta: '코스만 구매',
  },
]

const TIER_TO_CTA_ID: Record<string, string> = {
  monthly: 'pricing_monthly_cta',
  yearly: 'pricing_yearly_cta',
  single: 'pricing_single_cta',
}

export function Pricing() {
  const sectionRef = useRef<HTMLElement | null>(null)

  useEffect(() => {
    const el = document.getElementById('pricing')
    if (!el) return
    sectionRef.current = el as HTMLElement
    let fired = false
    const obs = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting && !fired) {
          fired = true
          track('pricing_view')
          obs.disconnect()
        }
      },
      { threshold: 0.5 },
    )
    obs.observe(el)
    return () => obs.disconnect()
  }, [])

  return (
    <Section tone="cool" paddingY="xl" id="pricing">
      <Container>
        <h2
          data-reveal
          className="text-heading-1 lg:text-display-lg text-center text-text-primary"
          style={{ fontWeight: 700, letterSpacing: '-0.02em' }}
        >
          내과 진료 한 번보다 적은 비용으로,
          <br className="hidden md:inline" /> 8주를 함께해요.
        </h2>

        <div
          data-reveal-stagger
          className="mt-16 grid gap-5 md:grid-cols-3 md:gap-6"
        >
          {tiers.map((tier) => (
            <div
              key={tier.key}
              data-reveal
              className={cn(
                'relative flex flex-col gap-6 rounded-2xl border bg-bg-cool p-7 transition-all duration-300',
                tier.recommended
                  ? 'border-cta shadow-xl ring-1 ring-cta-soft md:-translate-y-2 md:scale-[1.03]'
                  : 'border-line hover:-translate-y-1 hover:shadow-md',
              )}
            >
              {tier.badges && (
                <div className="absolute -top-3 right-6 flex gap-2">
                  {tier.badges.map((b, i) => (
                    <span
                      key={b}
                      className={cn(
                        'rounded-full px-3 py-1 text-caption font-medium shadow-sm',
                        i === 0
                          ? 'bg-cta text-white'
                          : 'bg-clinical-soft text-clinical-deep',
                      )}
                    >
                      {b}
                    </span>
                  ))}
                </div>
              )}

              <div>
                <h3 className="text-heading-3 text-text-primary" style={{ fontWeight: 700 }}>
                  {tier.header}
                </h3>
                <div className="mt-4 flex items-baseline gap-2">
                  <span className="text-display-lg text-text-primary" style={{ fontWeight: 800 }}>
                    {tier.price}
                  </span>
                  <span className="text-body text-text-muted">{tier.period}</span>
                </div>
                {tier.strikePrice && (
                  <p className="mt-1 text-caption text-text-muted line-through">{tier.strikePrice}</p>
                )}
                {tier.helper && (
                  <p className="mt-2 text-body-sm font-medium text-clinical-deep">{tier.helper}</p>
                )}
              </div>

              <ul className="space-y-3 text-body-sm text-text-secondary">
                {tier.features.map((f) => (
                  <li key={f} className="flex items-start gap-2.5">
                    <Check
                      size={18}
                      strokeWidth={2}
                      className={cn(
                        'mt-0.5 shrink-0',
                        tier.recommended ? 'text-cta' : 'text-clinical-deep',
                      )}
                    />
                    <span>{f}</span>
                  </li>
                ))}
              </ul>

              <div className="mt-auto flex flex-col gap-3">
                <CtaPrimary
                  label={tier.cta}
                  size="md"
                  href="#final-cta"
                  onClick={() => {
                    track('cta_clicked', {
                      cta_id: TIER_TO_CTA_ID[tier.key] ?? `pricing_card_${tier.key}`,
                      cta_text: tier.cta,
                      location: 'pricing',
                    })
                    document.getElementById('final-cta')?.scrollIntoView({ behavior: 'smooth' })
                  }}
                  className={cn(!tier.recommended && 'bg-text-primary hover:bg-text-secondary')}
                />
                <p className="text-caption text-text-muted">{tier.cancelPolicy}</p>
              </div>
            </div>
          ))}
        </div>

        {/* 가격 정당화 */}
        <div data-reveal className="mx-auto mt-12 max-w-prose-narrow text-center">
          <p className="text-body-sm leading-relaxed text-text-muted">
            한국 내과 진료 1회 평균 비용이 약 12,000~25,000원이에요.
            <br />
            Chew & Calm의 한 달 구독은 그보다 적은 9,900원이고,
            <br />
            글로벌 비교 제품인 Eat Right Now($24.99/월, 약 35,000원)의 1/3 이하예요.
            <br />
            <em className="not-italic text-text-secondary">
              진료를 대체하지 않아요. 진료가 닿지 못하는 8주의 일상을 채워요.
            </em>
          </p>
          <p className="mt-4 text-caption text-text-subtle">
            연간 구독은 30일 안에 100% 환불 가능해요. 월간 구독은 다음 결제일 24시간 전까지 해지하면 추가 청구 없어요.
          </p>
        </div>
      </Container>
    </Section>
  )
}
