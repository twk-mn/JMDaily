class Author < ApplicationRecord
  include Translatable

  belongs_to :user, optional: true
  has_many :articles, dependent: :restrict_with_error
  has_one_attached :photo do |attachable|
    attachable.variant :thumb, resize_to_fill: [ 96, 96 ], format: :webp
    attachable.variant :small, resize_to_fill: [ 48, 48 ], format: :webp
  end

  # `name` is treated as a proper noun and stays untranslated; `bio` and
  # `role_title` are the chrome an editor would want localized.
  translates :bio, :role_title

  # Social-link fields rendered in the bio card and on the author page,
  # in this display order. Adding a new SNS = add a row here, a column in
  # a migration, an admin-form field, and a permitted strong-param.
  SOCIAL_LINK_FIELDS = [
    [ :twitter_url,   "Twitter" ],
    [ :bluesky_url,   "Bluesky" ],
    [ :mastodon_url,  "Mastodon" ],
    [ :instagram_url, "Instagram" ],
    [ :facebook_url,  "Facebook" ],
    [ :linkedin_url,  "LinkedIn" ],
    [ :youtube_url,   "YouTube" ],
    [ :website_url,   "Website" ]
  ].freeze

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
