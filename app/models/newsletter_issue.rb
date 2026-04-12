class NewsletterIssue < ApplicationRecord
  STATUSES = %w[draft sent].freeze

  validates :subject, presence: true
  validates :body, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :recent, -> { order(created_at: :desc) }
  scope :sent, -> { where(status: "sent") }
  scope :draft, -> { where(status: "draft") }

  def sent?
    status == "sent"
  end
end
