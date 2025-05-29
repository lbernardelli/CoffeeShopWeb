import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="flash"
export default class extends Controller {
  static values = {
    duration: { type: Number, default: 3000 }
  }

  connect() {
    this.timeout = setTimeout(() => {
      this.dismiss()
    }, this.durationValue)
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  dismiss() {
    this.element.classList.add("animate-slide-out")

    setTimeout(() => {
      this.element.remove()
    }, 300)
  }
}
