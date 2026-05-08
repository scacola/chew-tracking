import { copyFileSync, mkdirSync } from 'node:fs'
import { join } from 'node:path'

const distDir = join(process.cwd(), 'dist')
const jaDir = join(distDir, 'ja')

mkdirSync(jaDir, { recursive: true })
copyFileSync(join(distDir, 'index.html'), join(jaDir, 'index.html'))
