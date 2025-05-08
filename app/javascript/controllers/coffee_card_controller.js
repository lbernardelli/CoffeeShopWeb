import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["variant", "variantInput"]

  connect() {
    // Select the first variant by default
    if (this.variantTargets.length > 0) {
      this.selectVariant({ currentTarget: this.variantTargets[0] })
    }
  }

  selectVariant(event) {
    const variantElement = event.currentTarget
    const variantId = variantElement.dataset.variantId

    // Remove selection from all variants
    this.variantTargets.forEach(target => {
      target.classList.remove("border-amber-600", "bg-amber-50")
      target.classList.add("border-gray-200")
    })

    // Add selection to clicked variant
    variantElement.classList.remove("border-gray-200")
    variantElement.classList.add("border-amber-600", "bg-amber-50")

    // Update the form's hidden field with the selected variant
    if (this.hasVariantInputTarget) {
      this.variantInputTarget.value = variantId
    }
  }
}
