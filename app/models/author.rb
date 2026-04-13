class Author < ApplicationRecord
  belongs_to :user, optional: true
  has_many :articles, dependent: :restrict_with_error
  has_one_attached :photo do |attachable|
    attachable.variant :thumb, resize_to_fill: [ 96, 96 ], format: :webp
    attachable.variant :small, resize_to_fill: [ 48, 48 ], format: :webp
  end

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
