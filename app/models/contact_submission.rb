class ContactSubmission < ApplicationRecord
  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :message, presence: true

  scope :unread, -> { where(read: false) }
  scope :read,   -> { where(read: true) }
  scope :recent, -> { order(created_at: :desc) }
end
