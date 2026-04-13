class FeedController < ApplicationController
  def index
    @articles = Article.published.recent.limit(25)
    respond_to do |format|
      format.rss { render layout: false }
    end
  end
end
