module Admin
  class SessionsController < ApplicationController
    layout "admin"

    def new
    end

    def create
      user = User.find_by(email: params[:email]&.downcase)
      if user&.authenticate(params[:password])
        reset_session
        session[:user_id] = user.id
        redirect_to admin_articles_path, notice: "Logged in successfully."
      else
        flash.now[:alert] = "Invalid email or password."
        render :new, status: :unprocessable_content
      end
    end

    def destroy
      reset_session
      redirect_to admin_login_path, notice: "Logged out."
    end
  end
end
