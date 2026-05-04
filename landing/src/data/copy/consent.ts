// landing/src/data/copy/consent.ts
//
// 컨센트 다이얼로그 카피 + 성공/에러 메시지 — 15_consent_copy.md §3·§4·§5 + §8 JSON 그대로.

export interface ConsentDialogCopy {
  /** 다이얼로그 헤드 (≤15자, 모바일 한 줄) */
  head: string
  /** 본문 2-3문장 */
  body: string
  checkbox: {
    /** "출시 소식 받기 (선택)" — 디폴트 OFF */
    label: string
    /** 체크 해제 상태에서 표시되는 보조 텍스트 (옵션) */
    uncheckedHint: string
  }
  links: {
    terms: string
    privacy: string
    versionLabel: string
    versionSeparator: string
  }
  buttons: {
    primary: string
    secondary: string
  }
}

export interface SuccessCopy {
  optedIn: string
  optedOut: string
}

export type ErrorReasonKey =
  | 'invalid'
  | 'network'
  | 'rate-limit'
  | 'config'
  | 'consent_required'
  | 'consent_skew'
  | 'unknown'

export type ErrorCopy = Record<ErrorReasonKey, string>

export interface ConsentMeta {
  consent_version: string
  tone: string
  validated: string
}

/** 디폴트 카피 — 15_consent_copy.md §8 JSON 그대로 */
export const consentDialogCopy: ConsentDialogCopy = {
  head: '출시되면 이메일로 알려드릴게요',
  body: '베타가 준비되면 가장 먼저 소식을 보내드려요. 출시 외 광고는 보내지 않고, 언제든 [수신거부]로 그만두실 수 있어요. 1만 명이 기다린다고 거짓말하지 않아요 — 함께 걸을 첫 사람들을 모으고 있어요.',
  checkbox: {
    label: '출시 소식 받기 (선택)',
    uncheckedHint: '출시 소식은 보내지 않아요. 신청은 그대로 처리돼요.',
  },
  links: {
    terms: '이용약관',
    privacy: '개인정보 처리방침',
    versionLabel: '약관 적용일',
    versionSeparator: ' · ',
  },
  buttons: {
    primary: '확인하고 신청',
    secondary: '취소',
  },
}

export const successCopy: SuccessCopy = {
  optedIn: '합류해주셔서 감사해요. 베타가 준비되면 가장 먼저 알려드릴게요.',
  optedOut:
    '신청해주셔서 감사해요. 따로 메일은 보내지 않을게요. 출시되면 사이트에서 만나요.',
}

export const errorCopy: ErrorCopy = {
  invalid: '이메일 주소 형식을 확인해주세요.',
  network: '전송에 실패했어요. 잠시 후 다시 시도해주세요.',
  'rate-limit': '요청이 많아 잠시 쉬어가요. 1분 뒤 다시 시도해주세요.',
  config: '전송 설정에 문제가 있어요. 잠시 후 다시 시도해주세요.',
  consent_required: '잠깐 문제가 있었어요. 다시 한 번 시도해주세요.',
  consent_skew: '기기 시간에 차이가 있는 것 같아요. 시계를 맞춘 뒤 다시 시도해주세요.',
  unknown: '전송 중 예기치 않은 문제가 있었어요. 잠시 후 다시 시도해주세요.',
}

export const consentMeta: ConsentMeta = {
  consent_version: '2026-05-04',
  tone: 'option-G (clinical-trust 30 / friendly-coaching 50 / mindful-calm 20)',
  validated: 'marketing-storyteller 2026-05-04 — §7 7항 전부 통과',
}
