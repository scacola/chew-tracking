import { ArrowRight } from 'lucide-react'
import { cn } from '../lib/cn'
import { trackEvent } from '../lib/analytics'

export function CtaSecondary({
  href,
  label,
  onClick,
  className,
  trackingName,
}: {
  href: string
  label: string
  onClick?: () => void
  className?: string
  trackingName?: string
}) {
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
      className={cn(
        'group inline-flex items-center gap-1 text-body font-medium text-text-secondary',
        'transition-colors hover:text-text-primary',
        'focus-visible:outline-2 focus-visible:outline-cta focus-visible:outline-offset-4',
        className,
      )}
    >
      <span>{label}</span>
      <ArrowRight
        size={16}
        strokeWidth={1.75}
        className="transition-transform group-hover:translate-x-0.5"
      />
    </a>
  )
}
