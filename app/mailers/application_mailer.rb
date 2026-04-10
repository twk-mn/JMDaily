class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("FROM_EMAIL", "noreply@jmdaily.com")
  layout "mailer"
end
