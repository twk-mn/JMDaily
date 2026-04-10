class User < ApplicationRecord
  has_secure_password

  has_one :author, dependent: :nullify

  validates :email, presence: true, uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :role, inclusion: { in: %w[admin editor] }
  validates :password, length: { minimum: 12 },
                       format: {
                         with: /\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d).+\z/,
                         message: "must include at least one uppercase letter, one lowercase letter, and one number"
                       },
                       if: :password_digest_changed?

  before_save :downcase_email

  def admin?
    role == "admin"
  end

  # --- Two-factor authentication ---

  def otp_enabled?
    totp_secret.present? && totp_enabled_at.present?
  end

  def generate_totp_secret!
    update!(totp_secret: ROTP::Base32.random, totp_enabled_at: nil)
  end

  def otpauth_uri
    ROTP::TOTP.new(totp_secret, issuer: "JMDaily").provisioning_uri(email)
  end

  def enable_totp!(code)
    return false if totp_secret.blank?
    return false unless ROTP::TOTP.new(totp_secret, issuer: "JMDaily").verify(code.to_s.gsub(/\s/, ""), drift_behind: 30)
    update!(totp_enabled_at: Time.current)
    true
  end

  def verify_otp(code)
    return false unless otp_enabled?
    ROTP::TOTP.new(totp_secret, issuer: "JMDaily").verify(code.to_s.gsub(/\s/, ""), drift_behind: 30, drift_ahead: 30)
  end

  def disable_totp!
    update!(totp_secret: nil, totp_enabled_at: nil)
  end

  private

  def downcase_email
    self.email = email.downcase
  end
end
