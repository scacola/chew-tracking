import { cn } from '../../lib/cn'

type State = 'idle' | 'pulse' | 'streaming' | 'gauge'

export function AirpodsSvg({
  state = 'idle',
  className,
}: {
  state?: State
  className?: string
}) {
  return (
    <svg
      viewBox="0 0 480 480"
      fill="none"
      className={cn('select-none', className)}
      role="img"
      aria-label="AirPods 시각화"
    >
      <defs>
        <linearGradient id="apod-body" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stopColor="#FAFBFD" />
          <stop offset="100%" stopColor="#D9DEE6" />
        </linearGradient>
        <linearGradient id="apod-stem" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="#EFF1F4" />
          <stop offset="100%" stopColor="#C4CAD3" />
        </linearGradient>
        <radialGradient id="apod-pulse-grad" cx="0.5" cy="0.5" r="0.5">
          <stop offset="0%" stopColor="#00B894" stopOpacity="0.55" />
          <stop offset="70%" stopColor="#00B894" stopOpacity="0.1" />
          <stop offset="100%" stopColor="#00B894" stopOpacity="0" />
        </radialGradient>
        <pattern id="apod-mesh" patternUnits="userSpaceOnUse" width="6" height="6">
          <circle cx="3" cy="3" r="0.6" fill="#3A424E" />
        </pattern>
      </defs>

      {/* 펄스 글로우 */}
      <g
        id="airpod-pulse"
        style={{
          opacity: state === 'pulse' || state === 'streaming' ? 1 : 0,
          transition: 'opacity 0.6s ease',
        }}
      >
        <circle cx="240" cy="200" r="160" fill="url(#apod-pulse-grad)">
          {(state === 'pulse' || state === 'streaming') && (
            <animate
              attributeName="r"
              values="120;180;120"
              dur="2.4s"
              repeatCount="indefinite"
            />
          )}
        </circle>
      </g>

      {/* AirPod body (둥근) */}
      <g id="airpod-body">
        <ellipse
          cx="240"
          cy="200"
          rx="78"
          ry="82"
          fill="url(#apod-body)"
          stroke="#B8BFC9"
          strokeWidth="1.5"
        />
        {/* 안쪽 메시 */}
        <ellipse cx="240" cy="195" rx="40" ry="36" fill="#1F2530" opacity="0.85" />
        <ellipse cx="240" cy="195" rx="40" ry="36" fill="url(#apod-mesh)" />
        {/* 마이크 점 */}
        <circle cx="240" cy="232" r="3" fill="#3A424E" opacity="0.5" />
      </g>

      {/* Stem (줄기) */}
      <g id="airpod-stem">
        <rect
          x="222"
          y="262"
          width="36"
          height="120"
          rx="18"
          fill="url(#apod-stem)"
          stroke="#B8BFC9"
          strokeWidth="1.2"
        />
        <line x1="240" y1="350" x2="240" y2="362" stroke="#9AA1AC" strokeWidth="1" />
      </g>

      {/* 데이터 라인 */}
      <g
        id="airpod-data-line"
        style={{
          opacity: state === 'streaming' || state === 'gauge' ? 1 : 0,
          transition: 'opacity 0.8s ease',
        }}
      >
        <path
          d="M 320 200 Q 380 180 420 220 Q 440 240 440 280"
          stroke="#1F4FE0"
          strokeWidth="2"
          strokeLinecap="round"
          strokeDasharray="6 8"
          fill="none"
        >
          <animate
            attributeName="stroke-dashoffset"
            from="0"
            to="-28"
            dur="1.6s"
            repeatCount="indefinite"
          />
        </path>
        <circle cx="320" cy="200" r="4" fill="#1F4FE0" />
        <circle cx="440" cy="280" r="4" fill="#00B894" />
      </g>
    </svg>
  )
}
