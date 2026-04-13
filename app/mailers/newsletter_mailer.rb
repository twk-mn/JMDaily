class NewsletterMailer < ApplicationMailer
  def confirmation(subscriber)
    @subscriber = subscriber
    @confirm_url = confirm_newsletter_url(token: subscriber.confirmation_token)
    mail(
      to:      subscriber.email,
      subject: "Confirm your subscription to Joetsu-Myoko Daily"
    )
  end

  def broadcast(subscriber, issue)
    @subscriber = subscriber
    @issue = issue
    @unsubscribe_url = newsletter_unsubscribe_url(token: subscriber.unsubscribe_token)
    mail(
      to:      subscriber.email,
      subject: issue.subject
    )
  end
end
