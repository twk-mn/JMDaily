require 'rails_helper'

RSpec.describe "Admin::Comments", type: :request do
  let!(:user) { create(:user) }
  let!(:article) { create(:article, :published, author: create(:author), category: create(:category)) }

  before { login_as(user) }

  describe "GET /admin/comments" do
    it "returns success" do
      get admin_comments_path
      expect(response).to have_http_status(:success)
    end

    it "lists comments" do
      create(:comment, article: article, name: "Test User")
      get admin_comments_path
      expect(response.body).to include("Test User")
    end

    it "filters by status" do
      create(:comment, article: article, name: "Pending User")
      create(:comment, :approved, article: article, name: "Approved User")
      get admin_comments_path, params: { status: "pending" }
      expect(response.body).to include("Pending User")
      expect(response.body).not_to include("Approved User")
    end
  end

  describe "POST /admin/comments/:id/approve" do
    let!(:comment) { create(:comment, article: article) }

    it "approves the comment" do
      post approve_admin_comment_path(comment)
      expect(comment.reload.status).to eq("approved")
    end

    it "redirects back" do
      post approve_admin_comment_path(comment)
      expect(response).to redirect_to(admin_comments_path)
    end
  end

  describe "POST /admin/comments/:id/reject" do
    let!(:comment) { create(:comment, article: article) }

    it "rejects the comment" do
      post reject_admin_comment_path(comment)
      expect(comment.reload.status).to eq("rejected")
    end
  end

  describe "DELETE /admin/comments/:id" do
    let!(:comment) { create(:comment, article: article) }

    it "deletes the comment" do
      expect {
        delete admin_comment_path(comment)
      }.to change(Comment, :count).by(-1)
    end

    it "redirects to comments index" do
      delete admin_comment_path(comment)
      expect(response).to redirect_to(admin_comments_path)
    end
  end
end
