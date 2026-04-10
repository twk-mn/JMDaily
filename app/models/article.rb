class Article < ApplicationRecord
  belongs_to :author
  belongs_to :category

  has_many :article_tags, dependent: :destroy
  has_many :tags, through: :article_tags
  has_many :article_locations, dependent: :destroy
  has_many :locations, through: :article_locations

  has_one_attached :featured_image
  has_rich_text :body

  STATUSES = %w[draft scheduled published archived].freeze

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true,
                   format: { with: /\A[a-z0-9\-]+\z/, message: "must be lowercase letters, numbers, and hyphens" }
  validates :status, inclusion: { in: STATUSES }
  validates :published_at, presence: true, if: -> { status == "published" }

  before_validation :generate_slug, if: -> { slug.blank? && title.present? }

  scope :published, -> { where(status: "published").where("published_at <= ?", Time.current) }
  scope :draft, -> { where(status: "draft") }
  scope :scheduled, -> { where(status: "scheduled") }
  scope :featured, -> { where(featured: true) }
  scope :breaking, -> { where(breaking: true) }
  scope :recent, -> { published.order(published_at: :desc) }
  scope :by_category, ->(category) { where(category: category) }
  scope :by_location, ->(location) { joins(:locations).where(locations: { id: location.id }) }

  def to_param
    slug
  end

  def published?
    status == "published" && published_at.present? && published_at <= Time.current
  end

  def display_date
    published_at || created_at
  end

  def effective_seo_title
    seo_title.presence || title
  end

  def effective_meta_description
    meta_description.presence || dek.presence || body.to_plain_text.truncate(160)
  end

  private

  def generate_slug
    self.slug = title.parameterize
  end
end
