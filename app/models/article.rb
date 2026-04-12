class Article < ApplicationRecord
  belongs_to :author
  belongs_to :category

  has_many :comments, dependent: :destroy
  has_many :article_tags, dependent: :destroy
  has_many :tags, through: :article_tags
  has_many :article_locations, dependent: :destroy
  has_many :locations, through: :article_locations

  has_one_attached :featured_image do |attachable|
    attachable.variant :thumb,  resize_to_fill: [ 400, 250 ],   format: :webp
    attachable.variant :medium, resize_to_fill: [ 800, 500 ],   format: :webp
    attachable.variant :large,  resize_to_limit: [ 1200, 800 ], format: :webp
  end
  has_rich_text :body

  STATUSES = %w[draft scheduled published archived].freeze

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true,
                   format: { with: /\A[a-z0-9\-]+\z/, message: "must be lowercase letters, numbers, and hyphens" }
  validates :status, inclusion: { in: STATUSES }
  validates :published_at, presence: true, if: -> { status == "published" }

  before_validation :generate_slug, if: -> { slug.blank? && title.present? }
  after_save :schedule_sitemap_regeneration, if: :status_changed_to_published?

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
    sanitized = sanitize_sql_array([ "plainto_tsquery('english', ?)", query ])
    published
      .where("search_vector @@ #{sanitized}")
      .order(Arel.sql("ts_rank(search_vector, #{sanitized}) DESC"))
  }

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

  def status_changed_to_published?
    saved_change_to_status? && status == "published"
  end

  def schedule_sitemap_regeneration
    RegenerateSitemapJob.perform_later
  end
end
