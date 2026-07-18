import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            entry.target.classList.add("is-visible")
            this.observer.unobserve(entry.target)
          }
        })
      },
      {
        threshold: 0.12,
        rootMargin: "0px 0px -8% 0px"
      }
    )

    this.element.querySelectorAll("[data-reveal]").forEach((element, index) => {
      element.style.setProperty("--reveal-delay", `${Math.min(index * 55, 440)}ms`)
      this.observer.observe(element)
    })
  }

  disconnect() {
    this.observer?.disconnect()
  }
}
