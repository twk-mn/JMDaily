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

    context "when posted from inside a turbo-frame" do
      let(:headers) { { "Turbo-Frame" => "newsletter-signup-home" } }

      it "renders the success partial inline instead of redirecting" do
        post newsletter_subscribe_path,
             params: { email: "frame@example.com", frame_id: "newsletter-signup-home", input_id: "home-newsletter-email" },
             headers: headers
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Almost there")
        expect(response.body).to include("frame@example.com")
        expect(response.body).to include('id="newsletter-signup-home"')
      end

      it "renders the error partial with a retry form when the email is invalid" do
        post newsletter_subscribe_path,
             params: { email: "not-an-email", frame_id: "newsletter-signup-home", input_id: "home-newsletter-email" },
             headers: headers
        expect(response).to have_http_status(:success)
        expect(response.body).to include('role="alert"')
        # The form is re-rendered so the user can correct and retry.
        expect(response.body).to include('id="home-newsletter-email"')
      end
    end
  end

  describe "GET /newsletter/confirm" do
    let!(:subscriber) { create(:newsletter_subscriber) }

    it "confirms the subscriber with a valid token" do
      get confirm_newsletter_path(token: subscriber.confirmation_token)
      expect(subscriber.reload.confirmed_at).to be_present
    end

    it "renders a success page on valid token" do
      get confirm_newsletter_path(token: subscriber.confirmation_token)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("You're subscribed")
      expect(response.body).to include(subscriber.email)
    end

    it "renders an expired-link page on invalid token" do
      get confirm_newsletter_path(token: "badtoken")
      expect(response).to have_http_status(:success)
      expect(response.body).to include("expired")
      # Offers a fresh signup form so the visitor can recover.
      expect(response.body).to include("confirm-newsletter-email")
    end
  end

  describe "GET /newsletter/unsubscribe" do
    let!(:subscriber) { create(:newsletter_subscriber, :confirmed) }

    it "unsubscribes by email" do
      get newsletter_unsubscribe_path(email: subscriber.email)
      expect(subscriber.reload.unsubscribed_at).to be_present
    end

    it "renders the unsubscribed page with a resubscribe form" do
      get newsletter_unsubscribe_path(email: subscriber.email)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("You're unsubscribed")
      expect(response.body).to include("resubscribe-newsletter-email")
    end

    it "shows an already-unsubscribed page when the visitor unsubscribes twice" do
      subscriber.unsubscribe!
      get newsletter_unsubscribe_path(email: subscriber.email)
      expect(response.body).to include("Already unsubscribed")
    end

    it "shows a friendly invalid-link page when the email is unknown" do
      get newsletter_unsubscribe_path(email: "ghost@example.com")
      expect(response.body).to include("couldn't find that subscription")
    end
  end
end
