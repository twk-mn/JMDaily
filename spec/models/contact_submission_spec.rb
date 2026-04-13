require 'rails_helper'

RSpec.describe ContactSubmission, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_presence_of(:message) }

    it 'validates email format' do
      submission = build(:contact_submission, email: "invalid")
      expect(submission).not_to be_valid
    end

    it 'accepts valid email' do
      submission = build(:contact_submission, email: "test@example.com")
      expect(submission).to be_valid
    end
  end
end
