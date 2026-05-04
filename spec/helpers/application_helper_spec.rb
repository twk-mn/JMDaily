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

  describe "#article_time_tag" do
    let(:time) { Time.zone.local(2026, 4, 28, 13, 30) }

    it "returns nil when time is nil so callers can skip the wrapper" do
      expect(helper.article_time_tag(nil)).to be_nil
    end

    it "renders the iso8601 timestamp in the datetime attribute" do
      html = helper.article_time_tag(time, format: :long)
      expect(html).to include(%(datetime="#{time.iso8601}"))
    end

    it "formats :long as 'April 28, 2026'" do
      expect(helper.article_time_tag(time, format: :long)).to include(">April 28, 2026<")
    end

    it "formats :short as 'Apr 28, 2026'" do
      expect(helper.article_time_tag(time, format: :short)).to include(">Apr 28, 2026<")
    end

    it "formats :compact as 'Apr 28' with no year" do
      expect(helper.article_time_tag(time, format: :compact)).to include(">Apr 28<")
    end

    it "formats :datetime with the time of day" do
      expect(helper.article_time_tag(time, format: :datetime)).to include(">April 28, 2026 at 1:30 PM<")
    end

    it "prepends a prefix when given" do
      html = helper.article_time_tag(time, format: :long, prefix: "Published")
      expect(html).to include(">Published April 28, 2026<")
    end

    it "passes html options through to the <time> tag" do
      html = helper.article_time_tag(time, format: :long, class: "text-xs")
      expect(html).to include(%(class="text-xs"))
    end

    it "raises for an unknown format so typos are caught early" do
      expect { helper.article_time_tag(time, format: :weird) }.to raise_error(KeyError)
    end
  end

  describe "#t_ui" do
    it "returns the DB row for the current locale when present" do
      UiString.create!(key: "footer.about_heading", locale: "ja", value: "について")
      I18n.with_locale(:ja) do
        expect(helper.t_ui("footer.about_heading")).to eq("について")
      end
    end

    it "falls back to the registered English default when no DB row or YAML exists" do
      I18n.with_locale(:ja) do
        # No JA UiString, no YAML key — falls through to DEFINITIONS default.
        expect(helper.t_ui("footer.about_heading")).to eq("About")
      end
    end

    it "falls through to the English DB row when the active locale has no row but EN does" do
      UiString.create!(key: "footer.about_heading", locale: "en", value: "About (custom)")
      I18n.with_locale(:ja) do
        expect(helper.t_ui("footer.about_heading")).to eq("About (custom)")
      end
    end

    it "prefers a YAML translation over the registered default" do
      I18n.backend.store_translations(:ja, { "footer" => { "about_heading" => "YAML JA" } })
      I18n.with_locale(:ja) do
        expect(helper.t_ui("footer.about_heading")).to eq("YAML JA")
      end
    ensure
      I18n.reload!
    end

    it "humanises the last segment of the key when nothing matches" do
      expect(helper.t_ui("nope.completely.unknown")).to eq("Unknown")
    end

    it "memoizes the per-locale lookup so multiple calls share one query" do
      UiString.create!(key: "footer.about_heading", locale: "en", value: "A")
      UiString.create!(key: "footer.legal_heading", locale: "en", value: "L")

      expect(UiString).to receive(:map_for).with("en").once.and_call_original
      helper.t_ui("footer.about_heading")
      helper.t_ui("footer.legal_heading")
    end

    it "accepts an explicit :locale option without affecting I18n.locale" do
      UiString.create!(key: "footer.about_heading", locale: "ja", value: "について")
      I18n.with_locale(:en) do
        expect(helper.t_ui("footer.about_heading", locale: :ja)).to eq("について")
        expect(I18n.locale).to eq(:en)
      end
    end
  end
end
