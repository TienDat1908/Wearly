module Admin
  class AccountsController < ApplicationController
    layout "admin"

    before_action :authenticate_user!
    before_action :require_admin!

    def edit
      @admin = current_user
    end

    def update
      @admin = current_user

      if update_admin_account
        redirect_to edit_admin_account_path, notice: t("flash.admin.account.updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def update_admin_account
      if sensitive_update_requested?
        @admin.update_with_password(admin_account_params)
      else
        params_without_password = admin_account_params.except(:current_password)
        @admin.update_without_password(params_without_password)
      end
    end

    def sensitive_update_requested?
      admin_account_params[:password].present? ||
        admin_account_params[:password_confirmation].present? ||
        email_update_requested?
    end

    def email_update_requested?
      admin_account_params[:email].present? &&
        admin_account_params[:email].to_s.downcase.strip != @admin.email
    end

    def admin_account_params
      params.require(:user).permit(
        :full_name,
        :phone,
        :email,
        :preferred_locale,
        :avatar,
        :password,
        :password_confirmation,
        :current_password
      )
    end
  end
end
