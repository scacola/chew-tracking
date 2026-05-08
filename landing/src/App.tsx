import { useEffect } from 'react'
import { StickyNav } from './sections/StickyNav'
import { Hero } from './sections/Hero'
import { Problem } from './sections/Problem'
import { Solution } from './sections/Solution'
import { AirPodsDemo } from './sections/AirPodsDemo'
import { HowItWorks } from './sections/HowItWorks'
import { Differentiation } from './sections/Differentiation'
import { FAQ } from './sections/FAQ'
import { FinalCTA } from './sections/FinalCTA'
import { Footer } from './sections/Footer'
import { initRevealOnScroll } from './interactions/revealOnScroll'
import { track } from './lib/analytics'
import { useCopy } from './hooks/useCopy'

let landingPageViewed = false

function App() {
  const copy = useCopy()

  useEffect(() => {
    const observer = initRevealOnScroll()
    return () => observer?.disconnect()
  }, [])

  useEffect(() => {
    document.documentElement.lang = copy.locale
    document.title =
      copy.locale === 'ja'
        ? 'Chew & Calm Coach | AirPodsで食事ペースを見える化'
        : 'Chew & Calm Coach | AirPods로 식사 속도 기록'
    const description = document.querySelector('meta[name="description"]')
    description?.setAttribute(
      'content',
      copy.locale === 'ja'
        ? 'AirPodsで食べる速さを見える化し、食事のペースを無理なく整えるセルフケアアプリ。'
        : 'AirPods로 식사 속도를 자동 기록하고, 매일 짧은 코치로 천천히 먹는 습관을 만드는 서비스.',
    )
  }, [copy.locale])

  // landing_page_viewed — 1회 발화. path/referrer만 전송.
  useEffect(() => {
    if (landingPageViewed) return
    if (typeof window === 'undefined') return
    landingPageViewed = true
    track('landing_page_viewed', {
      source: 'landing_page',
      path: window.location.pathname,
      referrer: document.referrer || undefined,
      locale: copy.locale,
    })
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
        <FAQ />
        <FinalCTA />
      </main>
      <Footer />
    </>
  )
}

export default App
