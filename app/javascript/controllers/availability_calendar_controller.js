import { Controller } from "@hotwired/stimulus"

// Month calendar for owner blocks + renter date picking.
// data-availability-calendar-busy-value: JSON array of {kind,start_on,end_on}
// data-availability-calendar-mode-value: "owner" | "renter"
export default class extends Controller {
  static targets = [
    "grid",
    "label",
    "startOn",
    "endOn",
    "startTime",
    "endTime",
    "hint"
  ]
  static values = {
    busy: { type: Array, default: [] },
    mode: { type: String, default: "owner" },
    month: String
  }

  connect() {
    this.cursor = this.monthValue ? new Date(`${this.monthValue}-01T12:00:00`) : new Date()
    this.cursor.setDate(1)
    this.selectionStart = null
    this.boundManualChange = () => this.onManualDateChange()
    if (this.hasStartOnTarget) this.startOnTarget.addEventListener("change", this.boundManualChange)
    if (this.hasEndOnTarget) this.endOnTarget.addEventListener("change", this.boundManualChange)
    this.render()
  }

  disconnect() {
    if (this.hasStartOnTarget) this.startOnTarget.removeEventListener("change", this.boundManualChange)
    if (this.hasEndOnTarget) this.endOnTarget.removeEventListener("change", this.boundManualChange)
  }

  previousMonth(event) {
    event.preventDefault()
    this.cursor.setMonth(this.cursor.getMonth() - 1)
    this.render()
  }

  nextMonth(event) {
    event.preventDefault()
    this.cursor.setMonth(this.cursor.getMonth() + 1)
    this.render()
  }

  pick(event) {
    const iso = event.currentTarget.dataset.date
    if (!iso || event.currentTarget.dataset.busy === "true") return

    if (this.modeValue === "renter") {
      this.pickRenter(iso)
    } else {
      this.pickOwner(iso)
    }
    this.render()
  }

  onManualDateChange() {
    if (this.modeValue === "renter") {
      if (this.rangeHasBusy(this.startOnTarget.value, this.endOnTarget.value)) {
        if (this.hasHintTarget) {
          this.hintTarget.textContent = this.hintTarget.dataset.busyMessage || "Selected range includes unavailable days."
        }
        if (this.hasEndOnTarget) this.endOnTarget.value = ""
      } else if (this.hasHintTarget) {
        this.hintTarget.textContent = ""
      }
      this.syncDateTimes()
    }
    this.render()
  }

  pickOwner(iso) {
    if (!this.selectionStart || (this.startOnTarget.value && this.endOnTarget.value)) {
      this.selectionStart = iso
      this.startOnTarget.value = iso
      this.endOnTarget.value = iso
      return
    }

    if (iso < this.selectionStart) {
      this.endOnTarget.value = this.selectionStart
      this.startOnTarget.value = iso
      this.selectionStart = iso
    } else {
      this.endOnTarget.value = iso
    }
  }

  pickRenter(iso) {
    const start = this.startOnTarget?.value
    const end = this.endOnTarget?.value

    if (!start || (start && end)) {
      if (this.hasStartOnTarget) this.startOnTarget.value = iso
      if (this.hasEndOnTarget) this.endOnTarget.value = ""
      this.syncDateTimes()
      return
    }

    if (iso < start) {
      if (this.hasStartOnTarget) this.startOnTarget.value = iso
      if (this.hasEndOnTarget) this.endOnTarget.value = start
    } else {
      if (this.hasEndOnTarget) this.endOnTarget.value = iso
    }

    if (this.rangeHasBusy(this.startOnTarget.value, this.endOnTarget.value)) {
      if (this.hasHintTarget) {
        this.hintTarget.textContent = this.hintTarget.dataset.busyMessage || "Selected range includes unavailable days."
      }
      if (this.hasEndOnTarget) this.endOnTarget.value = ""
      this.syncDateTimes()
      return
    }

    if (this.hasHintTarget) this.hintTarget.textContent = ""
    this.syncDateTimes()
  }

  syncDateTimes() {
    const start = this.hasStartOnTarget ? this.startOnTarget.value : ""
    const end = this.hasEndOnTarget ? this.endOnTarget.value : ""
    if (this.hasStartTimeTarget) {
      this.startTimeTarget.value = start ? `${start}T10:00` : ""
    }
    if (this.hasEndTimeTarget) {
      // Same calendar day still needs end_time > start_time for Booking validation.
      this.endTimeTarget.value = end ? `${end}T${end === start ? "18:00" : "10:00"}` : ""
    }
  }

  render() {
    const year = this.cursor.getFullYear()
    const month = this.cursor.getMonth()
    if (this.hasLabelTarget) {
      this.labelTarget.textContent = this.cursor.toLocaleDateString(undefined, {
        month: "long",
        year: "numeric"
      })
    }

    const firstDow = new Date(year, month, 1).getDay()
    const daysInMonth = new Date(year, month + 1, 0).getDate()
    const selectedStart = this.hasStartOnTarget ? this.startOnTarget.value : ""
    const selectedEnd = this.hasEndOnTarget ? this.endOnTarget.value : selectedStart

    let html = ""
    for (let i = 0; i < firstDow; i += 1) {
      html += `<div class="h-11"></div>`
    }

    for (let day = 1; day <= daysInMonth; day += 1) {
      const iso = `${year}-${String(month + 1).padStart(2, "0")}-${String(day).padStart(2, "0")}`
      const kinds = this.kindsFor(iso)
      const busy = kinds.length > 0
      const inSelection = selectedStart && selectedEnd && iso >= selectedStart && iso <= selectedEnd
      const isEdge = iso === selectedStart || iso === selectedEnd

      let classes = "h-11 rounded-xl text-sm font-black transition flex items-center justify-center border"
      if (busy) {
        classes += kinds.includes("booking")
          ? " bg-orange-100 border-orange-200 text-orange-700 cursor-not-allowed"
          : " bg-slate-200 border-slate-300 text-slate-500 cursor-not-allowed"
      } else if (isEdge) {
        classes += " bg-pink-500 border-pink-500 text-white"
      } else if (inSelection) {
        classes += " bg-pink-100 border-pink-200 text-pink-700"
      } else {
        classes += " bg-white border-slate-200 text-slate-950 hover:border-pink-300"
      }

      html += `<button type="button" class="${classes}" data-date="${iso}" data-busy="${busy}" data-action="availability-calendar#pick">${day}</button>`
    }

    this.gridTarget.innerHTML = html
  }

  kindsFor(iso) {
    return this.busyValue
      .filter((range) => iso >= range.start_on && iso <= range.end_on)
      .map((range) => range.kind)
  }

  rangeHasBusy(start, end) {
    if (!start || !end) return false
    const cursor = new Date(`${start}T12:00:00`)
    const last = new Date(`${end}T12:00:00`)
    while (cursor <= last) {
      const iso = cursor.toISOString().slice(0, 10)
      if (this.kindsFor(iso).length > 0) return true
      cursor.setDate(cursor.getDate() + 1)
    }
    return false
  }
}
