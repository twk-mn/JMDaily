class TagsController < ApplicationController
  include Pagy::Method

  def show
    @tag = Tag.find_by!(slug: params[:slug])
    @pagy, @articles = pagy(:offset,
      @tag.articles.published.recent,
      limit: 12
    )
  end
end
