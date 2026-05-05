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

  describe 'translations (Translatable concern)' do
    let(:tag) { create(:tag, name: "Festivals", slug: "festivals") }

    it 'has many translations and destroys them with the parent' do
      tag.translations.create!(locale: "ja", name: "祭り")
      expect { tag.destroy }.to change(TagTranslation, :count).by(-1)
    end

    it 'localized_name returns the JA translation when present' do
      tag.translations.create!(locale: "ja", name: "祭り")
      expect(tag.localized_name(:ja)).to eq("祭り")
    end

    it 'localized_name falls back to the parent name when missing' do
      expect(tag.localized_name(:ja)).to eq("Festivals")
    end

    it 'rejects nested translation rows where name is blank' do
      tag.update!(translations_attributes: [ { locale: "ja", name: "" } ])
      expect(tag.translations.where(locale: "ja")).to be_empty
    end
  end
end
