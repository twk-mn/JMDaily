module Admin
  class LocationsController < BaseController
    before_action :set_location, only: [:edit, :update, :destroy]

    def index
      @locations = Location.order(:name)
    end

    def new
      @location = Location.new
    end

    def create
      @location = Location.new(location_params)
      if @location.save
        redirect_to admin_locations_path, notice: "Location created."
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
    end

    def update
      if @location.update(location_params)
        redirect_to admin_locations_path, notice: "Location updated."
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @location.destroy
      redirect_to admin_locations_path, notice: "Location deleted."
    end

    private

    def set_location
      @location = Location.find(params[:id])
    end

    def location_params
      params.require(:location).permit(:name, :slug, :description)
    end
  end
end
