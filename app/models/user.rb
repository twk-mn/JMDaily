class User < ApplicationRecord
  has_secure_password

  has_one :author, dependent: :nullify

  validates :email, presence: true, uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :role, inclusion: { in: %w[admin editor] }

  before_save :downcase_email

  def admin?
    role == "admin"
  end

  private

  def downcase_email
    self.email = email.downcase
  end
end
