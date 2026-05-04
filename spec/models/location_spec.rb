require 'rails_helper'

RSpec.describe Location, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:article_locations).dependent(:destroy) }
    it { is_expected.to have_many(:articles).through(:article_locations) }
  end

  describe 'validations' do
    subject { build(:location) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
    it { is_expected.to validate_uniqueness_of(:slug) }

    it 'requires slug (or name to auto-generate)' do
      location = build(:location, name: nil, slug: nil)
      expect(location).not_to be_valid
      expect(location.errors[:slug]).to be_present
    end
  end

  describe 'slug generation' do
    it 'auto-generates slug from name' do
      location = create(:location, name: "Joetsu City", slug: nil)
      expect(location.slug).to eq("joetsu-city")
    end
  end

  describe '#to_param' do
    it 'returns slug' do
      location = build(:location, slug: "joetsu")
      expect(location.to_param).to eq("joetsu")
    end
  end

  describe 'translations (Translatable concern)' do
    let(:location) do
      create(:location, name: "Joetsu", slug: "joetsu",
             description: "Coverage of Joetsu City.")
    end

    it 'has many translations and destroys them with the parent' do
      location.translations.create!(locale: "ja", name: "上越", description: "上越市の取材")
      expect { location.destroy }.to change(LocationTranslation, :count).by(-1)
    end

    describe '#localized_name' do
      it 'returns the parent name when no translation exists for the locale' do
        expect(location.localized_name(:ja)).to eq("Joetsu")
      end

      it 'returns the translation name when one exists for the locale' do
        location.translations.create!(locale: "ja", name: "上越")
        expect(location.localized_name(:ja)).to eq("上越")
      end

      it 'falls back to the parent name when the translation name is blank' do
        location.translations.create!(locale: "ja", name: "", description: "Some desc")
        expect(location.localized_name(:ja)).to eq("Joetsu")
      end

      it 'defaults to the current I18n.locale when no locale is passed' do
        location.translations.create!(locale: "ja", name: "上越")
        I18n.with_locale(:ja) do
          expect(location.localized_name).to eq("上越")
        end
      end
    end

    describe '#localized_description' do
      it 'falls back to the parent description when missing' do
        expect(location.localized_description(:ja)).to eq("Coverage of Joetsu City.")
      end

      it 'returns the translation when present' do
        location.translations.create!(locale: "ja", description: "上越市の取材")
        expect(location.localized_description(:ja)).to eq("上越市の取材")
      end
    end

    describe 'nested attributes' do
      it 'accepts new translations through the parent record' do
        location.update!(translations_attributes: [
          { locale: "ja", name: "上越", description: "上越市" }
        ])
        expect(location.translations.find_by(locale: "ja").name).to eq("上越")
      end

      it 'rejects translation rows where every translatable field is blank' do
        location.update!(translations_attributes: [
          { locale: "ja", name: "", description: "" }
        ])
        expect(location.translations.where(locale: "ja")).to be_empty
      end

      it 'updates an existing translation via :id' do
        existing = location.translations.create!(locale: "ja", name: "上越")
        location.update!(translations_attributes: [
          { id: existing.id, locale: "ja", name: "上越市" }
        ])
        expect(existing.reload.name).to eq("上越市")
      end
    end
  end
end
