// landing/src/components/ConsentDialog.tsx
//
// 컨센트 다이얼로그 — 14_purpose_consent_ux.md §2 + 15_consent_copy.md §3 그대로.
//
// 핵심 결정 (designer 정정 우선):
//  - 체크박스 디폴트 = OFF (PIPA 능동 동의 원칙)
//  - autoFocus = primary 버튼 [확인하고 신청]
//  - Focus trap = HTML5 inert attribute (의존성 0)
//  - ESC + 백드롭 클릭 = 취소
//  - 모션: backdrop fade 200ms + dialog scale 0.96→1 250ms easeOut
//  - reduced-motion: transition-duration 0.01s (사실상 즉시)

import { createPortal } from 'react-dom'
import { useEffect, useRef, useState } from 'react'
import { Check, X } from 'lucide-react'
import { cn } from '../lib/cn'
import type { ConsentDialogCopy } from '../data/copy/consent'

export interface ConsentDialogProps {
  isOpen: boolean
  /** 사용자가 ESC, 백드롭 클릭, [취소] 버튼 누름 */
  onCancel: () => void
  /** [확인하고 신청] 클릭 — consentMarketing은 체크박스 상태 */
  onConfirm: (consentMarketing: boolean) => void
  copy: ConsentDialogCopy
  /** env.VITE_CONSENT_VERSION 주입 — "약관 적용일: ..." 표시 */
  consentVersion: string
}

export function ConsentDialog({
  isOpen,
  onCancel,
  onConfirm,
  copy,
  consentVersion,
}: ConsentDialogProps) {
  // 디폴트 OFF — PIPA 능동 동의 원칙 (14.md §0 결정 / 15.md §3.3.1)
  const [consentMarketing, setConsentMarketing] = useState(false)
  const primaryButtonRef = useRef<HTMLButtonElement>(null)

  // 다이얼로그가 열릴 때마다 체크박스 OFF로 리셋 (PIPA 능동 동의 + 재제출 안전)
  useEffect(() => {
    if (isOpen) setConsentMarketing(false)
  }, [isOpen])

  // ESC 키 처리
  useEffect(() => {
    if (!isOpen) return
    function handleKey(e: KeyboardEvent) {
      if (e.key === 'Escape') onCancel()
    }
    window.addEventListener('keydown', handleKey)
    return () => window.removeEventListener('keydown', handleKey)
  }, [isOpen, onCancel])

  // Focus trap via inert + autoFocus to primary button
  useEffect(() => {
    if (typeof document === 'undefined') return
    const root = document.getElementById('root')
    if (!root) return
    if (isOpen) {
      root.setAttribute('inert', '')
      // 다이얼로그 등장 모션 후 primary button focus (250ms 모션 + 약간의 여유)
      const t = setTimeout(() => {
        primaryButtonRef.current?.focus()
      }, 60)
      return () => {
        clearTimeout(t)
        root.removeAttribute('inert')
      }
    }
    root.removeAttribute('inert')
    return undefined
  }, [isOpen])

  if (typeof document === 'undefined') return null

  return createPortal(
    <>
      {/* Backdrop */}
      <div
        data-consent-backdrop
        className={cn(
          'fixed inset-0 z-40 bg-bg-deep/60 backdrop-blur-sm',
          'transition-opacity duration-200 ease-out',
          isOpen ? 'opacity-100' : 'pointer-events-none opacity-0',
        )}
        aria-hidden="true"
        onClick={onCancel}
      />

      {/* Dialog */}
      <div
        data-consent-dialog
        role="dialog"
        aria-modal="true"
        aria-labelledby="consent-dialog-title"
        aria-describedby="consent-dialog-body"
        aria-hidden={!isOpen}
        className={cn(
          'fixed left-1/2 top-1/2 z-50 w-[96vw] max-w-[480px] -translate-x-1/2 -translate-y-1/2',
          'max-h-[90vh] overflow-y-auto',
          'rounded-xl border border-line bg-bg-cool p-6 sm:p-8',
          'shadow-xl',
          'transition-all duration-300 ease-[cubic-bezier(0.16,1,0.3,1)]',
          isOpen
            ? 'pointer-events-auto scale-100 opacity-100'
            : 'pointer-events-none scale-[0.96] opacity-0',
        )}
      >
        {/* Close X (선택 — ESC와 동일) */}
        <button
          type="button"
          onClick={onCancel}
          className={cn(
            'absolute right-4 top-4 inline-flex h-8 w-8 items-center justify-center rounded-full text-text-muted',
            'transition-colors hover:bg-bg-mist hover:text-text-primary',
            'focus-visible:outline-2 focus-visible:outline-cta focus-visible:outline-offset-2',
          )}
          aria-label="닫기"
        >
          <X size={18} strokeWidth={1.75} />
        </button>

        {/* Head */}
        <h2
          id="consent-dialog-title"
          className="pr-8 text-heading-3 text-text-primary"
          style={{ fontWeight: 700, letterSpacing: '-0.015em' }}
        >
          {copy.head}
        </h2>

        {/* Body */}
        <p
          id="consent-dialog-body"
          className="mt-3 text-body leading-relaxed text-text-secondary"
        >
          {copy.body}
        </p>

        {/* Checkbox */}
        <div className="mt-6">
          <label
            htmlFor="consent-marketing-checkbox"
            className={cn(
              'flex cursor-pointer items-start gap-3 rounded-md p-2 -m-2',
              'transition-colors hover:bg-bg-mist/60',
            )}
          >
            <input
              id="consent-marketing-checkbox"
              type="checkbox"
              data-ph-no-capture="true"
              checked={consentMarketing}
              onChange={(e) => setConsentMarketing(e.target.checked)}
              className="peer sr-only"
            />
            <span
              aria-hidden="true"
              className={cn(
                'mt-[2px] flex h-5 w-5 shrink-0 items-center justify-center rounded-[6px] border-2',
                'transition-all duration-100 ease-out',
                consentMarketing
                  ? 'border-cta bg-cta'
                  : 'border-line-strong bg-bg-cool peer-hover:border-text-muted',
                'peer-focus-visible:outline-2 peer-focus-visible:outline-cta peer-focus-visible:outline-offset-2',
              )}
            >
              {consentMarketing && (
                <Check size={14} strokeWidth={3} className="text-white" />
              )}
            </span>
            <span className="text-body text-text-primary">{copy.checkbox.label}</span>
          </label>
          {!consentMarketing && copy.checkbox.uncheckedHint && (
            <p
              className="mt-2 pl-9 text-caption text-text-muted opacity-70"
              role="status"
            >
              {copy.checkbox.uncheckedHint}
            </p>
          )}
        </div>

        {/* Links */}
        <div className="mt-4 flex flex-wrap items-center gap-x-2 gap-y-1 text-caption text-text-muted">
          <a
            href="/terms"
            target="_blank"
            rel="noopener noreferrer"
            className={cn(
              'underline underline-offset-2 decoration-line-strong',
              'transition-colors hover:text-text-primary hover:decoration-text-primary',
              'focus-visible:outline-2 focus-visible:outline-cta focus-visible:outline-offset-2 focus-visible:rounded',
            )}
          >
            {copy.links.terms}
          </a>
          <span aria-hidden="true">·</span>
          <a
            href="/privacy"
            target="_blank"
            rel="noopener noreferrer"
            className={cn(
              'underline underline-offset-2 decoration-line-strong',
              'transition-colors hover:text-text-primary hover:decoration-text-primary',
              'focus-visible:outline-2 focus-visible:outline-cta focus-visible:outline-offset-2 focus-visible:rounded',
            )}
          >
            {copy.links.privacy}
          </a>
          <span aria-hidden="true">·</span>
          <span>
            {copy.links.versionLabel}: {consentVersion}
          </span>
        </div>

        {/* Actions */}
        <div className="mt-6 flex flex-col-reverse gap-2 sm:flex-row sm:justify-end sm:gap-3">
          <button
            type="button"
            onClick={onCancel}
            className={cn(
              'inline-flex h-12 items-center justify-center rounded-full border border-line bg-bg-cool px-6 text-body font-medium text-text-primary',
              'transition-all duration-200 ease-out hover:bg-bg-mist',
              'active:scale-[0.97]',
              'focus-visible:outline-2 focus-visible:outline-cta focus-visible:outline-offset-2',
            )}
          >
            {copy.buttons.secondary}
          </button>
          <button
            ref={primaryButtonRef}
            type="button"
            onClick={() => onConfirm(consentMarketing)}
            className={cn(
              'inline-flex h-12 items-center justify-center rounded-full bg-cta px-6 text-body font-medium text-white',
              'transition-all duration-200 ease-out hover:bg-cta-hover hover:shadow-lg',
              'active:scale-[0.97]',
              'focus-visible:outline-2 focus-visible:outline-cta focus-visible:outline-offset-2',
            )}
          >
            {copy.buttons.primary}
          </button>
        </div>
      </div>
    </>,
    document.body,
  )
}
