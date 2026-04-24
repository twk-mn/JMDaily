import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "modal", "form", "name", "articles", "newsletters",
    "codeHint", "typedInput", "confirmInput", "submit"
  ]

  openPurge(event) {
    const el = event.currentTarget
    const code = el.dataset.code
    this.currentCode = code
    this.nameTarget.textContent = el.dataset.name
    this.articlesTarget.textContent = el.dataset.articles
    this.newslettersTarget.textContent = el.dataset.newsletters
    this.codeHintTarget.textContent = code
    this.formTarget.action = el.dataset.purgeUrl
    this.typedInputTarget.value = ""
    this.confirmInputTarget.value = ""
    this.submitTarget.disabled = true
    this.modalTarget.style.display = "flex"
    this.typedInputTarget.focus()
  }

  closePurge() {
    this.modalTarget.style.display = "none"
  }

  onTyped() {
    const match = this.typedInputTarget.value === this.currentCode
    this.submitTarget.disabled = !match
    this.confirmInputTarget.value = match ? this.currentCode : ""
  }
}
