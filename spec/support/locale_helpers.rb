RSpec.configure do |config|
  # Public routes now require a /:locale segment. Inject :en as the default
  # so request specs don't need to specify locale in every path call.
  config.before(type: :request) do
    Rails.application.routes.default_url_options[:locale] = :en
  end

  config.after(type: :request) do
    Rails.application.routes.default_url_options.delete(:locale)
  end
end
