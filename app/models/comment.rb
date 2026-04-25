class Comment < ApplicationRecord
  belongs_to :article

  STATUSES = %w[pending approved rejected].freeze

  validates :name, presence: true
  validates :body, presence: true, length: { maximum: 2000 }
  # Per design spec §5.11 the email field is required on submission, but we
  # don't enforce it on later updates so admins can still moderate legacy
  # comments that were created before the requirement existed.
  validates :email, presence: true, on: :create
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :status, inclusion: { in: STATUSES }

  scope :approved, -> { where(status: "approved") }
  scope :pending,  -> { where(status: "pending") }
  scope :recent,   -> { order(created_at: :asc) }

  def approved?
    status == "approved"
  end

  def approve!
    update!(status: "approved")
  end

  def reject!
    update!(status: "rejected")
  end
end
