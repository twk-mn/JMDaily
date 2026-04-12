require 'rails_helper'

RSpec.describe "Admin::Dashboard", type: :request do
  let!(:user) { create(:user) }

  before { login_as(user) }

  describe "GET /admin" do
    it "returns success" do
      get admin_root_path
      expect(response).to have_http_status(:success)
    end

    it "shows article counts" do
      create(:article, :published, author: create(:author), category: create(:category))
      create(:article, author: create(:author), category: create(:category))
      get admin_root_path
      expect(response.body).to include("Published")
      expect(response.body).to include("Drafts")
    end

    it "shows subscriber count" do
      create(:newsletter_subscriber, :confirmed)
      get admin_root_path
      expect(response.body).to include("Subscribers")
    end

    it "shows pending comments alert when comments need moderation" do
      article = create(:article, :published, author: create(:author), category: create(:category))
      create(:comment, article: article)
      get admin_root_path
      expect(response.body).to include("awaiting moderation")
    end
  end
end
