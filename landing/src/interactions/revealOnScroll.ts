export function initRevealOnScroll(): IntersectionObserver | null {
  if (typeof window === 'undefined') return null
  if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
    document.querySelectorAll('[data-reveal]').forEach((el) => el.classList.add('revealed'))
    return null
  }
  const io = new IntersectionObserver(
    (entries) => {
      entries.forEach((e) => {
        if (e.isIntersecting) {
          e.target.classList.add('revealed')
          io.unobserve(e.target)
        }
      })
    },
    { threshold: 0.18, rootMargin: '0px 0px -8% 0px' }
  )
  document.querySelectorAll('[data-reveal]').forEach((el) => io.observe(el))
  // stagger index 자동 부여
  document.querySelectorAll('[data-reveal-stagger]').forEach((parent) => {
    Array.from(parent.children).forEach((child, i) => {
      ;(child as HTMLElement).style.setProperty('--i', String(i))
    })
  })
  return io
}
