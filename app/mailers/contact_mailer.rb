class ContactMailer < ApplicationMailer
  def new_submission(submission)
    @submission = submission
    mail(
      to:      ENV.fetch("EDITOR_EMAIL", "editor@jmdaily.com"),
      subject: "[JMDaily] New message: #{submission.subject.presence || "(no subject)"}",
      reply_to: "#{submission.name} <#{submission.email}>"
    )
  end
end
