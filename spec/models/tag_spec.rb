require 'rails_helper'

RSpec.describe Tag, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:article_tags).dependent(:destroy) }
    it { is_expected.to have_many(:articles).through(:article_tags) }
  end

  describe 'validations' do
    subject { build(:tag) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
    it { is_expected.to validate_uniqueness_of(:slug) }

    it 'requires slug (or name to auto-generate)' do
      tag = build(:tag, name: nil, slug: nil)
      expect(tag).not_to be_valid
      expect(tag.errors[:slug]).to be_present
    end
  end

  describe 'slug generation' do
    it 'auto-generates slug from name' do
      tag = create(:tag, name: "Winter Sports", slug: nil)
      expect(tag.slug).to eq("winter-sports")
    end
  end

  describe '#to_param' do
    it 'returns slug' do
      tag = build(:tag, slug: "test-tag")
      expect(tag.to_param).to eq("test-tag")
    end
  end
end
