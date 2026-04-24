class NewsletterIssue < ApplicationRecord
  STATUSES = %w[draft sent].freeze

  # Locales are driven by SiteLanguage — admins add or remove them at runtime.
  # Validation uses every known code (including deactivated ones) so historical
  # drafts/sent issues in a deactivated language continue to pass validation.
  def self.locales
    SiteLanguage.codes
  end

  validates :subject, presence: true
  validates :body,    presence: true
  validates :status,  inclusion: { in: STATUSES }
  validates :locale,  inclusion: { in: ->(_) { SiteLanguage.codes } }

  scope :recent, -> { order(created_at: :desc) }
  scope :sent, -> { where(status: "sent") }
  scope :draft, -> { where(status: "draft") }

  def sent?
    status == "sent"
  end
end
