import { useEffect, useState } from 'react'
import { CtaPrimary } from '../components/CtaPrimary'
import { cn } from '../lib/cn'
import { track } from '../lib/analytics'

const NAV_TARGET_TO_CTA_ID: Record<string, string> = {
  'how-it-works': 'nav_how',
  pricing: 'nav_pricing',
  faq: 'nav_faq',
}

export function StickyNav() {
  const [scrolled, setScrolled] = useState(false)

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 100)
    onScroll()
    window.addEventListener('scroll', onScroll, { passive: true })
    return () => window.removeEventListener('scroll', onScroll)
  }, [])

  return (
    <header
      className={cn(
        'fixed inset-x-0 top-0 z-40 transition-all duration-300',
        scrolled
          ? 'border-b border-line/50 bg-bg-cool/85 backdrop-blur-md'
          : 'border-b border-transparent bg-transparent',
      )}
    >
      <div className="mx-auto flex max-w-container items-center justify-between gap-4 px-4 py-3 md:px-8 md:py-4">
        <a
          href="#hero"
          onClick={(e) => {
            e.preventDefault()
            window.scrollTo({ top: 0, behavior: 'smooth' })
          }}
          className="text-heading-4 text-text-primary"
          style={{ fontWeight: 700, letterSpacing: '-0.01em' }}
        >
          Chew &amp; Calm
        </a>

        <nav className="hidden items-center gap-7 md:flex">
          {[
            ['작동 방식', 'how-it-works'],
            ['가격', 'pricing'],
            ['FAQ', 'faq'],
          ].map(([label, target]) => (
            <a
              key={target}
              href={`#${target}`}
              onClick={(e) => {
                e.preventDefault()
                track('cta_clicked', {
                  cta_id: NAV_TARGET_TO_CTA_ID[target] ?? `nav_${target}`,
                  cta_text: label,
                  location: 'sticky_nav',
                })
                document.getElementById(target)?.scrollIntoView({ behavior: 'smooth' })
              }}
              className="text-body-sm text-text-secondary transition-colors hover:text-text-primary"
            >
              {label}
            </a>
          ))}
        </nav>

        <CtaPrimary
          label="베타 합류"
          size="md"
          href="#final-cta"
          onClick={() => {
            track('cta_clicked', {
              cta_id: 'nav_join',
              cta_text: '베타 합류',
              location: 'sticky_nav',
            })
            document.getElementById('final-cta')?.scrollIntoView({ behavior: 'smooth' })
          }}
        />
      </div>
    </header>
  )
}
