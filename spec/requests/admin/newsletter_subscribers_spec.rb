require 'rails_helper'

RSpec.describe "Admin::NewsletterSubscribers", type: :request do
  let!(:admin) { create(:user, role: "admin") }
  before { login_as(admin) }

  describe "GET /admin/newsletter_subscribers" do
    it "returns success" do
      get admin_newsletter_subscribers_path
      expect(response).to have_http_status(:success)
    end

    it "lists subscriber emails" do
      create(:newsletter_subscriber, :confirmed, email: "reader@example.com")
      get admin_newsletter_subscribers_path
      expect(response.body).to include("reader@example.com")
    end

    it "redirects editors" do
      editor = create(:user, :editor)
      reset!
      login_as(editor)
      get admin_newsletter_subscribers_path
      expect(response).to redirect_to(admin_articles_path)
    end
  end

  describe "GET /admin/newsletter_subscribers.csv" do
    it "returns a CSV download" do
      create(:newsletter_subscriber, :confirmed)
      get admin_newsletter_subscribers_path(format: :csv)
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include("text/csv")
    end
  end

  describe "DELETE /admin/newsletter_subscribers/:id" do
    let!(:subscriber) { create(:newsletter_subscriber) }

    it "destroys the subscriber" do
      expect { delete admin_newsletter_subscriber_path(subscriber) }
        .to change(NewsletterSubscriber, :count).by(-1)
    end

    it "redirects to index" do
      delete admin_newsletter_subscriber_path(subscriber)
      expect(response).to redirect_to(admin_newsletter_subscribers_path)
    end
  end
end
