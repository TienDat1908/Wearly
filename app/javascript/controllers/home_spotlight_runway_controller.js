import { Controller } from "@hotwired/stimulus"

// Each look = horizontal strip of angles.
// Show ONE face at a time; drag adds spin velocity (turntable), not strip scrubbing.
export default class extends Controller {
  static targets = ["item", "stage", "orbit", "counter", "hint", "strip", "window"]
  static values = {
    index: { type: Number, default: 0 },
    spinFrameCount: { type: Number, default: 1 },
    tiltHint: { type: String, default: "" },
    spinHint: { type: String, default: "" }
  }

  // Lower = more rotation per pixel (feels like spinning, not scrubbing a timeline)
  static SPIN_GAIN = 0.045
  static SPIN_FRICTION = 0.965
  static SPIN_MIN_VELOCITY = 0.004

  connect() {
    this.dragging = false
    this.moved = false
    this.startX = 0
    this.angle = 0
    this.velocity = 0
    this.lastX = 0
    this.lastT = 0
    this.raf = null
    this.spinning = false

    this.onResize = () => {
      this.sizeAllStrips()
      this.render()
    }
    this.onWindowUp = () => this.endDrag()
    this.onWindowMove = (event) => this.drag(event)

    window.addEventListener("resize", this.onResize)
    window.addEventListener("pointerup", this.onWindowUp)
    window.addEventListener("pointermove", this.onWindowMove)

    this.stripTargets.forEach((strip) => {
      if (strip.complete) this.sizeStrip(strip)
      else strip.addEventListener("load", () => this.sizeStrip(strip), { once: true })
    })

    this.render()
    this.paint()
    this.updateHint()
  }

  disconnect() {
    window.removeEventListener("resize", this.onResize)
    window.removeEventListener("pointerup", this.onWindowUp)
    window.removeEventListener("pointermove", this.onWindowMove)
    this.stopLoop()
  }

  get frameCount() {
    return Math.max(1, Math.min(36, Number(this.spinFrameCountValue || 1)))
  }

  get spinEnabled() {
    return this.frameCount >= 2 && this.stripTargets.length > 0
  }

  sizeAllStrips() {
    this.stripTargets.forEach((strip) => this.sizeStrip(strip))
  }

  sizeStrip(strip) {
    const frames = this.frameCount
    if (frames < 2 || !strip.naturalWidth) return

    const windowEl = strip.closest(".home-runway-spin-window")
    if (!windowEl) return

    const maxHeight = Math.min(560, Math.max(320, window.innerHeight * 0.52))
    const scale = maxHeight / strip.naturalHeight
    const frameWidth = (strip.naturalWidth / frames) * scale
    const frameHeight = strip.naturalHeight * scale

    windowEl.style.width = `${frameWidth}px`
    windowEl.style.height = `${frameHeight}px`
    strip.style.width = `${frameWidth * frames}px`
    strip.style.height = `${frameHeight}px`
    strip.style.setProperty("--frames", String(frames))
  }

  select(event) {
    if (this.moved) {
      this.moved = false
      return
    }

    const index = Number(event.currentTarget.dataset.index)
    if (Number.isNaN(index) || index === this.indexValue) return

    this.indexValue = index
    this.angle = 0
    this.velocity = 0
    this.stopLoop()
    this.render()
    this.paint()
    this.updateHint()
  }

  startDrag(event) {
    if (!event.target.closest(".home-runway-item.is-active")) return
    if (!this.spinEnabled) return

    this.dragging = true
    this.moved = false
    this.startX = this.pointerX(event)
    this.velocity = 0
    this.lastX = this.startX
    this.lastT = performance.now()
    this.stopLoop()
    this.stageTarget.classList.add("is-dragging")
    this.stageTarget.classList.add("is-spinning")
    event.preventDefault()
  }

  drag(event) {
    if (!this.dragging || !this.spinEnabled) return

    const x = this.pointerX(event)
    if (Math.abs(x - this.startX) > 4) this.moved = true

    const now = performance.now()
    const dt = Math.max(8, now - this.lastT)
    const dx = x - this.lastX

    // Horizontal drag turns the model (angle), not a film strip scrub.
    this.angle = this.wrapAngle(this.angle - dx * this.constructor.SPIN_GAIN)
    this.velocity = (-dx / dt) * this.constructor.SPIN_GAIN * 16
    this.lastX = x
    this.lastT = now
    this.paint()
  }

  endDrag() {
    if (!this.dragging) return
    this.dragging = false
    this.stageTarget.classList.remove("is-dragging")

    if (!this.spinEnabled) {
      this.stageTarget.classList.remove("is-spinning")
      return
    }

    // Flick → keep spinning like a turntable.
    if (Math.abs(this.velocity) > this.constructor.SPIN_MIN_VELOCITY) {
      this.startLoop()
    } else {
      this.snapToFace()
      this.stageTarget.classList.remove("is-spinning")
    }
  }

  startLoop() {
    this.spinning = true
    const tick = () => {
      if (!this.spinning) return

      this.angle = this.wrapAngle(this.angle + this.velocity)
      this.velocity *= this.constructor.SPIN_FRICTION
      this.paint()

      if (Math.abs(this.velocity) < this.constructor.SPIN_MIN_VELOCITY) {
        this.velocity = 0
        this.snapToFace()
        this.spinning = false
        this.stageTarget.classList.remove("is-spinning")
        this.raf = null
        return
      }

      this.raf = requestAnimationFrame(tick)
    }

    this.stopLoop()
    this.raf = requestAnimationFrame(tick)
  }

  stopLoop() {
    this.spinning = false
    if (this.raf) cancelAnimationFrame(this.raf)
    this.raf = null
  }

  snapToFace() {
    const frames = this.frameCount
    const face = Math.round(this.angle * frames) / frames
    this.angle = this.wrapAngle(face)
    this.paint()
  }

  wrapAngle(value) {
    return ((value % 1) + 1) % 1
  }

  // angle 0..1 → which face of the strip to show (discrete frame, no partial slide)
  frameIndex() {
    const frames = this.frameCount
    return Math.round(this.angle * frames) % frames
  }

  paint() {
    const frames = this.frameCount
    const activeFrame = this.spinEnabled ? this.frameIndex() : 0

    this.itemTargets.forEach((item, index) => {
      const strip = item.querySelector("[data-home-spotlight-runway-target='strip']")
      if (!strip) return

      // Side looks always face forward; center look shows current spin face.
      const frame = index === this.indexValue ? activeFrame : 0
      strip.style.setProperty("--frames", String(frames))
      strip.style.setProperty("--frame", String(frame))
    })
  }

  render() {
    const total = this.itemTargets.length
    if (total === 0) return

    this.indexValue = ((this.indexValue % total) + total) % total

    const stageWidth = this.hasStageTarget ? this.stageTarget.clientWidth : window.innerWidth
    const mobile = stageWidth <= 640
    const maxOffset = Math.max(1, Math.floor((total - 1) / 2))
    const composition = Math.min(stageWidth * (mobile ? 0.96 : 0.86), mobile ? 420 : 980)
    const step = composition / (maxOffset * 2 + 0.55)

    this.itemTargets.forEach((item, index) => {
      const offset = this.circularOffset(index, this.indexValue, total)
      const active = offset === 0
      const distance = Math.abs(offset)
      const scale = active ? 1 : distance === 1 ? 0.62 : 0.5
      const opacity = active ? 1 : distance === 1 ? 0.96 : 0.84

      item.classList.toggle("is-active", active)
      item.setAttribute("aria-pressed", active ? "true" : "false")
      item.tabIndex = active || distance === 1 ? 0 : -1
      item.style.zIndex = String(100 - distance)
      item.style.opacity = String(opacity)
      item.style.transform = `translate(calc(-50% + ${offset * step}px), -52%) scale(${scale})`
    })

    this.updateCounter()
  }

  updateCounter() {
    if (!this.hasCounterTarget) return
    const total = Number(this.counterTarget.dataset.total || this.itemTargets.length)
    const current = String(this.indexValue + 1).padStart(2, "0")
    const max = String(total).padStart(2, "0")
    this.counterTarget.textContent = `${current} / ${max}`
  }

  updateHint() {
    if (!this.hasHintTarget) return
    this.hintTarget.textContent = this.spinEnabled
      ? (this.spinHintValue || this.hintTarget.textContent)
      : (this.tiltHintValue || this.hintTarget.textContent)
  }

  circularOffset(index, active, total) {
    let offset = index - active
    const half = Math.floor(total / 2)
    if (offset > half) offset -= total
    if (offset < -half) offset += total
    return offset
  }

  pointerX(event) {
    return event.touches?.[0]?.clientX ?? event.clientX
  }
}
