import { Controller } from "@hotwired/stimulus"

// Three-state theme toggle: light -> dark -> system -> light ...
// Stored in localStorage under "theme" as "light" | "dark" | <unset for system>.
// The <head> inline script reads this at boot; this controller writes it.
export default class extends Controller {
  cycle() {
    const current = localStorage.getItem("theme") || "system"
    const next = current === "light" ? "dark" : current === "dark" ? "system" : "light"

    if (next === "system") {
      localStorage.removeItem("theme")
      const prefersDark = window.matchMedia("(prefers-color-scheme: dark)").matches
      document.documentElement.classList.toggle("dark", prefersDark)
    } else {
      localStorage.setItem("theme", next)
      document.documentElement.classList.toggle("dark", next === "dark")
    }
  }
}
