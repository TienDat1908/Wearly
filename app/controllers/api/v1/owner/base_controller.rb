# frozen_string_literal: true

module Api
  module V1
    module Owner
      class BaseController < Api::V1::BaseController
        before_action :authenticate_api_user!
        before_action :require_owner!

        private

        def require_owner!
          return if current_api_user.owner?

          render json: { error: "Owner account required." }, status: :forbidden
        end
      end
    end
  end
end
