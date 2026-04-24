# Ensure the default SiteLanguage rows (en, ja) exist before every test.
#
# The rows are normally created by the SeedInitialSiteLanguages data migration,
# but `maintain_test_schema!` loads db/schema.rb (a structural dump) which drops
# and recreates tables without running data migrations, so the rows do not
# survive. Seeding before every test is cheap and keeps specs that rely on
# locale validation green.
RSpec.configure do |config|
  config.before(:each) do
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
end
