// landing/src/lib/env.ts
//
// 환경변수 zod 검증 + graceful degradation.
//
// 정책:
//   - 모든 키는 *optional*. 빌드는 키 없이도 통과해야 한다 (개발자 첫 clone, 키 설정 전).
//   - 운영 키 누락 시: 콘솔 warn만 + 해당 시스템(PostHog/Supabase) silent disable.
//   - 잘못된 형식(예: VITE_POSTHOG_KEY가 phc_로 시작 X) → zod 에러를 잡아 warn으로 격하.
//
// 자세한 셋업: _workspace/landing/13_data_v2_consolidated.md §6

import { z } from 'zod'

const EnvSchema = z.object({
  VITE_SUPABASE_URL: z.string().url().optional(),
  VITE_SUPABASE_ANON_KEY: z.string().min(20).optional(),
  VITE_POSTHOG_KEY: z
    .string()
    .regex(/^phc_/, 'PostHog public key must start with phc_')
    .optional(),
  VITE_POSTHOG_HOST: z.string().url().optional(),
  VITE_HASH_SALT: z.string().min(8, 'Salt must be at least 8 chars').optional(),
  VITE_CONSENT_VERSION: z
    .string()
    .regex(/^\d{4}-\d{2}-\d{2}$/, 'consent version must be ISO date (YYYY-MM-DD)')
    .default('2026-05-04'),
})

export type Env = z.infer<typeof EnvSchema>

function readRawEnv(): Record<string, unknown> {
  return {
    VITE_SUPABASE_URL: import.meta.env.VITE_SUPABASE_URL,
    VITE_SUPABASE_ANON_KEY: import.meta.env.VITE_SUPABASE_ANON_KEY,
    VITE_POSTHOG_KEY: import.meta.env.VITE_POSTHOG_KEY,
    VITE_POSTHOG_HOST: import.meta.env.VITE_POSTHOG_HOST,
    VITE_HASH_SALT: import.meta.env.VITE_HASH_SALT,
    VITE_CONSENT_VERSION: import.meta.env.VITE_CONSENT_VERSION,
  }
}

function parseEnv(): Env {
  const raw = readRawEnv()
  const result = EnvSchema.safeParse(raw)
  if (result.success) return result.data
  // 잘못된 형식 — 의미 있는 메시지로 warn하고 default 반환
  if (typeof window !== 'undefined') {
    console.warn(
      '[env] 환경변수 검증 실패 — 일부 분석/저장 기능이 비활성화됩니다.\n',
      result.error.issues.map((i) => `  ${i.path.join('.')}: ${i.message}`).join('\n'),
    )
  }
  // 잘못된 키는 제외하고 default + 유효한 것만 반환
  const safe: Record<string, unknown> = { VITE_CONSENT_VERSION: '2026-05-04' }
  for (const key of Object.keys(raw)) {
    const single = EnvSchema.pick({ [key]: true } as never).safeParse({ [key]: raw[key] })
    if (single.success) safe[key] = (single.data as Record<string, unknown>)[key]
  }
  return EnvSchema.parse(safe)
}

export const env: Env = parseEnv()

/** 런타임 helper — Supabase 사용 가능 여부 */
export function isSupabaseEnabled(): boolean {
  return !!(env.VITE_SUPABASE_URL && env.VITE_SUPABASE_ANON_KEY)
}

/** 런타임 helper — PostHog 사용 가능 여부 */
export function isPostHogEnabled(): boolean {
  return !!(env.VITE_POSTHOG_KEY && env.VITE_POSTHOG_HOST)
}

/** dev 환경에서 키 누락 안내 1회 */
let warnedOnce = false
export function warnIfDisabled(): void {
  if (warnedOnce) return
  warnedOnce = true
  if (typeof window === 'undefined') return
  if (!isSupabaseEnabled()) {
    console.warn(
      '[env] Supabase 키 누락 — 폼 제출이 비활성화됩니다. landing/.env에 VITE_SUPABASE_URL, VITE_SUPABASE_ANON_KEY 채우기.',
    )
  }
  if (!isPostHogEnabled()) {
    console.warn(
      '[env] PostHog 키 누락 — 분석이 비활성화됩니다. landing/.env에 VITE_POSTHOG_KEY, VITE_POSTHOG_HOST 채우기.',
    )
  }
}
