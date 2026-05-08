// landing/src/lib/supabaseClient.ts
//
// Supabase JS 클라이언트 — anon 키만 사용 (RLS 정책과 한 세트).
//
// 보안 모델:
//   - VITE_SUPABASE_ANON_KEY는 빌드 시 클라이언트 번들에 인라인됨 — 공개 안전 (RLS와 결합).
//   - service_role 키는 *절대 사용 X*. Dashboard SQL Editor·백오피스에서만.
//   - 키 누락 시: createClient 호출 안 함 → null 반환 → submitSignup이 'config' reason으로 거절.
//
// 자세한 통합 패턴: .claude/skills/landing-data-collection/references/supabase-integration.md §4

import { createClient, type SupabaseClient } from '@supabase/supabase-js'
import { env, isSupabaseEnabled } from './env'

export const supabase: SupabaseClient | null = isSupabaseEnabled()
  ? createClient(env.VITE_SUPABASE_URL!, env.VITE_SUPABASE_ANON_KEY!, {
      auth: {
        // 익명 폼 — 세션 영속 불필요. localStorage 오염 회피.
        persistSession: false,
        autoRefreshToken: false,
        detectSessionInUrl: false,
      },
      global: {
        headers: {
          'X-Client-Info': 'chew-coach-landing@v2',
        },
      },
    })
  : null
