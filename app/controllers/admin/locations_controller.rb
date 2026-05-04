module Admin
  class LocationsController < BaseController
    before_action :require_admin!
    before_action :set_location, only: [ :edit, :update, :destroy ]

    def index
      @pagy, @locations = pagy(:offset, Location.order(:name), limit: 50)
    end

    def new
      @location = Location.new
      build_translation_inputs
    end

    def create
      @location = Location.new(location_params)
      if @location.save
        redirect_to admin_locations_path, notice: "Location created."
      else
        build_translation_inputs
        render :new, status: :unprocessable_content
      end
    end

    def edit
      build_translation_inputs
    end

    def update
      if @location.update(location_params)
        redirect_to admin_locations_path, notice: "Location updated."
      else
        build_translation_inputs
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @location.destroy
      redirect_to admin_locations_path, notice: "Location deleted."
    end

    private

    def set_location
      @location = find_resource(Location)
    end

    def location_params
      params.require(:location).permit(
        :name, :slug, :description,
        translations_attributes: [ :id, :locale, :name, :description, :_destroy ]
      )
    end

    # Pre-build a translation row for every active non-English locale so the
    # form can render an input section per language without the editor
    # having to "add" each one. Existing translations are reused; new ones
    # are in-memory only and get rejected on save when left blank (see
    # Translatable#translation_attrs_blank?).
    def build_translation_inputs
      (SiteLanguage.active_codes - [ "en" ]).each do |locale|
        @location.translations.find_or_initialize_by(locale: locale)
      end
    end
  end
end
