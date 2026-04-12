require 'rails_helper'

RSpec.describe "Comments", type: :request do
  let!(:author) { create(:author) }
  let!(:category) { create(:category) }
  let!(:article) { create(:article, :published, author: author, category: category) }

  describe "POST /articles/:article_id/comments" do
    let(:valid_params) do
      { comment: { name: "Jane Reader", email: "jane@example.com", body: "Great article!" } }
    end

    it "creates a pending comment" do
      expect {
        post article_comments_path(article), params: valid_params
      }.to change(Comment, :count).by(1)

      expect(Comment.last.status).to eq("pending")
    end

    it "redirects to article with notice" do
      post article_comments_path(article), params: valid_params
      expect(response).to redirect_to(article_path(article, anchor: "comments"))
    end

    it "does not require email" do
      expect {
        post article_comments_path(article), params: {
          comment: { name: "Anonymous", body: "No email here" }
        }
      }.to change(Comment, :count).by(1)
    end

    it "rejects blank name" do
      expect {
        post article_comments_path(article), params: {
          comment: { name: "", body: "Some comment" }
        }
      }.not_to change(Comment, :count)
    end

    it "rejects blank body" do
      expect {
        post article_comments_path(article), params: {
          comment: { name: "Jane", body: "" }
        }
      }.not_to change(Comment, :count)
    end

    it "returns 404 for unpublished articles" do
      draft = create(:article, author: author, category: category)
      post article_comments_path(draft), params: valid_params
      expect(response).to have_http_status(:not_found)
    end
  end
end
