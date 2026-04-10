module ApplicationHelper
  def unread_messages_count
    @unread_messages_count ||= ContactSubmission.unread.count
  end

  def unread_tips_count
    @unread_tips_count ||= TipSubmission.unread.count
  end

  # Renders the highest-priority active ad for the given placement zone.
  # Returns nil (renders nothing) if no ad is currently running for that zone.
  def ad_for(zone)
    ad = Ad.pick_for_zone(zone)
    return unless ad

    ad.increment!(:impressions_count)
    render "shared/ad", ad: ad
  end
end
