class TipSubmission < ApplicationRecord
  validates :tip_body, presence: true

  scope :unread, -> { where(read: false) }
  scope :recent, -> { order(created_at: :desc) }
end
