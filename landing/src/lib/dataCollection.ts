// landing/src/lib/dataCollection.ts
//
// Web3Forms 통합 — 백엔드 없는 이메일 수집.
//
// 보안 모델:
//   - VITE_W3FORMS_KEY는 빌드 시 클라이언트 번들에 인라인된다 (Vite VITE_* 규칙).
//   - 이 키는 *해당 폼에 데이터를 push하는 권한만* 갖는다 — 다른 데이터를 읽을 수 없다.
//   - 따라서 노출은 안전. 단 봇이 직접 endpoint를 칠 수 있으므로 honeypot으로 방어.
//
// 운영 가이드: _workspace/landing/08_data_collection_runbook.md

const W3FORMS_ENDPOINT = 'https://api.web3forms.com/submit'

export type SubmitReason = 'rate-limit' | 'network' | 'invalid' | 'config'

export type SubmitResult =
  | { ok: true }
  | { ok: false; reason: SubmitReason }

export interface SubmitEmailPayload {
  email: string
  source: string // 'inline' | 'stacked' | 'caption' 등 — EmailForm variant
  /** honeypot — 봇이 채우면 차단. 정상 사용자에게는 안 보이는 필드 */
  _gotcha?: string
}

/**
 * Web3Forms로 이메일 1건 제출.
 *
 * 분기:
 *  - honeypot 채워짐 → { ok: true } (봇에는 성공처럼 보이게 — 분석 회피)
 *  - 이메일 형식·길이 위반 → { ok: false, reason: 'invalid' }
 *  - VITE_W3FORMS_KEY 미설정 → { ok: false, reason: 'config' } (개발자 신호)
 *  - HTTP 429 또는 Web3Forms 한도 초과 → { ok: false, reason: 'rate-limit' }
 *  - 그 외 네트워크/서버 오류 → { ok: false, reason: 'network' }
 */
export async function submitEmail(payload: SubmitEmailPayload): Promise<SubmitResult> {
  // 봇 차단 — honeypot이 채워졌으면 success처럼 응답 (하지만 실제 호출 X)
  if (payload._gotcha && payload._gotcha.length > 0) {
    return { ok: true }
  }

  // 클라이언트 검증
  const email = payload.email.trim()
  if (email.length < 5 || email.length > 200 || !email.includes('@')) {
    return { ok: false, reason: 'invalid' }
  }

  const accessKey = import.meta.env.VITE_W3FORMS_KEY as string | undefined
  if (!accessKey || accessKey.length === 0) {
    // 개발 환경에서 디버깅 쉽게 — 프로덕션 빌드에서도 콘솔에는 한 번만 찍힘
    console.warn(
      '[dataCollection] VITE_W3FORMS_KEY is not set. ' +
        'Set it in landing/.env (local) or GitHub repo Secrets (production). ' +
        'See _workspace/landing/08_data_collection_runbook.md',
    )
    return { ok: false, reason: 'config' }
  }

  try {
    const res = await fetch(W3FORMS_ENDPOINT, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Accept: 'application/json',
      },
      body: JSON.stringify({
        access_key: accessKey,
        email,
        subject: '[Chew Coach] 새 베타 신청',
        from_name: 'Chew Coach Landing',
        source: payload.source,
      }),
    })

    if (res.status === 429) {
      return { ok: false, reason: 'rate-limit' }
    }
    if (!res.ok) {
      // Web3Forms는 한도 초과 시 401, 키 오류도 401로 응답할 수 있음.
      // 사용자 입장에서는 "잠시 후 다시"로 통일 — rate-limit/network 둘 중 더 정확한 쪽으로.
      if (res.status === 401 || res.status === 403) {
        return { ok: false, reason: 'rate-limit' }
      }
      return { ok: false, reason: 'network' }
    }

    // Web3Forms 응답: { success: true, message: '...' } 또는 { success: false, message: '...' }
    const data: unknown = await res.json().catch(() => null)
    if (
      data &&
      typeof data === 'object' &&
      'success' in data &&
      (data as { success: unknown }).success === false
    ) {
      return { ok: false, reason: 'network' }
    }

    return { ok: true }
  } catch {
    return { ok: false, reason: 'network' }
  }
}
