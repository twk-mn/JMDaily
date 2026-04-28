require 'rails_helper'

RSpec.describe "Authors", type: :request do
  describe "GET /authors/:slug" do
    it "returns success" do
      author = create(:author)
      get author_path(author)
      expect(response).to have_http_status(:success)
    end

    it "displays author info and articles" do
      author = create(:author, name: "Jane Reporter")
      article = create(:article, :published, author: author, title: "Author Test Article")

      get author_path(author)
      expect(response.body).to include("Jane Reporter")
      expect(response.body).to include("Author Test Article")
    end

    it "returns 404 for non-existent author" do
      get author_path(slug: "nonexistent")
      expect(response).to have_http_status(:not_found)
    end

    it "renders breadcrumbs with Home and the author name" do
      author = create(:author, name: "Jane Reporter")
      get author_path(author)
      expect(response.body).to include('aria-label="Breadcrumb"')
      expect(response.body).to match(/aria-current="page"[^>]*>Jane Reporter</)
    end

    it "renders the empty state when the author has no articles" do
      author = create(:author, name: "Jane Reporter")
      get author_path(author)
      expect(response.body).to include("No published articles yet")
    end

    it "renders all configured social links on the author page" do
      author = create(:author,
                      twitter_url:   "https://twitter.com/jane",
                      bluesky_url:   "https://bsky.app/profile/jane",
                      mastodon_url:  "https://mastodon.social/@jane",
                      instagram_url: "https://instagram.com/jane",
                      facebook_url:  "https://facebook.com/jane",
                      linkedin_url:  "https://linkedin.com/in/jane",
                      youtube_url:   "https://youtube.com/@jane",
                      website_url:   "https://jane.example")

      get author_path(author)

      %w[Twitter Bluesky Mastodon Instagram Facebook LinkedIn YouTube Website].each do |label|
        expect(response.body).to include(">#{label}</a>"), "expected author page to render #{label} link"
      end
    end
  end
end
