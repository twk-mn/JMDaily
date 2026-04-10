class SearchController < ApplicationController
  include Pagy::Method

  def index
    if params[:q].present?
      @pagy, @articles = pagy(:offset, Article.search(params[:q]), limit: 12)
    else
      @articles = []
    end
  end
end
