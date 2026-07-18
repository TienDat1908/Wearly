module Users
  class RegistrationsController < Devise::RegistrationsController
    before_action :redirect_admin_to_admin_account, only: [:edit]

    protected

    def update_resource(resource, params)
      if sensitive_update_requested?(resource, params)
        resource.update_with_password(params)
      else
        params.delete(:current_password)
        resource.update_without_password(params)
      end
    end

    def after_update_path_for(_resource)
      edit_user_registration_path
    end

    private

    def redirect_admin_to_admin_account
      return unless current_user&.admin?

      redirect_to edit_admin_account_path
    end

    def sensitive_update_requested?(resource, params)
      params[:password].present? ||
        params[:password_confirmation].present? ||
        email_update_requested?(resource, params)
    end

    def email_update_requested?(resource, params)
      params[:email].present? && params[:email].to_s.downcase.strip != resource.email
    end
  end
end
