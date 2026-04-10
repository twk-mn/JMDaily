class Author < ApplicationRecord
  belongs_to :user, optional: true
  has_many :articles, dependent: :restrict_with_error
  has_one_attached :photo

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true,
                   format: { with: /\A[a-z0-9\-]+\z/, message: "must be lowercase letters, numbers, and hyphens" }

  before_validation :generate_slug, if: -> { slug.blank? && name.present? }

  def to_param
    slug
  end

  private

  def generate_slug
    self.slug = name.parameterize
  end
end
