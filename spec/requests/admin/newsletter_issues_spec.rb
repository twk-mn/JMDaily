require 'rails_helper'

RSpec.describe "Admin::NewsletterIssues", type: :request do
  let!(:admin) { create(:user, :admin) }

  before { login_as(admin) }

  describe "GET /admin/newsletter_issues" do
    it "returns success" do
      get admin_newsletter_issues_path
      expect(response).to have_http_status(:success)
    end

    it "lists issues" do
      create(:newsletter_issue, subject: "April Edition")
      get admin_newsletter_issues_path
      expect(response.body).to include("April Edition")
    end
  end

  describe "GET /admin/newsletter_issues/new" do
    it "returns success" do
      get new_admin_newsletter_issue_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /admin/newsletter_issues" do
    it "creates a draft issue" do
      expect {
        post admin_newsletter_issues_path, params: {
          newsletter_issue: { subject: "Test Issue", body: "Hello readers" }
        }
      }.to change(NewsletterIssue, :count).by(1)
    end

    it "redirects to index on success" do
      post admin_newsletter_issues_path, params: {
        newsletter_issue: { subject: "Test Issue", body: "Hello readers" }
      }
      expect(response).to redirect_to(admin_newsletter_issues_path)
    end

    it "renders new on invalid params" do
      post admin_newsletter_issues_path, params: {
        newsletter_issue: { subject: "", body: "" }
      }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /admin/newsletter_issues/:id" do
    let!(:issue) { create(:newsletter_issue) }

    it "updates the issue" do
      patch admin_newsletter_issue_path(issue), params: {
        newsletter_issue: { subject: "Updated Subject", body: issue.body }
      }
      expect(issue.reload.subject).to eq("Updated Subject")
    end

    it "cannot update a sent issue" do
      sent = create(:newsletter_issue, :sent)
      patch admin_newsletter_issue_path(sent), params: {
        newsletter_issue: { subject: "New Subject", body: sent.body }
      }
      expect(response).to redirect_to(admin_newsletter_issues_path)
      expect(sent.reload.subject).not_to eq("New Subject")
    end
  end

  describe "DELETE /admin/newsletter_issues/:id" do
    let!(:issue) { create(:newsletter_issue) }

    it "deletes a draft" do
      expect {
        delete admin_newsletter_issue_path(issue)
      }.to change(NewsletterIssue, :count).by(-1)
    end

    it "cannot delete a sent issue" do
      sent = create(:newsletter_issue, :sent)
      expect {
        delete admin_newsletter_issue_path(sent)
      }.not_to change(NewsletterIssue, :count)
    end
  end

  describe "POST /admin/newsletter_issues/:id/send_issue" do
    let!(:issue) { create(:newsletter_issue) }

    it "enqueues the send job" do
      expect {
        post send_issue_admin_newsletter_issue_path(issue)
      }.to have_enqueued_job(SendNewsletterIssueJob).with(issue.id)
    end

    it "redirects with notice" do
      post send_issue_admin_newsletter_issue_path(issue)
      expect(response).to redirect_to(admin_newsletter_issues_path)
    end

    it "cannot send an already-sent issue" do
      sent = create(:newsletter_issue, :sent)
      expect {
        post send_issue_admin_newsletter_issue_path(sent)
      }.not_to have_enqueued_job(SendNewsletterIssueJob)
    end
  end
end
