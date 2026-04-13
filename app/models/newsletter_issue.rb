class NewsletterIssue < ApplicationRecord
  STATUSES = %w[draft sent].freeze
  LOCALES  = %w[en ja].freeze

  validates :subject, presence: true
  validates :body,    presence: true
  validates :status,  inclusion: { in: STATUSES }
  validates :locale,  inclusion: { in: LOCALES }

  scope :recent, -> { order(created_at: :desc) }
  scope :sent, -> { where(status: "sent") }
  scope :draft, -> { where(status: "draft") }

  def sent?
    status == "sent"
  end
end
