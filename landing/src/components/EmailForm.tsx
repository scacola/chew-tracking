import { useState, type FormEvent } from 'react'
import { Mail, ArrowRight, Check } from 'lucide-react'
import { cn } from '../lib/cn'
import { submitEmail, type SubmitReason } from '../lib/dataCollection'

type Variant = 'inline' | 'stacked' | 'caption'

const ERROR_COPY: Record<SubmitReason, string> = {
  invalid: '이메일 주소 형식을 확인해주세요.',
  network: '전송에 실패했어요. 잠시 후 다시 시도해주세요.',
  'rate-limit': '요청이 많아 잠시 쉬어가요. 1분 뒤 다시 시도해주세요.',
  config: '전송 설정에 문제가 있어요. 잠시 후 다시 시도해주세요.',
}

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
  const [gotcha, setGotcha] = useState('')
  const [status, setStatus] = useState<'idle' | 'submitting' | 'success' | 'error'>('idle')
  const [errorReason, setErrorReason] = useState<SubmitReason>('invalid')
  const [shake, setShake] = useState(false)

  const isCaption = variant === 'caption'

  async function handleSubmit(e: FormEvent) {
    e.preventDefault()

    // 1차 클라이언트 검증 — 빠른 피드백
    if (!email.includes('@') || !email.includes('.')) {
      setErrorReason('invalid')
      setStatus('error')
      setShake(true)
      setTimeout(() => setShake(false), 400)
      return
    }

    setStatus('submitting')
    const result = await submitEmail({ email, source: variant, _gotcha: gotcha })

    if (result.ok) {
      setStatus('success')
      // 분석 라인 — 성공 시에만
      console.log('[track] beta_signup', { email, variant })
      return
    }

    // 에러 분기 — reason별 메시지 분리
    setErrorReason(result.reason)
    setStatus('error')
    setShake(true)
    setTimeout(() => setShake(false), 400)
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
      {/* honeypot — 봇이 채우면 차단. 시각적·접근성 트리에서 숨김 */}
      <input
        type="text"
        name="_gotcha"
        tabIndex={-1}
        aria-hidden="true"
        autoComplete="off"
        value={gotcha}
        onChange={(e) => setGotcha(e.target.value)}
        style={{
          position: 'absolute',
          left: '-9999px',
          width: '1px',
          height: '1px',
          opacity: 0,
          pointerEvents: 'none',
        }}
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
          {ERROR_COPY[errorReason]}
        </p>
      )}
    </form>
  )
}
