class NewsletterMailer < ApplicationMailer
  def confirmation(subscriber)
    @subscriber = subscriber
    @confirm_url = confirm_newsletter_url(token: subscriber.confirmation_token)
    mail(
      to:      subscriber.email,
      subject: "Confirm your subscription to Joetsu-Myoko Daily"
    )
  end
end
