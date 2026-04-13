class ArticleTranslation < ApplicationRecord
  belongs_to :article

  has_rich_text :body
  has_rich_text :context_box

  LOCALES = %w[en ja].freeze

  validates :locale, presence: true, inclusion: { in: LOCALES }
  validates :title, presence: true
  validates :slug, presence: true,
                   uniqueness: { scope: :locale, message: "is already taken for this locale" },
                   format: { with: /\A[a-z0-9\-]+\z/, message: "must be lowercase letters, numbers, and hyphens" }

  before_validation :generate_slug, if: -> { slug.blank? && title.present? }
  after_save :sync_search_vector, if: -> { locale == "en" && (saved_change_to_title? || saved_change_to_dek?) }

  def to_param
    slug
  end

  private

  def generate_slug
    self.slug = title.parameterize
  end

  # Keep the search_vector on articles current — the FTS trigger fires on
  # articles.title / articles.dek changes, so we propagate the English
  # translation's values back so search continues to work.
  def sync_search_vector
    article.update_columns(
      title: title,
      dek: dek.presence || article.dek
    )
  end
end
