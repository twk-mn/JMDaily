require "rails_helper"

RSpec.describe CategoryTranslation, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:category) }
  end

  describe "validations" do
    let(:category) { create(:category) }

    it "requires a locale" do
      t = CategoryTranslation.new(category: category, name: "News")
      expect(t).not_to be_valid
      expect(t.errors[:locale]).to be_present
    end

    it "rejects an unknown locale" do
      t = CategoryTranslation.new(category: category, locale: "xx", name: "News")
      expect(t).not_to be_valid
      expect(t.errors[:locale]).to be_present
    end

    it "accepts any locale present in SiteLanguage.codes" do
      t = CategoryTranslation.new(category: category, locale: "ja", name: "ニュース")
      expect(t).to be_valid
    end

    it "enforces one translation per locale per category" do
      category.translations.create!(locale: "ja", name: "ニュース")
      duplicate = CategoryTranslation.new(category: category, locale: "ja", name: "報道")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:locale]).to be_present
    end
  end
end
