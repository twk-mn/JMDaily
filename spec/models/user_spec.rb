require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { is_expected.to have_one(:author).dependent(:nullify) }
  end

  describe 'validations' do
    subject { build(:user) }

    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_inclusion_of(:role).in_array(%w[admin editor]) }
    it { is_expected.to have_secure_password }

    it 'rejects invalid email format' do
      expect(build(:user, email: "not-an-email")).not_to be_valid
    end

    it 'accepts valid email' do
      expect(build(:user, email: "test@example.com")).to be_valid
    end

    describe 'password complexity' do
      it 'requires minimum 12 characters' do
        user = build(:user, password: "Short1!", password_confirmation: "Short1!")
        expect(user).not_to be_valid
        expect(user.errors[:password]).to be_present
      end

      it 'requires at least one uppercase letter' do
        user = build(:user, password: "alllowercase123", password_confirmation: "alllowercase123")
        expect(user).not_to be_valid
      end

      it 'requires at least one lowercase letter' do
        user = build(:user, password: "ALLUPPERCASE123", password_confirmation: "ALLUPPERCASE123")
        expect(user).not_to be_valid
      end

      it 'requires at least one digit' do
        user = build(:user, password: "NoDigitsHereAtAll", password_confirmation: "NoDigitsHereAtAll")
        expect(user).not_to be_valid
      end

      it 'accepts a valid complex password' do
        user = build(:user, password: "ValidPass123!", password_confirmation: "ValidPass123!")
        expect(user).to be_valid
      end

      it 'does not re-validate on updates that do not change password' do
        user = create(:user)
        user.name = "New Name"
        expect(user).to be_valid
      end
    end
  end

  describe '#admin?' do
    it 'returns true for admin role' do
      expect(build(:user, role: "admin")).to be_admin
    end

    it 'returns false for editor role' do
      expect(build(:user, role: "editor")).not_to be_admin
    end
  end

  describe 'before_save' do
    it 'downcases email' do
      user = create(:user, email: "TEST@Example.COM")
      expect(user.reload.email).to eq("test@example.com")
    end
  end

  describe 'two-factor authentication' do
    let(:user) { create(:user) }

    describe '#otp_enabled?' do
      it 'returns false when no secret is set' do
        expect(user.otp_enabled?).to be false
      end

      it 'returns false when secret set but not confirmed' do
        user.update_columns(totp_secret: ROTP::Base32.random, totp_enabled_at: nil)
        expect(user.otp_enabled?).to be false
      end

      it 'returns true when fully enabled' do
        user.update_columns(totp_secret: ROTP::Base32.random, totp_enabled_at: Time.current)
        expect(user.otp_enabled?).to be true
      end
    end

    describe '#generate_totp_secret!' do
      it 'sets a totp_secret and clears totp_enabled_at' do
        user.generate_totp_secret!
        expect(user.reload.totp_secret).to be_present
        expect(user.totp_enabled_at).to be_nil
      end
    end

    describe '#enable_totp!' do
      it 'enables 2FA with a valid current code' do
        user.generate_totp_secret!
        code = ROTP::TOTP.new(user.totp_secret).now
        expect(user.enable_totp!(code)).to be true
        expect(user.reload.totp_enabled_at).to be_present
      end

      it 'rejects an invalid code' do
        user.generate_totp_secret!
        expect(user.enable_totp!("000000")).to be false
        expect(user.reload.totp_enabled_at).to be_nil
      end
    end

    describe '#verify_otp' do
      it 'returns falsy when 2FA is not enabled' do
        expect(user.verify_otp("123456")).to be_falsy
      end

      it 'verifies a valid code when 2FA is enabled' do
        user.update_columns(totp_secret: ROTP::Base32.random, totp_enabled_at: Time.current)
        code = ROTP::TOTP.new(user.totp_secret).now
        expect(user.verify_otp(code)).to be_truthy
      end
    end

    describe '#disable_totp!' do
      it 'clears secret and enabled_at' do
        user.update_columns(totp_secret: ROTP::Base32.random, totp_enabled_at: Time.current)
        user.disable_totp!
        expect(user.reload.totp_secret).to be_nil
        expect(user.totp_enabled_at).to be_nil
      end
    end
  end
end
