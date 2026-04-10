module Admin
  class AdsController < BaseController
    before_action :require_admin!
    before_action :set_ad, only: [:edit, :update, :destroy]

    def index
      @ads = Ad.order(placement_zone: :asc, priority: :desc, created_at: :desc)
    end

    def new
      @ad = Ad.new(ad_type: "direct", status: "active", link_target: "_blank", priority: 0)
    end

    def create
      @ad = Ad.new(ad_params)
      if @ad.save
        redirect_to admin_ads_path, notice: "Ad created."
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
    end

    def update
      if @ad.update(ad_params)
        redirect_to admin_ads_path, notice: "Ad updated."
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @ad.destroy
      redirect_to admin_ads_path, notice: "Ad deleted."
    end

    private

    def set_ad
      @ad = Ad.find(params[:id])
    end

    def ad_params
      params.require(:ad).permit(
        :name, :ad_type, :placement_zone, :status,
        :link_url, :link_target, :sponsor_label,
        :script_code,
        :starts_at, :ends_at,
        :target_category_id, :target_location_id,
        :priority, :image
      )
    end
  end
end
