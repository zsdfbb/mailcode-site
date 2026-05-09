document.addEventListener('DOMContentLoaded', function () {
  initScrollAnimations()
  initCopyButtons()
  initTabs()
  initLangSwitcher()
  initMobileMenu()
})

/* Scroll animations via IntersectionObserver */
function initScrollAnimations() {
  const els = document.querySelectorAll('.fade-up')
  if (!els.length) return
  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          entry.target.classList.add('visible')
          observer.unobserve(entry.target)
        }
      })
    },
    { threshold: 0.1, rootMargin: '0px 0px -40px 0px' }
  )
  els.forEach((el) => observer.observe(el))
}

/* Copy buttons */
function initCopyButtons() {
  document.querySelectorAll('.install-copy, .copy-btn').forEach((btn) => {
    btn.addEventListener('click', function () {
      const code = this.parentElement.querySelector('code, pre')
      if (!code) return
      const text = code.textContent.trim()
      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(text).then(() => showCopied(this))
      } else {
        fallbackCopy(text, this)
      }
    })
  })
}

function showCopied(el) {
  const orig = el.innerHTML
  el.classList.add('copied')
  el.innerHTML = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg> Copied'
  setTimeout(() => {
    el.classList.remove('copied')
    el.innerHTML = orig
  }, 2000)
}

function fallbackCopy(text, el) {
  const ta = document.createElement('textarea')
  ta.value = text
  ta.style.position = 'fixed'
  ta.style.opacity = '0'
  document.body.appendChild(ta)
  ta.select()
  try {
    document.execCommand('copy')
    showCopied(el)
  } catch (e) {
    // silently fail
  }
  document.body.removeChild(ta)
}

/* Installation tabs */
function initTabs() {
  document.querySelectorAll('.tab-btn').forEach((btn) => {
    btn.addEventListener('click', function () {
      const container = this.closest('.tabs')
      container.querySelectorAll('.tab-btn').forEach((b) => b.classList.remove('active'))
      container.querySelectorAll('.tab-content').forEach((c) => c.classList.remove('active'))
      this.classList.add('active')
      const target = this.getAttribute('data-tab')
      const content = container.querySelector('.tab-content[data-tab="' + target + '"]')
      if (content) content.classList.add('active')
    })
  })
}

/* Language switcher */
function initLangSwitcher() {
  const btn = document.querySelector('.lang-btn')
  const dropdown = document.querySelector('.lang-dropdown')
  if (!btn || !dropdown) return

  btn.addEventListener('click', function (e) {
    e.stopPropagation()
    dropdown.classList.toggle('open')
  })

  document.addEventListener('click', function () {
    dropdown.classList.remove('open')
  })

  dropdown.addEventListener('click', function (e) {
    e.stopPropagation()
  })
}

/* Mobile menu */
function initMobileMenu() {
  const toggle = document.querySelector('.mobile-toggle')
  const navLinks = document.querySelector('.nav-links')
  if (!toggle || !navLinks) return

  toggle.addEventListener('click', function () {
    navLinks.classList.toggle('open')
  })

  document.querySelectorAll('.nav-links a').forEach(function (link) {
    link.addEventListener('click', function () {
      navLinks.classList.remove('open')
    })
  })
}
