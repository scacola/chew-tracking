import { cn } from '../lib/cn'

type Status = 'inProgress' | 'beta' | 'live' | 'recruiting'

const styles: Record<Status, { dot: string; text: string; bg: string }> = {
  inProgress: { dot: 'bg-clinical', text: 'text-clinical-deep', bg: 'bg-clinical-soft/50' },
  recruiting: { dot: 'bg-coaching', text: 'text-coaching-deep', bg: 'bg-coaching-soft/50' },
  beta: { dot: 'bg-cta', text: 'text-cta', bg: 'bg-cta-soft/60' },
  live: { dot: 'bg-success', text: 'text-success', bg: 'bg-success/10' },
}

export function StatusChip({ status, label }: { status: Status; label: string }) {
  const s = styles[status]
  return (
    <span
      className={cn(
        'inline-flex items-center gap-2 rounded-full px-3 py-1 text-caption font-medium',
        s.bg,
        s.text,
      )}
    >
      <span className={cn('state-pulse h-1.5 w-1.5 rounded-full', s.dot)} aria-hidden />
      {label}
    </span>
  )
}
