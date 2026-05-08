import { ArrowRight } from 'lucide-react'
import type { ReactNode } from 'react'
import { cn } from '../lib/cn'
import { trackEvent } from '../lib/analytics'

export function CtaPrimary({
  href,
  onClick,
  label,
  icon,
  className,
  size = 'lg',
  trackingName,
}: {
  href?: string
  onClick?: () => void
  label: string
  icon?: ReactNode
  className?: string
  size?: 'md' | 'lg'
  trackingName?: string
}) {
  const cls = cn(
    'inline-flex items-center justify-center gap-2 rounded-full bg-cta text-white font-medium',
    'transition-all duration-200 ease-out hover:bg-cta-hover hover:shadow-lg',
    'active:scale-[0.97] active:transition-[transform] active:duration-100',
    'focus-visible:outline-2 focus-visible:outline-cta focus-visible:outline-offset-4',
    size === 'lg' ? 'h-14 px-8 text-body-lg' : 'h-11 px-6 text-body',
    className,
  )

  const content = (
    <>
      <span>{label}</span>
      {icon ?? <ArrowRight size={size === 'lg' ? 20 : 18} strokeWidth={1.75} />}
    </>
  )

  if (href) {
    return (
      <a
        href={href}
        onClick={(e) => {
          if (trackingName) trackEvent(trackingName, { label })
          if (href.startsWith('#') && onClick) {
            e.preventDefault()
            onClick()
          }
        }}
        className={cls}
      >
        {content}
      </a>
    )
  }
  return (
    <button
      type="button"
      onClick={() => {
        if (trackingName) trackEvent(trackingName, { label })
        onClick?.()
      }}
      className={cls}
    >
      {content}
    </button>
  )
}
