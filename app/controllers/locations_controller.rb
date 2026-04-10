class LocationsController < ApplicationController
  include Pagy::Method

  def show
    @location = Location.find_by!(slug: params[:slug])
    @pagy, @articles = pagy(:offset,
      Article.published.by_location(@location).recent,
      limit: 12
    )
  end
end
