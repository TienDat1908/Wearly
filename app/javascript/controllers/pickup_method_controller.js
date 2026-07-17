import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select", "selfPickup", "delivery", "deliveryAddress"]

  connect() {
    this.toggle()
  }

  toggle() {
    const deliverySelected = this.selectTarget.value === "delivery"

    this.selfPickupTarget.hidden = deliverySelected
    this.deliveryTarget.hidden = !deliverySelected
    this.deliveryAddressTarget.required = deliverySelected

    if (!deliverySelected) this.deliveryAddressTarget.value = ""
  }
}
