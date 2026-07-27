import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

// Live chat updates for the open conversation page.
export default class extends Controller {
  static targets = ["list", "empty", "input", "form"]
  static values = {
    conversationId: Number,
    currentUserId: Number,
    supportLabel: String,
    systemLabel: String,
    openBookingLabel: String,
    bookingPath: String,
    isSupport: Boolean
  }

  connect() {
    this.seenIds = new Set(
      Array.from(this.listTarget.querySelectorAll("[data-message-id]")).map((el) =>
        Number(el.dataset.messageId)
      )
    )

    this.consumer = createConsumer()
    this.subscription = this.consumer.subscriptions.create(
      { channel: "ConversationChannel", id: this.conversationIdValue },
      {
        received: (data) => this.onMessage(data),
        connected: () => {
          this.element.dataset.chatConnected = "true"
        },
        disconnected: () => {
          this.element.dataset.chatConnected = "false"
        }
      }
    )
  }

  disconnect() {
    this.subscription?.unsubscribe()
    this.consumer?.disconnect()
  }

  async send(event) {
    event.preventDefault()
    const body = this.inputTarget.value.trim()
    if (!body) return

    const form = this.formTarget
    const token = document.querySelector("meta[name='csrf-token']")?.content
    const response = await fetch(form.action, {
      method: "POST",
      headers: {
        Accept: "application/json",
        "X-CSRF-Token": token || "",
        "Content-Type": "application/json"
      },
      body: JSON.stringify({ message: { body } })
    })

    if (!response.ok) return

    const data = await response.json()
    this.appendMessage(data.message)
    this.inputTarget.value = ""
    this.inputTarget.focus()
  }

  onMessage(data) {
    if (data?.type !== "message_created" || !data.message) return
    this.appendMessage(data.message)
  }

  appendMessage(message) {
    const id = Number(message.id)
    if (this.seenIds.has(id)) return
    this.seenIds.add(id)

    if (this.hasEmptyTarget) this.emptyTarget.remove()

    const wrapper = document.createElement("div")
    wrapper.dataset.messageId = String(id)

    if (message.system) {
      wrapper.className = "flex justify-center"
      wrapper.dataset.system = "true"
      wrapper.innerHTML = `
        <div class="max-w-[92%] rounded-3xl border border-amber-200 bg-amber-50 px-4 py-3 text-center text-amber-950">
          <p class="text-[11px] font-black uppercase tracking-wider text-amber-700"></p>
          <p class="mt-2 whitespace-pre-wrap text-sm font-semibold leading-6"></p>
          <p class="mt-2 text-[11px] opacity-60"></p>
        </div>
      `
      const card = wrapper.firstElementChild
      const [labelEl, bodyEl, timeEl] = card.querySelectorAll("p")
      labelEl.textContent = this.systemLabelValue || "Wearly"
      bodyEl.textContent = message.body || ""
      timeEl.textContent = message.created_at
        ? new Date(message.created_at).toLocaleString()
        : ""

      if (this.bookingPathValue) {
        const link = document.createElement("a")
        link.href = this.bookingPathValue
        link.className =
          "mt-3 inline-flex rounded-full bg-amber-600 px-4 py-2 text-xs font-black text-white"
        link.textContent = this.openBookingLabelValue || "Open booking"
        card.insertBefore(link, timeEl)
      }
    } else {
      const mine = Number(message.sender?.id) === this.currentUserIdValue
      const senderLabel =
        this.isSupportValue && message.sender?.role === "admin"
          ? this.supportLabelValue
          : message.sender?.full_name || "User"

      wrapper.className = `flex ${mine ? "justify-end" : "justify-start"}`
      wrapper.innerHTML = `
        <div class="max-w-[80%] rounded-3xl px-4 py-3 ${mine ? "bg-slate-950 text-white" : "bg-slate-100 text-slate-900"}">
          <p class="text-xs font-black opacity-70"></p>
          <p class="mt-1 whitespace-pre-wrap font-semibold leading-6"></p>
          <p class="mt-2 text-[11px] opacity-60"></p>
        </div>
      `
      const [nameEl, bodyEl, timeEl] = wrapper.querySelectorAll("p")
      nameEl.textContent = senderLabel
      bodyEl.textContent = message.body || ""
      timeEl.textContent = message.created_at
        ? new Date(message.created_at).toLocaleString()
        : ""
    }

    this.listTarget.appendChild(wrapper)
    wrapper.scrollIntoView({ behavior: "smooth", block: "end" })
  }
}
