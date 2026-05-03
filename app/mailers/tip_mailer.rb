class TipMailer < ApplicationMailer
  def new_tip(tip)
    @tip = tip
    mail(
      to:      Setting.admin_email,
      subject: "[#{Setting.site_name}] New tip received"
    )
  end
end
