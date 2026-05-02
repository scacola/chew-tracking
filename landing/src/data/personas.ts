export type PersonaKey = 'stomach' | 'diet' | 'checkup'

export type PersonaContent = {
  key: PersonaKey
  subhead: string[]
}

export const personas: Record<PersonaKey, PersonaContent> = {
  stomach: {
    key: 'stomach',
    subhead: [
      '점심마다 영상 보며 11분 만에 끝나는 식사,',
      '당신의 위가 보내는 신호일 수 있어요.',
      '의사가 말한 "천천히 드세요" — 이번엔 데이터로 함께해요.',
    ],
  },
  diet: {
    key: 'diet',
    subhead: [
      '운동도, 칼로리도, 다 지켰는데 안 빠진다면 —',
      '먹는 속도를 의심해보세요.',
      '8주 만에, 정체기를 풀어줄 새로운 변수.',
    ],
  },
  checkup: {
    key: 'checkup',
    subhead: [
      '건강검진 결과지 위에 적혀 있던 그 한 줄 —',
      '"식사 속도 개선 권장."',
      '8주 코스로, 다음 검진까지 차분히 준비해요.',
    ],
  },
}
