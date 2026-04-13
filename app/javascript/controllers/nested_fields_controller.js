import { Controller } from "@hotwired/stimulus"

// Handles dynamic add/remove of nested fields_for rows (e.g. article sources).
//
// Usage:
//   data-controller="nested-fields"
//   data-nested-fields-index-value="<current count>"   — seed with existing row count
//
//   Add button:  data-action="nested-fields#add"
//               data-nested-fields-target="template"  (hidden <template> element)
//
//   Each row:    data-nested-fields-target="row"
//   Remove btn:  data-action="nested-fields#remove"   (inside the row)
//   Destroy input inside row: name contains "[_destroy]"

export default class extends Controller {
  static targets = ["template", "container", "row"]
  static values  = { index: Number }

  add(event) {
    event.preventDefault()

    const content = this.templateTarget.innerHTML
      .replace(/__INDEX__/g, this.indexValue)

    this.containerTarget.insertAdjacentHTML("beforeend", content)
    this.indexValue++
  }

  remove(event) {
    event.preventDefault()

    const row = event.target.closest("[data-nested-fields-target='row']")
    if (!row) return

    const destroyInput = row.querySelector("input[name*='[_destroy]']")
    if (destroyInput) {
      // Persisted row — mark for deletion and hide
      destroyInput.value = "1"
      row.style.display = "none"
    } else {
      // New (unsaved) row — remove from DOM entirely
      row.remove()
    }
  }
}
