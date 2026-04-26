require 'rails_helper'

RSpec.describe "Sitewide breaking banner", type: :request do
  context "when there is a published breaking article" do
    let!(:breaking) { create(:article, :breaking, title: "Breaking News Story") }

    it "renders the banner on the homepage" do
      get locale_root_path
      expect(response.body).to include('aria-label="Breaking news"')
      expect(response.body).to include("Breaking News Story")
    end

    it "renders the banner on a category index page" do
      category = create(:category, name: "News", slug: "news")
      create(:article, :published, category: category, title: "Some other article")
      get news_path
      expect(response.body).to include('aria-label="Breaking news"')
      expect(response.body).to include("Breaking News Story")
    end

    it "renders the banner on the about page" do
      create(:static_page, title: "About", slug: "about")
      get about_path
      expect(response.body).to include('aria-label="Breaking news"')
    end

    it "exposes a fingerprint and a dismiss button so the banner can be hidden" do
      get locale_root_path
      expect(response.body).to include('data-controller="breaking-banner"')
      expect(response.body).to include('data-breaking-banner-fingerprint-value="')
      expect(response.body).to include('data-action="click->breaking-banner#dismiss"')
      expect(response.body).to include('aria-label="Dismiss breaking news banner"')
    end
  end

  it "does not render the banner when there are no breaking articles" do
    create(:article, :published, title: "Regular article")
    get locale_root_path
    expect(response.body).not_to include('aria-label="Breaking news"')
  end

  it "does not render breaking articles that are still drafts" do
    create(:article, status: "draft", breaking: true, title: "Draft breaking story")
    get locale_root_path
    expect(response.body).not_to include('aria-label="Breaking news"')
    expect(response.body).not_to include("Draft breaking story")
  end
end
