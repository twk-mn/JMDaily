module Admin
  class CommentsController < BaseController
    before_action :set_comment, only: [ :approve, :reject, :destroy ]

    def index
      scope = Comment.includes(:article).order(created_at: :desc)
      scope = scope.where(status: params[:status]) if params[:status].present?
      @pagy, @comments = pagy(:offset, scope, limit: 25)
    end

    def approve
      @comment.approve!
      redirect_back_or_to admin_comments_path, notice: "Comment approved."
    end

    def reject
      @comment.reject!
      redirect_back_or_to admin_comments_path, notice: "Comment rejected."
    end

    def destroy
      @comment.destroy
      redirect_back_or_to admin_comments_path, notice: "Comment deleted."
    end

    private

    def set_comment
      @comment = Comment.find(params[:id])
    end
  end
end
