class SiteLanguage < ApplicationRecord
  # Curated list of ISO 639-1 codes the admin UI allows adding. Keeping this
  # to a whitelist prevents typos (e.g. "jp" vs "ja") from ever reaching the
  # routes constraint or I18n, where an unknown code would be hard to debug.
  ISO_OPTIONS = [
    { code: "en", name: "English",    native_name: "English",    flag_emoji: "🇬🇧" },
    { code: "ja", name: "Japanese",   native_name: "日本語",        flag_emoji: "🇯🇵" },
    { code: "ko", name: "Korean",     native_name: "한국어",        flag_emoji: "🇰🇷" },
    { code: "zh", name: "Chinese",    native_name: "中文",          flag_emoji: "🇨🇳" },
    { code: "es", name: "Spanish",    native_name: "Español",      flag_emoji: "🇪🇸" },
    { code: "fr", name: "French",     native_name: "Français",     flag_emoji: "🇫🇷" },
    { code: "de", name: "German",     native_name: "Deutsch",      flag_emoji: "🇩🇪" },
    { code: "it", name: "Italian",    native_name: "Italiano",     flag_emoji: "🇮🇹" },
    { code: "pt", name: "Portuguese", native_name: "Português",    flag_emoji: "🇵🇹" },
    { code: "ru", name: "Russian",    native_name: "Русский",      flag_emoji: "🇷🇺" },
    { code: "ar", name: "Arabic",     native_name: "العربية",       flag_emoji: "🇸🇦" },
    { code: "hi", name: "Hindi",      native_name: "हिन्दी",          flag_emoji: "🇮🇳" },
    { code: "id", name: "Indonesian", native_name: "Bahasa Indonesia", flag_emoji: "🇮🇩" },
    { code: "th", name: "Thai",       native_name: "ไทย",           flag_emoji: "🇹🇭" },
    { code: "vi", name: "Vietnamese", native_name: "Tiếng Việt",    flag_emoji: "🇻🇳" },
    { code: "tl", name: "Tagalog",    native_name: "Tagalog",      flag_emoji: "🇵🇭" },
    { code: "nl", name: "Dutch",      native_name: "Nederlands",   flag_emoji: "🇳🇱" },
    { code: "sv", name: "Swedish",    native_name: "Svenska",      flag_emoji: "🇸🇪" },
    { code: "no", name: "Norwegian",  native_name: "Norsk",        flag_emoji: "🇳🇴" },
    { code: "da", name: "Danish",     native_name: "Dansk",        flag_emoji: "🇩🇰" },
    { code: "fi", name: "Finnish",    native_name: "Suomi",        flag_emoji: "🇫🇮" },
    { code: "pl", name: "Polish",     native_name: "Polski",       flag_emoji: "🇵🇱" },
    { code: "tr", name: "Turkish",    native_name: "Türkçe",       flag_emoji: "🇹🇷" },
    { code: "he", name: "Hebrew",     native_name: "עברית",         flag_emoji: "🇮🇱" },
    { code: "uk", name: "Ukrainian",  native_name: "Українська",    flag_emoji: "🇺🇦" }
  ].freeze

  ISO_CODES = ISO_OPTIONS.map { |o| o[:code] }.freeze
  ISO_LOOKUP = ISO_OPTIONS.index_by { |o| o[:code] }.freeze

  # Fallback used during asset precompile / bootstrap when the site_languages
  # table isn't readable yet. Mirrors the initial seed so i18n never collapses.
  BOOT_FALLBACK_CODES = %w[en ja].freeze

  validates :code, presence: true, uniqueness: true, inclusion: { in: ISO_CODES }
  validates :name, presence: true
  validates :position, presence: true, numericality: { only_integer: true }

  before_validation :apply_iso_defaults, on: :create
  after_commit :bust_cache

  scope :active, -> { where(active: true).order(:position, :id) }
  scope :inactive, -> { where(active: false).order(:position, :id) }
  scope :ordered, -> { order(:position, :id) }

  class << self
    # Codes of every language that currently exists on the site, active or not.
    # Used to validate stored translations so historical rows in a deactivated
    # language still pass model validations.
    def codes
      cached(:codes) { ordered.pluck(:code) }
    end

    # Codes for languages that should be publicly reachable right now.
    def active_codes
      cached(:active_codes) { active.pluck(:code) }
    end

    # Codes that cannot be deactivated or deleted. English is seeded as
    # non-deletable and becomes the required editorial language.
    def required_codes
      cached(:required_codes) { where(deletable: false).pluck(:code) }
    end

    def required_code?(code)
      required_codes.include?(code.to_s)
    end

    # Safe during boot / asset precompile — swallows missing-table errors.
    def safe_active_codes
      active_codes
    rescue ActiveRecord::StatementInvalid, ActiveRecord::NoDatabaseError
      BOOT_FALLBACK_CODES
    end

    def route_constraint
      ->(req) { active_codes.include?(req.path_parameters[:locale].to_s) }
    end

    def iso_option(code)
      ISO_LOOKUP[code.to_s]
    end

    # Keep I18n.available_locales aligned with the set of languages the site
    # knows about. Called on every admin write (same-process update) and on
    # each request via ApplicationController (covers other processes after
    # their cache version refreshes).
    def sync_i18n!
      list = codes.map(&:to_sym)
      I18n.available_locales = list if list.any?
    rescue StandardError
      nil
    end

    # ISO entries not yet added as SiteLanguage rows — used by the "add
    # language" picker in the admin UI.
    def addable_iso_options
      existing = pluck(:code).to_set
      ISO_OPTIONS.reject { |o| existing.include?(o[:code]) }
    end

    private

    def cached(suffix)
      Rails.cache.fetch("site_languages:#{suffix}:v#{cache_version}", expires_in: 1.hour) do
        yield
      end
    end

    def cache_version
      Rails.cache.fetch("site_languages:cache_version") { 1 }
    end

    def bump_cache_version!
      Rails.cache.write("site_languages:cache_version", cache_version + 1)
    end
  end

  # Can this language be deactivated without breaking the site?
  # We never allow deactivating a required language, and we never allow the
  # site to reach zero active languages.
  def deactivatable?
    return false if !deletable
    return false if active && self.class.active.count <= 1
    true
  end

  # Can this language row be destroyed entirely?
  def purgeable?
    deletable && !active
  end

  def content_counts
    {
      articles: ArticleTranslation.where(locale: code).count,
      newsletter_issues: NewsletterIssue.where(locale: code).count
    }
  end

  def display_name
    native_name.presence || name
  end

  private

  def apply_iso_defaults
    defaults = self.class.iso_option(code)
    return unless defaults

    self.name        = defaults[:name]        if name.blank?
    self.native_name = defaults[:native_name] if native_name.blank?
    self.flag_emoji  = defaults[:flag_emoji]  if flag_emoji.blank?
  end

  def bust_cache
    self.class.send(:bump_cache_version!)
    refresh_i18n_available_locales
  end

  def refresh_i18n_available_locales
    self.class.sync_i18n!
  end
end
