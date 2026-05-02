import { type ReactNode } from 'react'
import { cn } from '../lib/cn'

type Size = 'default' | 'narrow' | 'prose'

const sizeClass: Record<Size, string> = {
  default: 'max-w-container',
  narrow: 'max-w-narrow',
  prose: 'max-w-prose-narrow',
}

export function Container({
  size = 'default',
  className,
  children,
}: {
  size?: Size
  className?: string
  children: ReactNode
}) {
  return (
    <div className={cn('mx-auto w-full px-4 md:px-8', sizeClass[size], className)}>
      {children}
    </div>
  )
}
