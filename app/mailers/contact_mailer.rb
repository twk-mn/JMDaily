class ContactMailer < ApplicationMailer
  def new_submission(submission)
    @submission = submission
    mail(
      to:      Setting.admin_email,
      subject: "[#{Setting.site_name}] New message: #{submission.subject.presence || "(no subject)"}",
      reply_to: "#{submission.name} <#{submission.email}>"
    )
  end
end
