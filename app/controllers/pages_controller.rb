class PagesController < ApplicationController
  def show
    @page = StaticPage.find_by!(slug: params[:slug])
    @contact_submission = ContactSubmission.new if params[:slug] == "contact"
  end

  def submit_contact
    @contact_submission = ContactSubmission.new(contact_params)
    if @contact_submission.save
      redirect_to contact_path, notice: "Thank you for your message. We'll get back to you soon."
    else
      @page = StaticPage.find_by!(slug: "contact")
      render :show, status: :unprocessable_content
    end
  end

  private

  def contact_params
    params.require(:contact_submission).permit(:name, :email, :subject, :message)
  end
end
