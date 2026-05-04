# DB-backed translations for UI chrome strings — menu labels, button text,
# footer copy, empty-state messages, etc. Editable from /admin/ui_strings
# rather than YAML so admins can localise the visible site without a deploy.
#
# Each known string is registered in DEFINITIONS so the admin form has
# something to render even before any rows exist, and so the fallback chain
# in `ApplicationHelper#t_ui` has a known set of keys to look up.
#
# Read API: views call `t_ui("footer.about_heading")`. The helper resolves:
#   1. UiString row matching (key, current locale) — when value is non-blank
#   2. config/locales/<locale>.yml via I18n.t — when defined
#   3. UiString row matching (key, "en") — admin-edited English source
#   4. DEFINITIONS[key][:default] — registered English default
#   5. The key itself (humanised) — last-resort fallback
#
# Step 1 is the only one that hits the database; per-request memoization
# in the helper batches every t_ui call into one query per locale.
class UiString < ApplicationRecord
  # Registry of known chrome strings. Adding a key here gives the admin form
  # a row to edit and `t_ui` a registered default to fall back to. Grouped by
  # `tab` so the admin can edit them a section at a time. Add an entry whenever
  # a view starts using a new `t_ui` key.
  DEFINITIONS = {
    # ---- Footer ---------------------------------------------------------
    "footer.about_heading" => {
      tab: "footer", default: "About",
      description: "Heading for the About column in the site footer."
    },
    "footer.legal_heading" => {
      tab: "footer", default: "Legal",
      description: "Heading for the Legal column in the site footer."
    },
    "footer.stay_informed_heading" => {
      tab: "footer", default: "Stay informed",
      description: "Heading above the newsletter signup block in the site footer."
    },
    "footer.stay_informed_blurb" => {
      tab: "footer", default: "Get the latest news delivered to your inbox.",
      description: "Short copy under the Stay informed heading."
    },
    "footer.about_us" => { tab: "footer", default: "About Us", description: "Footer link to the about page." },
    "footer.contact" => { tab: "footer", default: "Contact", description: "Footer link to the contact page." },
    "footer.submit_a_tip" => { tab: "footer", default: "Submit a Tip", description: "Footer link to the tip-submission page." },
    "footer.corrections_policy" => { tab: "footer", default: "Corrections Policy", description: "Footer link to the corrections policy." },
    "footer.privacy_policy" => { tab: "footer", default: "Privacy Policy", description: "Footer link to the privacy policy." },
    "footer.terms" => { tab: "footer", default: "Terms", description: "Footer link to the terms of use." },
    "footer.rss_feed" => { tab: "footer", default: "RSS Feed", description: "Footer link to the RSS feed." },
    "footer.copyright_suffix" => {
      tab: "footer", default: "All rights reserved.",
      description: "Trailing copyright phrase shown after the year and site name."
    },

    # ---- Header / navigation -------------------------------------------
    "nav.search_placeholder" => {
      tab: "header", default: "Search...",
      description: "Placeholder text for the masthead search input."
    },
    "nav.menu_button" => {
      tab: "header", default: "☰ Menu",
      description: "Mobile menu toggle button label."
    },
    "nav.skip_to_content" => {
      tab: "header", default: "Skip to content",
      description: "Accessibility skip-link shown when keyboard-focused."
    },

    # ---- Buttons / shared actions --------------------------------------
    "button.search" => { tab: "buttons", default: "Search", description: "Submit button on the search form." },
    "button.read_more" => { tab: "buttons", default: "Read more", description: "Generic read-more link label." },
    "button.subscribe" => { tab: "buttons", default: "Subscribe", description: "Newsletter subscribe button label." }
  }.freeze

  TABS = DEFINITIONS.values.map { |d| d[:tab] }.uniq.freeze

  validates :key, presence: true, uniqueness: { scope: :locale }
  validates :locale, presence: true,
                     inclusion: { in: ->(_) { SiteLanguage.codes } }

  scope :for_locale, ->(locale) { where(locale: locale.to_s) }

  class << self
    # All (key → value) pairs for one locale, materialised as a hash. Used by
    # the t_ui helper for per-request memoization so a page render hits the
    # DB at most once per locale rather than once per t_ui call.
    def map_for(locale)
      for_locale(locale).pluck(:key, :value).to_h
    end

    def definitions_for_tab(tab)
      DEFINITIONS.select { |_, d| d[:tab] == tab.to_s }
    end

    def default_for(key)
      DEFINITIONS.dig(key.to_s, :default)
    end
  end
end
