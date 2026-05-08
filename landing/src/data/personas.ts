export type PersonaKey = 'stomach' | 'diet' | 'checkup'

export type PersonaContent = {
  key: PersonaKey
  subhead: string[]
}

export const personas: Record<PersonaKey, PersonaContent> = {
  stomach: {
    key: 'stomach',
    subhead: [
      '점심마다 금방 끝나는 식사,',
      '내가 생각한 것보다 훨씬 빠를 수 있어요.',
      '이번엔 감이 아니라 기록으로 함께해요.',
    ],
  },
  diet: {
    key: 'diet',
    subhead: [
      '운동도, 식단도 챙기는데 변화가 더디다면 —',
      '먹는 속도를 의심해보세요.',
      '하루 한 번의 식사 리듬이 새로운 변수가 돼요.',
    ],
  },
  checkup: {
    key: 'checkup',
    subhead: [
      '결과표 위에 적혀 있던 그 한 줄 —',
      '"식사 속도를 조금만 늦춰보세요."',
      '8주 코스로, 다음 점검까지 차분히 준비해요.',
    ],
  },
}
