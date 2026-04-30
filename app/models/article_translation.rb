class ArticleTranslation < ApplicationRecord
  belongs_to :article

  has_rich_text :body
  has_rich_text :context_box

  # The list of supported locales is settings-driven — see SiteLanguage. We keep
  # class methods rather than constants so new languages added at runtime are
  # picked up without a boot restart.
  def self.supported_locales
    SiteLanguage.codes
  end

  def self.required_locales
    SiteLanguage.required_codes
  end

  def self.optional_locales
    supported_locales - required_locales
  end

  def self.required_locale?(locale)
    SiteLanguage.required_code?(locale)
  end

  validates :locale, presence: true,
                    inclusion: { in: ->(_) { SiteLanguage.codes } },
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

  # Translation slugs are unique scoped to locale, so collisions only happen
  # within the same language. Try bare parameterize, then date suffix, then
  # numbered fallback — mirrors Article#generate_slug.
  def generate_slug
    base = title.to_s.parameterize
    return self.slug = base if base.blank?

    scope = self.class.where(locale: locale).where.not(id: id)
    return self.slug = base unless scope.exists?(slug: base)

    date = (article&.published_at || Time.current).to_date.iso8601
    dated = "#{base}-#{date}"
    return self.slug = dated unless scope.exists?(slug: dated)

    i = 2
    loop do
      candidate = "#{dated}-#{i}"
      return self.slug = candidate unless scope.exists?(slug: candidate)
      i += 1
    end
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
