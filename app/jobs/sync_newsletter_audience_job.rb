class SyncNewsletterAudienceJob < ApplicationJob
  queue_as :default

  ACTIONS = %w[subscribe unsubscribe].freeze

  def perform(subscriber_id, action)
    return unless ACTIONS.include?(action.to_s)

    subscriber = NewsletterSubscriber.find_by(id: subscriber_id)
    return unless subscriber

    NewsletterAudience.public_send(action, subscriber)
  end
end
