module Admin
  class TwoFactorController < BaseController
    def show
      # Generate a fresh secret if none exists yet (or 2FA is disabled)
      unless current_user.totp_secret.present?
        current_user.generate_totp_secret!
      end
      @qr_svg = generate_qr_svg(current_user.otpauth_uri)
    end

    def enable
      if current_user.enable_totp!(params[:otp_code])
        redirect_to admin_two_factor_path, notice: "Two-factor authentication enabled."
      else
        current_user.reload
        @qr_svg = generate_qr_svg(current_user.otpauth_uri)
        flash.now[:alert] = "Invalid code — please try again."
        render :show, status: :unprocessable_content
      end
    end

    def disable
      current_user.disable_totp!
      redirect_to admin_two_factor_path, notice: "Two-factor authentication disabled."
    end

    private

    def generate_qr_svg(uri)
      RQRCode::QRCode.new(uri).as_svg(
        offset: 0,
        color: "000",
        shape_rendering: "crispEdges",
        module_size: 5,
        standalone: true
      )
    end
  end
end
