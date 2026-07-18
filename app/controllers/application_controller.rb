class ApplicationController < ActionController::Base
  before_action :set_locale
  before_action :ensure_active_user
  before_action :redirect_admin_from_public_area
  before_action :set_owner_pending_bookings_count
  before_action :configure_permitted_parameters, if: :devise_controller?

  private

  def set_locale
    I18n.locale = params[:locale].presence || current_user&.preferred_locale.presence || I18n.default_locale
  end

  def default_url_options
    { locale: I18n.locale }
  end

  def require_admin!
    return if current_user&.admin?

    redirect_to root_path, alert: t("flash.auth.admin_required")
  end

  def after_sign_in_path_for(resource)
    return edit_user_registration_path if resource.respond_to?(:phone) && resource.phone.blank? && !resource.admin?

    resource.admin? ? admin_root_path : super
  end

  def ensure_active_user
    return unless user_signed_in? && current_user.blocked?

    sign_out(current_user)
    redirect_to root_path, alert: t("flash.auth.account_blocked")
  end

  def require_owner!
    return if current_user&.owner?

    if current_user&.admin?
      redirect_to admin_root_path, alert: t("flash.auth.owner_area_unavailable")
      return
    end

    redirect_to root_path, alert: t("flash.auth.owner_required")
  end

  def redirect_admin_from_public_area
    return unless user_signed_in? && current_user.admin?
    return if controller_path.start_with?("admin/")
    return if devise_controller?

    redirect_to admin_root_path
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_in, keys: [:login])

    devise_parameter_sanitizer.permit(:sign_up) do |user_params|
      permitted = user_params.permit(
        :full_name,
        :phone,
        :email,
        :password,
        :password_confirmation,
        :role,
        :preferred_locale
      )

      permitted[:role] = "renter" unless %w[renter owner].include?(permitted[:role])
      permitted
    end

    devise_parameter_sanitizer.permit(:account_update) do |user_params|
      permitted = user_params.permit(
        :full_name,
        :phone,
        :email,
        :password,
        :password_confirmation,
        :current_password,
        :preferred_locale,
        :avatar,
        :address,
        :city,
        :district,
        :ward,
        :facebook_url,
        :instagram_url,
        :tiktok_url,
        :zalo_url,
        :website_url,
        :bank_name,
        :bank_account_name,
        :bank_account_number
      )
      permitted
    end
  end

  def set_owner_pending_bookings_count
    @owner_pending_bookings_count = 0

    return unless user_signed_in?
    return unless current_user.owner?

    @owner_pending_bookings_count =
      current_user.owner_bookings.where(status: "pending").count
  end
end
