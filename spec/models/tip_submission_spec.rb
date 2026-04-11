require 'rails_helper'

RSpec.describe TipSubmission, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:tip_body) }

    it 'is valid with only a tip body' do
      expect(build(:tip_submission, name: nil, email: nil)).to be_valid
    end

    it 'is valid with all fields' do
      expect(build(:tip_submission)).to be_valid
    end
  end

  describe 'scopes' do
    let!(:unread_tip) { create(:tip_submission, read: false) }
    let!(:read_tip)   { create(:tip_submission, read: true) }

    describe '.unread' do
      it 'returns only unread tips' do
        expect(TipSubmission.unread).to include(unread_tip)
        expect(TipSubmission.unread).not_to include(read_tip)
      end
    end

    describe '.recent' do
      it 'orders by created_at desc' do
        older = create(:tip_submission)
        newer = create(:tip_submission)
        newer.update_column(:created_at, 1.hour.from_now)
        expect(TipSubmission.recent.first).to eq(newer)
      end
    end
  end

  describe 'default values' do
    it 'defaults read to false' do
      tip = TipSubmission.new(tip_body: "test")
      expect(tip.read).to be false
    end
  end
end
