class CommentsController < ApplicationController
  before_action :set_article

  def create
    # Honeypot — bots fill the hidden website field, humans don't.
    if params[:website].present?
      redirect_to article_path(@article, anchor: "comments"),
        notice: "Your comment has been submitted and is awaiting moderation."
      return
    end

    @comment = @article.comments.new(comment_params)
    @comment.ip_address = request.remote_ip

    if @comment.save
      stash_pending_comment(@comment)
      redirect_to article_path(@article, anchor: "comments"),
        notice: "Your comment has been submitted and is awaiting moderation."
    else
      flash[:comment_form] = {
        "values" => comment_params.to_h,
        "errors" => @comment.errors.to_hash(true).transform_keys(&:to_s)
      }
      redirect_to article_path(@article, anchor: "comment-form")
    end
  end

  private

  def set_article
    @article = Article.published.find_by!(slug: params[:article_id])
  end

  def comment_params
    params.require(:comment).permit(:name, :email, :body)
  end

  def stash_pending_comment(comment)
    session[:pending_comments] ||= {}
    session[:pending_comments][@article.id.to_s] = comment.id
  end
end
