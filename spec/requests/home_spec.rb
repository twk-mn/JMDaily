require 'rails_helper'

RSpec.describe "Home", type: :request do
  describe "GET /en" do
    it "returns success" do
      get locale_root_path
      expect(response).to have_http_status(:success)
    end

    it "displays lead story when featured article exists" do
      article = create(:article, :featured)
      get locale_root_path
      expect(response.body).to include(article.title)
    end

    it "displays latest articles" do
      articles = create_list(:article, 3, :published)
      get locale_root_path
      articles.each do |article|
        expect(response.body).to include(article.title)
      end
    end

    it "displays breaking news" do
      create(:article, :breaking, title: "Breaking News Story")
      get locale_root_path
      expect(response.body).to include("Breaking News Story")
    end

    it "displays location-based articles" do
      joetsu = create(:location, name: "Joetsu", slug: "joetsu")
      article = create(:article, :published, title: "Joetsu Story")
      create(:article_location, article: article, location: joetsu)

      get locale_root_path
      expect(response.body).to include("Joetsu Story")
    end

    describe "section layout" do
      it "renders the hero with up to three stacked secondary stories" do
        create(:article, :featured, title: "Lead Story")
        create_list(:article, 4, :published).each_with_index do |a, i|
          a.translations.first.update!(title: "Recent Story #{i}")
          a.update!(title: "Recent Story #{i}")
        end

        get locale_root_path
        expect(response.body).to include("Lead Story")
        expect(response.body).to include('aria-label="Top stories"')
      end

      it "renders a Local News grid from the News category" do
        news = create(:category, name: "News", slug: "news")
        # Hero + 3 secondaries consume the four most recent articles, so the
        # fifth one lands in the Local News grid.
        5.times { |i| create(:article, :published, category: news, title: "News Item #{i}", published_at: (i + 1).hours.ago) }
        get locale_root_path
        expect(response.body).to include("News Item 4")
        expect(response.body).to match(/>Local News</)
      end

      it "renders the newsletter capture card with a subscribe form" do
        get locale_root_path
        expect(response.body).to include("Get the Joetsu-Myoko Daily")
        expect(response.body).to include(%(action="#{newsletter_subscribe_path}))
        expect(response.body).to include('id="home-newsletter-email"')
      end

      it "honors SiteConfig::HOMEPAGE_SECTIONS ordering" do
        original = SiteConfig::HOMEPAGE_SECTIONS
        stub_const("SiteConfig::HOMEPAGE_SECTIONS", %i[newsletter ad_mid])

        get locale_root_path

        expect(response.body).to include("Get the Joetsu-Myoko Daily")
        # Only these two sections are rendered now — hero / local_news / locations
        # should be absent.
        expect(response.body).not_to include('aria-label="Top stories"')
      ensure
        stub_const("SiteConfig::HOMEPAGE_SECTIONS", original) if original
      end
    end

    describe "language switcher" do
      it "renders a link for every active SiteLanguage" do
        SiteLanguage.create!(code: "ko", position: 5, active: true)

        get locale_root_path
        expect(response.body).to include('href="/ko"')
        expect(response.body).to include('href="/en"')
        expect(response.body).to include('href="/ja"')
      end

      it "omits languages that are inactive" do
        SiteLanguage.find_by(code: "ja").update!(active: false)

        get locale_root_path
        expect(response.body).not_to include('href="/ja"')
      end

      it "marks the current locale with aria-current" do
        get locale_root_path(locale: "en")
        # Scope to the language-switcher pill group so we don't match the
        # masthead's locale_root_path link, which also points at /en.
        switcher = response.body[/<div[^>]*aria-label="Language"[^>]*>.*?<\/div>/m]
        en_link = switcher[/<a\b[^>]*href="\/en"[^>]*>/] || switcher[/<a\b[^>]*aria-current[^>]*href="\/en"[^>]*>/]
        expect(en_link).to include('aria-current="true"')
      end
    end

    describe "site_name / tagline settings wiring" do
      it "uses the saved site_name in the masthead, footer, and og:site_name" do
        Setting.set("site_name", "Niigata News")
        get locale_root_path

        # Masthead h1
        expect(response.body).to match(/<h1[^>]*>\s*Niigata News\s*<\/h1>/)
        # Footer copyright + about-block heading
        expect(response.body).to include("Niigata News. All rights reserved.")
        # og:site_name + RSS title
        expect(response.body).to include('property="og:site_name" content="Niigata News"')
      end

      it "uses the saved tagline under the masthead" do
        Setting.set("tagline", "Hyperlocal coverage of Niigata")
        get locale_root_path

        # Tagline appears in the masthead p tag and the footer about blurb.
        expect(response.body).to include("Hyperlocal coverage of Niigata")
      end

      it "falls back to the registered defaults when no settings saved" do
        get locale_root_path

        expect(response.body).to include("Joetsu-Myoko Daily")
        # The hardcoded masthead tagline only appears when the setting is blank.
        expect(response.body).to include("Local news in English — Joetsu · Myoko · Niigata")
      end
    end

    describe "UI chrome strings (t_ui)" do
      it "renders the registered English defaults when no UiString rows exist" do
        get locale_root_path

        # Footer column headings come from UiString::DEFINITIONS via t_ui.
        expect(response.body).to include("About")
        expect(response.body).to include("Legal")
        expect(response.body).to include("Stay informed")
      end

      it "renders a saved UiString translation in the active locale" do
        UiString.create!(key: "footer.about_heading", locale: "ja", value: "について")
        UiString.create!(key: "footer.legal_heading", locale: "ja", value: "法的事項")

        get locale_root_path(locale: :ja)
        expect(response.body).to include("について")
        expect(response.body).to include("法的事項")
      end

      it "falls back to English when the active locale has no row" do
        UiString.create!(key: "footer.about_heading", locale: "en", value: "About Us Footer")

        get locale_root_path(locale: :ja)
        # Footer header takes the EN row when no JA row exists.
        expect(response.body).to include("About Us Footer")
      end
    end
  end
end
