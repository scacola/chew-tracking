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
      label: '다이어트 목적',
      helper: '천천히 먹는 습관을 만들고 싶어요',
      shortLabel: '다이어트',
    },
    digestion: {
      label: '소화 건강 개선',
      helper: '속이 편한 식사를 원해요',
      shortLabel: '소화 건강',
    },
    other: {
      label: '기타',
      helper: '식사 습관부터 가볍게 보고 싶어요',
      shortLabel: '기타',
    },
  },
}

export const purposeCopyJa: PurposeCopy = {
  legend: '関心のあるテーマは？',
  helperText: 'ご案内内容を整えるためだけに使います',
  error: '目的を1つ選択してください',
  options: {
    diet: {
      label: '早食いを整えたい',
      helper: '食べる速さに気づきたい',
      shortLabel: '早食い',
    },
    digestion: {
      label: '食事ペース',
      helper: '無理なく食べ方を整えたい',
      shortLabel: 'ペース',
    },
    other: {
      label: 'その他',
      helper: 'まずは軽く試してみたい',
      shortLabel: 'その他',
    },
  },
}

export const PURPOSE_VALUES: Purpose[] = ['diet', 'digestion', 'other']
