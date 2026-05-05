require 'rails_helper'

RSpec.describe StaticPage, type: :model do
  describe 'validations' do
    subject { build(:static_page) }

    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_uniqueness_of(:slug) }

    it 'requires slug (or title to auto-generate)' do
      page = build(:static_page, title: nil, slug: nil)
      expect(page).not_to be_valid
      expect(page.errors[:slug]).to be_present
    end
  end

  describe 'slug generation' do
    it 'auto-generates slug from title' do
      page = create(:static_page, title: "Privacy Policy", slug: nil)
      expect(page.slug).to eq("privacy-policy")
    end
  end

  describe '#to_param' do
    it 'returns slug' do
      page = build(:static_page, slug: "about")
      expect(page.to_param).to eq("about")
    end
  end

  describe 'translations (Translatable concern)' do
    let(:page) do
      create(:static_page, title: "About", slug: "about",
             seo_title: "About Joetsu-Myoko Daily",
             meta_description: "Local news.").tap do |p|
        p.update!(body: "<p>Independent local news.</p>")
      end
    end

    it 'has many translations and destroys them with the parent' do
      page.translations.create!(locale: "ja", title: "概要", meta_description: "ローカルニュース")
      expect { page.destroy }.to change(StaticPageTranslation, :count).by(-1)
    end

    it 'localized_title returns the JA translation when present' do
      page.translations.create!(locale: "ja", title: "概要")
      expect(page.localized_title(:ja)).to eq("概要")
    end

    it 'localized_title falls back to the parent title when missing' do
      expect(page.localized_title(:ja)).to eq("About")
    end

    it 'localized_body returns the JA rich-text when present' do
      ja = page.translations.create!(locale: "ja", title: "概要")
      ja.update!(body: "<p>地域のニュース</p>")
      expect(page.localized_body(:ja).to_plain_text).to include("地域のニュース")
    end

    it 'localized_body falls back to the parent rich-text when JA is blank' do
      page.translations.create!(locale: "ja", title: "概要")
      expect(page.localized_body(:ja).to_plain_text).to include("Independent local news.")
    end

    it 'rejects nested translation rows where every translatable field is blank' do
      page.update!(translations_attributes: [
        { locale: "ja", title: "", seo_title: "", meta_description: "", body: "" }
      ])
      expect(page.translations.where(locale: "ja")).to be_empty
    end
  end
end
