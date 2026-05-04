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
      expect(Category.all.to_a).to eq([ cat_a, cat_b ])
    end
  end

  describe '#to_param' do
    it 'returns slug' do
      category = build(:category, slug: "news")
      expect(category.to_param).to eq("news")
    end
  end

  describe 'translations (Translatable concern)' do
    let(:category) do
      create(:category, name: "News", slug: "news", description: "Local news.")
    end

    it 'has many translations and destroys them with the parent' do
      category.translations.create!(locale: "ja", name: "ニュース")
      expect { category.destroy }.to change(CategoryTranslation, :count).by(-1)
    end

    it 'localized_name returns the JA translation when present' do
      category.translations.create!(locale: "ja", name: "ニュース")
      expect(category.localized_name(:ja)).to eq("ニュース")
    end

    it 'localized_name falls back to the parent name when missing' do
      expect(category.localized_name(:ja)).to eq("News")
    end

    it 'localized_description returns the JA translation when present' do
      category.translations.create!(locale: "ja", description: "地域のニュース")
      expect(category.localized_description(:ja)).to eq("地域のニュース")
    end

    it 'rejects nested translation rows where every translatable field is blank' do
      category.update!(translations_attributes: [
        { locale: "ja", name: "", description: "" }
      ])
      expect(category.translations.where(locale: "ja")).to be_empty
    end

    it 'accepts new translations through nested attributes' do
      category.update!(translations_attributes: [
        { locale: "ja", name: "ニュース", description: "地域のニュース" }
      ])
      expect(category.translation_for(:ja).name).to eq("ニュース")
    end
  end
end
