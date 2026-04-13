class Comment < ApplicationRecord
  belongs_to :article

  STATUSES = %w[pending approved rejected].freeze

  validates :name, presence: true
  validates :body, presence: true, length: { maximum: 2000 }
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
