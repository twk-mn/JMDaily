class Correction < ApplicationRecord
  belongs_to :article

  validates :body,      presence: true
  validates :posted_at, presence: true

  before_validation :default_posted_at, on: :create

  default_scope { order(:posted_at, :id) }

  private

  def default_posted_at
    self.posted_at ||= Time.current
  end
end
