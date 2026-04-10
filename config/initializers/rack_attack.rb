class Rack::Attack
  # Throttle login attempts
  throttle("admin/login", limit: 5, period: 60.seconds) do |req|
    if req.path == "/admin/login" && req.post?
      req.ip
    end
  end

  # Throttle contact form submissions
  throttle("contact/submit", limit: 3, period: 60.seconds) do |req|
    if req.path == "/contact" && req.post?
      req.ip
    end
  end

  # General request throttle
  throttle("req/ip", limit: 300, period: 5.minutes) do |req|
    req.ip unless req.path.start_with?("/assets")
  end
end
