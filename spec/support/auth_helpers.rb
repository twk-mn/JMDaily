module AuthHelpers
  def login_as(user)
    post admin_login_path, params: { email: user.email, password: "Password123secure" }
  end
end

RSpec.configure do |config|
  config.include AuthHelpers, type: :request
end
