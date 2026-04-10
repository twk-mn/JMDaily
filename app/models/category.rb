class Category < ApplicationRecord
  has_many :articles, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true,
                   format: { with: /\A[a-z0-9\-]+\z/ }

  before_validation :generate_slug, if: -> { slug.blank? && name.present? }

  default_scope { order(:position) }

  def to_param
    slug
  end

  private

  def generate_slug
    self.slug = name.parameterize
  end
end
