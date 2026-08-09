# frozen_string_literal: true

module Api
  module V1
    class UsersController < BaseController
      def show
        user = User.active.find(params[:id])
        products = user.products.active.includes(photos_attachments: :blob).order(created_at: :desc).limit(12)

        shared_booking = nil
        if current_api_user_optional
          shared_booking = Booking
            .where(status: Booking::CHATTABLE_STATUSES)
            .where(
              "(renter_id = :me AND owner_id = :them) OR (renter_id = :them AND owner_id = :me)",
              me: current_api_user_optional.id,
              them: user.id
            )
            .order(created_at: :desc)
            .first
        end

        render json: {
          user: UserSerializer.new(user, request: request, public_profile: true).as_json,
          products: products.map { |product| ProductSerializer.new(product, request: request).as_json },
          shared_booking_id: shared_booking&.id,
          can_chat: shared_booking&.chattable? || false
        }
      end

      private

      def current_api_user_optional
        return @current_api_user if defined?(@current_api_user) && @current_api_user

        token = request.authorization.to_s.delete_prefix("Bearer ").presence
        @current_api_user = find_user_from_token(token)
        @current_api_user if @current_api_user&.active?
      end
    end
  end
end
