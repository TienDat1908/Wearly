import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "eyebrowInput",
    "titleInput",
    "subtitleInput",
    "imageInput",
    "activeInput",
    "frameInput",
    "eyebrow",
    "title",
    "subtitle",
    "status",
    "slideContainer",
    "slide",
    "dotContainer",
    "dot",
    "counter",
    "outfitGrid"
  ]

  connect() {
    this.index = 0
    this.update()
    this.show()
    this.clipExistingStripPreviews()
  }

  frameCount() {
    if (!this.hasFrameInputTarget) return 1
    return Math.max(1, Math.min(36, Number(this.frameInputTarget.value || 1)))
  }

  update() {
    if (this.hasEyebrowTarget && this.hasEyebrowInputTarget) {
      this.updateText(this.eyebrowTarget, this.eyebrowInputTarget.value)
    }
    if (this.hasTitleTarget && this.hasTitleInputTarget) {
      this.updateText(this.titleTarget, this.titleInputTarget.value)
    }
    if (this.hasSubtitleTarget && this.hasSubtitleInputTarget) {
      this.updateText(this.subtitleTarget, this.subtitleInputTarget.value)
    }
    this.updateStatus()
  }

  previewImage() {
    const files = Array.from(this.imageInputTarget.files).slice(0, 5)
    if (files.length === 0 || !this.hasSlideContainerTarget) return

    this.index = 0
    this.slideContainerTarget.replaceChildren()
    const frames = this.frameCount()

    files.forEach((file) => {
      const slide = document.createElement("div")
      slide.className = "absolute inset-0 flex items-end justify-center"
      slide.setAttribute("data-home-spotlight-preview-target", "slide")
      slide.appendChild(this.buildStripPreview(URL.createObjectURL(file), frames, "max-h-full"))
      this.slideContainerTarget.appendChild(slide)
    })

    this.renderOutfitGrid(files, frames)
    this.renderDots(files, frames)
    this.show()
  }

  go(event) {
    this.index = Number(event.currentTarget.dataset.index || 0)
    this.show()
  }

  updateText(target, value) {
    const nextValue = value.trim()
    target.textContent = nextValue.length > 0 ? nextValue : target.dataset.fallback
  }

  updateStatus() {
    if (!this.hasActiveInputTarget) return

    const live = this.activeInputTarget.checked
    this.statusTargets.forEach((status) => {
      status.textContent = live
        ? status.dataset.activeLabel
        : status.dataset.inactiveLabel
      status.classList.toggle("bg-emerald-500", live)
      status.classList.toggle("text-white", live)
      status.classList.toggle("bg-slate-100", !live)
      status.classList.toggle("text-slate-600", !live)
    })
  }

  show() {
    const total = this.slideTargets.length
    if (total === 0) return

    this.index = Math.min(this.index || 0, total - 1)

    this.slideTargets.forEach((slide, index) => {
      slide.classList.toggle("hidden", index !== this.index)
    })

    this.dotTargets.forEach((dot, index) => {
      const active = index === this.index
      dot.classList.toggle("border-pink-500", active)
      dot.classList.toggle("border-slate-200", !active)
    })

    if (this.hasCounterTarget) {
      this.counterTarget.textContent = `${this.index + 1} / ${total}`
    }

    if (this.hasDotContainerTarget) {
      this.dotContainerTarget.classList.toggle("hidden", total <= 1)
    }
  }

  renderDots(files, frames) {
    if (!this.hasDotContainerTarget) return
    this.dotContainerTarget.replaceChildren()

    files.forEach((file, index) => {
      const button = document.createElement("button")
      button.type = "button"
      button.className = "h-10 w-8 overflow-hidden rounded-md border border-slate-200"
      button.dataset.index = index
      button.setAttribute("data-action", "home-spotlight-preview#go")
      button.setAttribute("data-home-spotlight-preview-target", "dot")
      button.appendChild(this.buildStripPreview(URL.createObjectURL(file), frames, "h-full"))
      this.dotContainerTarget.appendChild(button)
    })
  }

  renderOutfitGrid(files, frames) {
    if (!this.hasOutfitGridTarget) return
    this.outfitGridTarget.replaceChildren()

    files.forEach((file, index) => {
      const figure = document.createElement("figure")
      figure.className = "overflow-hidden rounded-xl border border-slate-200 bg-[linear-gradient(180deg,#fff,#f3f4f6)]"
      figure.appendChild(this.buildStripPreview(URL.createObjectURL(file), frames, "aspect-[3/4]"))

      const caption = document.createElement("figcaption")
      caption.className = "px-1 py-1 text-center text-[9px] font-black uppercase tracking-wider text-slate-400"
      caption.textContent = frames >= 2 ? `Look ${index + 1} · 360` : `Look ${index + 1}`
      figure.appendChild(caption)
      this.outfitGridTarget.appendChild(figure)
    })
  }

  clipExistingStripPreviews() {
    const frames = this.frameCount()
    if (frames < 2) return

    this.element.querySelectorAll("[data-strip-preview='true']").forEach((image) => {
      const parent = image.parentElement
      if (!parent || parent.classList.contains("admin-strip-window")) return

      const windowEl = document.createElement("span")
      windowEl.className = "admin-strip-window"
      image.classList.add("admin-strip-sheet")
      image.style.setProperty("--frames", String(frames))
      image.style.setProperty("--frame", "0")
      parent.insertBefore(windowEl, image)
      windowEl.appendChild(image)

      const fit = () => this.fitAdminStrip(windowEl, image, frames)
      if (image.complete) fit()
      else image.addEventListener("load", fit, { once: true })
    })
  }

  buildStripPreview(src, frames, sizeClass) {
    if (frames < 2) {
      const image = document.createElement("img")
      image.className = `${sizeClass} w-full object-contain`
      image.alt = ""
      image.src = src
      return image
    }

    const windowEl = document.createElement("span")
    windowEl.className = `admin-strip-window ${sizeClass}`.trim()
    const image = document.createElement("img")
    image.className = "admin-strip-sheet"
    image.alt = ""
    image.src = src
    image.style.setProperty("--frames", String(frames))
    image.style.setProperty("--frame", "0")
    windowEl.appendChild(image)

    const fit = () => this.fitAdminStrip(windowEl, image, frames)
    if (image.complete) fit()
    else image.addEventListener("load", fit, { once: true })
    return windowEl
  }

  fitAdminStrip(windowEl, image, frames) {
    if (!image.naturalWidth) return
    const maxHeight = windowEl.classList.contains("h-full") ? 40 : 180
    const scale = maxHeight / image.naturalHeight
    const frameWidth = (image.naturalWidth / frames) * scale
    const frameHeight = image.naturalHeight * scale
    windowEl.style.width = `${frameWidth}px`
    windowEl.style.height = `${frameHeight}px`
    windowEl.style.margin = "0 auto"
    image.style.width = `${frameWidth * frames}px`
    image.style.height = `${frameHeight}px`
  }
}
