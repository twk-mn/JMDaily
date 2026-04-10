import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button"]
  static values  = { text: String }

  copy() {
    navigator.clipboard.writeText(this.textValue).then(() => {
      const btn = this.buttonTarget
      const original = btn.textContent
      btn.textContent = "Copied!"
      setTimeout(() => { btn.textContent = original }, 2000)
    })
  }
}
