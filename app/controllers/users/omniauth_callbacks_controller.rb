module Users
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    User.omniauth_providers.each do |provider|
      define_method(provider) do
        handle_oauth_callback(provider)
      end
    end

    def failure
      redirect_to new_user_session_path, alert: t("flash.auth.social_login_failed")
    end

    private

    def handle_oauth_callback(provider)
      I18n.locale = oauth_locale
      auth = request.env["omniauth.auth"]
      @user = User.from_omniauth(auth)

      if @user.persisted?
        flash[:notice] = t("flash.auth.social_login_success", provider: provider_label(provider))
        sign_in_and_redirect @user, event: :authentication
      else
        redirect_to new_user_session_path, alert: t("flash.auth.social_login_failed")
      end
    rescue ActiveRecord::RecordInvalid
      redirect_to new_user_session_path, alert: t("flash.auth.social_login_failed")
    end

    def provider_label(provider)
      t("auth.oauth.providers.#{provider}", default: provider.to_s.humanize)
    end

    def oauth_locale
      locale = request.env.dig("omniauth.params", "locale").presence || I18n.default_locale.to_s
      I18n.available_locales.map(&:to_s).include?(locale) ? locale : I18n.default_locale
    end
  end
end
