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

  # Throttle tip form submissions
  throttle("tip/submit", limit: 3, period: 60.seconds) do |req|
    if req.path == "/submit-a-tip" && req.post?
      req.ip
    end
  end

  # Throttle newsletter signups
  throttle("newsletter/subscribe", limit: 5, period: 60.seconds) do |req|
    if req.path == "/newsletter/subscribe" && req.post?
      req.ip
    end
  end

  # Throttle comment submissions
  throttle("comments/submit", limit: 3, period: 10.minutes) do |req|
    if req.path.end_with?("/comments") && req.post?
      req.ip
    end
  end

  # General request throttle
  throttle("req/ip", limit: 300, period: 5.minutes) do |req|
    req.ip unless req.path.start_with?("/assets")
  end
end
