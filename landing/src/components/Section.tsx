import { type ReactNode } from 'react'
import { cn } from '../lib/cn'

type Tone = 'cool' | 'warm' | 'mist' | 'deep'

const toneClass: Record<Tone, string> = {
  cool: 'bg-bg-cool text-text-primary',
  warm: 'bg-bg-warm text-text-primary',
  mist: 'bg-bg-mist text-text-primary',
  deep: 'bg-bg-deep text-text-on-deep',
}

export function Section({
  tone = 'cool',
  paddingY = 'lg',
  className,
  id,
  children,
}: {
  tone?: Tone
  paddingY?: 'lg' | 'xl'
  className?: string
  id?: string
  children: ReactNode
}) {
  return (
    <section
      id={id}
      className={cn(
        toneClass[tone],
        paddingY === 'xl' ? 'py-20 md:py-32' : 'py-16 md:py-24',
        'relative',
        className,
      )}
    >
      {children}
    </section>
  )
}
