import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "selectAll", "toolbar", "count"]

  toggleAll(event) {
    this.checkboxTargets.forEach(cb => { cb.checked = event.target.checked })
    this.updateCount()
  }

  updateCount() {
    const checked = this.checkboxTargets.filter(cb => cb.checked).length
    this.countTarget.textContent = checked
    this.toolbarTarget.style.removeProperty("display")
    this.toolbarTarget.style.display = checked > 0 ? "flex" : "none"
    this.selectAllTarget.checked = checked === this.checkboxTargets.length && checked > 0
    this.selectAllTarget.indeterminate = checked > 0 && checked < this.checkboxTargets.length
  }
}
