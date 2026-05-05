require "rails_helper"

RSpec.describe AuthorTranslation, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:author) }
  end

  describe "validations" do
    let(:author) { create(:author) }

    it "requires a locale" do
      t = AuthorTranslation.new(author: author, bio: "Bio")
      expect(t).not_to be_valid
      expect(t.errors[:locale]).to be_present
    end

    it "rejects an unknown locale" do
      t = AuthorTranslation.new(author: author, locale: "xx", bio: "Bio")
      expect(t).not_to be_valid
      expect(t.errors[:locale]).to be_present
    end

    it "accepts a known SiteLanguage code" do
      t = AuthorTranslation.new(author: author, locale: "ja", bio: "新潟の政治を担当")
      expect(t).to be_valid
    end

    it "enforces one translation per locale per author" do
      author.translations.create!(locale: "ja", bio: "新潟")
      duplicate = AuthorTranslation.new(author: author, locale: "ja", bio: "別")
      expect(duplicate).not_to be_valid
    end
  end
end
