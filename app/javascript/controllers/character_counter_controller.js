import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "count"]
  static values = { max: Number }

  connect() {
    this.update = this.update.bind(this)
    this.inputTarget.addEventListener("input", this.update)
    this.update()
  }

  disconnect() {
    this.inputTarget.removeEventListener("input", this.update)
  }

  update() {
    const length = this.inputTarget.value.length
    this.countTarget.textContent = `${length} / ${this.maxValue}`
    const over = length > this.maxValue
    this.countTarget.classList.toggle("text-red-700", over)
    this.countTarget.classList.toggle("dark:text-red-300", over)
    this.countTarget.classList.toggle("text-gray-600", !over)
    this.countTarget.classList.toggle("dark:text-gray-400", !over)
  }
}
