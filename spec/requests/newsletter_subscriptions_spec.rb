require 'rails_helper'

RSpec.describe "NewsletterSubscriptions", type: :request do
  describe "POST /newsletter/subscribe" do
    it "creates a subscriber and redirects" do
      expect {
        post newsletter_subscribe_path, params: { email: "new@example.com" }
      }.to change(NewsletterSubscriber, :count).by(1)
      expect(response).to be_redirect
    end

    it "sends a confirmation email" do
      expect {
        post newsletter_subscribe_path, params: { email: "new@example.com" }
      }.to have_enqueued_mail(NewsletterMailer, :confirmation)
    end

    it "redirects with alert on duplicate email" do
      create(:newsletter_subscriber, email: "existing@example.com")
      post newsletter_subscribe_path, params: { email: "existing@example.com" }
      expect(response).to be_redirect
      follow_redirect!
      expect(response.body).to include("taken").or include("already")
    end

    it "strips whitespace and downcases email" do
      post newsletter_subscribe_path, params: { email: "  Reader@Example.COM  " }
      expect(NewsletterSubscriber.last.email).to eq("reader@example.com")
    end
  end

  describe "GET /newsletter/confirm" do
    let!(:subscriber) { create(:newsletter_subscriber) }

    it "confirms the subscriber with a valid token" do
      get confirm_newsletter_path(token: subscriber.confirmation_token)
      expect(subscriber.reload.confirmed_at).to be_present
    end

    it "redirects with notice on valid token" do
      get confirm_newsletter_path(token: subscriber.confirmation_token)
      expect(response).to redirect_to(locale_root_path)
    end

    it "redirects with alert on invalid token" do
      get confirm_newsletter_path(token: "badtoken")
      expect(response).to redirect_to(locale_root_path)
      follow_redirect!
      expect(response.body).to include("invalid").or include("already")
    end
  end

  describe "GET /newsletter/unsubscribe" do
    let!(:subscriber) { create(:newsletter_subscriber, :confirmed) }

    it "unsubscribes by email" do
      get newsletter_unsubscribe_path(email: subscriber.email)
      expect(subscriber.reload.unsubscribed_at).to be_present
    end

    it "redirects to root" do
      get newsletter_unsubscribe_path(email: subscriber.email)
      expect(response).to redirect_to(locale_root_path)
    end
  end
end
