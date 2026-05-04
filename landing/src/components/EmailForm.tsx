// landing/src/components/EmailForm.tsx
//
// Phase 5-B-4: 목적 선택 + 컨센트 다이얼로그 + Supabase 저장 + PostHog 발화 통합.
// 변경: 14_purpose_consent_ux.md §7 + 09_analytics_plan.md §2 + 13_data_v2_consolidated.md §5

import { useRef, useState, type FormEvent } from 'react'
import { Mail, ArrowRight, Check } from 'lucide-react'
import { cn } from '../lib/cn'
import { submitSignup, type SubmitReason } from '../lib/dataCollection'
import { PurposeSelector, type PurposeVariant } from './PurposeSelector'
import { ConsentDialog } from './ConsentDialog'
import type { Purpose } from '../data/copy/purpose'
import { purposeCopy as defaultPurposeCopy } from '../data/copy/purpose'
import {
  consentDialogCopy as defaultConsentCopy,
  successCopy as defaultSuccessCopy,
  errorCopy as defaultErrorCopy,
  type ConsentDialogCopy,
  type SuccessCopy,
} from '../data/copy/consent'
import { env } from '../lib/env'
import { track, identify, type Source } from '../lib/analytics'
import { hashEmail } from '../lib/hashId'

/** URL ?p= 라우팅에서 persona 추출. 12.md §3.1 enum과 정합. */
function readPersonaFromUrl(): string {
  if (typeof window === 'undefined') return 'unknown'
  const p = new URLSearchParams(window.location.search).get('p')
  if (p === 'stomach' || p === 'diet' || p === 'checkup') return p
  return 'unknown'
}

type Variant = 'inline' | 'stacked' | 'caption'

const VARIANT_TO_PURPOSE_UI: Record<Variant, PurposeVariant> = {
  inline: 'segmented',
  stacked: 'cards',
  caption: 'dropdown',
}

export interface EmailFormProps {
  variant?: Variant
  placeholder?: string
  ctaLabel?: string
  helperText?: string
  /** 분석 source — 어디서 폼이 노출되었나 (track, Supabase에 모두 흘러감) */
  source: Source
  /** 카피 슬롯 — 미주입 시 디폴트 */
  purposeCopy?: typeof defaultPurposeCopy
  consentCopy?: ConsentDialogCopy
  successCopy?: SuccessCopy
}

export function EmailForm({
  variant = 'inline',
  placeholder = '이메일 주소',
  ctaLabel = '베타에 합류하기',
  helperText = '개인정보는 진행 소식 외에는 사용하지 않아요.',
  source,
  purposeCopy = defaultPurposeCopy,
  consentCopy = defaultConsentCopy,
  successCopy = defaultSuccessCopy,
}: EmailFormProps) {
  const [email, setEmail] = useState('')
  const [gotcha, setGotcha] = useState('')
  const [purpose, setPurpose] = useState<Purpose | null>(null)
  const [purposeError, setPurposeError] = useState(false)
  const [showConsentDialog, setShowConsentDialog] = useState(false)
  const [status, setStatus] = useState<'idle' | 'submitting' | 'success' | 'error'>(
    'idle',
  )
  const [errorReason, setErrorReason] = useState<SubmitReason>('invalid')
  const [shake, setShake] = useState(false)
  /** 옵트인 결과 — 성공 메시지 분기용 */
  const [optedIn, setOptedIn] = useState(false)

  const focusFiredOnce = useRef(false)
  const isCaption = variant === 'caption'

  function triggerShake() {
    setShake(true)
    setTimeout(() => setShake(false), 400)
  }

  function handleFormSubmit(e: FormEvent) {
    e.preventDefault()
    track('signup_submit_attempted', { source })

    // 1차 클라이언트 검증 — 빠른 피드백
    if (!email.includes('@') || !email.includes('.')) {
      setErrorReason('invalid')
      setStatus('error')
      track('signup_submit_failed', { source, reason: 'invalid_email' })
      triggerShake()
      return
    }
    if (!purpose) {
      setPurposeError(true)
      track('signup_submit_failed', { source, reason: 'purpose_missing' })
      triggerShake()
      return
    }

    // 2단계: ConsentDialog 띄우기
    track('signup_dialog_opened', { source, purpose })
    setShowConsentDialog(true)
  }

  async function handleConsentConfirm(consentMarketing: boolean) {
    setShowConsentDialog(false)
    setOptedIn(consentMarketing)
    setStatus('submitting')

    const consentAt = consentMarketing ? new Date().toISOString() : null

    const persona = readPersonaFromUrl()

    // 옵트인 시만 hash + identify (거절 시 anonymous 유지)
    let posthogDistinctId: string | null = null
    if (consentMarketing && env.VITE_HASH_SALT) {
      try {
        posthogDistinctId = await hashEmail(email, env.VITE_HASH_SALT)
      } catch {
        // hash/identify 실패해도 신청은 진행 — Supabase가 source of truth
      }
    }

    const result = await submitSignup({
      email,
      purpose: purpose!,
      consent_marketing: consentMarketing,
      consent_at: consentAt,
      consent_version: env.VITE_CONSENT_VERSION,
      source,
      posthog_distinct_id: posthogDistinctId,
      persona,
      _gotcha: gotcha,
    })

    if (result.ok) {
      setStatus('success')
      if (consentMarketing && posthogDistinctId) {
        identify(posthogDistinctId, {
          email_hash: posthogDistinctId,
          purpose: purpose ?? undefined,
          consent_marketing: true,
          consent_at: consentAt ?? undefined,
          consent_version: env.VITE_CONSENT_VERSION,
          persona,
        })
      }
      track('signup_succeeded', {
        source,
        purpose: purpose ?? undefined,
        consent_marketing: consentMarketing,
      })
      return
    }

    setErrorReason(result.reason)
    setStatus('error')
    track('signup_submit_failed', {
      source,
      purpose: purpose ?? undefined,
      reason: result.reason,
    })
    triggerShake()
  }

  function handleConsentCancel() {
    setShowConsentDialog(false)
    track('consent_dismiss', { source })
    // 폼 유지 — 사용자가 재제출 가능
  }

  if (status === 'success') {
    return (
      <div
        className={cn(
          'flex items-start gap-2',
          isCaption ? 'text-caption' : 'text-body',
        )}
        role="status"
      >
        <Check
          size={isCaption ? 16 : 20}
          strokeWidth={2}
          className="mt-0.5 shrink-0 text-success"
        />
        <span className="text-text-secondary">
          {optedIn ? successCopy.optedIn : successCopy.optedOut}
        </span>
      </div>
    )
  }

  return (
    <>
      <form
        onSubmit={handleFormSubmit}
        noValidate
        className={cn(
          'w-full',
          variant === 'inline' && 'flex flex-col gap-3',
          variant === 'stacked' && 'flex flex-col gap-4',
          variant === 'caption' && 'flex flex-col gap-2',
          shake && 'form-shake',
        )}
        aria-describedby="email-helper"
      >
        {/* honeypot — 봇이 채우면 차단. 시각적·접근성 트리에서 숨김 */}
        <input
          type="text"
          name="_gotcha"
          tabIndex={-1}
          aria-hidden="true"
          autoComplete="off"
          value={gotcha}
          onChange={(e) => setGotcha(e.target.value)}
          data-ph-no-capture="true"
          style={{
            position: 'absolute',
            left: '-9999px',
            width: '1px',
            height: '1px',
            opacity: 0,
            pointerEvents: 'none',
          }}
        />

        {/* 목적 선택 — variant에 따라 UI 분기 */}
        <PurposeSelector
          variant={VARIANT_TO_PURPOSE_UI[variant]}
          value={purpose}
          onChange={(p) => {
            setPurpose(p)
            setPurposeError(false)
            track('purpose_selected', { source, purpose: p })
          }}
          copy={purposeCopy}
          hasError={purposeError}
        />

        <div
          className={cn(
            variant === 'inline'
              ? 'flex flex-col gap-2 sm:flex-row sm:gap-2'
              : 'flex flex-col gap-2',
          )}
        >
          <div className="relative flex-1">
            {!isCaption && (
              <Mail
                size={18}
                strokeWidth={1.75}
                className="pointer-events-none absolute left-4 top-1/2 -translate-y-1/2 text-text-muted"
              />
            )}
            <input
              type="email"
              inputMode="email"
              autoComplete="email"
              placeholder={placeholder}
              value={email}
              data-ph-no-capture="true"
              onFocus={() => {
                if (!focusFiredOnce.current) {
                  track('email_input_focused', { source })
                  focusFiredOnce.current = true
                }
              }}
              onChange={(e) => {
                setEmail(e.target.value)
                if (status === 'error') setStatus('idle')
              }}
              className={cn(
                'w-full rounded-full border bg-bg-cool text-text-primary',
                'placeholder:text-text-subtle',
                'transition-all duration-200',
                'focus:border-cta focus:outline-none focus:ring-4 focus:ring-cta-soft',
                status === 'error' ? 'border-error' : 'border-line',
                isCaption ? 'h-10 px-4 text-body-sm' : 'h-14 pl-11 pr-4 text-body',
              )}
              aria-invalid={status === 'error'}
              required
            />
          </div>
          <button
            type="submit"
            disabled={status === 'submitting'}
            className={cn(
              'inline-flex items-center justify-center gap-2 rounded-full bg-cta text-white font-medium',
              'transition-all duration-200 ease-out hover:bg-cta-hover hover:shadow-lg',
              'active:scale-[0.97] disabled:opacity-60',
              isCaption ? 'h-10 px-5 text-body-sm' : 'h-14 px-7 text-body',
            )}
          >
            <span>{status === 'submitting' ? '처리 중...' : ctaLabel}</span>
            {status !== 'submitting' && <ArrowRight size={18} strokeWidth={1.75} />}
          </button>
        </div>

        {helperText && (
          <p
            id="email-helper"
            className={cn(
              'text-caption text-text-muted opacity-70',
              isCaption && 'opacity-60',
            )}
          >
            {helperText}
          </p>
        )}
        {status === 'error' && (
          <p className="text-caption text-error" role="alert">
            {defaultErrorCopy[errorReason]}
          </p>
        )}
      </form>

      <ConsentDialog
        isOpen={showConsentDialog}
        onCancel={handleConsentCancel}
        onConfirm={handleConsentConfirm}
        copy={consentCopy}
        consentVersion={env.VITE_CONSENT_VERSION}
      />
    </>
  )
}
