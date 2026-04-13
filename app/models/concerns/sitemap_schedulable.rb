module SitemapSchedulable
  extend ActiveSupport::Concern

  included do
    after_save :schedule_sitemap_regeneration, if: :status_changed_to_published?
  end

  private

  def status_changed_to_published?
    saved_change_to_status? && status == "published"
  end

  def schedule_sitemap_regeneration
    RegenerateSitemapJob.perform_later
  end
end
