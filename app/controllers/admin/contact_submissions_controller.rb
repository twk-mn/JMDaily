module Admin
  class ContactSubmissionsController < BaseController
    before_action :set_submission, only: [ :show, :destroy ]

    def index
      @pagy, @submissions = pagy(:offset, ContactSubmission.recent, limit: 25)
      @unread_count = ContactSubmission.unread.count
    end

    def show
      @submission.update!(read: true) unless @submission.read?
    end

    def destroy
      @submission.destroy
      redirect_to admin_contact_submissions_path, notice: "Message deleted."
    end

    private

    def set_submission
      @submission = ContactSubmission.find(params[:id])
    end
  end
end
