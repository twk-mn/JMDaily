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
end
