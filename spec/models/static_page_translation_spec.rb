require "rails_helper"

RSpec.describe StaticPageTranslation, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:static_page) }
    it { is_expected.to have_rich_text(:body) }
  end

  describe "validations" do
    let(:page) { create(:static_page) }

    it "requires a locale" do
      t = StaticPageTranslation.new(static_page: page, title: "About")
      expect(t).not_to be_valid
      expect(t.errors[:locale]).to be_present
    end

    it "rejects an unknown locale" do
      t = StaticPageTranslation.new(static_page: page, locale: "xx", title: "About")
      expect(t).not_to be_valid
      expect(t.errors[:locale]).to be_present
    end

    it "accepts a known SiteLanguage code" do
      t = StaticPageTranslation.new(static_page: page, locale: "ja", title: "概要")
      expect(t).to be_valid
    end

    it "enforces one translation per locale per page" do
      page.translations.create!(locale: "ja", title: "概要")
      duplicate = StaticPageTranslation.new(static_page: page, locale: "ja", title: "別")
      expect(duplicate).not_to be_valid
    end
  end
end
