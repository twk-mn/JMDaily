class Location < ApplicationRecord
  include Translatable

  has_many :article_locations, dependent: :destroy
  has_many :articles, through: :article_locations

  # `name` and `description` carry the canonical English values; per-locale
  # overrides live in `location_translations`. `localized_name(locale)` and
  # `localized_description(locale)` wrap the fallback logic.
  translates :name, :description

  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true,
                   format: { with: /\A[a-z0-9\-]+\z/ }

  before_validation :generate_slug, if: -> { slug.blank? && name.present? }

  def to_param
    slug
  end

  private

  def generate_slug
    self.slug = name.parameterize
  end
end
