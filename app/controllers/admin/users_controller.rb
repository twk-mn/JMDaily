module Admin
  class UsersController < BaseController
    before_action :require_admin!
    before_action :set_user, only: [:edit, :update, :destroy]

    def index
      @users = User.order(:name)
    end

    def new
      @user = User.new(role: "editor")
    end

    def create
      @user = User.new(user_create_params)
      if @user.save
        redirect_to admin_users_path, notice: "User created."
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
    end

    def update
      if @user.update(user_update_params)
        redirect_to admin_users_path, notice: "User updated."
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      if @user == current_user
        redirect_to admin_users_path, alert: "You cannot delete your own account."
        return
      end

      @user.destroy
      redirect_to admin_users_path, notice: "User deleted."
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_create_params
      params.require(:user).permit(:name, :email, :role, :password, :password_confirmation)
    end

    def user_update_params
      permitted = params.require(:user).permit(:name, :email, :role, :password, :password_confirmation)

      # Don't update password if left blank on edit
      if permitted[:password].blank?
        permitted.delete(:password)
        permitted.delete(:password_confirmation)
      end

      # Prevent changing your own role
      permitted.delete(:role) if @user == current_user

      permitted
    end
  end
end
