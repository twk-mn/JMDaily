require "rails_helper"

RSpec.describe TagTranslation, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:tag) }
  end

  describe "validations" do
    let(:tag) { create(:tag) }

    it "requires a locale" do
      t = TagTranslation.new(tag: tag, name: "Festivals")
      expect(t).not_to be_valid
      expect(t.errors[:locale]).to be_present
    end

    it "rejects an unknown locale" do
      t = TagTranslation.new(tag: tag, locale: "xx", name: "Festivals")
      expect(t).not_to be_valid
      expect(t.errors[:locale]).to be_present
    end

    it "accepts a known SiteLanguage code" do
      t = TagTranslation.new(tag: tag, locale: "ja", name: "祭り")
      expect(t).to be_valid
    end

    it "enforces one translation per locale per tag" do
      tag.translations.create!(locale: "ja", name: "祭り")
      duplicate = TagTranslation.new(tag: tag, locale: "ja", name: "別")
      expect(duplicate).not_to be_valid
    end
  end
end
