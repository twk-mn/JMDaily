import { Controller } from "@hotwired/stimulus"

// Hides the sitewide breaking-news banner once the visitor dismisses it.
// Dismissal is keyed to a fingerprint of the current breaking lineup, so a
// fresh breaking story brings the banner back even for prior dismissers.
export default class extends Controller {
  static values = { fingerprint: String }

  connect() {
    if (this.dismissedFingerprint() === this.fingerprintValue) {
      this.element.hidden = true
    }
  }

  dismiss() {
    try {
      sessionStorage.setItem(this.storageKey(), this.fingerprintValue)
    } catch (e) {
      // sessionStorage can throw in private browsing; hiding still works.
    }
    this.element.hidden = true
  }

  dismissedFingerprint() {
    try {
      return sessionStorage.getItem(this.storageKey())
    } catch (e) {
      return null
    }
  }

  storageKey() {
    return "breaking-banner-dismissed"
  }
}
