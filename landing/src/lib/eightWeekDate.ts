// 8주 후 날짜를 한국식 "X월 N째 주"로 반환
// 예: 2026-05-01 + 56일 = 2026-06-26 → "6월 마지막 주"
export function eightWeeksFromNowKR(today: Date = new Date()): string {
  const target = new Date(today)
  target.setDate(target.getDate() + 56)
  const month = target.getMonth() + 1
  const day = target.getDate()
  const lastDayOfMonth = new Date(target.getFullYear(), target.getMonth() + 1, 0).getDate()

  // 1-7: 첫 주, 8-14: 둘째 주, 15-21: 셋째 주, 22-끝: 마지막 주
  let weekLabel = ''
  if (day <= 7) weekLabel = '첫 주'
  else if (day <= 14) weekLabel = '둘째 주'
  else if (day <= 21) weekLabel = '셋째 주'
  else if (day >= lastDayOfMonth - 6) weekLabel = '마지막 주'
  else weekLabel = '넷째 주'

  return `${month}월 ${weekLabel}`
}
