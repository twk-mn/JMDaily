class PublishScheduledArticlesJob < ApplicationJob
  queue_as :default

  def perform
    due = Article.where(status: "scheduled")
                 .where("published_at <= ?", Time.current)

    count = due.count
    return if count.zero?

    due.update_all(status: "published")

    # update_all skips callbacks, so SitemapSchedulable's after_save trigger
    # doesn't fire — enqueue the regen explicitly so the sitemap reflects the
    # newly-published URLs without waiting for the nightly fallback.
    RegenerateSitemapJob.perform_later

    Rails.logger.info("[PublishScheduledArticlesJob] Published #{count} article(s)")
  end
end
