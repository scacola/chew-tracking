import { useState } from 'react'
import { Section } from '../components/Section'
import { Container } from '../components/Container'
import { FaqItemView } from '../components/FaqItem'
import { useCopy } from '../hooks/useCopy'
import { trackEvent } from '../lib/analytics'

export function FAQ() {
  const [openId, setOpenId] = useState<string | null>(null)
  const copy = useCopy()

  return (
    <Section tone="warm" paddingY="xl" id="faq">
      <Container size="narrow">
        <h2
          data-reveal
          className="text-heading-1 lg:text-display-lg text-center text-text-primary"
          style={{ fontWeight: 700, letterSpacing: '-0.02em' }}
        >
          {copy.faq.title}
        </h2>

        <div data-reveal className="mt-12 lg:mt-16" style={{ ['--i' as never]: 1 }}>
          <div className="rounded-2xl border border-line bg-bg-cool overflow-hidden">
            {copy.faq.items.map((item) => (
              <div key={item.id} className="px-6 md:px-8">
                <FaqItemView
                  id={item.id}
                  q={item.q}
                  a={item.a}
                  highlight={item.highlight}
                  isOpen={openId === item.id}
                  onToggle={() => {
                    setOpenId((cur) => {
                      const next = cur === item.id ? null : item.id
                      if (next) trackEvent('faq_open', { locale: copy.locale, faq_id: item.id })
                      return next
                    })
                  }}
                />
              </div>
            ))}
          </div>
        </div>

        <p data-reveal className="mt-8 text-center text-caption text-text-muted">
          {copy.faq.footer}
        </p>
      </Container>
    </Section>
  )
}
