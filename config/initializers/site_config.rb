# Central place for site-wide constants that aren't secrets but aren't
# worth putting in the database. Change these if the homepage sidebar
# locations or other structural site config ever needs updating.
module SiteConfig
  # Slugs of the two locations shown in the homepage sidebar.
  HOMEPAGE_LOCATION_SLUGS = %w[joetsu myoko].freeze

  # Admin session expires after this period of inactivity.
  ADMIN_SESSION_TIMEOUT = 2.hours
end
