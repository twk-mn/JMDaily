class PublishScheduledArticlesJob < ApplicationJob
  queue_as :default

  def perform
    due = Article.where(status: "scheduled")
                 .where("published_at <= ?", Time.current)

    count = due.count
    return if count.zero?

    due.update_all(status: "published")

    Rails.logger.info("[PublishScheduledArticlesJob] Published #{count} article(s)")
  end
end
