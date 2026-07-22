module Users
  class RegistrationsController < Devise::RegistrationsController
    before_action :redirect_admin_to_admin_account, only: [:edit]
    before_action :prepare_oauth_signup, only: [:new, :create]

    def new
      super do |resource|
        apply_pending_oauth_to(resource)
      end
    end

    def create
      return super unless pending_oauth_signup?

      build_resource(oauth_sign_up_params)
      resource.oauth_signup = true
      resource.password = User.oauth_password
      resource.password_confirmation = resource.password

      resource.social_accounts.build(
        provider: pending_oauth_signup[:provider],
        uid: pending_oauth_signup[:uid],
        email: pending_oauth_signup[:email],
        name: pending_oauth_signup[:name],
        avatar_url: pending_oauth_signup[:avatar_url]
      )

      resource.save
      yield resource if block_given?

      if resource.persisted?
        session.delete(:pending_omniauth)
        set_flash_message! :notice, :signed_up
        sign_up(resource_name, resource)
        respond_with resource, location: after_sign_up_path_for(resource)
      else
        clean_up_passwords resource
        set_minimum_password_length
        respond_with resource
      end
    end

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

    def prepare_oauth_signup
      @oauth_signup = pending_oauth_signup?
    end

    def pending_oauth_signup
      session[:pending_omniauth]&.with_indifferent_access
    end

    def pending_oauth_signup?
      pending_oauth_signup.present?
    end

    def apply_pending_oauth_to(resource)
      return unless pending_oauth_signup?

      resource.email = pending_oauth_signup[:email].presence ||
        "#{pending_oauth_signup[:provider]}-#{pending_oauth_signup[:uid]}@oauth.wearly.local"
      resource.full_name = pending_oauth_signup[:name]
      resource.preferred_locale = I18n.locale.to_s
      resource.role ||= "renter"
      resource.oauth_signup = true
    end

    def oauth_sign_up_params
      permitted = sign_up_params.slice(:full_name, :phone, :role, :preferred_locale)
      permitted[:email] = pending_oauth_signup[:email].presence ||
        "#{pending_oauth_signup[:provider]}-#{pending_oauth_signup[:uid]}@oauth.wearly.local"
      permitted[:full_name] = permitted[:full_name].presence || pending_oauth_signup[:name]
      permitted[:preferred_locale] = permitted[:preferred_locale].presence || I18n.locale.to_s
      permitted[:role] = "renter" unless %w[renter owner].include?(permitted[:role])
      permitted
    end

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
