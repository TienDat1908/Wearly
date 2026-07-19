import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["image", "counter", "coverBadge", "thumb"]

  connect() {
    this.currentIndex = 0
    this.total = this.thumbTargets.length
    this.show(0)
  }

  select(event) {
    event.preventDefault()
    this.show(Number(event.currentTarget.dataset.index))
  }

  previous(event) {
    event.preventDefault()
    this.show(this.currentIndex - 1)
  }

  next(event) {
    event.preventDefault()
    this.show(this.currentIndex + 1)
  }

  show(index) {
    if (this.total === 0) return

    this.currentIndex = (index + this.total) % this.total
    const selectedThumb = this.thumbTargets[this.currentIndex]

    this.imageTarget.src = selectedThumb.dataset.fullUrl
    this.imageTarget.alt = selectedThumb.dataset.alt
    this.counterTarget.textContent = `${this.currentIndex + 1} / ${this.total}`
    this.coverBadgeTarget.hidden = this.currentIndex !== 0

    this.thumbTargets.forEach((thumb, thumbIndex) => {
      const isActive = thumbIndex === this.currentIndex
      thumb.classList.toggle("border-pink-400", isActive)
      thumb.classList.toggle("ring-4", isActive)
      thumb.classList.toggle("ring-pink-100", isActive)
      thumb.classList.toggle("border-orange-100", !isActive)
    })
  }
}
