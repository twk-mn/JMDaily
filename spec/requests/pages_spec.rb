require 'rails_helper'

RSpec.describe "Pages", type: :request do
  describe "GET /about" do
    it "returns success" do
      create(:static_page, title: "About", slug: "about")
      get about_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /contact" do
    it "returns success" do
      create(:static_page, title: "Contact", slug: "contact")
      get contact_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /privacy-policy" do
    it "returns success" do
      create(:static_page, title: "Privacy Policy", slug: "privacy-policy")
      get privacy_policy_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /terms" do
    it "returns success" do
      create(:static_page, title: "Terms", slug: "terms")
      get terms_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /submit-a-tip" do
    it "returns success" do
      create(:static_page, title: "Submit a Tip", slug: "submit-a-tip")
      get submit_a_tip_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /contact" do
    before { create(:static_page, title: "Contact", slug: "contact") }

    it "creates contact submission with valid data" do
      expect {
        post submit_contact_path, params: {
          contact_submission: {
            name: "John", email: "john@example.com", subject: "Test", message: "Hello"
          }
        }
      }.to change(ContactSubmission, :count).by(1)
      expect(response).to redirect_to(contact_path)
    end

    it "re-renders form with invalid data" do
      post submit_contact_path, params: {
        contact_submission: {
          name: "", email: "", subject: "", message: ""
        }
      }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "POST /submit-a-tip" do
    before { create(:static_page, title: "Submit a Tip", slug: "submit-a-tip") }

    it "creates tip submission with valid data" do
      expect {
        post submit_tip_path, params: {
          tip_submission: { tip_body: "Something newsworthy happened." }
        }
      }.to change(TipSubmission, :count).by(1)
      expect(response).to redirect_to(submit_a_tip_path)
    end

    it "enqueues tip notification email" do
      expect {
        post submit_tip_path, params: {
          tip_submission: { tip_body: "A tip." }
        }
      }.to have_enqueued_mail(TipMailer, :new_tip)
    end

    it "re-renders form when tip body is blank" do
      post submit_tip_path, params: { tip_submission: { tip_body: "" } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
