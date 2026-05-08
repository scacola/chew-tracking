export type Locale = 'ko' | 'ja'

export type Accent = 'clinical' | 'cta' | 'coaching'

export type Copy = {
  locale: Locale
  nav: {
    how: string
    pricing: string
    faq: string
    cta: string
  }
  hero: {
    personaChip: Record<'stomach' | 'diet' | 'checkup', string>
    title: string[]
    accents: string[]
    bodyDesktop: string[]
    bodyMobile: string[]
    primaryCta: string
    secondaryCta: string
    trustSignals: string[]
  }
  problem: {
    title: string[]
    paragraphs: string[]
    clocks: { minutes: number; target: number; label: string; variant: 'fast' | 'target' }[]
    evidence: { text: string; accent: string; source: string }[]
    quotes: { quote: string; label: string }[]
    closing: string
  }
  solution: {
    title: string
    cards: {
      label: string
      header: string
      accent: Accent
      body: string[]
      highlight?: string
    }[]
  }
  demo: {
    label: string
    title: string[]
    body: string[]
    rows: { time: string; label: string; emphasis?: boolean }[]
    finaleLabel: string
    gaugeLabel: string
    gaugeAria: (score: number, change: number) => string
  }
  how: {
    title: string[]
    columns: {
      title: string
      body?: string[]
      items?: { label: string; text: string }[]
      chips?: string[]
      quote?: string[]
      quoteFooter?: string
    }[]
    closing: string
  }
  differentiation: {
    title: string[]
    cards: {
      id: string
      size: 'lg' | 'sm'
      accent: Accent
      title: string
      body: string
    }[]
    closing: string
  }
  trust: {
    title: string[]
    cards: {
      status: 'inProgress' | 'live' | 'beta'
      statusLabel: string
      title: string
      body: string[]
      progress?: { label: string; percent: number }
      bullets?: string[]
    }[]
    closing: string[]
  }
  pricing: {
    enabled: boolean
    title: string[]
    tiers: {
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
    }[]
    note: string[]
    refundNote: string
  }
  faq: {
    title: string
    footer: string
    items: {
      id: string
      q: string
      a: string
      highlight?: 'trust-core'
    }[]
  }
  finalCta: {
    title: string[]
    datePrefix: string
    letter: string[]
    formCta: string
    formPlaceholder: string
    formHelper: string
    pricingLink?: { prefix: string; label: string }
  }
  footer: {
    links: { label: string; target: string }[]
    formLabel: string
    formCta: string
    formPlaceholder: string
  }
  form: {
    submitting: string
    success: string
    invalidEmail: string
  }
  common: {
    scroll: string
    minute: string
  }
}
