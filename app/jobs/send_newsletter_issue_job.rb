class SendNewsletterIssueJob < ApplicationJob
  queue_as :default

  def perform(issue_id)
    issue = NewsletterIssue.find(issue_id)
    return if issue.sent?

    subscribers = NewsletterSubscriber.active.to_a
    subscribers.each do |subscriber|
      NewsletterMailer.broadcast(subscriber, issue).deliver_now
    end

    issue.update!(status: "sent", sent_at: Time.current, recipients_count: subscribers.size)
  end
end
