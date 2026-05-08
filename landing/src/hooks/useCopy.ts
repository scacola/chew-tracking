import { copies } from '../data/copy'
import { useLocale } from './useLocale'

export function useCopy() {
  return copies[useLocale()]
}
