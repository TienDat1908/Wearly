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
      dot.classList.toggle("bg-pink-500", index === this.index)
      dot.classList.toggle("bg-white/40", index !== this.index)
    })

    if (this.hasCounterTarget) {
      this.counterTarget.textContent = `${this.index + 1} / ${this.slideTargets.length}`
    }
  }
}
