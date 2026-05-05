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

  describe 'translations (Translatable concern)' do
    let(:author) do
      create(:author, name: "Aya Tanaka", slug: "aya-tanaka",
             role_title: "Senior reporter",
             bio: "Aya covers Niigata politics.")
    end

    it 'has many translations and destroys them with the parent' do
      author.translations.create!(locale: "ja", role_title: "上級記者", bio: "新潟の政治を担当")
      expect { author.destroy }.to change(AuthorTranslation, :count).by(-1)
    end

    it 'localized_bio returns the JA translation when present' do
      author.translations.create!(locale: "ja", bio: "新潟の政治を担当")
      expect(author.localized_bio(:ja)).to eq("新潟の政治を担当")
    end

    it 'localized_role_title falls back to the parent when no translation' do
      expect(author.localized_role_title(:ja)).to eq("Senior reporter")
    end

    it 'rejects nested translation rows where every translatable field is blank' do
      author.update!(translations_attributes: [
        { locale: "ja", role_title: "", bio: "" }
      ])
      expect(author.translations.where(locale: "ja")).to be_empty
    end

    it 'accepts new translations via nested attributes' do
      author.update!(translations_attributes: [
        { locale: "ja", role_title: "上級記者", bio: "新潟の政治を担当" }
      ])
      expect(author.translation_for(:ja).bio).to eq("新潟の政治を担当")
    end
  end
end
