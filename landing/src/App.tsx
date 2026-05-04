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
import { track } from './lib/analytics'

function App() {
  useEffect(() => {
    const observer = initRevealOnScroll()
    return () => observer?.disconnect()
  }, [])

  // landing_view — 1회 발화. UTM/persona/referrer 부속.
  useEffect(() => {
    if (typeof window === 'undefined') return
    const params = new URLSearchParams(window.location.search)
    const persona = (params.get('p') ?? 'unknown') as string
    track('landing_view', {
      path: window.location.pathname,
      referrer: document.referrer || undefined,
      utm_source: params.get('utm_source') ?? undefined,
      utm_medium: params.get('utm_medium') ?? undefined,
      utm_campaign: params.get('utm_campaign') ?? undefined,
      persona,
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
        <Authority />
        <Pricing />
        <FAQ />
        <FinalCTA />
      </main>
      <Footer />
    </>
  )
}

export default App
