class CategoriesController < ApplicationController
  include Pagy::Method

  def show
    @category = Category.find_by!(slug: params[:slug])
    @pagy, @articles = pagy(:offset,
      Article.published.where(category: @category).recent.includes(:translations),
      limit: 12
    )
  end
end
