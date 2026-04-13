class NewsletterSubscriptionsController < ApplicationController
  def create
    @subscriber = NewsletterSubscriber.new(email: params[:email].to_s.strip.downcase)

    if @subscriber.save
      NewsletterMailer.confirmation(@subscriber).deliver_later
      redirect_back_or_to root_path,
        notice: "Thanks! Check your inbox for a confirmation email."
    else
      redirect_back_or_to root_path,
        alert: @subscriber.errors.full_messages.first
    end
  end

  def confirm
    subscriber = NewsletterSubscriber.find_by(confirmation_token: params[:token])

    if subscriber
      subscriber.confirm!
      redirect_to root_path,
        notice: "You're confirmed! You'll hear from us when we launch the newsletter."
    else
      redirect_to root_path,
        alert: "That confirmation link is invalid or has already been used."
    end
  end

  def unsubscribe
    subscriber = if params[:token].present?
      NewsletterSubscriber.find_by(unsubscribe_token: params[:token])
    else
      NewsletterSubscriber.find_by(email: params[:email].to_s.strip.downcase)
    end
    subscriber&.unsubscribe!
    redirect_to root_path, notice: "You have been unsubscribed."
  end
end
