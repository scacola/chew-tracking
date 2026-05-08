// landing/src/lib/analytics.ts
//
// track() 단일 진입점 + identify() — 모든 분석 호출은 이 모듈을 통과한다.
//
// 정책:
//   - PII 차단: track() 시그니처에 email 받지 않음. props는 BaseProps 유니온.
//   - 봇·키 미설정 → silent no-op (posthog 자체가 init 안 됐으면 capture는 무시됨, 안전).
//   - 이벤트 이름은 AnalyticsEvent 유니온 — 오타 방지.
//
// 자세한 카탈로그: _workspace/landing/09_analytics_plan.md §2

import { posthog } from './posthogClient'
import Clarity from '@microsoft/clarity'
import { env, isClarityEnabled, isPostHogEnabled } from './env'

/** 이벤트 카탈로그 — 09_analytics_plan.md §2 표 그대로 */
export type AnalyticsEvent =
  | 'landing_view'
  | 'landing_page_viewed'
  | 'section_view'
  | 'cta_click'
  | 'cta_clicked'
  | 'faq_open'
  | 'email_focus'
  | 'email_input_focused'
  | 'purpose_select'
  | 'purpose_selected'
  | 'consent_view'
  | 'consent_dismiss'
  | 'form_submit_try'
  | 'form_submit_success'
  | 'form_submit_fail'
  | 'signup_dialog_opened'
  | 'signup_submit_attempted'
  | 'signup_submit_failed'
  | 'signup_succeeded'

export type Purpose = 'diet' | 'digestion' | 'other'
export type Source =
  | 'hero'
  | 'final_cta'
  | 'footer'
  | 'how_it_works'
  | 'faq'

/**
 * BaseProps — track() 시그니처의 props 타입.
 *
 * 절대 금지 (PII): `email`, `name`, `phone`, address, raw IP.
 * 코드 리뷰 시 grep으로 확인.
 */
export interface BaseProps {
  source?: Source | string
  purpose?: Purpose
  consent_marketing?: boolean
  consent_version?: string
  cta_id?: string
  cta_text?: string
  location?: string
  target?: 'scroll' | 'form' | 'external'
  section_id?: string
  faq_id?: string
  scroll_depth_pct?: number
  tier_focus?: string
  has_email?: boolean
  error_reason?: string
  reason?: string
  error_category?: string
  path?: string
  referrer?: string
  utm_source?: string
  utm_medium?: string
  utm_campaign?: string
  persona?: string
  is_duplicate?: boolean
  email_hash?: string
  locale?: 'ko' | 'ja'
  /** 그 외 자유 — 새 차원은 09_analytics_plan.md §3에 등록 후 사용 */
  [k: string]: unknown
}

let clarityStarted = false

function ensureClarity(): boolean {
  if (clarityStarted) return true
  if (!isClarityEnabled() || !env.VITE_CLARITY_PROJECT_ID) return false
  Clarity.init(env.VITE_CLARITY_PROJECT_ID)
  clarityStarted = true
  return true
}

/** 모든 분석 발화 단일 진입점 */
export function track(event: AnalyticsEvent, props: BaseProps = {}): void {
  if (typeof window === 'undefined') return
  if (isPostHogEnabled()) {
    posthog.capture(event, props)
  }
  if (ensureClarity()) {
    Clarity.event(event)
  }
}

/** identify trait 화이트리스트 — PII 금지 */
export interface IdentifyTraits {
  purpose?: Purpose
  consent_marketing?: boolean
  consent_at?: string
  consent_version?: string
  persona?: string
  email_hash?: string
}

/**
 * 옵트인 동의 시에만 호출. 거절 시 호출 X — anonymous 유지.
 * distinctId는 hashEmail() 결과 (sha256(email + salt)).
 */
export function identify(distinctId: string, traits: IdentifyTraits): void {
  if (typeof window === 'undefined') return
  if (!isPostHogEnabled()) return
  posthog.identify(distinctId, traits)
}
