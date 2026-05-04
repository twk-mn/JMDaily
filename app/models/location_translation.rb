class LocationTranslation < ApplicationRecord
  belongs_to :location

  # Locale codes are settings-driven via `SiteLanguage`, so the inclusion
  # check resolves at validation time rather than boot time — admins can
  # add a new language and start translating without a server restart.
  validates :locale, presence: true,
                     inclusion: { in: ->(_) { SiteLanguage.codes } },
                     uniqueness: { scope: :location_id, message: "translation already exists for this location" }
end
