// landing/src/data/copy/purpose.ts
//
// 목적 선택 UI 카피 — 15_consent_copy.md §1·§2 + §8 JSON 그대로.
//
// enum 값(`diet`/`digestion`/`other`)은 *불변*. UI 라벨만 자유롭게.
// 09_analytics_plan.md §3.3 + 12_supabase_schema.md §3.2 합의.

export type Purpose = 'diet' | 'digestion' | 'other'

export interface PurposeOption {
  /** 라디오 카드용 풀 라벨 (≤12자) */
  label: string
  /** 라디오 카드 helper / 마이크로카피 (≤30자) */
  helper: string
  /** 세그먼트 컨트롤용 짧은 라벨 (≤8자) */
  shortLabel: string
}

export interface PurposeCopy {
  /** 목적 선택 위 헤드 (≤16자) */
  legend: string
  /** 헤드 아래 helper */
  helperText: string
  /** 미선택 + 제출 시도 시 에러 (≤24자) */
  error: string
  options: Record<Purpose, PurposeOption>
}

/** 디폴트 카피 — 15_consent_copy.md 그대로 */
export const purposeCopy: PurposeCopy = {
  legend: '어떤 이유로 관심이 가세요?',
  helperText: '선택은 진행 소식을 더 잘 보내드리는 데만 써요',
  error: '목적을 하나 선택해주세요',
  options: {
    diet: {
      label: '체중·식습관',
      helper: '더 천천히 먹고 싶어요',
      shortLabel: '체중·식습관',
    },
    digestion: {
      label: '식사 리듬',
      helper: '먹는 속도가 궁금해요',
      shortLabel: '식사 리듬',
    },
    other: {
      label: '그 외 / 둘 다',
      helper: '먼저 습관을 보고 싶어요',
      shortLabel: '그 외',
    },
  },
}

export const PURPOSE_VALUES: Purpose[] = ['diet', 'digestion', 'other']
