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

let landingPageViewed = false

function App() {
  useEffect(() => {
    const observer = initRevealOnScroll()
    return () => observer?.disconnect()
  }, [])

  // landing_page_viewed — 1회 발화. path/referrer만 전송.
  useEffect(() => {
    if (landingPageViewed) return
    if (typeof window === 'undefined') return
    landingPageViewed = true
    track('landing_page_viewed', {
      source: 'landing_page',
      path: window.location.pathname,
      referrer: document.referrer || undefined,
    })
  }, [])

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
