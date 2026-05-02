import { useState, type FormEvent } from 'react'
import { Mail, ArrowRight, Check } from 'lucide-react'
import { cn } from '../lib/cn'

type Variant = 'inline' | 'stacked' | 'caption'

export function EmailForm({
  variant = 'inline',
  placeholder = '이메일 주소',
  ctaLabel = '베타에 합류하기',
  helperText = '개인정보는 진행 소식 외에는 사용하지 않아요.',
}: {
  variant?: Variant
  placeholder?: string
  ctaLabel?: string
  helperText?: string
}) {
  const [email, setEmail] = useState('')
  const [status, setStatus] = useState<'idle' | 'submitting' | 'success' | 'error'>('idle')
  const [shake, setShake] = useState(false)

  const isCaption = variant === 'caption'

  function handleSubmit(e: FormEvent) {
    e.preventDefault()
    if (!email.includes('@') || !email.includes('.')) {
      setStatus('error')
      setShake(true)
      setTimeout(() => setShake(false), 400)
      return
    }
    setStatus('submitting')
    // placeholder — 실제 백엔드 연결 전
    setTimeout(() => {
      setStatus('success')
      console.log('[track] beta_signup', { email, variant })
    }, 700)
  }

  if (status === 'success') {
    return (
      <div className={cn('flex items-center gap-2', isCaption ? 'text-caption' : 'text-body')}>
        <Check size={isCaption ? 16 : 20} strokeWidth={2} className="text-success" />
        <span className="text-text-secondary">합류해주셔서 감사해요. 진행 소식을 보내드릴게요.</span>
      </div>
    )
  }

  return (
    <form
      onSubmit={handleSubmit}
      className={cn(
        'w-full',
        variant === 'inline' && 'flex flex-col gap-3',
        variant === 'stacked' && 'flex flex-col gap-3',
        shake && 'form-shake',
      )}
      aria-describedby="email-helper"
    >
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
          이메일 주소 형식을 확인해주세요.
        </p>
      )}
    </form>
  )
}
