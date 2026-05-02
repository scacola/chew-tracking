import { useEffect, useState } from 'react'
import type { PersonaKey } from '../data/personas'

export function usePersonaRoute(): PersonaKey {
  const [persona, setPersona] = useState<PersonaKey>('stomach')

  useEffect(() => {
    const params = new URLSearchParams(window.location.search)
    const p = params.get('p')
    if (p === 'diet' || p === 'checkup' || p === 'stomach') {
      setPersona(p)
    }
  }, [])

  return persona
}
