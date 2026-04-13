class RecordAdClickJob < ApplicationJob
  queue_as :default

  def perform(ad_id)
    Ad.where(id: ad_id).update_all("clicks_count = clicks_count + 1")
  end
end
