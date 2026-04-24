import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  toggle(event) {
    const nowOpen = this.menuTarget.classList.toggle("hidden") === false
    const button = event.currentTarget
    if (button && button.hasAttribute("aria-expanded")) {
      button.setAttribute("aria-expanded", String(nowOpen))
    }
  }
}
