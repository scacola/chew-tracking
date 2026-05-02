import { ChevronDown } from 'lucide-react'
import { cn } from '../lib/cn'

export function FaqItemView({
  q,
  a,
  highlight,
  isOpen,
  onToggle,
  id,
}: {
  q: string
  a: string
  highlight?: 'trust-core'
  isOpen: boolean
  onToggle: () => void
  id: string
}) {
  return (
    <div
      className={cn(
        'border-b transition-colors',
        highlight === 'trust-core' && 'bg-clinical-soft/15',
        isOpen ? 'border-line/50' : 'border-line/30',
      )}
    >
      <button
        type="button"
        onClick={onToggle}
        aria-expanded={isOpen}
        aria-controls={`${id}-answer`}
        className={cn(
          'flex w-full items-center justify-between gap-4 py-5 text-left',
          'transition-colors hover:text-text-primary',
          'focus-visible:outline-2 focus-visible:outline-cta focus-visible:outline-offset-4',
        )}
      >
        <span className={cn('text-body-lg font-medium', highlight && 'text-clinical-deep')}>
          {q}
        </span>
        <ChevronDown
          size={20}
          strokeWidth={1.75}
          className={cn(
            'shrink-0 text-text-muted transition-transform duration-300',
            isOpen && 'rotate-180',
          )}
          aria-hidden
        />
      </button>
      <div
        id={`${id}-answer`}
        role="region"
        className={cn(
          'grid overflow-hidden transition-all duration-300 ease-reveal',
          isOpen ? 'grid-rows-[1fr] pb-5 pt-1 opacity-100' : 'grid-rows-[0fr] opacity-0',
        )}
      >
        <p className="min-h-0 text-body text-text-secondary leading-relaxed">{a}</p>
      </div>
    </div>
  )
}
