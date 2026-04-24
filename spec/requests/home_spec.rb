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
        # Attribute order isn't guaranteed — look for an <a> tag that contains
        # both href="/en" and aria-current="true".
        en_link = response.body[/<a\b[^>]*href="\/en"[^>]*>/] || response.body[/<a\b[^>]*aria-current[^>]*href="\/en"[^>]*>/]
        expect(en_link).to include('aria-current="true"')
      end
    end
  end
end
