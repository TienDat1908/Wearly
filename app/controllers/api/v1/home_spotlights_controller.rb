module Api
  module V1
    class HomeSpotlightsController < BaseController
      def show
        home_spotlight = HomeSpotlight
          .with_attached_images
          .with_attached_image
          .active
          .first

        render json: {
          home_spotlight: home_spotlight.present? ? HomeSpotlightSerializer.new(home_spotlight, request: request).as_json : nil
        }
      end
    end
  end
end
