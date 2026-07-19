import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview", "primaryIndex", "summary"]

  connect() {
    this.render()
  }

  render() {
    const files = Array.from(this.inputTarget.files || [])
    this.previewTarget.innerHTML = ""
    this.updateSummary(files.length)

    if (files.length === 0) {
      this.primaryIndexTarget.value = ""
      this.previewTarget.hidden = true
      return
    }

    const hasExistingPhotos = this.element.dataset.hasExistingPhotos === "true"
    const shouldDefaultToFirstNewPhoto = !hasExistingPhotos

    this.previewTarget.hidden = false

    if (shouldDefaultToFirstNewPhoto && this.primaryIndexTarget.value === "") {
      this.primaryIndexTarget.value = "0"
    }

    files.forEach((file, index) => {
      const selectedIndex =
        this.primaryIndexTarget.value === "" ? null : Number(this.primaryIndexTarget.value)

      const label = document.createElement("label")
      label.className = "group cursor-pointer"

      const radio = document.createElement("input")
      radio.type = "radio"
      radio.name = "new_primary_photo_choice"
      radio.className = "peer sr-only"
      radio.checked = selectedIndex === index
      radio.addEventListener("change", () => {
        this.primaryIndexTarget.value = String(index)
        this.updateBadges()
      })

      const card = document.createElement("div")
      card.className = "relative overflow-hidden rounded-[1.5rem] border-4 border-transparent bg-white shadow-sm peer-checked:border-pink-500 peer-checked:shadow-xl peer-checked:shadow-pink-100 transition"

      const image = document.createElement("img")
      image.src = URL.createObjectURL(file)
      image.className = "aspect-[4/5] w-full object-cover group-hover:scale-105 transition duration-500"
      image.alt = file.name

      const badge = document.createElement("div")
      badge.className = "photo-picker-new-badge absolute inset-x-3 bottom-3 rounded-full bg-white/90 px-3 py-2 text-center text-xs font-black text-slate-950 backdrop-blur"
      badge.dataset.index = String(index)
      badge.textContent =
        selectedIndex === index
          ? this.element.dataset.currentCoverText
          : this.element.dataset.useAsCoverText

      const filename = document.createElement("div")
      filename.className = "absolute inset-x-3 top-3 truncate rounded-full bg-slate-950/70 px-3 py-2 text-xs font-black text-white backdrop-blur"
      filename.textContent = file.name

      card.appendChild(image)
      card.appendChild(filename)
      card.appendChild(badge)
      label.appendChild(radio)
      label.appendChild(card)
      this.previewTarget.appendChild(label)
    })
  }

  updateSummary(count) {
    if (!this.hasSummaryTarget) return

    if (count === 0) {
      this.summaryTarget.textContent = this.element.dataset.noPhotosText
      return
    }

    this.summaryTarget.textContent = `${count} ${this.element.dataset.selectedPhotosSuffix}`
  }

  updateBadges() {
    const selectedIndex = this.primaryIndexTarget.value

    this.previewTarget.querySelectorAll(".photo-picker-new-badge").forEach((badge) => {
      badge.textContent =
        badge.dataset.index === selectedIndex
          ? this.element.dataset.currentCoverText
          : this.element.dataset.useAsCoverText
    })
  }
}
