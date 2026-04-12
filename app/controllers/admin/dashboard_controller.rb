module Admin
  class DashboardController < BaseController
    def index
      # Article stats
      @article_counts = Article.group(:status).count
      @published_today = Article.published.where("published_at >= ?", Time.current.beginning_of_day).count
      @scheduled_count = Article.scheduled.where("published_at > ?", Time.current).count

      # Recent content
      @recent_drafts = Article.draft.includes(:author).order(updated_at: :desc).limit(5)
      @recently_published = Article.published.includes(:author, :category).order(published_at: :desc).limit(5)

      # Inbox
      @unread_contacts = ContactSubmission.unread.count
      @unread_tips = TipSubmission.unread.count

      # Newsletter
      @subscriber_count = NewsletterSubscriber.active.count
      @new_subscribers_this_week = NewsletterSubscriber.active.where("created_at >= ?", 1.week.ago).count

      # Activity
      @recent_audit_logs = AuditLog.includes(:user).order(created_at: :desc).limit(8)
    end
  end
end
