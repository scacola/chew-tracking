import { useEffect, useRef, useState } from 'react'

export function HealthScoreGauge({
  score = 72,
  change = 3,
  size = 200,
  label = '위 건강 점수',
  ariaLabel,
}: {
  score?: number
  change?: number
  size?: number
  label?: string
  ariaLabel?: string
}) {
  const ref = useRef<SVGSVGElement>(null)
  const [animated, setAnimated] = useState(false)

  useEffect(() => {
    if (!ref.current) return
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((e) => {
          if (e.isIntersecting) {
            setAnimated(true)
            observer.disconnect()
          }
        })
      },
      { threshold: 0.5 },
    )
    observer.observe(ref.current)
    return () => observer.disconnect()
  }, [])

  const r = 64
  const circumference = 2 * Math.PI * r
  const progress = animated ? (score / 100) * circumference : 0

  return (
    <svg
      ref={ref}
      viewBox="0 0 160 160"
      width={size}
      height={size}
      role="img"
      aria-label={ariaLabel ?? `위 건강 점수 ${score}, 어제 대비 ${change > 0 ? '+' : ''}${change}`}
    >
      {/* 배경 원 */}
      <circle cx="80" cy="80" r={r} stroke="#E8EAEE" strokeWidth="6" fill="none" />
      {/* 진행 원 */}
      <circle
        cx="80"
        cy="80"
        r={r}
        stroke="#00B894"
        strokeWidth="6"
        fill="none"
        strokeLinecap="round"
        strokeDasharray={circumference}
        strokeDashoffset={circumference - progress}
        transform="rotate(-90 80 80)"
        style={{ transition: 'stroke-dashoffset 1.4s cubic-bezier(0.16,1,0.3,1)' }}
      />
      {/* 중앙 텍스트 */}
      <text
        x="80"
        y="78"
        textAnchor="middle"
        fontSize="36"
        fontWeight="700"
        fill="#0A0E1A"
        fontFamily="Pretendard Variable, system-ui"
      >
        {animated ? score : 0}
      </text>
      <text
        x="80"
        y="100"
        textAnchor="middle"
        fontSize="11"
        fill="#5A5F6E"
        fontFamily="Pretendard Variable, system-ui"
        letterSpacing="0.04em"
      >
        {label}
      </text>
      <text
        x="80"
        y="118"
        textAnchor="middle"
        fontSize="12"
        fontWeight="500"
        fill="#007A66"
        fontFamily="JetBrains Mono, monospace"
      >
        {change > 0 ? `↑ +${change}` : change < 0 ? `↓ ${change}` : '—'}
      </text>
    </svg>
  )
}
