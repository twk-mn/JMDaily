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

  def pending_comments_count
    @pending_comments_count ||= Comment.pending.count
  end

  def unread_inbox_count
    unread_messages_count + pending_comments_count + unread_tips_count
  end

  # Renders the highest-priority active ad for the given placement zone.
  # Impression is recorded asynchronously and deduplicated per-session per ad
  # so repeated page loads by the same visitor don't inflate counts.
  def ad_for(zone)
    ad = Ad.pick_for_zone(zone, locale: I18n.locale)
    return unless ad

    seen_key = "ad_seen_#{ad.id}"
    unless session[seen_key]
      session[seen_key] = true
      RecordAdImpressionJob.perform_later(ad.id)
    end

    render "shared/ad", ad: ad
  end

  # Currently-active breaking news (memoized per request) so the sitewide
  # breaking banner and any in-page breaking section share the same query.
  def current_breaking_articles
    @current_breaking_articles ||= Article.published.breaking.recent.includes(:translations).limit(3).to_a
  end

  # Locale-aware label for a location slug shown in the header navigation.
  # Falls back to the slug-titleized hardcoded label when the row or its
  # localization is missing, so deleting a Location row doesn't break the
  # masthead. Memoized per request so all three header location links plus
  # the mobile-menu repeats share a single query.
  def header_location_label(slug, fallback)
    @_header_location_lookup ||= Location.where(slug: %w[joetsu myoko itoigawa])
                                         .includes(:translations).index_by(&:slug)
    @_header_location_lookup[slug.to_s]&.localized_name || fallback
  end

  # A stable fingerprint of the current breaking lineup. The dismiss button
  # writes this to sessionStorage; if a *new* breaking article appears later,
  # the fingerprint changes and the banner returns even for visitors who
  # previously dismissed it.
  def breaking_articles_fingerprint
    current_breaking_articles.map(&:id).sort.join(",")
  end

  # Active site languages for the header switcher. The switcher always points at
  # locale_root so switching never 404s on a slug that doesn't exist in the new
  # language (article/tag/author pages that can resolve the *same* record in a
  # different locale render their own in-page language links).
  def language_switcher_options
    SiteLanguage.active.map do |lang|
      {
        code: lang.code,
        short_label: lang.code.upcase,
        display_name: lang.display_name,
        url: locale_root_path(locale: lang.code),
        current: I18n.locale.to_s == lang.code
      }
    end
  end

  # Named strftime patterns for the public-facing <time> tags. Centralised
  # so we don't drift between, say, "%B %-d, %Y" on a card and "%b %-d, %Y"
  # on a sibling card — every public surface picks from the same four shapes.
  ARTICLE_TIME_FORMATS = {
    long:     "%B %-d, %Y",                  # April 28, 2026
    short:    "%b %-d, %Y",                  # Apr 28, 2026
    compact:  "%b %-d",                      # Apr 28  (no year)
    datetime: "%B %-d, %Y at %-I:%M %p"      # April 28, 2026 at 1:30 PM
  }.freeze

  # Renders <time datetime="<iso8601>">[prefix ]<formatted>...</time>.
  # Returns nil for nil time so callers can drop the wrapper without an extra
  # `if`. Extra HTML options (e.g. class:) flow through to the <time> tag.
  def article_time_tag(time, format: :short, prefix: nil, **html_options)
    return nil unless time
    text = time.strftime(ARTICLE_TIME_FORMATS.fetch(format))
    text = "#{prefix} #{text}" if prefix.present?
    time_tag(time, text, **html_options)
  end
end
