class ArticleTranslation < ApplicationRecord
  belongs_to :article

  has_rich_text :body
  has_rich_text :context_box

  LOCALES = %w[en ja].freeze

  # Locales that must be filled in on every article. Other supported locales are
  # optional — editors can publish without them. English is the primary editorial
  # language. This list will become settings-driven in a later change; the
  # distinction is introduced here so callers can rely on it now.
  REQUIRED_LOCALES = %w[en].freeze

  def self.optional_locales
    LOCALES - REQUIRED_LOCALES
  end

  def self.required_locale?(locale)
    REQUIRED_LOCALES.include?(locale.to_s)
  end

  validates :locale, presence: true, inclusion: { in: LOCALES },
                    uniqueness: { scope: :article_id, message: "translation already exists for this article" }
  validates :title, presence: true
  validates :slug, presence: true,
                   uniqueness: { scope: :locale, message: "is already taken for this locale" },
                   format: { with: /\A[a-z0-9\-]+\z/, message: "must be lowercase letters, numbers, and hyphens" }

  before_validation :generate_slug, if: -> { slug.blank? && title.present? }
  after_save :sync_search_vector, if: -> { saved_change_to_title? || saved_change_to_dek? }

  def to_param
    slug
  end

  private

  def generate_slug
    self.slug = title.parameterize
  end

  # Keep denormalised search columns on articles in sync.
  # English: propagates title/dek back to articles so the PG tsvector trigger fires.
  # Japanese: updates ja_search_text used for trigram search.
  def sync_search_vector
    if locale == "en"
      article.update_columns(
        title: title,
        dek: dek.presence || article.dek
      )
    elsif locale == "ja"
      article.update_columns(
        ja_search_text: [ title, dek.presence ].compact.join(" ")
      )
    end
  rescue ActiveRecord::ActiveRecordError => e
    Rails.logger.error("ArticleTranslation#sync_search_vector failed for article #{article_id}: #{e.message}")
  end
end
