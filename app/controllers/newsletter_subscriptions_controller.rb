class NewsletterSubscriptionsController < ApplicationController
  def create
    email = params[:email].to_s.strip.downcase
    @subscriber = NewsletterSubscriber.new(email: email)
    frame_id = params[:frame_id].presence || "newsletter-signup-home"
    input_id = params[:input_id].presence || "home-newsletter-email"

    unless turnstile_passed?(:newsletter)
      return render_failure("Please complete the verification challenge.", frame_id, input_id)
    end

    if @subscriber.save
      NewsletterMailer.confirmation(@subscriber).deliver_later
      if turbo_frame_request?
        render partial: "newsletter_subscriptions/signup_success",
               locals: { frame_id: frame_id, email: email }
      else
        redirect_back_or_to locale_root_path,
          notice: "Thanks! Check your inbox for a confirmation email."
      end
    else
      message = @subscriber.errors.full_messages.first || "Something went wrong. Please try again."
      render_failure(message, frame_id, input_id)
    end
  end

  def confirm
    subscriber = NewsletterSubscriber.find_by(confirmation_token: params[:token])

    if subscriber
      subscriber.confirm!
      @state = :confirmed
      @subscriber = subscriber
    else
      @state = :invalid
    end
    render :confirm
  end

  def unsubscribe
    @subscriber = if params[:token].present?
      NewsletterSubscriber.find_by(unsubscribe_token: params[:token])
    else
      NewsletterSubscriber.find_by(email: params[:email].to_s.strip.downcase)
    end

    if @subscriber
      already_off = @subscriber.unsubscribed?
      @subscriber.unsubscribe! unless already_off
      @state = already_off ? :already_unsubscribed : :unsubscribed
    else
      @state = :invalid
    end
    render :unsubscribe
  end

  private

  def render_failure(message, frame_id, input_id)
    if turbo_frame_request?
      render partial: "newsletter_subscriptions/signup_error",
             locals: { frame_id: frame_id, input_id: input_id, message: message }
    else
      redirect_back_or_to locale_root_path, alert: message
    end
  end
end
