module Api
  module V1
    class BaseController < ActionController::API
      before_action :set_locale

      private

      attr_reader :current_api_user

      def authenticate_api_user!
        token = request.authorization.to_s.delete_prefix("Bearer ").presence
        @current_api_user = User.find_signed(token, purpose: :mobile_auth) if token.present?

        return if @current_api_user&.active?

        render json: { error: "Unauthorized" }, status: :unauthorized
      end

      def set_locale
        I18n.locale = params[:locale].presence_in(I18n.available_locales.map(&:to_s)) || I18n.default_locale
      end

      def mobile_auth_payload(user)
        {
          token: user.signed_id(purpose: :mobile_auth, expires_in: 30.days),
          user: UserSerializer.new(user, request: request).as_json
        }
      end
    end
  end
end
