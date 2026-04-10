module Admin
  class TipSubmissionsController < BaseController
    before_action :set_tip, only: [:show, :destroy]

    def index
      @tips = TipSubmission.recent
      @unread_count = TipSubmission.unread.count
    end

    def show
      @tip.update!(read: true) unless @tip.read?
    end

    def destroy
      @tip.destroy
      redirect_to admin_tip_submissions_path, notice: "Tip deleted."
    end

    private

    def set_tip
      @tip = TipSubmission.find(params[:id])
    end
  end
end
