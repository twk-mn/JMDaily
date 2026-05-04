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

    describe "translated bio + role_title" do
      it "renders the JA bio and role on the author page when a translation exists" do
        author = create(:author, name: "Aya Tanaka", slug: "aya-tanaka",
                                 role_title: "Senior reporter",
                                 bio: "Covers Niigata politics.")
        author.translations.create!(locale: "ja", role_title: "上級記者", bio: "新潟の政治を担当")

        get "/ja/authors/aya-tanaka"
        expect(response.body).to include("上級記者")
        expect(response.body).to include("新潟の政治を担当")
      end

      it "falls back to English when no translation exists for the active locale" do
        create(:author, name: "Aya Tanaka", slug: "aya-tanaka",
                       role_title: "Senior reporter",
                       bio: "Covers Niigata politics.")
        get "/ja/authors/aya-tanaka"
        expect(response.body).to include("Senior reporter")
        expect(response.body).to include("Covers Niigata politics.")
      end
    end

    describe "Open Graph meta" do
      it "sets og:type to profile" do
        author = create(:author)
        get author_path(author)
        expect(response.body).to include('property="og:type" content="profile"')
      end

      it "uses the author bio in the meta description (truncated)" do
        long_bio = "Jane has covered Niigata for a decade. " * 10
        author = create(:author, name: "Jane Reporter", role_title: "Senior reporter", bio: long_bio)
        get author_path(author)
        expect(response.body).to include('name="description"')
        expect(response.body).to include("Senior reporter")
      end
    end

    describe "Person JSON-LD" do
      it "emits a Person schema with name, URL, and worksFor" do
        author = create(:author, name: "Jane Reporter", role_title: "Senior reporter", bio: "Jane covers Niigata.")
        get author_path(author)
        expect(response.body).to include('"@type":"Person"')
        expect(response.body).to include('"name":"Jane Reporter"')
        expect(response.body).to include('"jobTitle":"Senior reporter"')
        expect(response.body).to include('"description":"Jane covers Niigata."')
        expect(response.body).to include('"worksFor":{"@type":"Organization","name":"Joetsu-Myoko Daily"}')
      end

      it "includes social profile URLs in sameAs" do
        author = create(:author,
                        twitter_url: "https://twitter.com/jane",
                        bluesky_url: "https://bsky.app/profile/jane",
                        website_url: "https://jane.example")
        get author_path(author)

        expect(response.body).to include('"sameAs"')
        expect(response.body).to include('"https://twitter.com/jane"')
        expect(response.body).to include('"https://bsky.app/profile/jane"')
        expect(response.body).to include('"https://jane.example"')
      end

      it "omits sameAs entirely when no social URLs are set" do
        author = create(:author, twitter_url: nil, bluesky_url: nil, website_url: nil)
        get author_path(author)
        expect(response.body).not_to include('"sameAs"')
      end

      it "drops non-http(s) social URLs from sameAs" do
        author = create(:author,
                        twitter_url: "javascript:alert(1)",
                        instagram_url: "ftp://example.com",
                        website_url: "https://jane.example")
        get author_path(author)

        expect(response.body).not_to include("javascript:alert")
        expect(response.body).not_to include("ftp://example.com")
        expect(response.body).to include('"https://jane.example"')
      end

      it "omits jobTitle and description from the schema when not set" do
        author = create(:author, role_title: nil, bio: nil)
        get author_path(author)

        # Pull out just the Person JSON-LD payload so the assertion isn't
        # tripped up by the meta description tag elsewhere on the page.
        person_payload = response.body[/"@type":"Person".*?\}\}/m]
        expect(person_payload).not_to include('"jobTitle"')
        expect(person_payload).not_to include('"description"')
      end
    end
  end
end
