module Api
  module V1
    class AuthController < BaseController
      before_action :authenticate_api_user!, only: [:me, :profile]

      def sign_in
        user = User.find_for_database_authentication(login: auth_params[:login].to_s)

        unless user&.valid_password?(auth_params[:password].to_s)
          render json: { error: "Invalid email, phone, or password." }, status: :unauthorized
          return
        end

        unless user.active?
          render json: { error: "This account is blocked." }, status: :forbidden
          return
        end

        render json: mobile_auth_payload(user), status: :ok
      end

      def sign_up
        user = User.new(sign_up_params)
        user.role = "renter" unless %w[renter owner].include?(user.role)

        if user.save
          render json: mobile_auth_payload(user), status: :created
        else
          render json: {
            error: user.errors.full_messages.to_sentence,
            errors: user.errors.to_hash(true)
          }, status: :unprocessable_entity
        end
      end

      def me
        render json: { user: UserSerializer.new(current_api_user, request: request).as_json }
      end

      def profile
        attrs = profile_params

        if current_api_user.update(attrs)
          render json: { user: UserSerializer.new(current_api_user, request: request).as_json }, status: :ok
        else
          render json: {
            error: current_api_user.errors.full_messages.to_sentence,
            errors: current_api_user.errors.to_hash(true)
          }, status: :unprocessable_entity
        end
      end

      private

      def auth_params
        params.require(:user).permit(:login, :password)
      end

      def sign_up_params
        params.require(:user).permit(
          :full_name,
          :phone,
          :email,
          :password,
          :role,
          :preferred_locale
        )
      end

      def profile_params
        params.require(:user).permit(
          :full_name,
          :phone,
          :address,
          :city,
          :district,
          :ward,
          :preferred_locale,
          :facebook_url,
          :instagram_url,
          :tiktok_url,
          :zalo_url,
          :website_url,
          :avatar
        )
      end
    end
  end
end
