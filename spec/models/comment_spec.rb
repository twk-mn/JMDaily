require 'rails_helper'

RSpec.describe Comment, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:article) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:body) }
    it { is_expected.to validate_length_of(:body).is_at_most(2000) }
    it { is_expected.to validate_inclusion_of(:status).in_array(Comment::STATUSES) }
  end

  describe 'scopes' do
    let!(:approved) { create(:comment, :approved) }
    let!(:pending_comment) { create(:comment) }
    let!(:rejected) { create(:comment, :rejected) }

    it 'approved returns only approved comments' do
      expect(Comment.approved).to contain_exactly(approved)
    end

    it 'pending returns only pending comments' do
      expect(Comment.pending).to contain_exactly(pending_comment)
    end
  end

  describe '#approve!' do
    it 'sets status to approved' do
      comment = create(:comment)
      comment.approve!
      expect(comment.reload.status).to eq("approved")
    end
  end

  describe '#reject!' do
    it 'sets status to rejected' do
      comment = create(:comment)
      comment.reject!
      expect(comment.reload.status).to eq("rejected")
    end
  end

  describe '#approved?' do
    it 'returns true for approved comments' do
      expect(build(:comment, :approved)).to be_approved
    end

    it 'returns false for pending comments' do
      expect(build(:comment)).not_to be_approved
    end
  end
end
