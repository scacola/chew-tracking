import { useEffect } from 'react'
import { StickyNav } from './sections/StickyNav'
import { Hero } from './sections/Hero'
import { Problem } from './sections/Problem'
import { Solution } from './sections/Solution'
import { AirPodsDemo } from './sections/AirPodsDemo'
import { HowItWorks } from './sections/HowItWorks'
import { Differentiation } from './sections/Differentiation'
import { Authority } from './sections/Authority'
import { Pricing } from './sections/Pricing'
import { FAQ } from './sections/FAQ'
import { FinalCTA } from './sections/FinalCTA'
import { Footer } from './sections/Footer'
import { initRevealOnScroll } from './interactions/revealOnScroll'
import { useCopy } from './hooks/useCopy'

function App() {
  const copy = useCopy()

  useEffect(() => {
    const observer = initRevealOnScroll()
    return () => observer?.disconnect()
  }, [])

  useEffect(() => {
    const meta = {
      ko: {
        title: 'Chew & Calm Coach — 8주, 위 건강을 차분히 되찾아요',
        description:
          '위염 진단을 받았거나, 체중이 정체되었거나, 점심마다 더부룩한 30·40대라면 — 이미 끼고 있는 AirPods로 식사 속도를 자동 측정하고, 임상 28일 코스로 매일 2-3분 위 건강을 되찾아요.',
        ogDescription:
          '이미 끼고 있는 AirPods가 식사 속도를 자동으로 보여주고, 임상 28일 코스가 매일 2-3분 함께 걸어요.',
        ogLocale: 'ko_KR',
        skip: '본문으로 건너뛰기',
      },
      ja: {
        title: 'Chew & Calm Coach｜AirPodsで食べる速さを見える化',
        description:
          'AirPodsのモーションデータで食事ペースを記録。早食いに気づき、ゆっくり食べる習慣を育てるセルフケアアプリ。ベータ版参加受付中。',
        ogDescription:
          'AirPodsで食べる速さを見える化。早食いに気づき、食事のペースを無理なく整えるセルフケアアプリ。',
        ogLocale: 'ja_JP',
        skip: '本文へスキップ',
      },
    }[copy.locale]

    document.documentElement.lang = copy.locale
    document.title = meta.title
    document.querySelector('meta[name="description"]')?.setAttribute('content', meta.description)
    document.querySelector('meta[property="og:title"]')?.setAttribute('content', meta.title)
    document
      .querySelector('meta[property="og:description"]')
      ?.setAttribute('content', meta.ogDescription)
    document.querySelector('meta[property="og:locale"]')?.setAttribute('content', meta.ogLocale)
    const skipLink = document.querySelector<HTMLAnchorElement>('.skip-link')
    if (skipLink) skipLink.textContent = meta.skip
  }, [copy.locale])

  return (
    <>
      <StickyNav />
      <main id="main">
        <Hero />
        <Problem />
        <Solution />
        <AirPodsDemo />
        <HowItWorks />
        <Differentiation />
        <Authority />
        {copy.pricing.enabled && <Pricing />}
        <FAQ />
        <FinalCTA />
      </main>
      <Footer />
    </>
  )
}

export default App
