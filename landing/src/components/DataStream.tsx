type Row = { time: string; label: string; emphasis?: boolean }

export function DataStream({
  rows,
  finale,
}: {
  rows: Row[]
  finale?: { score: number; change: number }
}) {
  return (
    <div className="font-mono text-data-mono rounded-xl border border-line/60 bg-bg-deep p-5 text-text-on-deep shadow-md md:p-6">
      <ul className="space-y-1.5">
        {rows.map((r, i) => (
          <li
            key={i}
            data-reveal
            style={{ ['--i' as never]: i }}
            className="flex items-baseline gap-3"
          >
            <span className="text-text-on-deep/50">&gt;</span>
            <span className="text-clinical-soft tabular-nums">{r.time}</span>
            <span className={r.emphasis ? 'text-text-on-deep' : 'text-text-on-deep/80'}>
              {r.label}
            </span>
          </li>
        ))}
      </ul>
      <div className="my-4 border-t border-line/30" />
      {finale && (
        <div className="flex items-baseline justify-between">
          <span className="text-text-on-deep/70 text-caption">위 건강 점수 →</span>
          <div className="flex items-baseline gap-3">
            <span className="text-2xl font-semibold text-text-on-deep tabular-nums">
              {finale.score}
            </span>
            <span className="text-clinical-soft text-body-sm tabular-nums">
              {finale.change > 0 ? `↑ +${finale.change}` : `↓ ${finale.change}`}
            </span>
          </div>
        </div>
      )}
    </div>
  )
}
