import { useCopy } from '../hooks/useCopy'

export function ScrollIndicator() {
  const copy = useCopy()
  return (
    <div className="scroll-indicator flex flex-col items-center gap-2 text-text-muted" aria-hidden>
      <span className="text-caption">{copy.common.scroll}</span>
      <svg width="14" height="20" viewBox="0 0 14 20" fill="none">
        <rect x="1" y="1" width="12" height="18" rx="6" stroke="currentColor" strokeOpacity="0.4" />
        <circle cx="7" cy="6" r="1.5" fill="currentColor" />
      </svg>
    </div>
  )
}
