// landing/src/lib/posthogClient.ts
//
// PostHog init — 단일 가드 (__loaded 체크) + SSR 가드 + 봇 차단.
//
// 정책:
//   - capture_pageview: false (직접 발화 — SPA 라우팅 안전)
//   - autocapture allowlist ['click'] (input/change PII 자동수집 차단)
//   - disable_session_recording: true (베타 단계 OFF)
//   - respect_dnt: true (DNT 헤더 사용자 자동 opt-out)
//   - 키 미설정 → silent disable + dev console warn
//
// 자세한 패턴: .claude/skills/landing-analytics-instrumentation/SKILL.md §1·6

import posthog from 'posthog-js'
import { env, isPostHogEnabled } from './env'

const BOT_UA = /(bot|crawler|spider|headless|lighthouse|gtmetrix|pingdom|uptimerobot)/i

function isBot(): boolean {
  if (typeof navigator === 'undefined') return false
  return BOT_UA.test(navigator.userAgent)
}

let initAttempted = false

/**
 * PostHog 초기화. 다음 모든 조건을 만족해야 실제 init.
 *  - 브라우저 환경 (typeof window !== 'undefined')
 *  - 봇 UA 아님
 *  - 환경변수 둘 다 설정 (VITE_POSTHOG_KEY + VITE_POSTHOG_HOST)
 *  - 이미 init되지 않음 (posthog.__loaded false)
 */
export function initPostHog(): void {
  if (initAttempted) return
  initAttempted = true

  if (typeof window === 'undefined') return
  if (isBot()) return
  if (!isPostHogEnabled()) {
    if (import.meta.env.DEV) {
      console.warn('[posthog] keys missing — analytics disabled')
    }
    return
  }
  // 동일 모듈 재import 방어 (HMR·라이브러리 중복 init 방지)
  // posthog-js는 내부적으로 __loaded flag를 갖는다.
  if ((posthog as unknown as { __loaded?: boolean }).__loaded) return

  posthog.init(env.VITE_POSTHOG_KEY!, {
    api_host: env.VITE_POSTHOG_HOST!,
    capture_pageview: false,
    capture_pageleave: true,
    autocapture: {
      // input/change/submit는 캡처 X — PII 차단의 1차 방어선
      dom_event_allowlist: ['click'],
    },
    persistence: 'localStorage+cookie',
    respect_dnt: true,
    mask_all_text: false,
    session_recording: {
      maskAllInputs: true,
    },
    disable_session_recording: true,
    loaded: (ph) => {
      if (import.meta.env.DEV) ph.debug()
    },
  })
}

export { posthog }
