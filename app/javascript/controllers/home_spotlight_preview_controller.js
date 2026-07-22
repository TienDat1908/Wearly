import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "eyebrowInput",
    "titleInput",
    "subtitleInput",
    "imageInput",
    "activeInput",
    "eyebrow",
    "title",
    "subtitle",
    "status",
    "slideContainer",
    "slide",
    "dotContainer",
    "dot",
    "counter",
    "controls",
  ]

  connect() {
    this.index = 0
    this.update()
    this.show()
  }

  update() {
    this.updateText(this.eyebrowTarget, this.eyebrowInputTarget.value)
    this.updateText(this.titleTarget, this.titleInputTarget.value)
    this.updateText(this.subtitleTarget, this.subtitleInputTarget.value)
    this.updateStatus()
  }

  previewImage() {
    const files = Array.from(this.imageInputTarget.files).slice(0, 5)

    if (files.length === 0 || !this.hasSlideContainerTarget) return

    this.index = 0
    this.slideContainerTarget.replaceChildren()

    files.forEach((file, index) => {
      const slide = document.createElement("div")
      slide.className = "absolute inset-0"
      slide.setAttribute("data-home-spotlight-preview-target", "slide")

      const image = document.createElement("img")
      image.className = "h-full w-full object-cover"
      image.alt = ""
      image.src = URL.createObjectURL(file)

      slide.appendChild(image)
      this.slideContainerTarget.appendChild(slide)
    })

    this.renderDots(files.length)
    this.show()
  }

  previous() {
    this.move(-1)
  }

  next() {
    this.move(1)
  }

  go(event) {
    this.index = Number(event.currentTarget.dataset.index || 0)
    this.show()
  }

  move(direction) {
    const total = this.slideTargets.length
    if (total <= 1) return

    this.index = (this.index + direction + total) % total
    this.show()
  }

  updateText(target, value) {
    const nextValue = value.trim()
    target.textContent = nextValue.length > 0 ? nextValue : target.dataset.fallback
  }

  updateStatus() {
    if (!this.hasStatusTarget || !this.hasActiveInputTarget) return

    this.statusTarget.textContent = this.activeInputTarget.checked
      ? this.statusTarget.dataset.activeLabel
      : this.statusTarget.dataset.inactiveLabel
  }

  show() {
    const total = this.slideTargets.length
    if (total === 0) return

    this.index = Math.min(this.index || 0, total - 1)

    this.slideTargets.forEach((slide, index) => {
      slide.classList.toggle("hidden", index !== this.index)
    })

    this.dotTargets.forEach((dot, index) => {
      dot.classList.toggle("bg-pink-500", index === this.index)
      dot.classList.toggle("w-5", index === this.index)
      dot.classList.toggle("bg-white/35", index !== this.index)
      dot.classList.toggle("w-2", index !== this.index)
    })

    if (this.hasCounterTarget) {
      this.counterTarget.textContent = `${this.index + 1} / ${total}`
    }

    this.controlsTargets.forEach((control) => {
      control.classList.toggle("hidden", total <= 1)
    })

    if (this.hasDotContainerTarget) {
      this.dotContainerTarget.classList.toggle("hidden", total <= 1)
    }
  }

  renderDots(total) {
    if (!this.hasDotContainerTarget) return

    this.dotContainerTarget.replaceChildren()

    for (let index = 0; index < total; index += 1) {
      const dot = document.createElement("button")
      dot.type = "button"
      dot.className = "h-2 rounded-full transition"
      dot.dataset.index = index
      dot.setAttribute("aria-label", `Preview image ${index + 1}`)
      dot.setAttribute("data-action", "home-spotlight-preview#go")
      dot.setAttribute("data-home-spotlight-preview-target", "dot")

      this.dotContainerTarget.appendChild(dot)
    }
  }
}
