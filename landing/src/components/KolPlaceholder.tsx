import { StatusChip } from './StatusChip'

export function KolPlaceholder({
  role,
  status = 'recruiting',
}: {
  role: string
  status?: 'recruiting'
}) {
  return (
    <div className="flex items-start gap-4 rounded-xl border border-line/60 bg-bg-mist p-5">
      {/* 실루엣 */}
      <div className="kol-breathe relative flex h-16 w-16 shrink-0 items-center justify-center rounded-full bg-line/40">
        <svg viewBox="0 0 64 64" width="40" height="40" aria-hidden>
          <circle cx="32" cy="22" r="11" fill="#C9CDD4" />
          <path
            d="M 12 56 Q 12 38 32 38 Q 52 38 52 56 Z"
            fill="#C9CDD4"
          />
        </svg>
      </div>
      <div className="flex flex-col gap-1.5">
        <p className="text-caption text-text-muted">{role}</p>
        <p className="text-body font-medium text-text-secondary">[KOL 이름 비공개]</p>
        <StatusChip status={status} label="영입 진행 중" />
      </div>
    </div>
  )
}
