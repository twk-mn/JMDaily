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

    it 'validates email format' do
      user = build(:user, email: "not-an-email")
      expect(user).not_to be_valid
      expect(user.errors[:email]).to be_present
    end

    it 'accepts valid email' do
      user = build(:user, email: "test@example.com")
      expect(user).to be_valid
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
end
