require "rails_helper"

RSpec.describe LocationTranslation, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:location) }
  end

  describe "validations" do
    let(:location) { create(:location) }

    it "requires a locale" do
      t = LocationTranslation.new(location: location, name: "上越")
      expect(t).not_to be_valid
      expect(t.errors[:locale]).to be_present
    end

    it "rejects an unknown locale" do
      t = LocationTranslation.new(location: location, locale: "xx", name: "X")
      expect(t).not_to be_valid
      expect(t.errors[:locale]).to be_present
    end

    it "accepts any locale present in SiteLanguage.codes" do
      t = LocationTranslation.new(location: location, locale: "ja", name: "上越")
      expect(t).to be_valid
    end

    it "enforces one translation per locale per location" do
      location.translations.create!(locale: "ja", name: "上越")
      duplicate = LocationTranslation.new(location: location, locale: "ja", name: "上越市")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:locale]).to be_present
    end

    it "allows the same locale across different locations" do
      other = create(:location, name: "Myoko", slug: "myoko")
      location.translations.create!(locale: "ja", name: "上越")
      sibling = LocationTranslation.new(location: other, locale: "ja", name: "妙高")
      expect(sibling).to be_valid
    end
  end
end
