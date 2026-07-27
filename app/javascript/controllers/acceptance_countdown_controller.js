import { Controller } from "@hotwired/stimulus"

// Live countdown until booking.acceptance_deadline (ISO8601).
export default class extends Controller {
  static targets = ["display"]
  static values = {
    deadline: String,
    expired: { type: String, default: "Expired" },
    hoursLabel: { type: String, default: "h" },
    minutesLabel: { type: String, default: "m" },
    secondsLabel: { type: String, default: "s" }
  }

  connect() {
    this.tick()
    this.timer = window.setInterval(() => this.tick(), 1000)
  }

  disconnect() {
    if (this.timer) window.clearInterval(this.timer)
  }

  tick() {
    const deadline = Date.parse(this.deadlineValue)
    if (Number.isNaN(deadline)) return

    const remainingMs = deadline - Date.now()
    if (remainingMs <= 0) {
      this.displayTarget.textContent = this.expiredValue
      this.element.classList.add("is-expired")
      if (this.timer) {
        window.clearInterval(this.timer)
        this.timer = null
      }
      return
    }

    const totalSeconds = Math.floor(remainingMs / 1000)
    const hours = Math.floor(totalSeconds / 3600)
    const minutes = Math.floor((totalSeconds % 3600) / 60)
    const seconds = totalSeconds % 60

    const parts = []
    if (hours > 0) parts.push(`${hours}${this.hoursLabelValue}`)
    parts.push(`${minutes}${this.minutesLabelValue}`)
    parts.push(`${String(seconds).padStart(2, "0")}${this.secondsLabelValue}`)

    this.displayTarget.textContent = parts.join(" ")
  }
}
