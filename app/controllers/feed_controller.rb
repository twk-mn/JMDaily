class FeedController < ApplicationController
  def index
    requested = params[:locale].to_s
    @locale = SiteLanguage.active_codes.include?(requested) ? requested : "en"

    @articles = Article.published
      .recent
      .includes(:author, :category, :translations)
      .limit(25)

    respond_to do |format|
      format.rss { render layout: false }
    end
  end
end
