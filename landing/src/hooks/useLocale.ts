import { useEffect, useState } from 'react'
import type { Locale } from '../data/copy'

function getLocaleFromPath(): Locale {
  if (typeof window === 'undefined') return 'ko'
  const segments = window.location.pathname.split('/').filter(Boolean)
  return segments.includes('ja') ? 'ja' : 'ko'
}

export function useLocale(): Locale {
  const [locale, setLocale] = useState<Locale>(() => getLocaleFromPath())

  useEffect(() => {
    setLocale(getLocaleFromPath())
  }, [])

  return locale
}
