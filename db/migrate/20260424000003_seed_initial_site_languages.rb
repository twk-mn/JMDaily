class SeedInitialSiteLanguages < ActiveRecord::Migration[8.0]
  # Seed the two locales that the site has shipped with so existing
  # ArticleTranslation / NewsletterIssue rows continue to validate after the
  # hardcoded LOCALES constants are replaced with a SiteLanguage lookup.
  # English is marked non-deletable — it is the required editorial language.
  def up
    return unless defined?(SiteLanguage)

    SiteLanguage.reset_column_information

    SiteLanguage.find_or_create_by!(code: "en") do |l|
      l.name        = "English"
      l.native_name = "English"
      l.flag_emoji  = "🇬🇧"
      l.position    = 0
      l.active      = true
      l.deletable   = false
    end

    SiteLanguage.find_or_create_by!(code: "ja") do |l|
      l.name        = "Japanese"
      l.native_name = "日本語"
      l.flag_emoji  = "🇯🇵"
      l.position    = 1
      l.active      = true
      l.deletable   = true
    end
  end

  def down
    return unless defined?(SiteLanguage)
    SiteLanguage.where(code: %w[en ja]).destroy_all
  end
end
