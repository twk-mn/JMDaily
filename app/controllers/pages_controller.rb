class PagesController < ApplicationController
  def show
    @page = StaticPage.find_by!(slug: params[:slug])
    @contact_submission = ContactSubmission.new if params[:slug] == "contact"
    @tip_submission = TipSubmission.new if params[:slug] == "submit-a-tip"
  end

  def submit_contact
    @contact_submission = ContactSubmission.new(contact_params)
    if @contact_submission.save
      ContactMailer.new_submission(@contact_submission).deliver_later
      redirect_to contact_path, notice: "Thank you for your message. We'll get back to you soon."
    else
      @page = StaticPage.find_by!(slug: "contact")
      render :show, status: :unprocessable_content
    end
  end

  def submit_tip
    @tip_submission = TipSubmission.new(tip_params)
    if @tip_submission.save
      TipMailer.new_tip(@tip_submission).deliver_later
      redirect_to submit_a_tip_path, notice: "Thank you — your tip has been received. We protect the confidentiality of our sources."
    else
      @page = StaticPage.find_by!(slug: "submit-a-tip")
      render :show, status: :unprocessable_content
    end
  end

  private

  def contact_params
    params.require(:contact_submission).permit(:name, :email, :subject, :message)
  end

  def tip_params
    params.require(:tip_submission).permit(:name, :email, :tip_body)
  end
end
