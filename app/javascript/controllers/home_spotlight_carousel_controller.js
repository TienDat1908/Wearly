import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["slide", "dot", "counter"]

  connect() {
    this.index = 0
    this.show()
  }

  next() {
    this.index = (this.index + 1) % this.slideTargets.length
    this.show()
  }

  previous() {
    this.index = (this.index - 1 + this.slideTargets.length) % this.slideTargets.length
    this.show()
  }

  go(event) {
    this.index = Number(event.currentTarget.dataset.index)
    this.show()
  }

  show() {
    this.slideTargets.forEach((slide, index) => {
      slide.classList.toggle("hidden", index !== this.index)
    })

    this.dotTargets.forEach((dot, index) => {
      const active = index === this.index
      const compactDot = dot.classList.contains("h-2.5")

      if (compactDot) {
        dot.classList.toggle("bg-pink-500", active)
        dot.classList.toggle("bg-slate-300", !active)
        dot.classList.toggle("bg-white/40", false)
        dot.classList.toggle("w-8", active)
        dot.classList.toggle("w-2.5", !active)
      } else {
        dot.classList.toggle("border-pink-500", active)
        dot.classList.toggle("border-white", !active)
      }
    })

    if (this.hasCounterTarget) {
      this.counterTarget.textContent = `${this.index + 1} / ${this.slideTargets.length}`
    }
  }
}
