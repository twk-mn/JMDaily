class StaticPage < ApplicationRecord
  has_rich_text :body

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true,
                   format: { with: /\A[a-z0-9\-]+\z/ }

  before_validation :generate_slug, if: -> { slug.blank? && title.present? }

  def to_param
    slug
  end

  private

  def generate_slug
    self.slug = title.parameterize
  end
end
