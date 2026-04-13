module ApplicationHelper
  # Returns a sanitized http/https URL, or nil if the URL is blank or unsafe.
  # Used to prevent Brakeman warnings about rendering user-supplied URLs directly.
  def safe_external_url(url)
    return nil if url.blank?

    uri = URI.parse(url.to_s)
    uri.to_s if uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
  rescue URI::InvalidURIError
    nil
  end

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
