import { Container } from '../components/Container'
import { EmailForm } from '../components/EmailForm'

export function Footer() {
  return (
    <footer className="border-t border-line bg-bg-cool py-12 md:py-16">
      <Container>
        <div className="grid gap-10 md:grid-cols-3 md:gap-8">
          {/* 좌: 로고 */}
          <div>
            <h3 className="text-heading-3 text-text-primary" style={{ fontWeight: 700 }}>
              Chew & Calm
            </h3>
            <p className="mt-2 text-caption text-text-muted">© 2026 Chew & Calm Coach</p>
          </div>

          {/* 가운데: 빠른 링크 */}
          <nav className="flex flex-wrap gap-4 md:gap-6">
            {[
              ['How', 'how-it-works'],
              ['FAQ', 'faq'],
              ['Privacy', '#'],
              ['Terms', '#'],
            ].map(([label, target]) => (
              <a
                key={label}
                href={target.startsWith('#') ? target : `#${target}`}
                onClick={(e) => {
                  if (!target.startsWith('#')) {
                    e.preventDefault()
                    document.getElementById(target)?.scrollIntoView({ behavior: 'smooth' })
                  }
                }}
                className="text-body-sm text-text-secondary transition-colors hover:text-text-primary"
              >
                {label}
              </a>
            ))}
          </nav>

          {/* 우: 작은 폼 */}
          <div>
            <p className="mb-3 text-caption text-text-muted">진행 소식 받기</p>
            <EmailForm
              variant="caption"
              ctaLabel="구독"
              placeholder="이메일"
              helperText=""
              source="footer"
            />
          </div>
        </div>
      </Container>
    </footer>
  )
}
