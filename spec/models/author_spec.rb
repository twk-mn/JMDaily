require 'rails_helper'

RSpec.describe Author, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:user).optional }
    it { is_expected.to have_many(:articles).dependent(:restrict_with_error) }
  end

  describe 'validations' do
    subject { build(:author) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:slug) }

    it 'requires slug (or name to auto-generate)' do
      author = build(:author, name: nil, slug: nil)
      expect(author).not_to be_valid
      expect(author.errors[:slug]).to be_present
    end
  end

  describe 'slug generation' do
    it 'auto-generates slug from name' do
      author = create(:author, name: "John Smith", slug: nil)
      expect(author.slug).to eq("john-smith")
    end

    it 'does not overwrite existing slug' do
      author = create(:author, name: "John Smith", slug: "custom-slug")
      expect(author.slug).to eq("custom-slug")
    end
  end

  describe 'slug format validation' do
    it 'rejects slugs with uppercase' do
      author = build(:author, slug: "UPPERCASE")
      expect(author).not_to be_valid
    end

    it 'rejects slugs with spaces' do
      author = build(:author, slug: "has space")
      expect(author).not_to be_valid
    end

    it 'accepts valid slugs' do
      author = build(:author, slug: "valid-slug-123")
      expect(author).to be_valid
    end
  end

  describe '#to_param' do
    it 'returns slug' do
      author = build(:author, slug: "test-author")
      expect(author.to_param).to eq("test-author")
    end
  end
end
