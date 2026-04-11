require 'rails_helper'

RSpec.describe "Admin::ContactSubmissions", type: :request do
  let!(:user) { create(:user) }
  before { login_as(user) }

  describe "GET /admin/contact_submissions" do
    it "returns success" do
      get admin_contact_submissions_path
      expect(response).to have_http_status(:success)
    end

    it "lists submissions" do
      create(:contact_submission, name: "Jane Doe")
      get admin_contact_submissions_path
      expect(response.body).to include("Jane Doe")
    end
  end

  describe "GET /admin/contact_submissions/:id" do
    let!(:submission) { create(:contact_submission, read: false) }

    it "returns success" do
      get admin_contact_submission_path(submission)
      expect(response).to have_http_status(:success)
    end

    it "marks submission as read" do
      expect { get admin_contact_submission_path(submission) }
        .to change { submission.reload.read }.from(false).to(true)
    end
  end

  describe "DELETE /admin/contact_submissions/:id" do
    let!(:submission) { create(:contact_submission) }

    it "destroys the submission" do
      expect { delete admin_contact_submission_path(submission) }
        .to change(ContactSubmission, :count).by(-1)
    end

    it "redirects to index" do
      delete admin_contact_submission_path(submission)
      expect(response).to redirect_to(admin_contact_submissions_path)
    end
  end

  describe "authentication" do
    it "redirects to login when not authenticated" do
      reset!
      get admin_contact_submissions_path
      expect(response).to redirect_to(admin_login_path)
    end
  end
end
