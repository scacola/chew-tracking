// landing/src/components/PurposeSelector.tsx
//
// 목적 선택 UI — 14_purpose_consent_ux.md §1 그대로.
// 3 variant: cards (디폴트, 라디오 카드 3개) / segmented (pill 3개) / dropdown (네이티브 select)

import { Scale, Sparkles, MoreHorizontal, Check } from 'lucide-react'
import { cn } from '../lib/cn'
import type { Purpose, PurposeCopy } from '../data/copy/purpose'
import { PURPOSE_VALUES } from '../data/copy/purpose'

export type PurposeVariant = 'cards' | 'segmented' | 'dropdown'

export interface PurposeSelectorProps {
  variant?: PurposeVariant
  value: Purpose | null
  onChange: (next: Purpose) => void
  copy: PurposeCopy
  /** 미선택 + 제출 시도 시 강조 */
  hasError?: boolean
  className?: string
}

const ICON_MAP: Record<Purpose, typeof Scale> = {
  diet: Scale,
  digestion: Sparkles,
  other: MoreHorizontal,
}

export function PurposeSelector({
  variant = 'cards',
  value,
  onChange,
  copy,
  hasError = false,
  className,
}: PurposeSelectorProps) {
  if (variant === 'dropdown') {
    return (
      <PurposeDropdown
        value={value}
        onChange={onChange}
        copy={copy}
        hasError={hasError}
        className={className}
      />
    )
  }
  if (variant === 'segmented') {
    return (
      <PurposeSegmented
        value={value}
        onChange={onChange}
        copy={copy}
        hasError={hasError}
        className={className}
      />
    )
  }
  return (
    <PurposeRadioCards
      value={value}
      onChange={onChange}
      copy={copy}
      hasError={hasError}
      className={className}
    />
  )
}

// ----- variant: cards -----------------------------------------------------

function PurposeRadioCards({
  value,
  onChange,
  copy,
  hasError,
  className,
}: Omit<PurposeSelectorProps, 'variant'>) {
  return (
    <div className={cn('flex flex-col gap-2', className)}>
      <div className="flex flex-col gap-0.5">
        <span
          id="purpose-legend"
          className="text-body-sm font-semibold text-text-primary"
        >
          {copy.legend}
        </span>
        <span className="text-caption text-text-muted opacity-80">{copy.helperText}</span>
      </div>
      <div
        role="radiogroup"
        aria-labelledby="purpose-legend"
        aria-invalid={hasError || undefined}
        className="grid grid-cols-1 gap-3 sm:grid-cols-3 sm:gap-3"
      >
        {PURPOSE_VALUES.map((p) => {
          const Icon = ICON_MAP[p]
          const isSelected = value === p
          const opt = copy.options[p]
          return (
            <label
              key={p}
              className={cn(
                'group relative flex cursor-pointer flex-col gap-2 rounded-xl border bg-bg-cool p-4 sm:p-4',
                'transition-all duration-200 ease-out',
                'hover:border-line-strong hover:shadow-sm',
                'has-[:focus-visible]:outline-2 has-[:focus-visible]:outline-cta has-[:focus-visible]:outline-offset-2',
                isSelected
                  ? 'border-cta bg-cta-soft/40 shadow-sm ring-2 ring-cta/20'
                  : hasError
                    ? 'border-error/60'
                    : 'border-line',
              )}
            >
              <input
                type="radio"
                name="purpose"
                value={p}
                checked={isSelected}
                onChange={() => onChange(p)}
                className="peer sr-only"
              />
              <div className="flex items-start justify-between gap-3">
                <div className="flex flex-col gap-1">
                  <div className="flex items-center gap-2">
                    <Icon size={18} strokeWidth={1.75} className="text-clinical-deep" />
                    <span className="text-body font-semibold text-text-primary">
                      {opt.label}
                    </span>
                  </div>
                  <p className="text-body-sm text-text-muted">{opt.helper}</p>
                </div>
                <div
                  aria-hidden="true"
                  className={cn(
                    'mt-1 flex h-5 w-5 shrink-0 items-center justify-center rounded-full border-2',
                    'transition-colors duration-150',
                    isSelected
                      ? 'border-cta bg-cta'
                      : 'border-line-strong bg-transparent',
                  )}
                >
                  {isSelected && <Check size={12} strokeWidth={3} className="text-white" />}
                </div>
              </div>
            </label>
          )
        })}
      </div>
      {hasError && (
        <p className="text-caption text-error" role="alert">
          {copy.error}
        </p>
      )}
    </div>
  )
}

// ----- variant: segmented -------------------------------------------------

function PurposeSegmented({
  value,
  onChange,
  copy,
  hasError,
  className,
}: Omit<PurposeSelectorProps, 'variant'>) {
  return (
    <div className={cn('flex flex-col gap-1.5', className)}>
      <span
        id="purpose-legend-segmented"
        className="text-caption text-text-muted opacity-80"
      >
        {copy.legend}
      </span>
      <div
        role="radiogroup"
        aria-labelledby="purpose-legend-segmented"
        aria-invalid={hasError || undefined}
        className={cn(
          'inline-flex w-full rounded-full border bg-bg-cool p-1',
          hasError ? 'border-error/60' : 'border-line',
        )}
      >
        {PURPOSE_VALUES.map((p) => {
          const isSelected = value === p
          const opt = copy.options[p]
          return (
            <button
              key={p}
              type="button"
              role="radio"
              aria-checked={isSelected}
              onClick={() => onChange(p)}
              className={cn(
                'flex-1 rounded-full px-3 py-2 text-body-sm transition-all duration-200 ease-out',
                'focus-visible:outline-2 focus-visible:outline-cta focus-visible:outline-offset-2',
                isSelected
                  ? 'bg-cta text-white shadow-sm'
                  : 'text-text-muted hover:bg-bg-mist hover:text-text-primary',
              )}
            >
              {opt.shortLabel}
            </button>
          )
        })}
      </div>
      {hasError && (
        <p className="text-caption text-error" role="alert">
          {copy.error}
        </p>
      )}
    </div>
  )
}

// ----- variant: dropdown --------------------------------------------------

function PurposeDropdown({
  value,
  onChange,
  copy,
  hasError,
  className,
}: Omit<PurposeSelectorProps, 'variant'>) {
  return (
    <div className={cn('flex flex-col gap-1', className)}>
      <label htmlFor="purpose-dropdown" className="sr-only">
        {copy.legend}
      </label>
      <select
        id="purpose-dropdown"
        value={value ?? ''}
        onChange={(e) => {
          const v = e.target.value
          if (v === 'diet' || v === 'digestion' || v === 'other') onChange(v)
        }}
        aria-invalid={hasError || undefined}
        className={cn(
          'h-10 w-full rounded-full border bg-bg-cool px-4 text-body-sm text-text-primary',
          'focus:outline-none focus:ring-4 focus:ring-cta-soft',
          'transition-all duration-200',
          hasError ? 'border-error focus:border-cta' : 'border-line focus:border-cta',
        )}
      >
        <option value="" disabled>
          {copy.legend}
        </option>
        {PURPOSE_VALUES.map((p) => (
          <option key={p} value={p}>
            {copy.options[p].label}
          </option>
        ))}
      </select>
      {hasError && (
        <p className="text-caption text-error" role="alert">
          {copy.error}
        </p>
      )}
    </div>
  )
}
