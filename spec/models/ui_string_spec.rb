require "rails_helper"

RSpec.describe UiString, type: :model do
  describe "validations" do
    it "requires a key" do
      s = UiString.new(locale: "en", value: "OK")
      expect(s).not_to be_valid
      expect(s.errors[:key]).to be_present
    end

    it "requires a locale" do
      s = UiString.new(key: "footer.about_heading", value: "OK")
      expect(s).not_to be_valid
      expect(s.errors[:locale]).to be_present
    end

    it "rejects an unknown locale" do
      s = UiString.new(key: "footer.about_heading", locale: "xx", value: "OK")
      expect(s).not_to be_valid
      expect(s.errors[:locale]).to be_present
    end

    it "accepts any locale present in SiteLanguage.codes" do
      s = UiString.new(key: "footer.about_heading", locale: "ja", value: "について")
      expect(s).to be_valid
    end

    it "enforces uniqueness of (key, locale)" do
      UiString.create!(key: "footer.about_heading", locale: "ja", value: "について")
      duplicate = UiString.new(key: "footer.about_heading", locale: "ja", value: "別")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:key]).to be_present
    end

    it "allows the same key across different locales" do
      UiString.create!(key: "footer.about_heading", locale: "en", value: "About")
      ja = UiString.new(key: "footer.about_heading", locale: "ja", value: "について")
      expect(ja).to be_valid
    end
  end

  describe ".map_for" do
    it "returns key→value hash filtered by locale" do
      UiString.create!(key: "a.b", locale: "en", value: "AB")
      UiString.create!(key: "c.d", locale: "en", value: "CD")
      UiString.create!(key: "a.b", locale: "ja", value: "ABJa")

      expect(UiString.map_for("en")).to eq("a.b" => "AB", "c.d" => "CD")
      expect(UiString.map_for("ja")).to eq("a.b" => "ABJa")
    end

    it "returns an empty hash for a locale with no rows" do
      expect(UiString.map_for("ja")).to eq({})
    end
  end

  describe ".definitions_for_tab" do
    it "returns only definitions for the matching tab" do
      footer = UiString.definitions_for_tab("footer")
      expect(footer.keys).to all(start_with("footer."))
    end
  end

  describe ".default_for" do
    it "returns the registered English default" do
      expect(UiString.default_for("footer.about_heading")).to eq("About")
    end

    it "returns nil for an unknown key" do
      expect(UiString.default_for("nope.unknown")).to be_nil
    end
  end
end
