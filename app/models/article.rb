class Article < ApplicationRecord
  include Sluggable
  include SitemapSchedulable

  belongs_to :author
  belongs_to :category

  has_many :translations, class_name: "ArticleTranslation", dependent: :destroy, inverse_of: :article
  has_many :sources, class_name: "ArticleSource", dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :article_tags, dependent: :destroy
  has_many :tags, through: :article_tags
  has_many :article_locations, dependent: :destroy
  has_many :locations, through: :article_locations

  accepts_nested_attributes_for :translations, allow_destroy: false, reject_if: :optional_translation_blank?
  accepts_nested_attributes_for :sources, allow_destroy: true, reject_if: :all_blank

  has_one_attached :featured_image do |attachable|
    attachable.variant :thumb,  resize_to_fill: [ 400, 250 ],   format: :webp
    attachable.variant :medium, resize_to_fill: [ 800, 500 ],   format: :webp
    attachable.variant :large,  resize_to_limit: [ 1200, 800 ], format: :webp
  end

  STATUSES = %w[draft scheduled published archived].freeze
  SUPPORTED_LOCALES = ArticleTranslation::LOCALES

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true,
                   format: { with: /\A[a-z0-9\-]+\z/, message: "must be lowercase letters, numbers, and hyphens" }
  validates :status, inclusion: { in: STATUSES }
  validates :published_at, presence: true, if: -> { status == "published" }

  # Seed the article-level title from the English translation before Sluggable's
  # generate_slug runs, so the slug can be auto-derived when the editor only fills
  # in translation titles (the admin form has no article-level title input).
  before_validation :seed_title_from_translations, prepend: true, if: -> { title.blank? }

  scope :published, -> { where(status: "published").where("published_at <= ?", Time.current) }
  scope :draft, -> { where(status: "draft") }
  scope :scheduled, -> { where(status: "scheduled") }
  scope :featured, -> { where(featured: true) }
  scope :breaking, -> { where(breaking: true) }
  scope :recent, -> { published.order(published_at: :desc) }
  scope :by_category, ->(category) { where(category: category) }
  scope :by_location, ->(location) { joins(:locations).where(locations: { id: location.id }) }
  scope :search, ->(query) {
    return none if query.blank?
    if japanese?(query)
      published
        .where("ja_search_text ILIKE ?", "%#{sanitize_sql_like(query)}%")
        .order(published_at: :desc)
    else
      sanitized = sanitize_sql_array([ "plainto_tsquery('english', ?)", query ])
      published
        .where("search_vector @@ #{sanitized}")
        .order(Arel.sql("ts_rank(search_vector, #{sanitized}) DESC"))
    end
  }

  def self.japanese?(text)
    text.match?(/[\u3000-\u9FFF\uF900-\uFAFF\uFF00-\uFFEF]/)
  end

  # Returns the slug for the current I18n locale, falling back to the base slug.
  def to_param
    if translations.loaded?
      locale_str = I18n.locale.to_s
      (translations.find { |t| t.locale == locale_str } || translations.first)&.slug || slug
    else
      slug
    end
  end

  # Find a translation for the given locale, or nil.
  def translation_for(locale)
    locale_str = locale.to_s
    translations.find { |t| t.locale == locale_str }
  end

  def published?
    status == "published" && published_at.present? && published_at <= Time.current
  end

  def display_date
    published_at || created_at
  end

  def effective_seo_title(translation = nil)
    translation&.seo_title.presence || seo_title.presence || translation&.title.presence || title
  end

  def effective_meta_description(translation = nil)
    translation&.meta_description.presence ||
      meta_description.presence ||
      translation&.dek.presence ||
      dek.presence ||
      translation&.body&.to_plain_text&.truncate(160) ||
      ""
  end

  def reading_time(translation = nil)
    body = translation&.body
    return 1 unless body
    words = body.to_plain_text.split.size
    minutes = (words / 200.0).ceil
    minutes < 1 ? 1 : minutes
  end

  private

  # Drop translation rows for optional locales when the editor left every content
  # field blank. The hidden `locale` input is always populated by the form, so the
  # default `:all_blank` check never rejects anything — we have to ignore
  # bookkeeping fields explicitly. Required locales are always kept so their
  # validations surface instead of silently disappearing.
  def optional_translation_blank?(attrs)
    locale = attrs[:locale] || attrs["locale"]
    return false if ArticleTranslation.required_locale?(locale)

    attrs.except(:id, "id", :locale, "locale", :_destroy, "_destroy").values.all?(&:blank?)
  end

  def seed_title_from_translations
    en = translations.find { |t| t.locale == "en" }
    self.title = en.title if en&.title.present?
  end
end
