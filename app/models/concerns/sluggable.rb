module Sluggable
  extend ActiveSupport::Concern

  included do
    before_validation :generate_slug, if: -> { slug.blank? && title.present? }
  end

  private

  def generate_slug
    self.slug = title.to_s.parameterize
  end
end
