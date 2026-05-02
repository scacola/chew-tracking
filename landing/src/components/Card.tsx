import type { ReactNode } from 'react'
import { cn } from '../lib/cn'

type Variant = 'flat' | 'elevated' | 'highlight' | 'outline'
type Tone = 'cool' | 'warm' | 'mist' | 'deep'

const variantClass: Record<Variant, string> = {
  flat: 'border border-line bg-bg-cool',
  elevated: 'border border-line bg-bg-cool shadow-md hover:shadow-lg transition-shadow',
  highlight: 'border-2 border-cta bg-bg-cool shadow-lg',
  outline: 'border border-line/60 bg-transparent',
}

const toneClass: Record<Tone, string> = {
  cool: 'bg-bg-cool',
  warm: 'bg-bg-warm',
  mist: 'bg-bg-mist',
  deep: 'bg-bg-deep text-text-on-deep border-line/30',
}

export function Card({
  variant = 'flat',
  tone,
  className,
  children,
}: {
  variant?: Variant
  tone?: Tone
  className?: string
  children: ReactNode
}) {
  return (
    <div
      className={cn(
        'rounded-xl p-6 md:p-8',
        variantClass[variant],
        tone && toneClass[tone],
        className,
      )}
    >
      {children}
    </div>
  )
}
