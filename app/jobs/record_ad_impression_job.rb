class RecordAdImpressionJob < ApplicationJob
  queue_as :default

  def perform(ad_id)
    Ad.where(id: ad_id).update_all("impressions_count = impressions_count + 1")
  end
end
