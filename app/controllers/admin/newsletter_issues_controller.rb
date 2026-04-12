module Admin
  class NewsletterIssuesController < BaseController
    before_action :require_admin!
    before_action :set_issue, only: [ :show, :edit, :update, :destroy, :send_issue ]

    def index
      @pagy, @issues = pagy(:offset, NewsletterIssue.recent, limit: 20)
    end

    def new
      @issue = NewsletterIssue.new
    end

    def create
      @issue = NewsletterIssue.new(issue_params)
      if @issue.save
        redirect_to admin_newsletter_issues_path, notice: "Issue saved as draft."
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
    end

    def update
      if @issue.sent?
        redirect_to admin_newsletter_issues_path, alert: "Sent issues cannot be edited."
      elsif @issue.update(issue_params)
        redirect_to admin_newsletter_issues_path, notice: "Issue updated."
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      if @issue.sent?
        redirect_to admin_newsletter_issues_path, alert: "Sent issues cannot be deleted."
      else
        @issue.destroy
        redirect_to admin_newsletter_issues_path, notice: "Issue deleted."
      end
    end

    def send_issue
      if @issue.sent?
        redirect_to admin_newsletter_issues_path, alert: "This issue has already been sent."
      else
        SendNewsletterIssueJob.perform_later(@issue.id)
        redirect_to admin_newsletter_issues_path, notice: "Sending to #{NewsletterSubscriber.active.count} subscribers…"
      end
    end

    private

    def set_issue
      @issue = NewsletterIssue.find(params[:id])
    end

    def issue_params
      params.require(:newsletter_issue).permit(:subject, :body)
    end
  end
end
