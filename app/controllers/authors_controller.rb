class AuthorsController < ApplicationController
  include Pagy::Method

  def show
    @author = Author.find_by!(slug: params[:slug])
    @pagy, @articles = pagy(:offset,
      Article.published.where(author: @author).recent,
      limit: 12
    )
  end
end
