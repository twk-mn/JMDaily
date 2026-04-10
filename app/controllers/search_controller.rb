class SearchController < ApplicationController
  include Pagy::Method

  def index
    if params[:q].present?
      query = Article.sanitize_sql_like(params[:q])
      @pagy, @articles = pagy(:offset,
        Article.published
          .where("title ILIKE :q OR dek ILIKE :q", q: "%#{query}%")
          .recent,
        limit: 12
      )
    else
      @articles = []
    end
  end
end
