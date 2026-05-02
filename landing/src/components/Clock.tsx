import { cn } from '../lib/cn'

// 24시간 시계 형태 — 식사 시간 시각화
// minutes: 0-60 (실제로 11분 vs 20분 비교)
export function Clock({
  minutes,
  target,
  label,
  variant = 'fast',
}: {
  minutes: number
  target: number
  label: string
  variant?: 'fast' | 'target'
}) {
  const r = 56
  const circumference = 2 * Math.PI * r
  // 60분 기준 → 분당 각도 6도, 60분 = 한 바퀴
  const fillRatio = Math.min(minutes / 60, 1)
  const dash = fillRatio * circumference

  const stroke = variant === 'fast' ? '#FB7185' : '#00B894'
  const dim = variant === 'fast' ? 'rgba(251,113,133,0.12)' : 'rgba(0,184,148,0.12)'

  return (
    <div className="flex flex-col items-center gap-3">
      <svg viewBox="0 0 140 140" width="140" height="140" role="img" aria-label={label}>
        <circle cx="70" cy="70" r={r} stroke="#E8EAEE" strokeWidth="2" fill={dim} />
        <circle
          cx="70"
          cy="70"
          r={r}
          stroke={stroke}
          strokeWidth="6"
          fill="none"
          strokeLinecap="round"
          strokeDasharray={`${dash} ${circumference}`}
          transform="rotate(-90 70 70)"
        />
        {/* 권장 시간 마커 (target) */}
        {target !== minutes && (
          <line
            x1="70"
            y1="14"
            x2="70"
            y2="22"
            stroke={variant === 'fast' ? '#00B894' : '#5A5F6E'}
            strokeWidth="2"
            strokeLinecap="round"
            transform={`rotate(${(target / 60) * 360} 70 70)`}
            opacity="0.5"
          />
        )}
        <text
          x="70"
          y="72"
          textAnchor="middle"
          fontSize="32"
          fontWeight="700"
          fill="#0A0E1A"
          fontFamily="Pretendard Variable, system-ui"
        >
          {minutes}
        </text>
        <text
          x="70"
          y="92"
          textAnchor="middle"
          fontSize="11"
          fill="#5A5F6E"
          fontFamily="Pretendard Variable, system-ui"
          letterSpacing="0.06em"
        >
          분
        </text>
      </svg>
      <p className={cn('text-caption', variant === 'fast' ? 'text-coaching-deep' : 'text-clinical-deep')}>
        {label}
      </p>
    </div>
  )
}
