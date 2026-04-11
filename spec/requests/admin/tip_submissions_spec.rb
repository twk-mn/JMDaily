require 'rails_helper'

RSpec.describe "Admin::TipSubmissions", type: :request do
  let!(:user) { create(:user) }
  before { login_as(user) }

  describe "GET /admin/tip_submissions" do
    it "returns success" do
      get admin_tip_submissions_path
      expect(response).to have_http_status(:success)
    end

    it "lists tip body previews" do
      create(:tip_submission, tip_body: "Something suspicious happened")
      get admin_tip_submissions_path
      expect(response.body).to include("Something suspicious happened")
    end
  end

  describe "GET /admin/tip_submissions/:id" do
    let!(:tip) { create(:tip_submission, read: false) }

    it "returns success" do
      get admin_tip_submission_path(tip)
      expect(response).to have_http_status(:success)
    end

    it "marks tip as read" do
      expect { get admin_tip_submission_path(tip) }
        .to change { tip.reload.read }.from(false).to(true)
    end
  end

  describe "DELETE /admin/tip_submissions/:id" do
    let!(:tip) { create(:tip_submission) }

    it "destroys the tip" do
      expect { delete admin_tip_submission_path(tip) }
        .to change(TipSubmission, :count).by(-1)
    end

    it "redirects to index" do
      delete admin_tip_submission_path(tip)
      expect(response).to redirect_to(admin_tip_submissions_path)
    end
  end

  describe "authentication" do
    it "redirects to login when not authenticated" do
      reset!
      get admin_tip_submissions_path
      expect(response).to redirect_to(admin_login_path)
    end
  end
end
