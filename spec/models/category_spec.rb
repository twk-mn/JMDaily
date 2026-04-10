require 'rails_helper'

RSpec.describe Category, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:articles).dependent(:restrict_with_error) }
  end

  describe 'validations' do
    subject { build(:category) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
    it { is_expected.to validate_uniqueness_of(:slug) }

    it 'requires slug (or name to auto-generate)' do
      category = build(:category, name: nil, slug: nil)
      expect(category).not_to be_valid
      expect(category.errors[:slug]).to be_present
    end
  end

  describe 'slug generation' do
    it 'auto-generates slug from name' do
      category = create(:category, name: "Local News", slug: nil)
      expect(category.slug).to eq("local-news")
    end
  end

  describe 'default_scope' do
    it 'orders by position' do
      cat_b = create(:category, position: 2)
      cat_a = create(:category, position: 1)
      expect(Category.all.to_a).to eq([cat_a, cat_b])
    end
  end

  describe '#to_param' do
    it 'returns slug' do
      category = build(:category, slug: "news")
      expect(category.to_param).to eq("news")
    end
  end
end
