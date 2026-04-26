# Central place for site-wide constants that aren't secrets but aren't
# worth putting in the database. Change these if the homepage sidebar
# locations or other structural site config ever needs updating.
module SiteConfig
  # Slugs of the two locations shown in the homepage sidebar.
  HOMEPAGE_LOCATION_SLUGS = %w[joetsu myoko].freeze

  # Ordered list of homepage section partials. Each entry maps to
  # app/views/home/sections/_<key>.html.erb. Reorder, add, or remove
  # entries to change the homepage without touching the template.
  HOMEPAGE_SECTIONS = %i[hero ad_mid local_news locations newsletter].freeze

  # Admin session expires after this period of inactivity.
  ADMIN_SESSION_TIMEOUT = 2.hours
end
