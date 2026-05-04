import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './styles/globals.css'
import App from './App.tsx'
import { initPostHog } from './lib/posthogClient'
import { warnIfDisabled } from './lib/env'

// PostHog init — 진입점 1회. 키 미설정 / 봇 / SSR 시 silent disable.
initPostHog()
// dev 환경에서 비활성화된 시스템 안내 (production은 빌드 시점에 키 누락 시 GitHub Actions가 차단할 수 있음)
warnIfDisabled()

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>,
)
