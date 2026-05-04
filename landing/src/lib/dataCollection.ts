// landing/src/lib/dataCollection.ts
//
// Supabase 통합 — 옵션 G 베타 신청 영구 저장.
//
// 본 라운드 (Phase 5-B-4) 마이그: Web3Forms 호출 *완전 제거* → Supabase upsert.
//   - 마이그 패스 B (즉시 컷오버) — 12_supabase_schema.md §6 권장.
//   - VITE_W3FORMS_KEY 의존성 제거.
//   - 보안 모델: anon 키만 (RLS 정책과 한 세트). service_role 절대 X.
//
// 자세한 운영 가이드: _workspace/landing/12_supabase_schema.md, 08_data_collection_runbook.md

import { supabase } from './supabaseClient'
import type { Purpose } from '../data/copy/purpose'

export type SubmitReason =
  | 'invalid'
  | 'network'
  | 'rate-limit'
  | 'config'
  | 'consent_required'

export type SubmitResult = { ok: true } | { ok: false; reason: SubmitReason }

export interface SubmitSignupPayload {
  email: string
  purpose: Purpose
  consent_marketing: boolean
  /** 옵트인 시 ISO timestamp, 거절 시 null */
  consent_at: string | null
  /** ISO date 약관 버전 (env.VITE_CONSENT_VERSION) */
  consent_version: string
  /** 폼 위치 — analytics source와 동일 enum */
  source: string
  /** sha256(email_lower + salt) — 옵트인 시만, 거절 시 null */
  posthog_distinct_id: string | null
  /** 방문자가 본 랜딩 variant (URL ?p= 라우팅) — 미주입 시 'unknown' */
  persona?: string
  /** honeypot — 봇 차단 (정상 사용자에게는 안 보이는 필드) */
  _gotcha?: string
}

/**
 * Supabase signups 테이블에 신청 1건 insert.
 *
 * 분기:
 *  - honeypot 채워짐 → { ok: true } (봇에는 성공처럼 응답)
 *  - 이메일 형식·길이 위반 → { ok: false, reason: 'invalid' }
 *  - Supabase 클라이언트 미설정 → { ok: false, reason: 'config' }
 *  - PostgREST 23505 (unique violation) → { ok: true } (중복 이메일은 사용자에게 success)
 *  - PostgREST 42501 (RLS deny) → { ok: false, reason: 'config' }
 *  - 그 외 → { ok: false, reason: 'network' }
 *
 * 중복 처리: 23505는 사용자에게 성공 처리 — 같은 이메일이 다시 와도 성공으로 보임.
 */
export async function submitSignup(payload: SubmitSignupPayload): Promise<SubmitResult> {
  // 봇 차단 — honeypot이 채워졌으면 success처럼 응답하되 실제 호출 X
  if (payload._gotcha && payload._gotcha.length > 0) {
    return { ok: true }
  }

  // 클라이언트 검증
  const email = payload.email.trim()
  if (email.length < 5 || email.length > 200 || !email.includes('@') || !email.includes('.')) {
    return { ok: false, reason: 'invalid' }
  }

  // Supabase 클라이언트 미설정 (env 누락) — silent disable + 사용자에게는 config 신호
  if (!supabase) {
    if (import.meta.env.DEV) {
      console.warn(
        '[dataCollection] Supabase client not initialized (env missing). ' +
          'Set VITE_SUPABASE_URL + VITE_SUPABASE_ANON_KEY in landing/.env. ' +
          'See _workspace/landing/13_data_v2_consolidated.md §6',
      )
    }
    return { ok: false, reason: 'config' }
  }

  try {
    const { error } = await supabase.from('signups').insert(
      {
        email,
        purpose: payload.purpose,
        // persona는 미지정 시 DB column default 'unknown'에 위임 (12.md §3.1)
        ...(payload.persona ? { persona: payload.persona } : {}),
        consent_marketing: payload.consent_marketing,
        consent_at: payload.consent_at,
        consent_version: payload.consent_version,
        source: payload.source,
        posthog_distinct_id: payload.posthog_distinct_id,
        user_agent:
          typeof navigator !== 'undefined' ? navigator.userAgent.slice(0, 500) : null,
      },
    )

    if (error) {
      // PostgREST 에러 코드 매핑
      // 23505 = unique violation (race 시) — upsert인데도 발생하면 사용자에게는 성공으로 처리
      if (error.code === '23505') return { ok: true }
      // 42501 = RLS 정책 deny (insufficient_privilege) — 정책 누락 / 잘못된 키
      if (error.code === '42501') return { ok: false, reason: 'config' }
      // 23514 = check constraint (예: consent_marketing=true인데 consent_at=null) → consent_required
      if (error.code === '23514') return { ok: false, reason: 'consent_required' }
      return { ok: false, reason: 'network' }
    }

    return { ok: true }
  } catch (e) {
    if (import.meta.env.DEV) console.warn('[dataCollection] submit failed:', e)
    return { ok: false, reason: 'network' }
  }
}
