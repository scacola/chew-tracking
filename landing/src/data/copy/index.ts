import { ko } from './ko'
import { ja } from './ja'
import type { Copy, Locale } from './types'

export const copies: Record<Locale, Copy> = { ko, ja }

export type { Copy, Locale }
