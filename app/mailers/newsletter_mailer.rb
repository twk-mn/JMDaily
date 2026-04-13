class NewsletterMailer < ApplicationMailer
  def confirmation(subscriber)
    @subscriber = subscriber
    @confirm_url = confirm_newsletter_url(token: subscriber.confirmation_token, locale: :en)
    mail(
      to:      subscriber.email,
      subject: "Confirm your subscription to Joetsu-Myoko Daily"
    )
  end

  def broadcast(subscriber, issue)
    @subscriber = subscriber
    @issue      = issue
    locale      = issue.locale.presence || "en"
    @unsubscribe_url = newsletter_unsubscribe_url(token: subscriber.unsubscribe_token, locale: locale)
    @home_url        = locale_root_url(locale: locale)

    mail(
      to:      subscriber.email,
      subject: issue.subject
    )
  end
end
