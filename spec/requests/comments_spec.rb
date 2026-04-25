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

    it "requires email on submission" do
      expect {
        post article_comments_path(article), params: {
          comment: { name: "Anonymous", body: "No email here" }
        }
      }.not_to change(Comment, :count)
    end

    it "rejects blank name" do
      expect {
        post article_comments_path(article), params: {
          comment: { name: "", email: "x@example.com", body: "Some comment" }
        }
      }.not_to change(Comment, :count)
    end

    it "rejects blank body" do
      expect {
        post article_comments_path(article), params: {
          comment: { name: "Jane", email: "x@example.com", body: "" }
        }
      }.not_to change(Comment, :count)
    end

    it "silently discards submissions with the honeypot field filled" do
      expect {
        post article_comments_path(article), params: valid_params.merge(website: "http://spam.com")
      }.not_to change(Comment, :count)
      expect(response).to redirect_to(article_path(article, anchor: "comments"))
    end

    it "returns 404 for unpublished articles" do
      draft = create(:article, author: author, category: category)
      post article_comments_path(draft), params: valid_params
      expect(response).to have_http_status(:not_found)
    end

    context "on validation failure" do
      it "redirects back to the comment form anchor" do
        post article_comments_path(article), params: { comment: { name: "", body: "", email: "" } }
        expect(response).to redirect_to(article_path(article, anchor: "comment-form"))
      end

      it "stashes form values and field errors in flash" do
        post article_comments_path(article), params: { comment: { name: "Jane", body: "", email: "bad" } }
        expect(flash[:comment_form]).to be_present
        expect(flash[:comment_form]["values"]).to include("name" => "Jane", "email" => "bad")
        expect(flash[:comment_form]["errors"].keys).to include("body")
      end
    end

    context "after successful submission" do
      it "stores the new comment id in the session for inline preview" do
        post article_comments_path(article), params: valid_params
        comment_id = Comment.last.id
        expect(session[:pending_comments][article.id.to_s]).to eq(comment_id)
      end
    end
  end

  describe "rendering on the article page" do
    it "shows an empty state when there are no comments" do
      get article_path(article)
      expect(response.body).to include("No comments yet")
    end

    it "shows the awaiting-moderation badge for the visitor's just-posted comment" do
      post article_comments_path(article), params: { comment: { name: "Sam", email: "s@example.com", body: "Pending body" } }
      follow_redirect!
      expect(response.body).to include("Awaiting moderation")
      expect(response.body).to include("Pending body")
    end

    it "shows the inline error summary after a failed submission" do
      post article_comments_path(article), params: { comment: { name: "", body: "", email: "" } }
      follow_redirect!
      expect(response.body).to include("There was a problem with your comment")
      expect(response.body).to include('aria-live="polite"')
    end

    it "preserves form values in the flash so the user doesn't retype them" do
      post article_comments_path(article), params: { comment: { name: "Jane", body: "", email: "x@example.com" } }
      follow_redirect!
      expect(response.body).to include('value="Jane"')
      expect(response.body).to include('value="x@example.com"')
    end

    it "renders comment bodies through simple_format so paragraph breaks survive" do
      comment = create(:comment, article: article, status: "approved", body: "Para one.\n\nPara two.")
      get article_path(article)
      expect(response.body).to include("<p>Para one.</p>")
      expect(response.body).to include("<p>Para two.</p>")
    end

    it "renders the body character counter target" do
      get article_path(article)
      expect(response.body).to include('data-controller="character-counter"')
      expect(response.body).to include('data-character-counter-target="count"')
    end
  end
end
