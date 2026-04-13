module Admin
  class SessionsController < ApplicationController
    layout "admin"

    def new
    end

    def create
      user = User.find_by(email: params[:email]&.downcase)
      if user&.authenticate(params[:password])
        if user.otp_enabled?
          # Store user id temporarily — not a full login until OTP is verified
          session[:pending_2fa_user_id] = user.id
          redirect_to admin_two_factor_verify_path
        else
          complete_login(user)
        end
      else
        flash.now[:alert] = "Invalid email or password."
        render :new, status: :unprocessable_content
      end
    end

    def verify_otp
    end

    def confirm_otp
      user = User.find_by(id: session[:pending_2fa_user_id])
      unless user&.otp_enabled?
        redirect_to admin_login_path, alert: "Session expired. Please log in again."
        return
      end

      if user.verify_otp(params[:otp_code])
        session.delete(:pending_2fa_user_id)
        complete_login(user)
      else
        flash.now[:alert] = "Invalid code. Please try again."
        render :verify_otp, status: :unprocessable_content
      end
    end

    def destroy
      reset_session
      redirect_to admin_login_path, notice: "Logged out."
    end

    private

    def complete_login(user)
      reset_session
      session[:user_id] = user.id
      session[:last_active_at] = Time.current.to_s
      redirect_to admin_articles_path, notice: "Logged in successfully."
    end
  end
end
