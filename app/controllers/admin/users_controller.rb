module Admin
  class UsersController < ApplicationController
    layout "admin"

    before_action :authenticate_user!
    before_action :require_admin!
    before_action :set_user, only: [:show, :edit, :update]

    def index
      @users = User.order(created_at: :desc)
      @users = @users.where(role: params[:role]) if params[:role].present?
      @users = @users.where(status: params[:status]) if params[:status].present?

      if params[:q].present?
        keyword = "%#{params[:q].strip.downcase}%"
        @users = @users.where(
          "LOWER(email) LIKE :keyword OR LOWER(full_name) LIKE :keyword OR phone LIKE :keyword",
          keyword: keyword
        )
      end
    end

    def show; end

    def edit; end

    def update
      if @user.update(user_params)
        redirect_to admin_user_path(@user), notice: t("flash.admin.users.updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(
        :full_name,
        :phone,
        :email,
        :role,
        :status,
        :preferred_locale,
        :city,
        :district,
        :ward,
        :address
      )
    end
  end
end
