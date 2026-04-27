class NewsletterSubscriber < ApplicationRecord
  before_create :generate_confirmation_token
  before_create :generate_unsubscribe_token

  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }

  scope :confirmed,     -> { where.not(confirmed_at: nil) }
  scope :unsubscribed,  -> { where.not(unsubscribed_at: nil) }
  scope :active,        -> { confirmed.where(unsubscribed_at: nil) }
  scope :recent,        -> { order(created_at: :desc) }

  def confirmed?
    confirmed_at.present?
  end

  def unsubscribed?
    unsubscribed_at.present?
  end

  def confirm!
    update!(confirmed_at: Time.current, confirmation_token: nil)
    SyncNewsletterAudienceJob.perform_later(id, "subscribe") if NewsletterAudience.configured?
  end

  def unsubscribe!
    update!(unsubscribed_at: Time.current)
    SyncNewsletterAudienceJob.perform_later(id, "unsubscribe") if NewsletterAudience.configured?
  end

  private

  def generate_confirmation_token
    self.confirmation_token = SecureRandom.urlsafe_base64(32)
  end

  def generate_unsubscribe_token
    self.unsubscribe_token = SecureRandom.urlsafe_base64(32)
  end
end
