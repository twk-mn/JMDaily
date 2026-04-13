class CommentsController < ApplicationController
  before_action :set_article

  def create
    # Honeypot — bots fill the hidden website field, humans don't
    if params[:website].present?
      redirect_to article_path(@article, anchor: "comments"),
        notice: "Your comment has been submitted and is awaiting moderation."
      return
    end

    @comment = @article.comments.new(comment_params)
    @comment.ip_address = request.remote_ip

    if @comment.save
      redirect_to article_path(@article, anchor: "comments"),
        notice: "Your comment has been submitted and is awaiting moderation."
    else
      redirect_to article_path(@article, anchor: "comment-form"),
        alert: @comment.errors.full_messages.first
    end
  end

  private

  def set_article
    @article = Article.published.find_by!(slug: params[:article_id])
  end

  def comment_params
    params.require(:comment).permit(:name, :email, :body)
  end
end
