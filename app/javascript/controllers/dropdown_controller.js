import { Controller } from "@hotwired/stimulus"

// Click-to-toggle dropdown with outside-click + Escape to close.
// Markup:
//   <div data-controller="dropdown">
//     <button data-action="dropdown#toggle" data-dropdown-target="trigger" aria-haspopup="true" aria-expanded="false">…</button>
//     <div data-dropdown-target="menu" hidden>…</div>
//   </div>
export default class extends Controller {
  static targets = ["trigger", "menu"]

  connect() {
    this._onDocClick = this._onDocClick.bind(this)
    this._onKeydown = this._onKeydown.bind(this)
    document.addEventListener("click", this._onDocClick)
    document.addEventListener("keydown", this._onKeydown)
  }

  disconnect() {
    document.removeEventListener("click", this._onDocClick)
    document.removeEventListener("keydown", this._onKeydown)
  }

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()
    this.menuTarget.hidden ? this.open() : this.close()
  }

  open() {
    this.menuTarget.hidden = false
    if (this.hasTriggerTarget) this.triggerTarget.setAttribute("aria-expanded", "true")
  }

  close() {
    this.menuTarget.hidden = true
    if (this.hasTriggerTarget) this.triggerTarget.setAttribute("aria-expanded", "false")
  }

  _onDocClick(event) {
    if (this.element.contains(event.target)) return
    this.close()
  }

  _onKeydown(event) {
    if (event.key === "Escape") this.close()
  }
}
