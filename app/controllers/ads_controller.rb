class AdsController < ApplicationController
  def click
    ad = Ad.find(params[:id])

    if ad.ad_type == "direct" && ad.link_url.present?
      ad.increment!(:clicks_count)
      redirect_to ad.link_url, allow_other_host: true, status: :found
    else
      redirect_to root_path
    end
  end
end
