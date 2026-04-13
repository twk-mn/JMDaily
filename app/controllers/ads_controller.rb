class AdsController < ApplicationController
  def click
    ad = Ad.find(params[:id])

    if ad.ad_type == "direct" && safe_ad_url?(ad.link_url)
      RecordAdClickJob.perform_later(ad.id)
      redirect_to ad.link_url, allow_other_host: true, status: :found
    else
      redirect_to root_path
    end
  end

  private

  def safe_ad_url?(url)
    url.present? && url.match?(/\Ahttps?:\/\//i)
  end
end
