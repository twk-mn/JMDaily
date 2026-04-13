require 'rails_helper'

RSpec.describe NewsletterIssue, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:subject) }
    it { is_expected.to validate_presence_of(:body) }
    it { is_expected.to validate_inclusion_of(:status).in_array(NewsletterIssue::STATUSES) }
  end

  describe 'scopes' do
    let!(:draft) { create(:newsletter_issue) }
    let!(:sent) { create(:newsletter_issue, :sent) }

    it 'draft returns only drafts' do
      expect(NewsletterIssue.draft).to contain_exactly(draft)
    end

    it 'sent returns only sent issues' do
      expect(NewsletterIssue.sent).to contain_exactly(sent)
    end
  end

  describe '#sent?' do
    it 'returns true when status is sent' do
      expect(build(:newsletter_issue, :sent)).to be_sent
    end

    it 'returns false when status is draft' do
      expect(build(:newsletter_issue)).not_to be_sent
    end
  end
end
