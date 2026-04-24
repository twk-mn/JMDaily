require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#language_switcher_options" do
    it "returns an entry per active SiteLanguage, ordered by position" do
      options = helper.language_switcher_options
      codes = options.map { |o| o[:code] }
      expect(codes).to eq(%w[en ja])
    end

    it "flags the current locale as current" do
      I18n.with_locale(:ja) do
        options = helper.language_switcher_options
        ja = options.find { |o| o[:code] == "ja" }
        en = options.find { |o| o[:code] == "en" }

        expect(ja[:current]).to be true
        expect(en[:current]).to be false
      end
    end

    it "includes display name, short label, and a locale_root url" do
      en = helper.language_switcher_options.find { |o| o[:code] == "en" }

      expect(en[:short_label]).to eq("EN")
      expect(en[:display_name]).to eq("English")
      expect(en[:url]).to eq("/en")
    end

    it "excludes inactive languages" do
      SiteLanguage.find_by(code: "ja").update!(active: false)

      codes = helper.language_switcher_options.map { |o| o[:code] }
      expect(codes).to eq(%w[en])
    end

    it "picks up newly added languages without code changes" do
      SiteLanguage.create!(code: "ko", position: 99, active: true)

      codes = helper.language_switcher_options.map { |o| o[:code] }
      expect(codes).to include("ko")
    end
  end
end
