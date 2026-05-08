import Clarity from '@microsoft/clarity'
import type { Locale } from '../data/copy'

let clarityStarted = false

type AnalyticsProps = Record<string, string | number | boolean | null | undefined>

function getProjectId() {
  return import.meta.env.VITE_CLARITY_PROJECT_ID as string | undefined
}

function formatEventName(name: string, props?: AnalyticsProps) {
  if (!props) return name

  const encoded = Object.entries(props)
    .filter(([, value]) => value !== undefined && value !== null)
    .map(([key, value]) => `${key}:${String(value)}`)
    .join('|')

  return encoded ? `${name}|${encoded}` : name
}

export function initClarity() {
  const projectId = getProjectId()
  if (!projectId || clarityStarted) return

  Clarity.init(projectId)
  clarityStarted = true
}

export function trackEvent(name: string, props?: AnalyticsProps) {
  if (!clarityStarted) return
  Clarity.event(formatEventName(name, props))
}

export function trackLandingView(locale: Locale, path: string) {
  trackEvent('landing_view', { locale, path })
}
