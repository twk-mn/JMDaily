require 'rails_helper'

RSpec.describe "Feed", type: :request do
  describe "GET /feed" do
    it "returns RSS feed" do
      create(:article, :published, title: "Feed Article")
      get feed_path(format: :rss)
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include("application/rss+xml")
      expect(response.body).to include("Feed Article")
    end

    it "includes only published articles" do
      create(:article, :published, title: "Published Story")
      create(:article, status: "draft", title: "Draft Story")
      get feed_path(format: :rss)
      expect(response.body).to include("Published Story")
      expect(response.body).not_to include("Draft Story")
    end
  end
end
