require 'rails_helper'

RSpec.describe "Tags", type: :request do
  describe "GET /tags/:slug" do
    it "returns success" do
      tag = create(:tag)
      get tag_path(slug: tag.slug)
      expect(response).to have_http_status(:success)
    end

    it "displays articles with that tag" do
      tag = create(:tag)
      article = create(:article, :published, title: "Tagged Article")
      create(:article_tag, article: article, tag: tag)

      get tag_path(slug: tag.slug)
      expect(response.body).to include("Tagged Article")
    end

    it "returns 404 for non-existent tag" do
      get tag_path(slug: "nonexistent")
      expect(response).to have_http_status(:not_found)
    end
  end
end
