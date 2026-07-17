class ApplicationController < ActionController::Base
  before_action :set_locale
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

  def require_owner!
    return if current_user&.owner? || current_user&.admin?

    redirect_to root_path, alert: t("flash.auth.owner_required")
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
        :role,
        :preferred_locale
      )

      permitted[:role] = "renter" unless %w[renter owner].include?(permitted[:role])
      permitted
    end
  end

  def set_owner_pending_bookings_count
    @owner_pending_bookings_count = 0

    return unless user_signed_in?
    return unless current_user.owner? || current_user.admin?

    @owner_pending_bookings_count =
      if current_user.admin?
        Booking.where(status: "pending").count
      else
        current_user.owner_bookings.where(status: "pending").count
      end
  end
end
