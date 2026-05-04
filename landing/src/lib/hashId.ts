// landing/src/lib/hashId.ts
//
// distinctId hash 공식 — sha256(email_lower + VITE_HASH_SALT) 64자 hex.
//
// 양 시스템 (PostHog distinct_id, Supabase posthog_distinct_id) 동일 hash 사용.
// salt는 빌드 시 번들에 인라인되므로 보안 가치 약함 — rainbow table 회피용.
//
// 13_data_v2_consolidated.md §3 참조.

/**
 * @param email 사용자가 입력한 이메일 (raw, 대소문자/공백 포함 가능)
 * @param salt VITE_HASH_SALT
 * @returns 64자 hex SHA-256
 */
export async function hashEmail(email: string, salt: string): Promise<string> {
  const normalized = email.trim().toLowerCase()
  const data = new TextEncoder().encode(normalized + salt)
  const buf = await crypto.subtle.digest('SHA-256', data)
  return Array.from(new Uint8Array(buf))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('')
}
