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

function App() {
  useEffect(() => {
    const observer = initRevealOnScroll()
    return () => observer?.disconnect()
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
