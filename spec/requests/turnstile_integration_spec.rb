require 'rails_helper'

# End-to-end coverage for the Turnstile guard on the four protected forms.
# Verification is faked via Turnstile.test_verification_result so the specs
# don't need a Cloudflare network call.
RSpec.describe "Turnstile integration", type: :request do
  before do
    Setting.set("turnstile_site_key", "site")
    Setting.set("turnstile_secret_key", "secret")
  end

  after { Turnstile.test_verification_result = nil }

  describe "comments form" do
    let(:author)   { create(:author) }
    let(:category) { create(:category) }
    let(:article)  { create(:article, :published, author: author, category: category) }
    let(:params)   { { comment: { name: "J", email: "j@example.com", body: "Nice." } } }

    it "blocks creation when the toggle is on and verification fails" do
      Setting.set("turnstile_on_comments", true)
      Turnstile.test_verification_result = false

      expect { post article_comments_path(article), params: params }
        .not_to change(Comment, :count)
    end

    it "creates the comment when verification passes" do
      Setting.set("turnstile_on_comments", true)
      Turnstile.test_verification_result = true

      expect { post article_comments_path(article), params: params }
        .to change(Comment, :count).by(1)
    end

    it "is not enforced when the toggle is off (no verification needed)" do
      Setting.set("turnstile_on_comments", false)

      expect { post article_comments_path(article), params: params }
        .to change(Comment, :count).by(1)
    end
  end

  describe "contact form" do
    before { create(:static_page, title: "Contact", slug: "contact") }
    let(:params) { { contact_submission: { name: "X", email: "x@e.com", subject: "S", message: "M" } } }

    it "blocks creation when verification fails" do
      Setting.set("turnstile_on_contact", true)
      Turnstile.test_verification_result = false

      expect { post submit_contact_path, params: params }
        .not_to change(ContactSubmission, :count)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "creates the submission when verification passes" do
      Setting.set("turnstile_on_contact", true)
      Turnstile.test_verification_result = true

      expect { post submit_contact_path, params: params }
        .to change(ContactSubmission, :count).by(1)
    end
  end

  describe "tip form" do
    before { create(:static_page, title: "Submit a Tip", slug: "submit-a-tip") }
    let(:params) { { tip_submission: { tip_body: "A real tip." } } }

    it "blocks creation when verification fails" do
      Setting.set("turnstile_on_tips", true)
      Turnstile.test_verification_result = false

      expect { post submit_tip_path, params: params }
        .not_to change(TipSubmission, :count)
    end

    it "creates the tip when verification passes" do
      Setting.set("turnstile_on_tips", true)
      Turnstile.test_verification_result = true

      expect { post submit_tip_path, params: params }
        .to change(TipSubmission, :count).by(1)
    end
  end

  describe "newsletter signup" do
    let(:params) { { email: "new@example.com" } }

    it "blocks signup when verification fails" do
      Setting.set("turnstile_on_newsletter", true)
      Turnstile.test_verification_result = false

      expect { post newsletter_subscribe_path, params: params }
        .not_to change(NewsletterSubscriber, :count)
    end

    it "creates the subscriber when verification passes" do
      Setting.set("turnstile_on_newsletter", true)
      Turnstile.test_verification_result = true

      expect { post newsletter_subscribe_path, params: params }
        .to change(NewsletterSubscriber, :count).by(1)
    end
  end

  describe "widget partial" do
    it "renders a widget div when the form is enabled" do
      Setting.set("turnstile_on_contact", true)
      create(:static_page, title: "Contact", slug: "contact")

      get contact_path
      expect(response.body).to include("cf-turnstile")
      expect(response.body).to include('data-sitekey="site"')
    end

    it "renders nothing when the form is disabled" do
      Setting.set("turnstile_on_contact", false)
      create(:static_page, title: "Contact", slug: "contact")

      get contact_path
      expect(response.body).not_to include("cf-turnstile")
    end
  end
end
