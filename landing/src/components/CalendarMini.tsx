// 28일 코스 진행 상황을 보여주는 4주 × 7일 그리드
export function CalendarMini({ completedDays = 0 }: { completedDays?: number }) {
  const totalDays = 28
  return (
    <div className="grid grid-cols-7 gap-1.5" role="img" aria-label={`28일 중 ${completedDays}일 완료`}>
      {Array.from({ length: totalDays }).map((_, i) => {
        const completed = i < completedDays
        return (
          <div
            key={i}
            className={`aspect-square rounded-md border ${
              completed
                ? 'border-clinical bg-clinical/15'
                : 'border-line bg-bg-cool'
            }`}
            style={{ transitionDelay: `${i * 30}ms` }}
            data-reveal
          />
        )
      })}
    </div>
  )
}
