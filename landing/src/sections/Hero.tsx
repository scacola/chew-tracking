import { CtaPrimary } from '../components/CtaPrimary'
import { CtaSecondary } from '../components/CtaSecondary'
import { ScrollIndicator } from '../components/ScrollIndicator'
import { AirpodsSvg } from '../components/icons/AirpodsSvg'
import { usePersonaRoute } from '../hooks/usePersonaRoute'
import { personas } from '../data/personas'
import { track } from '../lib/analytics'

function smoothScrollTo(id: string) {
  document.getElementById(id)?.scrollIntoView({ behavior: 'smooth', block: 'start' })
}

export function Hero() {
  const persona = usePersonaRoute()
  const subhead = personas[persona].subhead

  return (
    <section
      id="hero"
      className="relative overflow-hidden bg-grad-hero"
    >
      {/* Persona-specific subhead chip — discreet */}
      <div className="absolute right-4 top-4 z-10 hidden md:block">
        <span className="rounded-full border border-line bg-bg-cool/80 px-3 py-1 text-caption text-text-muted backdrop-blur">
          {persona === 'stomach' ? '식사 리듬' : persona === 'diet' ? '정체기' : '점검'} 시각
        </span>
      </div>

      <div className="mx-auto flex min-h-svh max-w-container flex-col items-center justify-center px-4 pb-20 pt-16 md:px-8 md:pt-24 lg:pt-32">
        <div className="grid w-full items-center gap-10 lg:grid-cols-[1.1fr_1fr] lg:gap-16">
          {/* Left: 텍스트 */}
          <div className="order-2 flex flex-col gap-6 lg:order-1">
            <h1
              data-reveal
              className="text-display-lg lg:text-display-xl text-text-primary"
              style={{ fontWeight: 800, letterSpacing: '-0.025em' }}
            >
              AirPods로 식사 속도를 자동 기록하고,
              <br />
              매일 짧은 코치로 천천히 먹는 습관을 만들어요.
            </h1>

            <p
              data-reveal
              className="text-body-lg text-text-secondary"
              style={{ ['--i' as never]: 1 }}
            >
              <span className="hidden lg:inline">
                이미 끼고 있는 에어팟이 식사 중 리듬을 자동으로 기록하고,
                <br />
                매일 2-3분의 코치 카드가 천천히 먹는 흐름을 잡아줘요.
              </span>
              <span className="lg:hidden">
                이미 끼고 있는 에어팟이
                <br />
                식사 리듬을 기록하고,
                <br />
                매일 2-3분 코치 카드가 함께해요.
              </span>
            </p>

            {/* 페르소나별 서브헤드 — 모바일에서만 (자기 페르소나 페인 직접 자극) */}
            <div
              data-reveal
              className="rounded-lg border border-line/50 bg-bg-cool/60 p-4 text-body-sm text-text-secondary backdrop-blur lg:hidden"
              style={{ ['--i' as never]: 2 }}
            >
              {subhead.map((line, i) => (
                <span key={i} className="block">
                  {line}
                </span>
              ))}
            </div>

            <div
              data-reveal
              className="flex flex-col gap-4 sm:flex-row sm:items-center"
              style={{ ['--i' as never]: 3 }}
            >
              <CtaPrimary
                label="베타에 합류하기"
                href="#final-cta"
                onClick={() => {
                  track('cta_clicked', {
                    cta_id: 'hero_primary',
                    cta_text: '베타에 합류하기',
                    location: 'hero',
                  })
                  smoothScrollTo('final-cta')
                }}
              />
              <CtaSecondary
                href="#airpods-demo"
                label="어떻게 작동하는지 보기"
                onClick={() => {
                  track('cta_clicked', {
                    cta_id: 'hero_secondary',
                    cta_text: '어떻게 작동하는지 보기',
                    location: 'hero',
                  })
                  smoothScrollTo('airpods-demo')
                }}
              />
            </div>

            <p
              data-reveal
              className="flex flex-wrap items-center gap-x-2 gap-y-1 text-caption text-text-muted opacity-70"
              style={{ ['--i' as never]: 4 }}
            >
              <span>AirPods 기반 자동 측정</span>
              <span aria-hidden>·</span>
              <span>매일 짧은 코치 카드</span>
              <span aria-hidden>·</span>
              <span>베타 모집 중</span>
            </p>
          </div>

          {/* Right: AirPods 정적 SVG */}
          <div className="order-1 flex justify-center lg:order-2 lg:justify-end">
            <div className="relative w-[280px] sm:w-[360px] lg:w-[460px]">
              <AirpodsSvg state="idle" />
            </div>
          </div>
        </div>

        {/* Scroll indicator */}
        <div className="absolute bottom-8 left-1/2 -translate-x-1/2">
          <ScrollIndicator />
        </div>
      </div>
    </section>
  )
}
