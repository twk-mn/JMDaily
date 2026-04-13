class TipMailer < ApplicationMailer
  def new_tip(tip)
    @tip = tip
    mail(
      to:      ENV.fetch("EDITOR_EMAIL", "editor@jmdaily.com"),
      subject: "[JMDaily] New tip received"
    )
  end
end
