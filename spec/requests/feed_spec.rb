require "rails_helper"

RSpec.describe "Feed", type: :request do
  describe "GET /feed" do
    let!(:article) { create(:article, :published, title: "Feed Article") }

    it "returns RSS feed" do
      get feed_path(format: :rss)
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include("application/rss+xml")
    end

    it "includes only published articles" do
      create(:article, status: "draft", title: "Draft Story")
      get feed_path(format: :rss)
      expect(response.body).to include("Feed Article")
      expect(response.body).not_to include("Draft Story")
    end

    it "defaults to English locale" do
      get feed_path(format: :rss)
      expect(response.body).to include("Joetsu-Myoko Daily")
      expect(response.body).to include("<language>en</language>")
    end

    it "serves Japanese feed when locale=ja" do
      get feed_path(format: :rss, locale: "ja")
      expect(response.body).to include("<language>ja</language>")
    end

    it "falls back to English for unknown locale" do
      get feed_path(format: :rss, locale: "fr")
      expect(response.body).to include("<language>en</language>")
    end

    it "uses translation title in English feed" do
      en_translation = article.translations.find { |t| t.locale == "en" }
      get feed_path(format: :rss)
      expect(response.body).to include(en_translation.title)
    end

    it "falls back to EN translation for articles without JA translation" do
      get feed_path(format: :rss, locale: "ja")
      en_translation = article.translations.find { |t| t.locale == "en" }
      expect(response.body).to include(en_translation.title)
    end
  end
end
